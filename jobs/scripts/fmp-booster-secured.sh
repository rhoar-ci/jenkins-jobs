#!/bin/bash

oc apply -f service.sso.yaml

# don't let Vert.x test deploy/undeploy SSO on its own, we can do better
sed -i '/COMMAND_EXECUTOR.execCommand/d' src/test/java/io/openshift/booster/SecuredBoosterIT.java || true

SSO_URL=$(oc get route secure-sso -o jsonpath='https://{.spec.host}/auth')

mvn clean verify -B
mvn clean verify -B -Popenshift,openshift-it -DSSO_AUTH_SERVER_URL=${SSO_URL}

oc delete -f service.sso.yaml
