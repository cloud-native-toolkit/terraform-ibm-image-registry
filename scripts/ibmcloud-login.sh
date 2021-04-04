#!/usr/bin/env bash

REGION="$1"
RESOURCE_GROUP="$2"

if [[ -z "${APIKEY}" ]]; then
  echo "The APIKEY is required"
  exit 1
fi

ibmcloud login -r "${REGION}" -g "${RESOURCE_GROUP}" --apikey "${APIKEY}"
