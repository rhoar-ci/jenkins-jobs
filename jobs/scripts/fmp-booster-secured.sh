#!/bin/bash

oc apply -f service.sso.yaml

SSO_URL=$(oc get route secure-sso -o jsonpath='https://{.spec.host}/auth')

while [ $(oc get dc/sso -o jsonpath='{.status.availableReplicas}') -ne 1 ]
do
    sleep 10
done

mvn clean verify -B
mvn clean verify -B -Popenshift,openshift-it -Dskip.sso.init=true -DSSO_AUTH_SERVER_URL=${SSO_URL}

oc delete -f service.sso.yaml
