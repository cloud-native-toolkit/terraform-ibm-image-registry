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

echo "Getting current global pull secret"
oc extract secret/pull-secret -n openshift-config --to="${GLOBAL_DIR}"

if grep -q "icr.io" "${GLOBAL_DIR}/.dockerconfigjson"; then
  echo "The global pull secret already contains the values for icr.io. Nothing to do"
  exit 0
fi

echo "Getting icr pull secret"
oc extract secret/all-icr-io -n default --to="${ICR_DIR}"

echo "Merging pull secrets"
jq -s '.[0] * .[1]' "${GLOBAL_DIR}/.dockerconfigfile" "${ICR_DIR}/.dockerconfigfile" > "${RESULT_FILE}"


echo "Updating global pull secret"
oc set data secret/pull-secret -n openshift-config --from-file=".dockerconfigjson=${RESULT_FILE}"