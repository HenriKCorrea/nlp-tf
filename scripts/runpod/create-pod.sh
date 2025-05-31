curl --request POST \
  --url https://rest.runpod.io/v1/pods \
  --header "Authorization: Bearer $(gopass show -o cloud/runpod/api)" \
  --header 'Content-Type: application/json' \
  --data '{
  "allowedCudaVersions": [],
  "cloudType": "COMMUNITY",
  "computeType": "GPU",
  "containerDiskInGb": 500,
  "containerRegistryAuthId": "clzdaifot0001l90809257ynb",
  "countryCodes": [],
  "cpuFlavorIds": [],
  "cpuFlavorPriority": "availability",
  "dataCenterIds": [
    "EU-RO-1",
    "CA-MTL-1",
    "EU-SE-1",
    "US-IL-1",
    "EUR-IS-1",
    "EU-CZ-1",
    "US-TX-3",
    "EUR-IS-2",
    "US-KS-2",
    "US-GA-2",
    "US-WA-1",
    "US-TX-1",
    "CA-MTL-3",
    "EU-NL-1",
    "US-TX-4",
    "US-CA-2",
    "US-NC-1",
    "OC-AU-1",
    "US-DE-1",
    "EUR-IS-3",
    "CA-MTL-2",
    "AP-JP-1",
    "EUR-NO-1",
    "EU-FR-1",
    "US-KS-3",
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
  "name": "dev-pod",
  "ports": [
    "8888/http,22/tcp"
  ],
  "supportPublicIp": true,
  "vcpuCount": 2,
  "volumeInGb": 20,
  "volumeMountPath": "/workspace"
}'