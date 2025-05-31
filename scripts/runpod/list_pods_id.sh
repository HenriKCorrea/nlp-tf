#!/bin/bash
# See https://docs.runpod.io/api-reference/pods/GET/pods

list_pods_id_api() {

  request_cmd=("curl" "--request" "GET")
  request_cmd+=("--url" "https://rest.runpod.io/v1/pods")
  request_cmd+=("--header" "Authorization: Bearer $(gopass show -o cloud/runpod/api)")

  parse_cmd=("jq" "-r")
  parse_cmd+=('.[].id')

  # Execute the request and parse the output
  "${request_cmd[@]}" | "${parse_cmd[@]}"
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  list_pods_id_api "$@"
fi
