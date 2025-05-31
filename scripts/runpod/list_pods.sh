#!/bin/bash
# Retrieve a list of all RunPod pods using the RunPod API.
# Ensure gopass is installed and configured to retrieve the API key
# Usage: ./list_pods.sh
# See https://docs.runpod.io/api-reference/pods/GET/pods

list_pods_api() {
  # Prepare the request command with necessary headers and parameters
  query_params=()
  query_params+=("includeMachine=true")
  query_params+=("includeNetworkVolume=true")
  
  request_cmd=("curl" "--request" "GET")
  request_cmd+=("--url" "https://rest.runpod.io/v1/pods?$(IFS='&'; echo "${query_params[*]}")")
  request_cmd+=("--header" "Authorization: Bearer $(gopass show -o cloud/runpod/api)")
  request_cmd+=("--header" "Content-Type: application/json")

  # Execute the request
  "${request_cmd[@]}"
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  list_pods_api "$@"
fi
