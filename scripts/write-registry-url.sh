#!/usr/bin/env bash

REGION="$1"
REGISTRY_URL_FILE="$2"

if [[ "${REGION}" =~ "us-" ]]; then
  REGION="us-south"
elif [[ "${REGION}" == "eu-gb" ]]; then
  REGION="uk-south"
elif [[ "${REGION}" =~ "eu-" ]]; then
  REGION="eu-central"
elif [[ "${REGION}" =~ "jp-" ]]; then
  REGION="ap-north"
elif [[ "${REGION}" =~ "ap-" ]]; then
  REGION="ap-south"
fi

ibmcloud cr region-set "${REGION}"

REGISTRY_URL=$(ibmcloud cr region | grep "icr.io" | sed -E "s/.*'(.*icr.io)'.*/\1/")
if [[ -n "${REGISTRY_URL_FILE}" ]]; then
  echo -n "${REGISTRY_URL}" > "${REGISTRY_URL_FILE}"
fi
