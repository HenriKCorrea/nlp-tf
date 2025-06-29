#!/bin/bash
# See https://docs.runpod.io/api-reference/pods/GET/pods

_list_pods() {
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

_parse_ssh_exposed_tcp() {
  # Parse the JSON response to extract SSH connection details
  parse_cmd=("jq" "-r")
  parse_cmd+=('map("ssh root@" + .publicIp + " -p " + (.portMappings."22" | tostring) ) | .[]')

  # Execute the parsing command
  "${parse_cmd[@]}"
}

_get_pod_hostname() {
  # Get the pod hostname by executing an SSH command
  ssh_command_cmd=($@)
  ssh_command_cmd+=("-t" 'bash -i -c "echo \$RUNPOD_POD_HOSTNAME"')
  parse_tail_cmd=("tail" "-n" "1")
  
  # Execute the SSH command to get the pod hostname
  "${ssh_command_cmd[@]}" 2>/dev/null | "${parse_tail_cmd[@]}"
}

_list_pods_ssh() {
  # Read lines from stdin and process each SSH connection string
  while IFS= read -r ssh_connection_string; do
    # Extract the pod hostname from the SSH connection string
    pod_hostname="$(_get_pod_hostname "$ssh_connection_string")"
    echo "$ssh_connection_string"
    if [[ -n "$pod_hostname" ]]; then
      # sprintf "ssh %s@ssh.runpod.io -i ~/.ssh/id_ed25519\n" "$pod_hostname"
      printf "ssh %s@ssh.runpod.io\n" "$pod_hostname"
    fi
  done
}

list_pods_ssh_api() {
  _list_pods | _parse_ssh_exposed_tcp | _list_pods_ssh
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  list_pods_ssh_api "$@"
fi
