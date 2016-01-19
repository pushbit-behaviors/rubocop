#!/bin/bash -l

echo "Setting git defaults"
git config --global user.email "bot@pushbit.co"
git config --global user.name "pushbot"
git config --global push.default simple

echo $PATH
echo $GEM_PATH
gem list

echo "cloning git repo"
git clone https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git target

echo "entering git repo"
cd target

echo "checking out new branch"
git checkout ${BASE_BRANCH}

echo "Updating styles"
OUTPUT_JSON="$(rubocop -a -f json)"

git diff --quiet ${BASE_BRANCH} && git diff --cached --quiet
if [ $? -eq 0 ]; then
  echo "There were no updates"
  exit 0
fi

echo ${OUTPUT_JSON} | ruby ../execute.rb 
