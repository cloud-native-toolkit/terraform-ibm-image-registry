#!/usr/bin/env bash

REGISTRY_NAMESPACE="$1"
RESOURCE_GROUP="$2"
REGION="$3"

# The name of a registry namespace cannot contain uppercase characters
# Lowercase the resource group name, just in case...
REGISTRY_NAMESPACE=$(echo "$REGISTRY_NAMESPACE" | tr '[:upper:]' '[:lower:]')

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
echo "Checking registry namespace: ${REGISTRY_NAMESPACE}"
NS=$(ibmcloud cr namespaces | grep "${REGISTRY_NAMESPACE}" ||: )
if [[ -z "${NS}" ]]; then
    echo -e "Registry namespace ${REGISTRY_NAMESPACE} not found, creating it."
    set -e
    ibmcloud cr namespace-add "${REGISTRY_NAMESPACE}" -g "${RESOURCE_GROUP}" || exit 1
else
    echo -e "Registry namespace ${REGISTRY_NAMESPACE} found."
fi
