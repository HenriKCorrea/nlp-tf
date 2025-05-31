#!/bin/bash
# This script creates a new CPU pod with the specified configuration.
# Ensure gopass is installed and configured to retrieve the API key

create_cpu_pod_api() {

    curl --request POST \
    --url https://rest.runpod.io/v1/pods \
    --header "Authorization: Bearer $(gopass show -o cloud/runpod/api)" \
    --header 'Content-Type: application/json' \
    --data '{
    "allowedCudaVersions": [],
    "cloudType": "COMMUNITY",
    "computeType": "CPU",
    "containerDiskInGb": 5,
    "countryCodes": [],
    "cpuFlavorIds": [
        "cpu3c"
    ],
    "cpuFlavorPriority": "availability",
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
    "imageName": "runpod/base:0.5.1-cpu",
    "interruptible": false,
    "locked": false,
    "minDiskBandwidthMBps": 123,
    "minDownloadMbps": 123,
    "minUploadMbps": 123,
    "name": "dev-pod-cpu",
    "ports": [
        "8888/http,22/tcp"
    ],
    "supportPublicIp": true,
    "vcpuCount": 2,
    "volumeInGb": 20,
    "volumeMountPath": "/workspace"
    }'
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  create_cpu_pod_api "$@"
fi
