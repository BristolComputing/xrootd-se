
FROM rockylinux:9

LABEL maintainer Bristol Site Admins <lcg-admin@bristol.ac.uk>



RUN dnf update -y -q && \
  dnf clean all && \
  rm -rf /var/cache/yum/*

# Create the xrootd user with a fixed GID/UID
# OSG default ID 10940 but we want 1094 (or 1000 for testing)
ARG XROOTD_GID=1094
ARG XROOTD_UID=1094
ARG XROOTD_VERSION="5.7.1-2.el9"

RUN groupadd -o -g ${XROOTD_GID} xrootd
RUN useradd -o -u ${XROOTD_UID} -g ${XROOTD_GID} -s /bin/sh xrootd

RUN dnf update -y -q \
  && dnf install -q -y epel-release https://repo.opensciencegrid.org/osg/23-main/osg-23-main-el9-release-latest.rpm \
  && dnf clean all \
  && rm -fr /var/cache/yum

RUN dnf update -y -q \
  && dnf install -q -y --enablerepo=osg-contrib \
  cronie \
  iproute \
  less \
  supervisor \
  which \
  xrootd-${XROOTD_VERSION} \
  xrootd-client-${XROOTD_VERSION} \
  xrootd-cmstfc \
  xrootd-scitokens-${XROOTD_VERSION} \
  xrootd-selinux-${XROOTD_VERSION} \
  xrootd-server-${XROOTD_VERSION} \
  xrootd-server-libs-${XROOTD_VERSION} \
  xrootd-voms-${XROOTD_VERSION} \
  && dnf clean all \
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

# xrootd folder fixes
RUN mkdir -p /var/run/xrootd /var/spool/xrootd /etc/xrootd_info \
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
ARG XRDSUM_VERSION=2024.6.1
RUN /miniconda/bin/pip --no-cache-dir install xrdsum==${XRDSUM_VERSION}

# gather info and test gathering script
ADD etc/xrootd/list_installed.sh /tmp/list_installed.sh
RUN /tmp/list_installed.sh >> /etc/xrootd_info/installed_packages.info
ADD etc/xrootd/scan_versions.sh /tmp/scan_versions.sh
RUN /tmp/scan_versions.sh

VOLUME /xrootd

COPY etc/supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
