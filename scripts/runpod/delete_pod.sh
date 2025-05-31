#!/bin/bash
#
# delete_pod.sh - Delete RunPod pods by ID using the RunPod API.
#
# Usage:
#   delete_pod.sh POD_ID [POD_ID ...]
#     Delete one or more pods by specifying their IDs as arguments.
#   delete_pod.sh < POD_ID_FILE
# 
# Description:
#   This script deletes RunPod pods using the REST API. You can provide pod IDs
#   as command-line arguments, or pipe them via standard input. The script
#   requires a valid API token, which is retrieved using gopass.
#
# Requirements:
#   - curl
#   - gopass (with the API token stored at cloud/runpod/api)
#
# Examples:
#   ./delete_pod.sh pod123 pod456
#   echo "pod123" | ./delete_pod.sh
#   ./list_pods_id.sh | ./delete_pod.sh
#
# Exit Codes:
#   0  Success
#   1  Failure
#
# See https://docs.runpod.io/api-reference/pods/DELETE/pods

delete_pod_api() {
  url="https://rest.runpod.io/v1/pods"

  delete_cmd=("curl" "--request" "DELETE")
  delete_cmd+=("--header" "Authorization: Bearer $(gopass show -o cloud/runpod/api)")

  # Iterate over each pod ID provided as argument
  for pod_id in "$@"; do
    # Execute the delete command
    if "${delete_cmd[@]}" --url "$url/$pod_id"; then
      echo "Deleted pod $pod_id" 1>&2
    fi
  done

  # Iterate over each pod ID from stdin (if file descriptor is used)
  if [[ ! -t 0 ]]; then
    while IFS= read -r pod_id; do
      # Execute the delete command
      if "${delete_cmd[@]}" --url "$url/$pod_id"; then
        echo "Deleted pod $pod_id" 1>&2
      fi
    done
  fi
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  delete_pod_api "$@"
fi
