#!/bin/bash

# OpenShift 3.7 doesn't support Kubernetes deployments all that well,
# so we change the JDG YAML file to be a deployment config instead
#
# when we upgrade to OpenShift 3.9, this should be removed
if [[ "$JOB_NAME" =~ "cache" ]] ; then
  for F in service.cache.yml tests/src/test/resources/test-cache.yml tests/src/test/resources/test-cacheserver.yml ; do
    if [[ -f $F ]] ; then
      echo "Editing the JDG resource $F to make it a DeploymentConfig instead of Deployment"
      sed -i -e "s|apiVersion: extensions/v1beta1|apiVersion: v1|" -e "s|kind: Deployment|kind: DeploymentConfig|" -e "s|replicas: 1|replicas: 1\n      triggers:\n      - type: ConfigChange|" $F
    fi
  done
fi

mvn clean verify -B
mvn clean verify -B -Popenshift,openshift-it
