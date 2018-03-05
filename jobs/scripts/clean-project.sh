#!/bin/bash

echo "Cleaning project $(oc project --short) in cluster $OPENSHIFT_CLUSTER"

if [[ "$OPENSHIFT_CLUSTER" =~ "local" ]] && grep -q fake /my-secrets/clusters/$OPENSHIFT_CLUSTER-token ; then
  # in development, there's no separate namespace just for running tests
  echo "Actually no, this is development environment"
else
  # `|| true` because OpenShift Online Starter clusters have some strange access restrictions that cause failures;
  # see https://bugzilla.redhat.com/show_bug.cgi?id=1515703 for more info
  oc delete all --all || true
fi
