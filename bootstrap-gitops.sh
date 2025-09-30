#!/bin/bash

ELAPSED_SECONDS=0
INTERVAL_SECONDS=15
TIMEOUT_SECONDS=300

# Ensure that cluster argument is always passed through
if [ $# -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    echo "Error: You must provide OpenShift cluster name as an argument"
    exit 1
fi

CLUSTER=$1

echo "Use kustomize to intialise OpenShift GitOps operator onto cluster..."
oc apply -k post-config/gitops-operator/overlays/${CLUSTER}/

echo -e "\nWait until OpenShift GitOps operator has been installed successfully..."

while [ $ELAPSED_SECONDS -lt $TIMEOUT_SECONDS ]
do

  STATUS=$(oc get argocd openshift-gitops -n openshift-gitops -o jsonpath="{.status.phase}")

  if [ "$STATUS" == "Available" ]; then
    echo "OpenShift GitOps operator is running successfully (Phase: $STATUS)."
    break
  else
    echo "Waiting for operator to be ready... (Current Phase: ${STATUS})"
    sleep $INTERVAL_SECONDS
    ELAPSED_SECONDS=$((ELAPSED_SECONDS + INTERVAL_SECONDS))
  fi

done

# final check at timeout
STATUS=$(oc get argocd openshift-gitops -n openshift-gitops -o jsonpath="{.status.phase}")

if [ "$STATUS" != "Available" ]; then
    echo "Timed out after $TIMEOUT_SECONDS seconds waiting for the OpenShift GitOps operator."
    exit 1
fi

echo -e "\nBootstrapping GitOps for ${CLUSTER}..."
oc create -f cluster-apps/${CLUSTER}/post-config.yaml -n openshift-gitops
