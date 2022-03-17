[![CI to Docker Hub](https://github.com/BristolComputing/xrootd-se/actions/workflows/docker-release.yml/badge.svg)](https://github.com/BristolComputing/xrootd-se/actions/workflows/docker-release.yml)

# xrootd storage element

This repository provides the necessary Docker images and config files to
run an xrootd storage element in either standalone (1 node) or clustered (1 redirector + N servers).
Configuration examples are provided for HDFS and POSIX storage backends, but the Docker images are built with HDFS dependencies (Java, xrootd-hdfs, hadoop client).



## Prerequisites

### storage super-user

The storage system, e.g. HDFS, needs to know the `xrootd` user which should have the same UID across the cluster

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

### CVMFS

Configure with Puppet or your favourite management system.
Alternatively, check out [manual instructions](https://cvmfs.readthedocs.io/en/stable/cpt-quickstart.html).

Since we've observed interactions between Docker and CVMFS where `autofs` is not doing its job, we typically disable `autofs` and add the relevant CVMFS repositories to `/etc/fstab`:

```bash
systemctl stop autofs.service
systemctl disable autofs.service
mkdir -p /cvmfs/grid.cern.ch
echo "grid.cern.ch    /cvmfs/grid.cern.ch     cvmfs defaults 0 0" >> /etc/fstab
mount /cvmfs/grid.cern.ch
```

`/cvmfs/grid.cern.ch` will be used for
 - `/cvmfs/grid.cern.ch/certificates` (allows us to drop fetch-crl)
 - `/cvmfs/grid.cern.ch/vomses` (no-worry, automatic VO server updates)
 - `/etc/grid-security/vomsdir` (similar to above)

### Directory structure (first-time-only)

Any folder referenced in etc/xrootd/Authfile needs to be created first.
Two scripts are provided for that purpoise:
 - `etc/xrootd/initial_setup_hdfs.sh` for HDFS
 - `etc/xrootd/initial_setup_posix.sh` for POSIX

All created directories will be owned by `xrootd:xrootd`.

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

For production we use `systemctl` to start/stop our containers.

### xrootd manager/redirector

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
 --build-arg XROOTD_GID=1094 \
 --build-arg XROOTD_UID=1094 \
 .
# service uses the `latest` tag, so we need to create a 2nd tag here
docker tag kreczko/xrootdse:$tag kreczko/xrootdse:latest
# TBD: Maybe we should have an easy way to set the tag via `Environment` in the systemctl unit

# host folders and user
# user, manual or via puppet (use same XROOTD_UID and XROOTD_GID as for the container build)
groupadd -o -g ${XROOTD_GID} xrootd
useradd -o -u ${XROOTD_UID} -g ${XROOTD_GID} -s /bin/sh xrootd

mkdir -p /var/run/xrootd /var/log/xrootd
chown xrootd:xrootd /var/run/xrootd /var/log/xrootd
```

Make sure that `XROOTD_GID` and `XROOTD_UID` correspond to the `gid` and `uid` of the `xrootd` user on the cluster.

Alternatively, instead of building the image yourself, you can use the tagged images from [Docker hub](https://hub.docker.com/repository/docker/kreczko/xrootdse).
Remember to change the version in `/etc/systemd/system/docker.xrootdse.service`.

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
```

#### Step 2: Set up systemctl unit

```bash
# setting up service
cp etc/systemd/system/docker.xrootdgateway.service /etc/systemd/system/.
sed -i "s/xrootdsefqdn/$(hostname -f)/g" /etc/systemd/system/docker.xrootdgateway.service
systemctl enable docker.xrootdgateway
systemctl start docker.xrootdgateway
```

### Updates

This documentation assumes no local, uncommitted changes exist and production is always deployed from a tagged release.

#### On redirector

```bash
UPGRADE_DIR=/root/xroot_upgrades/$(date +%Y-%m-%d)
mkdir -p ${UPGRADE_DIR}
cd /opt/xrootd-se
git fetch origin

previous_tag=$(git describe --tags --abbrev=0 | sed "s/v//g")
echo $previous_tag >> ${UPGRADE_DIR}/previous_tag
# set the version you want. To list all available tags: git tag -l
new_tag=<version number>
echo $new_tag >> ${UPGRADE_DIR}/new_tag
git checkout v$new_tag
git checkout -b upgrading_from_${previous_tag}_to_${new_tag}

docker tag kreczko/xrootdse:latest kreczko/xrootdse:$previous_tag
docker pull kreczko/xrootdse:$new_tag
docker tag kreczko/xrootdse:$new_tag kreczko/xrootdse:latest

systemctl stop docker.xrootdse
cp -p /etc/systemd/system/docker.xrootdse.service ${UPGRADE_DIR}/.
cp etc/systemd/system/docker.xrootdse.service /etc/systemd/system/.
systemctl daemon-reload
systemctl start docker.xrootdse
```

#### on each gateway

```bash
UPGRADE_DIR=/root/xroot_upgrades/$(date +%Y-%m-%d)
mkdir -p ${UPGRADE_DIR}
cd /opt/xrootd-se
git fetch origin

previous_tag=$(git describe --tags --abbrev=0 | sed "s/v//g")
echo $previous_tag >> ${UPGRADE_DIR}/previous_tag
# set the version you want. To list all available tags: git tag -l
new_tag=<version number>
echo $new_tag >> ${UPGRADE_DIR}/new_tag
git checkout v$new_tag

docker tag kreczko/xrootdse:latest kreczko/xrootdse:$previous_tag
docker pull kreczko/xrootdse:$new_tag
docker tag kreczko/xrootdse:$new_tag kreczko/xrootdse:latest

systemctl stop docker.xrootdgateway
cp -p /etc/systemd/system/docker.xrootdgateway.service ${UPGRADE_DIR}/.
cp etc/systemd/system/docker.xrootdgateway.service /etc/systemd/system/.
systemctl daemon-reload
systemctl start docker.xrootdgateway

```

#### Restore previous version

In case something goes wrong, you can undo the changes by:

On redirector:

```bash
UPGRADE_DIR=<select the upgrade dir that you want to undo>
cd /opt/xrootd-se
git fetch origin
previous_tag=$(cat ${UPGRADE_DIR}/previous_tag)
new_tag=$(cat ${UPGRADE_DIR}/new_tag)
git checkout v$previous_tag

docker tag kreczko/xrootdse:latest kreczko/xrootdse:$new_tag
docker pull kreczko/xrootdse:$previous_tag
docker tag kreczko/xrootdse:$previous_tag kreczko/xrootdse:latest

systemctl stop docker.xrootdse
cp -p ${UPGRADE_DIR}/docker.xrootdse.service /etc/systemd/system/docker.xrootdse.service
systemctl daemon-reload
systemctl start docker.xrootdse
```

On each gateway:

```bash
UPGRADE_DIR=<select the upgrade dir that you want to undo>
cd /opt/xrootd-se
git fetch origin
previous_tag=$(cat ${UPGRADE_DIR}/previous_tag)
new_tag=$(cat ${UPGRADE_DIR}/new_tag)
git checkout $previous_tag

docker tag kreczko/xrootdse:latest kreczko/xrootdse:$new_tag
docker pull kreczko/xrootdse:$previous_tag
docker tag kreczko/xrootdse:$previous_tag kreczko/xrootdse:latest

systemctl stop docker.xrootdse
cp -p ${UPGRADE_DIR}/docker.xrootdgateway.service /etc/systemd/system/docker.xrootdgateway.service
systemctl daemon-reload
systemctl start docker.xrootdgateway
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

### Logs

Logs for the xrootd roles will be available on the host under

- `/var/log/xrootd/clustered/cmsd.log`
- `/var/log/xrootd/clustered/xrootd.log`

for the clustered version and in `/var/log/xrootd/clustered/standalone` for the standalone version.

## For development

### Docker-compose

From [Official Docs](https://docs.docker.com/compose/install/):

```bash
sudo curl -L \
"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

## Releases

To make a release:

- upgrade version tag in
  - `etc/systemd/system/docker.xrootdgateway.service`
  - `etc/systemd/system/docker.xrootdse.service`
- create git tag: `git tag v<version number>`
- push tag to main repo: `git push origin v<version number>`
