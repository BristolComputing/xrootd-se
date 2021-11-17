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

yum update
yum install -y docker-ce --enablerepo=epel,centos-extras

systemctl enable docker
systemctl start docker

# disable repo
sed -i "s/enabled=1/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
```

On some systems you might need CentOS extras:
Create `/etc/yum.repos.d/centos-extras.repo` with content:
```bash
[centos-extras]
name=Centos extras - $basearch
baseurl=http://mirror.centos.org/centos/7/extras/x86_64
enabled=0
gpgcheck=0
```

or configure with puppet

### Docker-compose

From https://docs.docker.com/compose/install/:

```
bash
sudo curl -L \
"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```
### CVMFS

--> Configure with Puppet

Then

```bash
systemctl stop autofs.service
systemctl disable autofs.service
mkdir -p /cvmfs/grid.cern.ch
echo "grid.cern.ch    /cvmfs/grid.cern.ch     cvmfs defaults 0 0" >> /etc/fstab
mount /cvmfs/grid.cern.ch
```

### Directory structure (first-time-only)

Any folder referenced in etc/xrootd/Authfile needs to be created first

### IP forwarding

If 
```bash
cat /proc/sys/net/ipv4/ip_forward
# or 
cat /proc/sys/net/ipv6/conf/all/forwarding
```
returns `0` you must enable the IP forwarding for docker to work.


```bash
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-ip_forwaring.conf
echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.d/99-ip_forwaring.conf
sysctl -p /etc/sysctl.d/99-ip_forwaring.conf
```
## Production

### xrootd manager

#### Step 1: Download and prepare files and container

```bash
cd /opt
git clone git@github.com:BristolComputing/xrootd-se.git
cd xrootd-se
# select tag
tag=<selected tag>
git checkout $tag

mkdir -p .secrets/prod/etc/xrootd
mkdir -p .secrets/prod/etc/grid-security/xrd

# copy hostcert.pem and hostkey.pem
cp -p ~/certs/*.pem .secrets/prod/etc/grid-security/xrd/.
cp ~/macaroon-secret .secrets/prod/etc/xrootd
# or create new one with
# openssl rand -base64 -out .secrets/prod/etc/xrootd/macaroon-secret 64
chown -R xrootd:xrootd .secrets/prod/etc/grid-security/xrd
chown -R xrootd:xrootd .secrets/prod/etc/xrootd/macaroon-secret

# building container
# adjust storage superuser in container to match host via XROOTD_GID and XROOTD_UID:
docker build -t kreczko/xrootdse:$tag \
 --build-arg XROOTD_GID=974 \
 --build-arg XROOTD_UID=977 \
 .
# service uses the `latest` tag, so we need to create a 2nd tag here
docker tag kreczko/xrootdse:$tag kreczko/xrootdse:latest
# TBD: Maybe we should have an easy way to set the tag via `Environment` in the systemctl unit
```

#### Step 2: Set up systemctl unit

```bash
# setting up service
cp etc/systemd/system/docker.xrootdse.service /etc/systemd/system/docker.xrootdse.service
sed -i "s/xrootdsefqdn/$(hostname -f)/g" /etc/systemd/system/docker.xrootdse.service
systemctl enable docker.xrootdse
systemctl start docker.xrootdse
```

### xrootd gateway

#### Step 1a: Download and prepare files and container

Same as Step 1 for the xrootd manager (see above).

#### Step 1b: pick underlying file system

```bash
# for HDFS copy
cp -p optional/etc/xrootd/config.d/*hdfs*.cfg etc/xrootd/config.d/.
# for POSIX (e.g. testing)
cp -p optional/etc/xrootd/config.d/*posix*.cfg etc/xrootd/config.d/.

#### Step 2: Set up systemctl unit

```bash
# setting up service
cp etc/systemd/system/docker.xrootdgateway.service /etc/systemd/system/.
sed -i "s/xrootdsefqdn/$(hostname -f)/g" /etc/systemd/system/docker.xrootdgateway.service
systemctl enable docker.xrootdgateway
systemctl start docker.xrootdgateway
```

### Updates

#### Deploying updated container or config files

```bash
cd /opt/xrootd-se
git fetch origin
git checkout main
git pull origin main
git checkout <new tag>
```
Then redo Step 1 for the node in question. You can skip the certificate steps.
If the systemd files changed, please also run Step 2 but with the following modifications
```bash
systemctl stop docker.xrootdse # or docker.xrootdgateway
# copy new files and run sed command
systemctl daemon-reload
# enable and start the updated service
```


### Restarting and reloading

- To restart the whole service:
  - manager: `systemctl restart docker.xrootdse`
  - gateway: `systemctl restart docker.xrootdse`
- To restart a particular deamon:
  - cmsd (manager): `docker exec -ti docker.xrootdse.service supervisorctl restart cmsd`
  - xrootd (manager): `docker exec -ti docker.xrootdse.service supervisorctl restart xrootd-clustered`
  - cmsd (gateway): `docker exec -ti docker.xrootdgateway.service supervisorctl restart cmsd`
  - xrootd (gateway): `docker exec -ti docker.xrootdgateway.service supervisorctl restart xrootd-clustered`
- Reload services (e.g. changed config):
  - manager: `systemctl reload docker.xrootdse`
  - gateway: `systemctl reload docker.xrootdse`
