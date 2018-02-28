#!/bin/bash

echo "Cleaning project $(oc project --short) in cluster $OPENSHIFT_CLUSTER"

if [[ "$OPENSHIFT_CLUSTER" =~ "local" ]] && grep -q fake /my-secrets/clusters/$OPENSHIFT_CLUSTER-token ; then
  # in development, there's no separate namespace just for running tests
  echo "Actually no, this is development environment"
else
  oc delete all --all
fi
