#!/bin/bash
# This script creates a new GPU pod with the specified configuration.
# Ensure gopass is installed and configured to retrieve the API key
# See https://docs.runpod.io/api-reference/pods/POST/pods

_generate_payload_template() {
    cat <<EOF
{
    "allowedCudaVersions": [],
    "cloudType": "COMMUNITY",
    "computeType": "GPU",
    "containerDiskInGb": 300,
    "countryCodes": [],
    "dataCenterIds": [
        "US-TX-4",
        "US-IL-1",
        "US-TX-3",
        "US-GA-2",
        "US-WA-1",
        "US-TX-1",
        "US-KS-3",
        "EU-RO-1",
        "US-CA-2",
        "US-NC-1",
        "US-DE-1",
        "US-KS-2",
        "CA-MTL-1",
        "CA-MTL-3",
        "CA-MTL-2",
        "EU-SE-1",
        "EU-CZ-1",
        "EU-NL-1",
        "EUR-IS-1",
        "EUR-IS-2",
        "EUR-IS-3",
        "EUR-NO-1",
        "OC-AU-1",
        "AP-JP-1",
        "EU-FR-1",
        "US-GA-1"
    ],
    "dataCenterPriority": "availability",
    "dockerEntrypoint": [],
    "dockerStartCmd": [],
    "env": {
        "JUPYTER_PASSWORD": "{{ RUNPOD_SECRET_jupyter }}"
    },
    "globalNetworking": true,
    "gpuCount": 1,
    "gpuTypeIds": [
        "NVIDIA A100 80GB PCIe"
    ],
    "gpuTypePriority": "custom",
    "imageName": "runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04",
    "interruptible": true,
    "locked": false,
    "minDiskBandwidthMBps": 123,
    "minDownloadMbps": 123,
    "minRAMPerGPU": 8,
    "minUploadMbps": 123,
    "minVCPUPerGPU": 2,
    "name": "dev-pod-gpu",
    "ports": [
        "8888/http,22/tcp"
    ],
    "supportPublicIp": true,
    "vcpuCount": 2
}
EOF
}

# Retrieve payload from stdin.
# If payload cloudTipe is SECURE, attempt pick the first available network volume ID.
# When a network volume is available, add it to the payload as networkVolumeId and forward the payload.
# If cloudType is not SECURE or no network volumes are available, forward payload as it is.
_pick_network_volume_id() {
    # Parse stdin to get the payload
    payload="$(cat -)"
    # Check if the payload contains "cloudType" and is set to "SECURE"
    # Use jq for JSON parsing
    cloud_type="$(echo "$payload" | jq -r '.cloudType // empty')"

    # If cloudType is SECURE, proceed to get the network volume ID
    if [[ "$cloud_type" == "SECURE" ]]; then
        # Execute the request to get network volumes
        request_cmd=("curl" "--request" "GET")
        request_cmd+=("--url" "https://rest.runpod.io/v1/networkvolumes")
        request_cmd+=("--header" "Authorization: Bearer $(gopass show -o cloud/runpod/api)")

        parse_cmd=("jq" "-r")
        parse_cmd+=('if type=="array" then .[0].id else null end')
        network_volume_id="$("${request_cmd[@]}" | "${parse_cmd[@]}")"

        # If a network volume ID is found, add it to the payload
        if [[ -n "$network_volume_id" && "$network_volume_id" != "null" ]]; then
            add_network_volume=("jq"
                "--arg" "argVol" "$network_volume_id"
                '. + {"networkVolumeId": $argVol}')
            payload="$(echo "$payload" | "${add_network_volume[@]}")"
        fi
    fi

    # Forward the payload
    echo "$payload"
}

create_gpu_pod_api() {
    request_cmd=("curl" "--request" "POST")
    request_cmd+=("--url" "https://rest.runpod.io/v1/pods")
    request_cmd+=("--header" "Authorization: Bearer $(gopass show -o cloud/runpod/api)")
    request_cmd+=("--header" "Content-Type: application/json")
    payload="$(_generate_payload_template)"
    request_cmd+=("--data" "$payload")

    # Execute the request
    "${request_cmd[@]}"
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  create_gpu_pod_api "$@"
fi
