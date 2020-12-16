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

GLOBAL_FILE="${TMP_DIR}/global.json"
ICR_FILE="${TMP_DIR}/icr.json"
RESULT_FILE="${TMP_DIR}/config.json"

echo "Getting current global pull secret"
oc get secret pull-secret -n openshift-config -o jsonpath='{ .data.\.dockerconfigjson }' | base64 -d > "${GLOBAL_FILE}"

if grep -q "icr.io" "${GLOBAL_FILE}"; then
  echo "The global pull secret already contains the values for icr.io. Nothing to do"
  exit 0
fi

echo "Getting icr pull secret"
oc get secret all-icr-io -n default -o jsonpath='{ .data.\.dockerconfigjson }' | base64 -d > "${ICR_FILE}"

echo "Merging pull secrets"
jq -s '.[0] * .[1]' "${GLOBAL_FILE}" "${ICR_FILE}" > "${RESULT_FILE}"

echo "Updating global pull secret"
oc set data secret/pull-secret -n openshift-config --from-file=".dockerconfigjson=${RESULT_FILE}"