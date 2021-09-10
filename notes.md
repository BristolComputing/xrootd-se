https://github.com/opensciencegrid/docker-xrootd-standalone
https://github.com/opensciencegrid/docker-software-base
https://dune.bnl.gov/wiki/Basic_XRootD
https://github.com/xrootd/xrootd/issues/1268
https://gridpp-storage.blogspot.com/2019/10/modern-account-mapping-for-cephxrootd.html

https://towardsdatascience.com/hdfs-simple-docker-installation-guide-for-data-science-workflow-b3ca764fc94b

```
docker run --rm --publish 1094:1094 \
    -v $PWD/data:/data \
    xrootdse
```
```
xrootd -c /etc/xrootd/xrootd-standalone.cfg -k fifo -n standalone -k 10 -s /var/run/xrootd/xrootd-standalone.pid -l /var/log/xrootd/xrootd.log
```

```
xrdcp /bin/sh  root://localhost:1094///xrootd/second_test
```

```bash
docker-compose up -d
docker-compose run  xrootdclient
xrdcp /bin/sh  root://xrootdse:1094///xrootd/test
xrdcp /bin/sh  root://172.19.0.3:1094///xrootd/test
```


```
docker exec -ti xrootd-se_xrootdse_1 tail /var/log/xrootd/standalone/xrootd.log
docker exec -ti xrootd-se_xrootdse_1 tail /var/log/xrootd/clustered/xrootd.log
docker exec -ti xrootd-se_xrootdgateway_1 tail /var/log/xrootd/clustered/xrootd.log


docker-compose run --rm  xrootdclient
xrdcp /bin/sh  root://xrootdse:1094///xrootd/test


docker exec -ti xrootd-se_${xrootdse}_1 supervisorctl restart xrootd-standalone
docker exec -ti xrootd-se_${xrootdse}_1 supervisorctl restart xrootd-clustered
docker exec -ti xrootd-se_${xrootdgateway}_1 supervisorctl restart xrootd-clustered
```


```
https://dune.bnl.gov/wiki/Basic_XRootD
```


```
xrdcp /bin/sh  root://xrootd.phy.bris.ac.uk:1094///xrootd/test
xrdfs xrootd.phy.bris.ac.uk:1094 ls /xrootd/test
xrdfs xrootd.phy.bris.ac.uk:1094 query checksum /xrootd/test
```

## Check hostnames

```bash
xrootdse=xrootd.phy.bris.ac.uk
xrootdgateway=io-37-02.acrc.bris.ac.uk

docker exec -ti xrootd-se_${xrootdse}_1 hostname -f
docker exec -ti xrootd-se_${xrootdgateway}_1 hostname -f
```

## Check logs

```bash
docker exec -ti xrootd-se_${xrootdse}_1 tail /var/log/xrootd/clustered/xrootd.log
docker exec -ti xrootd-se_${xrootdgateway}_1 tail /var/log/xrootd/clustered/xrootd.log

docker exec -ti xrootd-se_${xrootdse}_1 tail /var/log/xrootd/clustered/cmsd.log
docker exec -ti xrootd-se_${xrootdgateway}_1 tail /var/log/xrootd/clustered/cmsd.log
```

## Check data

```bash
docker exec -ti xrootd-se_${xrootdse}_1 ls -lah /xrootd
```

## Transfer tests with certs
```bash
xrootdse=xrootd.phy.bris.ac.uk
source /cvmfs/grid.cern.ch/umd-c7ui-latest/etc/profile.d/setup-c7-ui-example.sh
voms-proxy-init --voms dteam

xrdcp /bin/sh  root://${xrootdse}:1094///xrootd/test
xrdfs ${xrootdse}:1094 query checksum /xrootd/test
xrdfs ${xrootdse}:1094 rm /xrootd/test
```
