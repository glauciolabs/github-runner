#!/bin/bash

if [[ -n "$RUNNER_NAME" ]]; then
  if [[ "$RUNNER_NAME" != github-runner-* ]]; then
    NAME_ARG="--name github-runner-$RUNNER_NAME"
  else
    NAME_ARG="--name $RUNNER_NAME"
  fi
else
  NAME_ARG="--name github-runner-linux"
fi

if [ -z "$GITHUB_URL" ]; then
  echo "Error: The GITHUB_URL environment variable is required."
  exit 1
fi

# Se o RUNNER_TOKEN for um PAT (ghp_ ou github_pat_), obter o Registration Token e Remove Token automaticamente
if [[ "$RUNNER_TOKEN" == ghp_* ]] || [[ "$RUNNER_TOKEN" == github_pat_* ]]; then
  echo "Personal Access Token (PAT) detectado. Solicitando Registration Token temporário à API do GitHub..."
  TARGET_PATH=$(echo "$GITHUB_URL" | sed -e 's|^https://github.com/||')
  
  if [[ "$TARGET_PATH" == *"/"* ]]; then
    REG_API_URL="https://api.github.com/repos/${TARGET_PATH}/actions/runners/registration-token"
    REMOVE_API_URL="https://api.github.com/repos/${TARGET_PATH}/actions/runners/remove-token"
  else
    REG_API_URL="https://api.github.com/orgs/${TARGET_PATH}/actions/runners/registration-token"
    REMOVE_API_URL="https://api.github.com/orgs/${TARGET_PATH}/actions/runners/remove-token"
  fi

  # Usar "Bearer" no Header para suportar tanto ghp_ (Classic PAT) quanto github_pat_ (Fine-Grained PAT)
  REG_TOKEN=$(curl -sX POST -H "Authorization: Bearer $RUNNER_TOKEN" -H "Accept: application/vnd.github+json" "$REG_API_URL" | jq -r '.token')
  REMOVE_TOKEN=$(curl -sX POST -H "Authorization: Bearer $RUNNER_TOKEN" -H "Accept: application/vnd.github+json" "$REMOVE_API_URL" | jq -r '.token')

  if [[ "$REG_TOKEN" == "null" || -z "$REG_TOKEN" ]]; then
    echo "Erro: Não foi possível obter o Registration Token com o PAT fornecido. Verifique se o PAT possui permissões 'admin:org' ou 'repo'."
    exit 1
  fi
  AUTH_ARG="--token $REG_TOKEN"
else
  AUTH_ARG="--token $RUNNER_TOKEN"
fi

cleanup() {
  echo "Received termination signal. Removing runner from GitHub..."
  if [[ -n "$REMOVE_TOKEN" && "$REMOVE_TOKEN" != "null" ]]; then
    ./config.sh remove --token "$REMOVE_TOKEN" || true
  else
    ./config.sh remove $AUTH_ARG || true
  fi
}

trap 'cleanup' SIGINT SIGTERM EXIT

echo "Registering runner with GitHub..."
if [[ -n "$RUNNER_GROUP" ]]; then
  ./config.sh --url "$GITHUB_URL" $AUTH_ARG --unattended --replace $NAME_ARG --runnergroup "$RUNNER_GROUP" || \
  ./config.sh --url "$GITHUB_URL" $AUTH_ARG --unattended --replace $NAME_ARG
else
  ./config.sh --url "$GITHUB_URL" $AUTH_ARG --unattended --replace $NAME_ARG
fi

echo "Starting runner..."
./run.sh &
PID=$!
wait $PID || true
