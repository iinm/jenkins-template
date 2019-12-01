#!/usr/bin/env bash

set -eu

: "${GIT_URL:="$(git config --get remote.origin.url)"}"
: "${GIT_BRANCH:="$(git rev-parse --abbrev-ref HEAD)"}"
: "${GIT_CREDENTIAL_ID?}"

for script in ./jobs/*.groovy; do
  job_name=$(basename "$script" | sed s/.groovy$//)
  echo "--- Update job $job_name"

  # shellcheck disable=SC2016
  job_xml=$(env GIT_URL="$GIT_URL" GIT_CREDENTIAL_ID="$GIT_CREDENTIAL_ID" GIT_BRANCH="$GIT_BRANCH" SCRIPT_PATH="$script" envsubst '$GIT_URL $GIT_CREDENTIAL_ID $GIT_BRANCH $SCRIPT_PATH' < ./job_template.xml)
  echo "$job_xml"

  if ! (echo "$job_xml" | ./jenkins-cli create-job "$job_name"); then
    echo "$job_xml" | ./jenkins-cli update-job "$job_name"
  fi
  ./jenkins-cli build "$job_name" -s -p JUST_RELOAD_JENKINSFILE=true || true
done
