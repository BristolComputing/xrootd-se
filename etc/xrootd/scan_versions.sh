#!/usr/bin/env bash

echo "## Packages"
echo "### xrootd"
echo ""
echo "| package | version | source |"
echo "--- | --- | ---|"
cat /etc/xrootd_info/installed_packages.info
echo ""
echo "### xrootd-hdfs"
echo "\`\`\`bash"
cat /etc/xrootd_info/xrootd-hdfs.info
echo "\`\`\`"

