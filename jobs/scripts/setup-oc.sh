#!/bin/bash

echo "OpenShift cluster $OPENSHIFT_CLUSTER"

API_SERVER=$(cat /my-secrets/clusters/$OPENSHIFT_CLUSTER-url)

OPENSHIFT_GIT_VERSION=$(curl --silent --insecure $API_SERVER/version/openshift | jq --raw-output .gitVersion)

echo "OpenShift version $OPENSHIFT_GIT_VERSION"

case "$OPENSHIFT_GIT_VERSION" in
  v1.4*|v3.4*)
    OC_URL=https://github.com/openshift/origin/releases/download/v1.4.1/openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz
    ;;
  v1.5*|v3.5*)
    OC_URL=https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz
    ;;
  v3.6*)
    OC_URL=https://github.com/openshift/origin/releases/download/v3.6.1/openshift-origin-client-tools-v3.6.1-008f2d5-linux-64bit.tar.gz
    ;;
  v3.7*)
    OC_URL=https://github.com/openshift/origin/releases/download/v3.7.1/openshift-origin-client-tools-v3.7.1-ab0f056-linux-64bit.tar.gz
    ;;
  v3.8*|v3.9*)
    OC_URL=https://mirror.openshift.com/pub/openshift-v3/clients/${OPENSHIFT_GIT_VERSION#v}/linux/oc.tar.gz
    ;;
  *)
    echo "Unknown OpenShift version"
    exit 1
    ;;
esac

echo "Downloading client tools $OC_URL"

curl --location --silent --output oc.tar.gz $OC_URL
tar xfz oc.tar.gz

mkdir -p $WORKSPACE/custom-bin
if [[ "$OC_URL" =~ "github" ]] ; then
  mv openshift-origin-client-tools*/oc $WORKSPACE/custom-bin
  rm -rf openshift-origin-client-tools
else
  mv oc $WORKSPACE/custom-bin
fi
rm oc.tar.gz

if [[ "$OPENSHIFT_CLUSTER" =~ "local" ]] && grep -q fake /my-secrets/clusters/$OPENSHIFT_CLUSTER-token ; then
  # just for development to ease managing secrets; in prod, this branch should never be taken
  TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
else
  TOKEN=$(cat /my-secrets/clusters/$OPENSHIFT_CLUSTER-token)
fi

PARAMS=''
if [[ "$OPENSHIFT_CLUSTER" =~ "local" ]] ; then
  PARAMS='--insecure-skip-tls-verify=true'
fi
$WORKSPACE/custom-bin/oc login $API_SERVER --token $TOKEN $PARAMS
