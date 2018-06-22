FROM base/archlinux:latest
MAINTAINER Thomas Steinbach
# with credits upstream: https://hub.docker.com/r/geerlingguy/docker-ubuntu1604-ansible/
# with credits upstream: https://github.com/naftulikay/docker-xenial-vm.git
# with credits to https://developers.redhat.com/blog/2014/05/05/running-systemd-within-docker-container/

ENV container=docker

RUN pacman -Syu --noconfirm \
    && pacman -S --noconfirm \
         python \
         dbus \
         syslog-ng \
         systemd \
         sudo \
         openssh \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man

RUN \
    rm -f /usr/lib/systemd/system/sysinit.target.wants/systemd-firstboot.service; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup.service; \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*;

COPY initctl_faker.sh .

RUN chmod +x initctl_faker.sh && \
    rm -fr /sbin/initctl && \
    ln -s /initctl_faker.sh /sbin/initctl

# custom utility for awaiting systemd "boot" in the container 
COPY bin/systemd-await-target /usr/bin/systemd-await-target
COPY bin/wait-for-boot /usr/bin/wait-for-boot                                                                            

VOLUME ["/sys/fs/cgroup"]
ENTRYPOINT ["/lib/systemd/systemd"]
