#!/bin/bash

mvn clean verify -B
mvn clean verify -B -Popenshift,openshift-it
