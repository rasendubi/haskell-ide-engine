#!/bin/bash

virtualenv env
. env/bin/activate
pip install -U Sphinx

set -e # exit with nonzero exit code if anything fails

# build docs generator and create docs
stack build
stack exec hie-docs-generator -- --prefix docs/source/

# run our compile script, discussed above
cd docs
make clean
make html

# disable for pull requests
if [ "$TRAVIS_PULL_REQUEST" != "false" ]
then
    echo "Exiting: in a pull request"
    exit 0
fi

# disable for other branches than master
if [ "$TRAVIS_BRANCH" != "master" ]
then
    echo "Exiting: not on master branch"
    exit 0
fi

# disable for other repos as it will fail anyway because the
# encryption is repo specific
if [ "$TRAVIS_REPO_SLUG" != "haskell/haskell-ide-engine" ]
then
    echo "Exiting: not on haskell/haskell-ide-engine repo"
    exit 0
fi

# go to the out directory and create a *new* Git repo
cd build/html

touch .nojekyll
git init

# inside this git repo we'll pretend to be a new user
git config user.name "Travis CI"
git config user.email "moritz.kiefer@purelyfunctional.org"

# The first and only commit to this new Git repo contains all the
# files present with the commit message "Deploy to GitHub Pages".
git add .
git commit -m "Deploy to GitHub Pages"

# Force push from the current repo's master branch to the remote
# repo's gh-pages branch. (All previous history on the gh-pages branch
# will be lost, since we are overwriting it.) We redirect any output to
# /dev/null to hide any sensitive credential data that might otherwise be exposed.
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:gh-pages
