#!/bin/bash
# See https://docs.runpod.io/api-reference/pods/GET/pods

list_pods_ssh_api() {
  # Prepare the request command with necessary headers and parameters
  query_params=()
  query_params+=("includeMachine=true")
  query_params+=("includeNetworkVolume=true")
  
  request_cmd=("curl" "--request" "GET")
  request_cmd+=("--url" "https://rest.runpod.io/v1/pods?$(IFS='&'; echo "${query_params[*]}")")
  request_cmd+=("--header" "Authorization: Bearer $(gopass show -o cloud/runpod/api)")
  request_cmd+=("--header" "Content-Type: application/json")

  parse_cmd=("jq" "-r")
  parse_cmd+=('map("ssh root@" + .publicIp + " -p " + (.portMappings."22" | tostring) ) | .[]')

  # Execute the request
  "${request_cmd[@]}" | "${parse_cmd[@]}"
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  list_pods_ssh_api "$@"
fi
