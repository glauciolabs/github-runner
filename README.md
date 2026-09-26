# GitHub Self-Hosted Runner for Kubernetes

This repository contains the container image source, entrypoint scripts, and Kubernetes manifests for deploying auto-scaling **GitHub Self-Hosted Runners** on Kubernetes clusters.

---

## 🚀 Authentication & Registration Mechanics

The container entrypoint (`entrypoint.sh`) supports **two authentication modes**:

1. **Personal Access Token (PAT) — Recommended for Production:**
   - When provided with a PAT (`ghp_...` or `github_pat_...`), the runner automatically requests a fresh, short-lived registration token from the GitHub REST API every time a pod starts or restarts.
   - **No 1-hour expiration limit!** Pods can restart indefinitely without manual intervention.

2. **Temporary Registration Token:**
   - Single-use token generated from GitHub UI or `gh` CLI. Valid for 60 minutes.

---

## 🔑 How to Create a Personal Access Token (PAT)

### Method 1: Via GitHub Web UI

1. Navigate to GitHub and click your profile picture in the top-right corner -> **Settings**.
2. In the left sidebar, scroll down to **Developer settings**.
3. Select **Personal access tokens** -> **Tokens (classic)**.
4. Click **Generate new token** -> **Generate new token (classic)**.
5. Provide a descriptive name (e.g., `k8s-github-runner`).
6. Select the required **Scopes**:
   - **`admin:org`**: Required for organization-level runners (`https://github.com/glauciolabs`).
   - **`repo`**: Required for repository-level runners (`https://github.com/glauciolabs/<repo>`).
   - **`write:packages` / `read:packages`**: Required if pulling or pushing images to GitHub Container Registry (`ghcr.io`).
7. Click **Generate token** and copy the generated key (`ghp_xxxxxxxxxxxx`).

---

### Method 2: Token Management via `gh` CLI

Verify your active GitHub authentication and permissions:

```bash
gh auth status
```

Generate an Organization Runner Registration Token:

```bash
gh api -X POST /orgs/glauciolabs/actions/runners/registration-token --jq '.token'
```

Generate a Repository-Level Runner Registration Token:

```bash
gh api -X POST /repos/glauciolabs/drupal-app/actions/runners/registration-token --jq '.token'
```

---

## 🐳 Local Testing via Docker

Build the local Docker image:

```bash
docker build -t github-runner:test -f container/Dockerfile container/
```

Run a test container locally:

```bash
# Obtain a fresh token
TOKEN=$(gh api -X POST /orgs/glauciolabs/actions/runners/registration-token --jq '.token')

docker run --rm \
  -e GITHUB_URL="https://github.com/glauciolabs" \
  -e RUNNER_GROUP="k8s-runners" \
  -e RUNNER_TOKEN="$TOKEN" \
  -e RUNNER_NAME="gcs-1" \
  github-runner:test
```

---

## ☸️ Kubernetes Deployment & Secret Management

### 1. Create GHCR Image Pull Secret

To allow Kubernetes to pull the runner container image from GitHub Container Registry (`ghcr.io`), create the `ghcr-secret` in the target namespace (`github-runner`):

```bash
kubectl create secret docker-registry ghcr-secret \
  --namespace=github-runner \
  --docker-server=ghcr.io \
  --docker-username=glauciocampos \
  --docker-password=YOUR_PAT_WITH_READ_PACKAGES \
  --docker-email=your-email@domain.com
```

### 2. Configure Runner Credentials Secret

Update `kubernetes/base/secrets.yml` or inject via your Secret Manager / KeyVault:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-runner-secrets
  namespace: github-runner
type: Opaque
stringData:
  GITHUB_URL: "https://github.com/glauciolabs"
  RUNNER_GROUP: "k8s-runners"
  RUNNER_TOKEN: "ghp_YOUR_PERSONAL_ACCESS_TOKEN"
```

### 3. Apply Kubernetes Manifests

```bash
kubectl apply -k kubernetes/base/
```

Each runner pod will automatically register under the format `github-runner-<k8s-nodename>` (e.g. `github-runner-gcs-1`, `github-runner-h89-1`, `github-runner-gww-1`) and clean up upon termination.