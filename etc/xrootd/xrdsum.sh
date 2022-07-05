#!/usr/bin/env bash

RESULT=$(xrdsum get --store-result --chunk-size 64 --verbose --storage-catalog /etc/xrootd/storage.xml "$1")
ECODE=$?

# XRootD expects return on stdout - checksum followed by a new line
printf "%s\n" "$RESULT"
exit "$ECODE"
