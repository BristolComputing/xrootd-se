# Notes

## Useful links

- https://github.com/opensciencegrid/docker-xrootd-standalone
- https://github.com/opensciencegrid/docker-software-base
- https://dune.bnl.gov/wiki/Basic_XRootD
- https://github.com/xrootd/xrootd/issues/1268
- https://gridpp-storage.blogspot.com/2019/10/modern-account-mapping-for-cephxrootd.html
- https://twiki.cern.ch/twiki/bin/view/CMSPublic/XRootDoverHTTP
- https://twiki.cern.ch/twiki/bin/view/CMSPublic/HDFSXRootDInstall
- https://towardsdatascience.com/hdfs-simple-docker-installation-guide-for-data-science-workflow-b3ca764fc94b
- https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units
- https://github.com/paulmillar/http-tpc-utils.git
- [Storage accounting twiki](https://twiki.cern.ch/twiki/bin/view/LCG/StorageSpaceAccounting)
  - [Storage accounting spec](https://twiki.cern.ch/twiki/pub/LCG/StorageSpaceAccounting/SRR.v6.pdf)
- [CMS CRIC](https://cms-cric.cern.ch/cms/site/detail/T2_UK_SGrid_Bristol/)

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
# standalone
docker exec -ti xrootd-se_${xrootdse}_1 supervisorctl restart xrootd-standalone
# clustered
docker exec -ti xrootd-se_${xrootdse}_1 supervisorctl restart xrootd-clustered
docker exec -ti xrootd-se_${xrootdgateway}_1 supervisorctl restart xrootd-clustered
# cmsd
docker exec -ti xrootd-se_${xrootdse}_1 supervisorctl restart cmsd
docker exec -ti xrootd-se_${xrootdgateway}_1 supervisorctl restart cmsd

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

## HDFS Commands

```bash
docker exec -ti xrootd-se_${xrootdse}_1 hdfs dfs -ls /
docker exec -ti xrootd-se_${xrootdse}_1 hdfs dfs -ls /xrootd

docker exec -ti xrootd-se_${xrootdgateway}_1 hdfs dfs -ls /
docker exec -ti xrootd-se_${xrootdgateway}_1 hdfs dfs -ls /xrootd
```


## Debugging

### Same certs as xrootd

```diff
-http.cadir /etc/grid-security/certificates
-http.cert /etc/grid-security/xrd/hostcert.pem
-http.key /etc/grid-security/xrd/hostkey.pem
+#http.cadir /etc/grid-security/certificates
+#http.cert /etc/grid-security/xrd/hostcert.pem
+#http.key /etc/grid-security/xrd/hostkey.pem
+http.httpsmode auto
```
did not fix the tests

### Register new HTTP port:

```diff
diff --git a/etc/xrootd/config.d/20-https.cfg b/etc/xrootd/config.d/20-https.cfg
index a309486..de6bd6d 100644
--- a/etc/xrootd/config.d/20-https.cfg
+++ b/etc/xrootd/config.d/20-https.cfg
@@ -11,6 +11,7 @@ if exec xrootd
   http.listingdeny no
   http.staticpreload http://static/robots.txt /etc/xrootd/robots.txt
   xrd.protocol http:$(httpsPort) /usr/lib64/libXrdHttp.so
+  xrd.protocol http:$(httpsPort) +port
   http.selfhttps2http yes

   # Enable third-party-copy
```
as per [docs](https://xrootd.slac.stanford.edu/doc/dev54/xrd_config.htm#_Toc88513976) and [github issue](https://github.com/xrootd/xrootd/issues/1087)