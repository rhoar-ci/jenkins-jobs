#!/bin/bash

# requires `s2i-functions.sh` to be included before this file

runEnd2EndTest () {
  local mission=''
  local runtime=''

  case "$BOOSTER_NAME" in
    *vertx*) runtime=vertx ;;
    *wfswarm*) runtime=wfswarm ;;
    *spring-boot*) runtime=springboot ;;
  esac
  case "$BOOSTER_NAME" in
    *crud*) mission=crud ;;
    *configmap*) mission=configMap ;;
    *secured*) mission=securedHttp ;;
    *health-check*) mission=healthCheck ;;
    *circuit-breaker*) mission=circuitBreaker ;;
    *cache*) mission=cache ;;
    *http*) mission=http ;;
  esac

  local pomFile='./pom.xml'
  if [[ -d greeting-service ]] ; then
    # this is fine for now: it covers all multi-module boosters and doesn't affect single-module boosters
    pomFile='./greeting-service/pom.xml'
  fi
  local routeName=$(xmlstarlet select -N mvn=http://maven.apache.org/POM/4.0.0 --template --value-of '/mvn:project/mvn:artifactId' ${pomFile})
  local url=$(oc get route ${routeName} -o jsonpath='http://{.spec.host}/')

  echo "Running E2E tests for $runtime/$mission at $url"

  git clone https://github.com/rhoar-qe/boosters-e2e-tests.git
  pushd boosters-e2e-tests
  npm install
  # we only need Chrome, and Gecko driver is hosted at GitHub, which often responds with "API rate limit exceeded"
  npx webdriver-manager update --gecko=false
  npm run test -- --suite=${mission} --params.url.${mission}=${url} --params.runtime=${runtime}
  popd
}

s2i_setup

runEnd2EndTest

s2i_teardown
