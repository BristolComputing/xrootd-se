#!/usr/bin/env bash

yum list installed | egrep "xrootd|voms|macaroons|scitokens"  | awk '{printf("|%-30s| %20s | %15s |\n", $1, $2, $3)}'
