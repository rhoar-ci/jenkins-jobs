#!/bin/bash

processYamlFile () {
  local yaml=$1
  local action=$2

  echo "Processing $yaml"

  local commandSuffix=""
  if [[ $action == "delete" ]] ; then
    commandSuffix="|| true" # don't fail everything at the very end
  fi

  local dir=$(dirname $(dirname $yaml))
  sed -i -e 's/RUNTIME_VERSION/latest/' $yaml
  if grep -q 'kind: Template' $yaml ; then
    # TODO maybe use GIT_BRANCH instead of GIT_COMMIT?
    eval "oc process -f $yaml -p SOURCE_REPOSITORY_URL=$GIT_URL -p SOURCE_REPOSITORY_REF=$GIT_COMMIT -p SOURCE_REPOSITORY_DIR=$dir | oc $action -f - $commandSuffix"
  else
    eval "oc $action -f $yaml $commandSuffix"
  fi
}

processYamlFilesOfAKind () {
  local action=$1
  local kind=$2

  for yaml in $(find . -type f -regex "^.*/\.openshiftio/$kind\.\(\w+\.\)?ya?ml$") ; do
    processYamlFile $yaml $action
  done
}

emulateLauncherApply () {
  local action="apply"

  echo "Emulating Launcher: oc $action"
  processYamlFilesOfAKind $action "resource"
  processYamlFilesOfAKind $action "service"
  processYamlFilesOfAKind $action "application"
}

emulateLauncherDelete () {
  local action="delete"

  echo "Emulating Launcher: oc $action"
  processYamlFilesOfAKind $action "application"
  processYamlFilesOfAKind $action "service"
  processYamlFilesOfAKind $action "resource"
}

applyGitWorkaround () {
  # workaround for https://github.com/openshift/origin/issues/8374
  cat << EOF > my-gitconfig
[user]
        name = Workaround
        email = workaround@example.com
EOF

  oc create secret generic workaround --from-file=.gitconfig=my-gitconfig
  oc annotate secret workaround 'build.openshift.io/source-secret-match-uri-1=*://*/*'
}

removeGitWorkaround () {
  # workaround for https://github.com/openshift/origin/issues/8374
  oc delete secret workaround
}

applyDeploymentWorkaround () {
  # OpenShift 3.7 doesn't support Kubernetes deployments all that well,
  # so we change the JDG YAML file to be a deployment config instead
  #
  # when we upgrade to OpenShift 3.9, this should be removed
  if [[ "$JOB_NAME" =~ "cache" ]] ; then
    for F in service.cache.yml .openshiftio/service.cache.yml greeting-service/.openshiftio/service.cache.yml ; do
      if [[ -f $F ]] ; then
        echo "Editing the JDG resource $F to make it a DeploymentConfig instead of Deployment"
        sed -i -e "s|apiVersion: extensions/v1beta1|apiVersion: v1|" -e "s|kind: Deployment|kind: DeploymentConfig|" -e "s|replicas: 1|replicas: 1\n      triggers:\n      - type: ConfigChange|" $F
      fi
    done
  fi
}

s2i_setup () {
  applyGitWorkaround
  applyDeploymentWorkaround

  emulateLauncherApply
  sleep 300 # if only there was a way to actually wait for the build and deployment to finish...
}

s2i_teardown () {
  emulateLauncherDelete

  removeGitWorkaround
}
