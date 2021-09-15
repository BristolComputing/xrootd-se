#!/usr/bin/env bash

mkdir -p /xrootd
chown -R xrootd:xrootd /xrootd

directories=$(python extract_directories.py)

for directory in $directories; do
    su -s /bin/bash xrootd -c "mkdir -p $directory"
done
