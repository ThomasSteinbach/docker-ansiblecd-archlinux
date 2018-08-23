FROM thomass/ansibleci-base:latest as ansibleci-base

FROM base/archlinux:latest
LABEL maintainer="Thomas Steinbach"

# with credits upstream: https://hub.docker.com/r/geerlingguy/docker-ubuntu1604-ansible/
# with credits upstream: https://github.com/naftulikay/docker-xenial-vm.git
# with credits to https://developers.redhat.com/blog/2014/05/05/running-systemd-within-docker-container/

ENV container=docker

RUN pacman -Sy --noconfirm && \
    pacman -S --noconfirm \
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
      openssh
    #&& rm -Rf /usr/share/doc && rm -Rf /usr/share/man

RUN systemctl enable sshd

# Ansible
RUN pip3 install ansible==2.6.2
RUN mkdir -p /etc/ansible
RUN printf '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

# Inspec
RUN gem install inspec -v  2.2.61
RUN ln -s "$(ruby -e 'print Gem.user_dir')/bin/inspec" /usr/local/bin/inspec

RUN rm -f /usr/lib/systemd/system/sysinit.target.wants/systemd-firstboot.service

COPY files/initctl_faker.sh .
RUN rm -fr /sbin/initctl && \
    ln -s /initctl_faker.sh /sbin/initctl

# custom utility for awaiting systemd "boot" in the container 
COPY files/systemd-await-target /usr/bin/systemd-await-target
COPY files/wait-for-boot /usr/bin/wait-for-boot                                                                            

VOLUME ["/sys/fs/cgroup"]

COPY --from=ansibleci-base /ansibleci-base /ansibleci-base

EXPOSE 22/tcp
HEALTHCHECK --interval=5s --timeout=3s \
  CMD < /dev/tcp/127.0.0.1/22

#CMD ["/ansibleci-base/scripts/start-docker.sh"]
ENTRYPOINT ["/lib/systemd/systemd"]

RUN useradd --home-dir /ansible --create-home ansible
WORKDIR /ansible
# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "ansible:ansible" | chpasswd
RUN echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
