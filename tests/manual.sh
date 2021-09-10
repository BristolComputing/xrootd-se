#!/usr/bin/env bash
source /cvmfs/grid.cern.ch/umd-c7ui-latest/etc/profile.d/setup-c7-ui-example.sh
voms-proxy-init --voms cms

# CMS
STORE=/xrootd/cms/store/user/kreczko
xrdcp /bin/sh root://xrootd.phy.bris.ac.uk:1094//$STORE/test
xrdfs xrootd.phy.bris.ac.uk:1094 ls $STORE/
xrdfs xrootd.phy.bris.ac.uk:1094 query checksum $STORE/test

xrdfs xrootd.phy.bris.ac.uk:1094 ls /xrootd/cms/store/

# should not work
STORE=/xrootd/cms/store/NOWRITEACCESSHERE
xrdcp /bin/sh root://xrootd.phy.bris.ac.uk:1094//$STORE/test
xrdfs xrootd.phy.bris.ac.uk:1094 ls $STORE/
xrdfs xrootd.phy.bris.ac.uk:1094 query checksum $STORE/test