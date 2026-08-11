#!/bin/bash

if [[ -n "$RUNNER_NAME" ]]; then
  NAME_ARG="--name $RUNNER_NAME"
else
  NAME_ARG="--name linux-runner"
fi

if [[ -n "$RUNNER_TOKEN" ]]; then
  AUTH_ARG="--token $RUNNER_TOKEN"
else
  echo "Authentication method not provided, please provide either RUNNER_TOKEN"
  exit 1
fi

if [[ -n "$RUNNER_GROUP" ]]; then
  RUNNER_GROUP_ARG="--runnergroup $RUNNER_GROUP"
else
  RUNNER_GROUP_ARG="--runnergroup Default"
fi

if [ -z "$GITHUB_URL" ]; then
  echo "Error: The GITHUB_URL environment variable is required."
  exit 1
fi

cleanup() {
  echo "Received termination signal. Removing runner from GitHub..."
  ./config.sh remove $AUTH_ARG
}

trap 'cleanup' SIGINT SIGTERM EXIT

echo "Registering runner with GitHub..."
./config.sh --url "$GITHUB_URL" $AUTH_ARG --unattended --replace $NAME_ARG "$RUNNER_GROUP_ARG"

echo "Starting runner..."
./run.sh &
PID=$!
wait $PID || true


