FROM centos:7

RUN yum update -y -q \
  && yum install sudo git epel-release -y -q \
  && yum clean all \
  && rm -fr /var/cache/yum

RUN yum install -q -y \
    xrootd \
    xrootd-client \
    xrootd-scitokens \
    xrootd-selinux \
    xrootd-server \
    xrootd-server-libs \
    xrootd-voms \
  && yum clean all \
  && rm -fr /var/cache/yum


VOLUME /xrootd