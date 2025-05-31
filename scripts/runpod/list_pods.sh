#!/bin/bash
# Retrieve a list of all RunPod pods using the RunPod API.
# Ensure gopass is installed and configured to retrieve the API key
# Usage: ./list_pods.sh

list_pods_api() {
    curl --request GET \
    --url https://rest.runpod.io/v1/pods \
    --header "Authorization: Bearer $(gopass show -o cloud/runpod/api)"
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  list_pods_api "$@"
fi
