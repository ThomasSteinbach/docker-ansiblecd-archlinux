FROM base/archlinux:latest
LABEL maintainer="Thomas Steinbach"

RUN pacman -Sy --noconfirm && \
    pacman -S --noconfirm \
      python \
      sudo \
      openssh && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man


RUN /usr/bin/ssh-keygen -A && \
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

RUN useradd --home-dir /gitlab --create-home --groups wheel gitlab
WORKDIR /gitlab
# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "gitlab:gitlab" | chpasswd

EXPOSE 22/tcp
HEALTHCHECK --interval=5s --timeout=3s \
  CMD < /dev/tcp/127.0.0.1/22

CMD ["/usr/bin/sshd", "-D", "-e"]
