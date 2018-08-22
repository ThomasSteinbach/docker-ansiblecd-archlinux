FROM thomass/ansibleci-base:latest as ansibleci-base

FROM base/archlinux:latest
LABEL maintainer="Thomas Steinbach"

# with credits upstream: https://hub.docker.com/r/geerlingguy/docker-ubuntu1604-ansible/
# with credits upstream: https://github.com/naftulikay/docker-xenial-vm.git
# with credits to https://developers.redhat.com/blog/2014/05/05/running-systemd-within-docker-container/

ENV container=docker

RUN pacman -Syu --noconfirm \
    && pacman -S --noconfirm \
         python \
         python-pip \
         rubygems \
         ruby-rdoc \
         base-devel \
         dbus \
         syslog-ng \
         systemd \
         sudo \
         docker \
         openssh \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man

RUN systemctl enable sshd

# Ansible
RUN pip3 install ansible==2.6.2
RUN mkdir -p /etc/ansible
RUN printf '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

# Inspec
RUN gem install docker-api -v  1.34.2
RUN gem install inspec -v  2.2.61
RUN ln -s "$(ruby -e 'print Gem.user_dir')/bin/inspec" /usr/local/bin/inspec

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

COPY files/initctl_faker.sh .
RUN rm -fr /sbin/initctl && \
    ln -s /initctl_faker.sh /sbin/initctl

# custom utility for awaiting systemd "boot" in the container 
COPY files/systemd-await-target /usr/bin/systemd-await-target
COPY files/wait-for-boot /usr/bin/wait-for-boot                                                                            

VOLUME ["/sys/fs/cgroup"]

COPY --from=ansibleci-base /ansibleci-base /ansibleci-base
RUN ln -s /ansibleci-base/scripts/run-tests.sh /usr/local/bin/run-tests && \
    ln -s /ansibleci-base/ansible-plugins/human_log.py /usr/lib/python3.7/site-packages/ansible/plugins/callback/human_log.py

EXPOSE 22/tcp
HEALTHCHECK --interval=5m --timeout=3s \
  < /dev/tcp/127.0.0.1/22

#CMD ["/ansibleci-base/scripts/start-docker.sh"]
ENTRYPOINT ["/lib/systemd/systemd"]

RUN useradd --create-home ansible
# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "ansible:ansible" | chpasswd
