#!/usr/bin/env bash

echo "## Packages"
echo "### xrootd"
echo ""
echo "Installed Xrootd versions"
echo "================================================================================"
echo "| package | version | source |"
echo "--- | --- | ---|"
yum list installed | egrep "xrootd|voms|macaroons|scitokens"  | awk '{printf("|%-30s| %20s | %10s |\n", $1, $2, $3)}'
echo "================================================================================"
echo ""
echo "### xrootd-hdfs"
echo "\`\`\`bash"
echo "cat /etc/xrootd_info/xrootd-hdfs.info"
echo "\`\`\`"

