FROM kreczko/xrootd-hdfs-build
ARG XROOTD_HDFS_COMMIT_HASH=25bf07d
ARG XROOTD_HDFS_BRANCH=kreczko-checksum-debug
ARG XROOTD_HDFS_REPO=https://github.com/uobdic/xrootd-hdfs.git

RUN mkdir -p /tmp/build
WORKDIR /tmp
RUN git clone -b $XROOTD_HDFS_BRANCH --single-branch $XROOTD_HDFS_REPO \
  && cd xrootd-hdfs \
  && git checkout $XROOTD_HDFS_COMMIT_HASH
WORKDIR /tmp/build
RUN scl enable devtoolset-8 "cmake3 /tmp/xrootd-hdfs; make"
ENV JAVA_HOME=/etc/alternatives/jre
RUN /opt/hadoop/bin/hdfs version >> /tmp/build/xrootd-hdfs.info \
  && echo "" >> /tmp/build/xrootd-hdfs.info \
  && echo "xrootd-hdfs $(grep 'Version:' /tmp/xrootd-hdfs/rpm/xrootd-hdfs.spec | awk '{print $2}')" >> /tmp/build/xrootd-hdfs.info \
  && echo "Source code repository $XROOTD_HDFS_REPO -b $XROOTD_HDFS_BRANCH -r $XROOTD_HDFS_COMMIT_HASH" >> /tmp/build/xrootd-hdfs.info \
  && echo "Compiled by $(cat /etc/redhat-release) on $(date --utc +%Y-%m-%dT%H:%MZ)" >> /tmp/build/xrootd-hdfs.info

FROM centos:7

LABEL maintainer Bristol Site Admins <lcg-admin@bristol.ac.uk>

RUN rm -f /usr/lib64/libXrdHdfs* && mkdir -p /usr/libexec/xrootd-hdfs /etc/xrootd_info
COPY --from=0 /opt/hadoop /opt/hadoop
COPY --from=0 /tmp/build/libXrdHdfs-5.so /usr/lib64
COPY --from=0 /tmp/build/libXrdHdfsReal-5.so /usr/lib64
COPY --from=0 /tmp/build/xrootd_hdfs_envcheck /usr/libexec/xrootd-hdfs
COPY --from=0 /tmp/build/xrootd-hdfs.info /etc/xrootd_info/xrootd-hdfs.info

RUN yum update -y -q && \
  yum clean all && \
  rm -rf /var/cache/yum/*

# Create the xrootd user with a fixed GID/UID
# OSG default ID 10940 but we want 1094 (or 1000 for testing)
ARG XROOTD_GID=1094
ARG XROOTD_UID=1094
ARG XROOTD_VERSION="5.6.3-2.el7"

RUN groupadd -o -g ${XROOTD_GID} xrootd
RUN useradd -o -u ${XROOTD_UID} -g ${XROOTD_GID} -s /bin/sh xrootd

COPY ./etc/yum.repos.d/xrootd-stable.repo /etc/yum.repos.d/xrootd-stable.repo

RUN yum update -y -q \
  && yum install -q -y epel-release https://repo.opensciencegrid.org/osg/3.6/osg-3.6-el7-release-latest.rpm \
  && yum clean all \
  && rm -fr /var/cache/yum
RUN cat /etc/yum.repos.d/epel.repo
RUN yum update -y -q \
  && yum install -q -y --enablerepo=osg-contrib \
  cronie \
  iproute \
  java-1.8.0-openjdk-headless \
  less \
  supervisor \
  which \
  xrootd \
  xrootd-client \
  xrootd-cmstfc \
  xrootd-lcmaps \
  xrootd-scitokens \
  xrootd-selinux \
  xrootd-server-${XROOTD_VERSION} \
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
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_LIB_DIR=/opt/hadoop/lib
ENV HADOOP_LIBEXEC_DIR=/opt/hadoop/libexec

ENV JAVA_HOME=/etc/alternatives/jre
ENV LD_LIBRARY_PATH=/opt/hadoop/lib/native:/etc/alternatives/jre/lib/amd64/server
ENV CLASSPATH=/etc/hadoop/conf.cloudera.hdfs:/opt/hadoop/share/hadoop/client/*:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/*

# xrootd folder fixes
RUN mkdir -p /var/run/xrootd /var/spool/xrootd \
  && chown xrootd:xrootd /var/run/xrootd /var/spool/xrootd

# install python3 and other dependencies for xrdsum plugin
WORKDIR /tmp
RUN yum install -y -q wget \
  && yum clean all \
  && rm -fr /var/cache/yum
RUN curl -LO "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" \
  && bash Miniconda3-latest-Linux-x86_64.sh -p /miniconda -b \
  && rm -f Miniconda3-latest-Linux-x86_64.sh \
  && ln -s /miniconda/bin/conda /usr/bin/conda \
  && conda update -y conda \
  && conda init \
  && conda install -y -q python=3.9 \
  && conda clean --all
ENV PATH=/miniconda/bin:$PATH
ARG XRDSUM_VERSION=2023.12.1
RUN /miniconda/bin/pip --no-cache-dir install xrdsum[hdfs]==${XRDSUM_VERSION}

# gather info and test gathering script
ADD etc/xrootd/list_installed.sh /tmp/list_installed.sh
RUN /tmp/list_installed.sh >> /etc/xrootd_info/installed_packages.info
ADD etc/xrootd/scan_versions.sh /tmp/scan_versions.sh
RUN /tmp/scan_versions.sh

VOLUME /xrootd

COPY etc/supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
