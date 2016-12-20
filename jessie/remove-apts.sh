#!/bin/bash


set -e

echo "Updating apt cache"
apt-get update

if [[ ! -z "$@" ]]; then
  echo "Removing $@"
  apt-get remove -y --purge --auto-remove $@
fi

rm -rf /var/cache/apt/* /var/lib/apt/lists/*
