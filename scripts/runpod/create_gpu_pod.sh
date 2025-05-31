#!/bin/bash
# This script creates a new GPU pod with the specified configuration.
# Ensure gopass is installed and configured to retrieve the API key

create_gpu_pod_api() {
    request_cmd=("curl" "--request" "POST")
    request_cmd+=("--url" "https://rest.runpod.io/v1/pods")
    request_cmd+=("--header" "Authorization: Bearer $(gopass show -o cloud/runpod/api)")
    request_cmd+=("--header" "Content-Type: application/json")
    payload='{
    "allowedCudaVersions": [],
    "cloudType": "COMMUNITY",
    "computeType": "GPU",
    "containerDiskInGb": 500,
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
        "ENV_VAR": "value"
    },
    "globalNetworking": true,
    "gpuCount": 1,
    "gpuTypeIds": [
        "NVIDIA RTX A4000"
    ],
    "gpuTypePriority": "custom",
    "imageName": "runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04",
    "interruptible": false,
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
    "vcpuCount": 2,
    "volumeInGb": 20,
    "volumeMountPath": "/workspace"
    }'
    request_cmd+=("--data" "$payload")

    # Execute the request
    "${request_cmd[@]}"
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  create_gpu_pod_api "$@"
fi
