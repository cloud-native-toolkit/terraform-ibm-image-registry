#!/usr/bin/env bash

CLUSTER_TYPE="$1"

if [[ ! "${CLUSTER_TYPE}" =~ ocp4 ]]; then
  echo "The cluster is not an OpenShift 4.x cluster. Skipping global pull secret"
  exit 0
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR="${PWD}/tmp"
fi
mkdir -p "${TMP_DIR}"

GLOBAL_DIR="${TMP_DIR}/pull-secret/global"
ICR_DIR="${TMP_DIR}/pull-secret/icr"
RESULT_FILE="${TMP_DIR}/pull-secret/config.json"

mkdir -p "${GLOBAL_DIR}"
mkdir -p "${ICR_DIR}"

if ! oc get secret/all-icr-io -n default 1> /dev/null 2> /dev/null; then
  echo "IBM Cloud pull secret does not exist. Exiting"
  exit 0
fi

echo "Getting current global pull secret"
oc extract secret/pull-secret -n openshift-config --to="${GLOBAL_DIR}" --confirm
if [[ ! -f "${GLOBAL_DIR}/.dockerconfigjson" ]]; then
  echo "Error retrieving global pull secret"
  exit 0
fi

if grep -q "icr.io" "${GLOBAL_DIR}/.dockerconfigjson"; then
  echo "The global pull secret already contains the values for icr.io. Nothing to do"
  exit 0
fi

echo "Getting icr pull secret"
oc extract secret/all-icr-io -n default --to="${ICR_DIR}" --confirm
if [[ ! -f "${ICR_DIR}/.dockerconfigjson" ]]; then
  echo "Error retrieving icr pull secret"
  exit 0
fi

echo "Merging pull secrets"
jq -s '.[0] * .[1]' "${GLOBAL_DIR}/.dockerconfigjson" "${ICR_DIR}/.dockerconfigjson" > "${RESULT_FILE}"

RESULT_BASE64=$(base64 < "${RESULT_FILE}")
PATCH="[{\"op\": \"replace\", \"path\": \"/data/.dockerconfigjson\", \"value\": \"${RESULT_BASE64}\"}]"

echo "Patching global pull secret"
oc patch secret pull-secret -n openshift-config --type=json -p="${PATCH}"
