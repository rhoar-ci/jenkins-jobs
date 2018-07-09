#!/bin/bash

# requires `s2i-functions.sh` to be included before this file

s2i_setup

# the "-Dnamespace.use.current=true -DenableImageStreamDetection=false" stuff shouldn't be necessary
# and when all boosters move to using this by default, it should be removed from here
mvn clean verify -B -Popenshift-it -Denv.init.enabled=false       -Dnamespace.use.current=true -DenableImageStreamDetection=false

s2i_teardown
