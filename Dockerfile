FROM kreczko/xrootd-hdfs-build

RUN mkdir -p /tmp/build
WORKDIR /tmp
RUN git clone -b kreczko-hdfs3-debug --single-branch https://github.com/uobdic/xrootd-hdfs.git
WORKDIR /tmp/build
RUN scl enable devtoolset-8 "cmake3 /tmp/xrootd-hdfs; make"

FROM opensciencegrid/software-base:3.5-el7-release

LABEL maintainer Bristol Site Admins <lcg-admin@bristol.ac.uk>

RUN yum update -y && \
  yum clean all && \
  rm -rf /var/cache/yum/*

# Create the xrootd user with a fixed GID/UID
# OSG default ID 10940 but we want 1000
ARG XROOTD_GID=1000
ARG XROOTD_UID=1000

RUN groupadd -o -g ${XROOTD_GID} xrootd
RUN useradd -o -u ${XROOTD_UID} -g ${XROOTD_GID} -s /bin/sh xrootd

# hadoop-*, (xrootd-hdfs dependency) in OSG is badly packed, hadoop-* pulls X11, cups, etc.
RUN yum install -q -y \
    iproute \
    java-1.8.0-openjdk-headless \
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

ARG TESTING=false
RUN ${TESTING} -eq true || (rm -f /usr/bin/hadoop* \
  && rm -f /usr/bin/hdfs* \
  && rm -f /etc/alternatives/hadoop-conf \
  && ln -s /etc/hadoop/conf.cloudera.hdfs /etc/alternatives/hadoop-conf)
RUN ${TESTING} -eq false || rm -fr /etc/hadoop/*

ENV PATH=/opt/hadoop/bin:$PATH
ENV HADOOP_CONF_DIR=/etc/hadoop/conf.cloudera.hdfs
ENV JAVA_HOME=/etc/alternatives/jre
ENV LD_LIBRARY_PATH=/opt/hadoop/lib/native:/etc/alternatives/jre/lib/amd64/server

RUN rm -f /usr/lib64/libXrdHdfs* && mkdir -p  /usr/libexec/xrootd-hdfs
COPY --from=0 /opt/hadoop /opt/hadoop
COPY --from=0 /tmp/build/libXrdHdfs-5.so /usr/lib64
COPY --from=0 /tmp/build/libXrdHdfsReal-5.so /usr/lib64
COPY --from=0 /tmp/build/xrootd_hdfs_envcheck /usr/libexec/xrootd-hdfs

VOLUME /xrootd