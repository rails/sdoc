#!/bin/bash
set -ev
if [ "${rdoc}" = "master" ]; then
  echo "Installing RDoc HEAD..."
  gem install rake -v"< 11"
  gem install hoe
  gem install kpeg -v"~> 0.9"
  gem install racc -v"~> 1.4"
  gem install minitest -v"~> 4.7"
  gem install json -v"~ 1.4"
  git clone --depth=1 https://github.com/rdoc/rdoc
  cd rdoc
  rake
  rake install_gem
  echo "Using RDoc HEAD..."
else
  echo "Using bundled RDoc..."
fi
