#!/bin/bash

echo "URL is $URL"
command /opt/actions-runner/config.sh --url ${URL} --token ${TOKEN}

command /opt/actions-runner/run.sh