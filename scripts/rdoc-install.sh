#!/bin/bash
set -ev
if [ "${sinatra}" = "master" ]; then
  git clone --depth=1 https://github.com/rdoc/rdoc
  cd rdoc
  rake
  rake install_gem
  echo "Using RDoc HEAD..."
else
  echo "Using bundled RDoc..."
fi
