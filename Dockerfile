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

# hadoop-*, (xrootd-hdfs dependency) in OSG is badly packed, hadoop-* pulls X11, cups, etc.
RUN yum install -q -y \
    iproute \
    java-1.8.0-openjdk-headless \
    xrootd \
    xrootd-client \
    xrootd-hdfs \
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

ARG TESTING=false
RUN ${TESTING} -eq true || (rm -f /usr/bin/hadoop* \
  && rm -f /usr/bin/hdfs* \
  && rm -f /etc/alternatives/hadoop-conf \
  && ln -s /opt/cloudera/parcels/CDH/bin/hadoop /usr/bin/hadoop \
  && ln -s /opt/cloudera/parcels/CDH/bin/hadoop-0.20 /usr/bin/hadoop-0.20 \
  && ln -s /opt/cloudera/parcels/CDH/bin/hadoop-fuse-dfs /usr/bin/hadoop-fuse-dfs \
  && ln -s /opt/cloudera/parcels/CDH/bin/hdfs /usr/bin/hdfs \
  && ln -s /opt/cloudera/parcels/CDH/lib64 /usr/lib/hadoop/lib/native \
  && ln -s /etc/hadoop/conf.cloudera.hdfs /etc/alternatives/hadoop-conf)
RUN ${TESTING} -eq false || rm -fr /etc/hadoop/*

ENV HADOOP_CONF_DIR=/etc/hadoop/conf.cloudera.hdfs
ENV HADOOP_COMMON_LIB_NATIVE_DIR=/usr/lib/hadoop/lib
ENV HADOOP_OPTS="-Djava.net.preferIPv4Stack=true -Djava.library.path=/usr/lib/hadoop/lib"

VOLUME /xrootd