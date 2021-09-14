# xrootd-se
XrootD SE deployment


## Prerequisites

### storage super-user

The storage system, e.g. HDFS, needs to know the `xrootd` user which should have the same UID

### Docker

```bash
yum install -y epel-release yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

or configure with puppet

### CVMFS

--> Configure with Puppet

### Directory structure (first-time-only)

Any folder referenced in etc/xrootd/Authfile needs to be created first


## Production

### xrootd manager

```bash
cd /opt
git clone git@github.com:BristolComputing/xrootd-se.git
git checkout <selected tag>

mkdir -p .secrets/prod/etc/xrootd
mkdir -p .secrets/prod/etc/grid-security/xrd

cp ~/certs/*.pem .secrets/prod/etc/grid-security/xrd/.
cp ~/macaroon-secret .secrets/prod/etc/xrootd
# or create new one with
# openssl rand -base64 -out .secrets/prod/etc/xrootd/macaroon-secret 64

# building container
docker-compose build .
docker tag xrootdse xrootdse:latest

# setting up service
cp etc/systemd/system/docker.xrootdse.service /etc/systemd/system/docker.xrootdse.service
sed -i "s/xrootdseqfqdm/$(hostname -f)/g" /etc/systemd/system/docker.xrootdse.service
systemctl enable docker.xrootdse
systemctl start docker.xrootdse

```

### xrootd gateway

```bash
cd /opt
git clone git@github.com:BristolComputing/xrootd-se.git
git checkout <selected tag>

mkdir -p .secrets/prod/etc/xrootd
mkdir -p .secrets/prod/etc/grid-security/xrd

cp ~/certs/*.pem .secrets/prod/etc/grid-security/xrd/.
cp ~/macaroon-secret .secrets/prod/etc/xrootd
# or create new one with
# openssl rand -base64 -out .secrets/prod/etc/xrootd/macaroon-secret 64

# building container
docker-compose build .
docker tag xrootdse xrootdse:latest

# setting up service
cp etc/systemd/system/docker.xrootdse.service /etc/systemd/system/docker.xrootdse.service
sed -i "s/xrootdseqfqdm/$(hostname -f)/g" /etc/systemd/system/docker.xrootdse.service
systemctl enable docker.xrootdse
systemctl start docker.xrootdse
```

### Updating


### Restarting

- To restart the whole service: `systemctl restart docker.xrootd`
- To restart a particular deamon: 
  - cmsd: `docker exec -ti xrootd-se supervisorctl restart cmsd`
  - xrootd: `docker exec -ti xrootd-se supervisorctl restart xrootd-clustered`