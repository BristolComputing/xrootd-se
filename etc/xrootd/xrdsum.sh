<<<<<<< HEAD
#!/usr/bin/env bash

RESULT=$(xrdsum --verbose --debug -l /var/log/xrootd/clustered/checksum.log get --store-result --read-size 128 "$1")
ECODE=$?

# XRootD expects return on stdout - checksum followed by a new line
printf "%s\n" "$RESULT"
exit "$ECODE"
