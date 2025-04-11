#!/bin/bash

WORKFLOW_NAME="Build OpenSSH mipsel"
GITHUB_TOKEN="$1"
GITHUB_REPOSITORY="$2"
GITHUB_REF="$3"
JOBNAME="build (ubuntu-latest, mipsel)"

function githubenv_set(){
    local var_name="$1"
    local var_value="${!var_name}"
    echo "$var_name=$var_value" >> "$GITHUB_ENV"
}

function del_skip_deploy(){
DEPLOY_STATUS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$LAST_RUN/jobs" | jq -r '.jobs[] | select(.name == "build") | .conclusion')
# Проверяем статус job с именем 'deploy'
if [ "$DEPLOY_STATUS" == "success" ]; then
    echo "Job '$JOBNAME' completed successfully."
elif [ "$DEPLOY_STATUS" == "skipped" ]; then
    echo "Job '$JOBNAME' did not succeed or has not completed yet."
    curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$LAST_RUN"
elif [ -z "$DEPLOY_STATUS" ]; then
    echo "Build..."
else
    echo "Job '$JOBNAME' did not succeed or has not completed yet."
    curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$LAST_RUN"
fi
}

LAST_RUN=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs?branch=$GITHUB_REF&status=completed" | \
  jq --arg WORKFLOW_NAME "$WORKFLOW_NAME" '.workflow_runs[] | select(.conclusion == "success" and .name == $WORKFLOW_NAME) | .id' | head -n 1)

if [ -n $LAST_RUN ] ; then
del_skip_deploy
fi

# Получение последней версии
LAST_SSH_VERSION=$(curl -s "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/" | grep -oP 'openssh-\K\d+\.\d+p\d+(?=\.tar\.gz)' | sort -V | tail -n 1)
# Найдем последний успешный запуск
LAST_RUN=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs?branch=$GITHUB_REF&status=completed" | \
  jq --arg WORKFLOW_NAME "$WORKFLOW_NAME" '.workflow_runs[] | select(.conclusion == "success" and .name == $WORKFLOW_NAME) | .id' | head -n 1)
#echo "LAST_RUN=$LAST_RUN"
# Получение артефактов из последнего успешного запуска
if [ $? -eq 1 ] || [ -z $LAST_RUN ]; then
  echo "Build..."
  LAST_ARTIFACT_VERSION="0"
elif [ -n "$LAST_RUN" ]; then
  ARTIFACTS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${LAST_RUN}/artifacts" | \
    jq -r '.artifacts[] | select(.name | contains("openssh")) | .name')
  LAST_ARTIFACT_VERSION=$(echo "$ARTIFACTS" | grep -oP '(?<=openssh-)\d+\.\d+p\d+')
else
  echo "No successful runs found for the specified workflow."
  echo "No artifacts found."
  #exit 1
  LAST_ARTIFACT_VERSION="0"
fi

function get_vers() {
    echo "Setting GitHub environment variables..."
    for prog in DEPLOY_STATUS LAST_SSH_VERSION LAST_RUN ARTIFACTS LAST_ARTIFACT_VERSION; do
        echo "$prog=${!prog}"  # Для отладки
        githubenv_set "$prog"
    done
}
get_vers

