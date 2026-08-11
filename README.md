# Kubernetes GitHub Actions Self-Hosted Runner

A multi-architecture (`linux/amd64`, `linux/arm64`) containerized GitHub Actions Self-Hosted Runner designed for Kubernetes deployments.

## Features

- **Multi-Architecture Support**: Built for both `x86_64` (`amd64`) and `arm64` architectures.
- **Dynamic Registration & Graceful Cleanup**:
  - Automatically registers with GitHub Actions on startup.
  - Intercepts termination signals (`SIGTERM`, `SIGINT`, `EXIT`) via Bash `trap` to cleanly deregister and remove the runner from GitHub when the Pod or container stops.
- **Pre-installed Tooling**:
  - **Runtimes & SDKs**: .NET 10, Node.js 26 (Yarn), OpenJDK 25, Go 1.26, Python 3 (Poetry).
  - **DevOps & Security CLI**: `kubectl`, `helm`, `argocd`, `trivy`, `snyk`.

---

## Environment Variables

| Variable | Required | Description | Default |
| :--- | :---: | :--- | :--- |
| `GITHUB_URL` | **Yes** | Target GitHub Organization or Repository URL (e.g., `https://github.com/glauciolabs`) | - |
| `RUNNER_TOKEN` | **Yes** | GitHub Actions Runner Registration Token | - |
| `RUNNER_NAME` | No | Custom name for the runner instance | `linux-runner` (or Pod name in Kubernetes) |
| `RUNNER_GROUP` | No | Target Runner Group in GitHub | `Default` |

---

## Getting Started

### 1. Docker (Local Testing)

Build and run locally with Docker:

```bash
# Build the image
docker build -t github-runner:latest -f container/Dockerfile container/

# Run the container
docker run -d --network=host \
  -e GITHUB_URL="https://github.com/your-org" \
  -e RUNNER_TOKEN="YOUR_REGISTRATION_TOKEN" \
  -e RUNNER_NAME="local-runner" \
  --name github-runner \
  github-runner:latest
```

Stop the container to verify graceful deregistration:

```bash
docker stop github-runner
```

---

### 2. Kubernetes Deployment

#### Secrets Setup

Configure `kubernetes/production/secrets.yml` (encode values in Base64 or use SealedSecrets/Kustomize secretGenerator):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-runner-secrets
type: Opaque
stringData:
  GITHUB_URL: "https://github.com/your-org"
  RUNNER_TOKEN: "YOUR_REGISTRATION_TOKEN"
  RUNNER_GROUP: "Default"
```

#### Deploying to Kubernetes

Apply the manifests:

```bash
kubectl apply -k kubernetes/production/
```

Scale up or down gracefully:

```bash
# Scale replicas
kubectl scale deployment github-runner --replicas=3 -n default
```

When pods are terminated or scaled down, Kubernetes sends a `SIGTERM` signal, causing the runner to cleanly unregister from GitHub before exiting.

---

## Project Structure

```text
.
├── container/
│   ├── Dockerfile         # Multi-stage image build definition
│   └── entrypoint.sh      # Signal trapping, startup registration & cleanup script
└── kubernetes/
    └── production/
        ├── deployment.yml # Kubernetes Deployment manifest
        ├── secrets.yml    # Kubernetes Secret configuration
        └── kustomization.yml
```
