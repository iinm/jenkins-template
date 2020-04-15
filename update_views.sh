#!/usr/bin/env bash

set -eu

: "${VIEW_DIR:="./views"}"

for view_dir in "$VIEW_DIR"/*; do
  view_name=$(basename "$view_dir")
  echo "--- Update view $view_name"

  # shellcheck disable=SC2016
  view_xml=$(env VIEW_NAME="$view_name" envsubst '$VIEW_NAME' < ./view_template.xml)
  echo "$view_xml"

  if ! (echo "$view_xml" | ./jenkins-cli create-view "$view_name"); then
    echo "$view_xml" | ./jenkins-cli update-view "$view_name"
  fi

  for script in "$view_dir"/*.groovy; do
    job_name=$(basename "$script" | sed 's/.groovy$//')
    echo "add job to view.  view=$view_name job=$job_name"
    ./jenkins-cli add-job-to-view "$view_name" "$job_name"
  done
done
