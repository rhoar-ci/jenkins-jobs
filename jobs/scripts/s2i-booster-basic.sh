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

emulateLauncherApply
sleep 300 # if only there was a way to actually wait for the build and deployment to finish...

# the "-Dnamespace.use.current=true -DenableImageStreamDetection=false" stuff shouldn't be necessary
# and when all boosters move to using this by default, it should be removed from here
mvn clean verify -B -Popenshift-it -Denv.init.enabled=false       -Dnamespace.use.current=true -DenableImageStreamDetection=false

emulateLauncherDelete
