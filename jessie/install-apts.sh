#!/bin/bash


set -e

echo "Updating apt cache"
apt-get update

if [[ ! -z "$@" ]]; then
  echo "Installing $@"
  apt-get install -y --no-install-recommends $@
fi

rm -rf /var/cache/apt/* /var/lib/apt/lists/*
