https://github.com/opensciencegrid/docker-xrootd-standalone
https://github.com/opensciencegrid/docker-software-base

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
```