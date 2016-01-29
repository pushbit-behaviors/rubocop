#!/bin/bash

echo "entering git repo"
cd code

echo "Updating styles"
OUTPUT_JSON="$(rubocop -a -f json)"

git diff --quiet ${BASE_BRANCH} && git diff --cached --quiet
if [ $? -eq 0 ]; then
  echo "There were no updates"
  exit 0
fi

echo ${OUTPUT_JSON} | ruby ../execute.rb 
