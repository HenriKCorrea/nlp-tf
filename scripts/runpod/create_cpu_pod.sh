#!/bin/bash
# This script creates a new CPU pod with the specified configuration.
# Ensure gopass is installed and configured to retrieve the API key
# See https://docs.runpod.io/api-reference/pods/POST/pods

create_cpu_pod_api() {
    request_cmd=("curl" "--request" "POST")
    request_cmd+=("--url" "https://rest.runpod.io/v1/pods")
    request_cmd+=("--header" "Authorization: Bearer $(gopass show -o cloud/runpod/api)")
    request_cmd+=("--header" "Content-Type: application/json")
    payload='{
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
        "RCLONE_CONFIG_NLP_TF_TYPE": "s3",
        "RCLONE_CONFIG_NLP_TF_PROVIDER": "DigitalOcean",
        "RCLONE_CONFIG_NLP_TF_ACCESS_KEY_ID": "DO801PGFZX74RBHNLYHK", 
        "RCLONE_CONFIG_NLP_TF_SECRET_ACCESS_KEY": "{{ RUNPOD_SECRET_S3_TOKEN }}",
        "RCLONE_CONFIG_NLP_TF_ENDPOINT": "sfo3.digitaloceanspaces.com"
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
    request_cmd+=("--data" "$payload")

    # Execute the request
    "${request_cmd[@]}"
}

# Check if the script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  create_cpu_pod_api "$@"
fi
