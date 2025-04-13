#!/bin/bash

WORKFLOW_NAME="Build OpenSSH mipsel"
GITHUB_TOKEN="$1"
GITHUB_REPOSITORY="$2"
GITHUB_REF="$3"
#JOBNAME="build"

function githubenv_set() {
	var_name="$1"         # Получаем имя переменной
	var_value="${!1}"     # Получаем значение переменной по имени
	#echo "$var_name=$var_value"
	echo "$var_name=$var_value" >> "$GITHUB_ENV"
}

function del_skip_deploy(){
DEPLOY_STATUS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$LAST_RUN/jobs" | jq -r '.jobs[] | select(.name == "build (ubuntu-latest, mipsel)") | .conclusion')
# Проверяем статус job с именем 'deploy'
if [ "$DEPLOY_STATUS" == "success" ]; then
    echo "Job '$JOBNAME' completed successfully."
elif [ -z "$DEPLOY_STATUS" ]; then
    echo "Build..."  
else
    echo "Job '$JOBNAME' did not succeed or has not completed yet."
    curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$LAST_RUN"
fi
}

LAST_RUN=$(curl -s "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs?branch=$GITHUB_REF&status=completed" | \
    jq --arg WORKFLOW_NAME "$WORKFLOW_NAME" '.workflow_runs[] | select(.conclusion == "success" and .name == $WORKFLOW_NAME) | .id' | head -n 1)

del_skip_deploy
# get tar.gz curl -s https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/ | grep -oP 'openssh-\d+\.\d+p\d+\.tar\.gz' | sort -V | tail -n 1
#function last-veracrypt-version(){
# Получение последней версии VeraCrypt
LAST_SSH_VERSION=$(curl -s "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/" | grep -oP 'openssh-\K\d+\.\d+p\d+(?=\.tar\.gz)' | sort -V | tail -n 1)
#echo "last vera=$LAST_VERACRYPT_VERSION"
# Укажите название вашего workflow

# Получаем ID workflow по его имени
#WORKFLOW_ID=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
#  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows" | \
#  jq -r ".workflows[] | select(.name == \"$WORKFLOW_NAME\") | .id")
#echo "wf ID $WORKFLOW_ID"

# Найдем последний успешный запуск
LAST_RUN=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs?branch=$GITHUB_REF&status=completed" | \
  jq --arg WORKFLOW_NAME "$WORKFLOW_NAME" '.workflow_runs[] | select(.conclusion == "success" and .name == $WORKFLOW_NAME) | .id' | head -n 1)

# Получение артефактов из последнего успешного запуска
if [ -n "$LAST_RUN" ]; then
  ARTIFACTS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${LAST_RUN}/artifacts" | \
    jq -r '.artifacts[] | select(.name | contains("mipsel")) | .name')
  LAST_ARTIFACT_VERSION=$(echo "$ARTIFACTS" | grep -oP '(?<=openssh-)\d+\.\d+p\d+')
else
  echo "No successful runs found for the specified workflow."
  LAST_ARTIFACT_VERSION=0
fi

function get_vers(){
echo "aget_vers"
for prog in DEPLOY_STATUS LAST_SSH_VERSION LAST_RUN ARTIFACTS LAST_ARTIFACT_VERSION ; do
    echo "$prog=${!prog}"
	githubenv_set $prog
done
}
get_vers