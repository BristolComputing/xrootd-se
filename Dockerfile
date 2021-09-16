ARG BASE_YUM_REPO=release

FROM opensciencegrid/software-base:3.5-el7-$BASE_YUM_REPO

LABEL maintainer Bristol Site Admins <lcg-admin@bristol.ac.uk>

RUN yum update -y && \
  yum clean all && \
  rm -rf /var/cache/yum/*

# Create the xrootd user with a fixed GID/UID
# OSG default ID 10940 but we want 1000
ARG XROOTD_GID=1000
ARG XROOTD_UID=1000

RUN groupadd -o -g ${XROOTD_GID}  xrootd
RUN useradd -o -u ${XROOTD_UID} -g ${XROOTD_GID} -s /bin/sh xrootd

RUN yum install -q -y \
    iproute \
    xrootd \
    xrootd-client \
    xrootd-lcmaps \
    xrootd-scitokens \
    xrootd-selinux \
    xrootd-server \
    xrootd-server-libs \
    xrootd-voms \
  && yum clean all \
  && rm -fr /var/cache/yum

# Default root dir
ENV XC_ROOTDIR /xrootd

# ADD supervisord.d/* /etc/supervisord.d/
ADD image-config.d/* /etc/osg/image-config.d/
# ADD etc/xrootd/* /etc/xrootd
# link secrets
RUN rm -f /etc/grid-security/ban-mapfile \
  && rm -f /etc/grid-security/ban-voms-mapfile \
  && ln -s /.secrets/etc/grid-security/xrd /etc/grid-security/xrd \
  && ln -s /etc/grid-security/xrd/hostcert.pem /etc/grid-security/hostcert.pem \
  && ln -s /etc/grid-security/xrd/hostkey.pem /etc/grid-security/hostkey.pem \
  && ln -s /.secrets/etc/grid-security/ban-mapfile /etc/grid-security/ban-mapfile \
  && ln -s /.secrets/etc/grid-security/ban-voms-mapfile /etc/grid-security/ban-voms-mapfile \
  && ln -s /.secrets/etc/grid-security/grid-mapfile /etc/grid-security/grid-mapfile \
  && ln -s /.secrets/etc/grid-security/voms-mapfile /etc/grid-security/voms-mapfile \
  && ln -s /.secrets/etc/xrootd/macaroon-secret /etc/xrootd/macaroon-secret

VOLUME /xrootd