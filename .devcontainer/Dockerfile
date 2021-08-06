FROM centos:7

RUN yum update -y -q \
 && yum install sudo git epel-release -y -q \
 && yum clean all \
 && rm -fr /var/cache/yum

RUN yum -q -y install xrootd-client \
 && yum clean all \
 && rm -fr /var/cache/yum

ENV USERNAME xrootduser
ARG USERID=1000

RUN export OLD_ID=$(id ${USERNAME} -u) \
&& useradd ${USERNAME} -u ${USERID} -o -d /home/${USERNAME} -m -s /bin/bash \
&& echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
&& chmod 0440 /etc/sudoers.d/${USERNAME} \
&& cp -p /root/.bashrc /home/${USERNAME}/. \
&& chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

ENV DEV_DIR /xrootd_testing
VOLUME ${DEV_DIR}
WORKDIR ${DEV_DIR}

USER ${USERNAME}
ENV HOME /home/${USERNAME}
