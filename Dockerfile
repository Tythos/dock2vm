FROM alpine:3.16
RUN apk update
RUN apk --no-cache --cache-max-age 30 add \
  busybox-initscripts \
  linux-virt \
  openrc \
  cloud-init \
  bash \
  openssh \
  cloud-utils \
  cloud-utils-growpart \
  util-linux \
  openssh-server-pam \
  doas \
  sudo \
  e2fsprogs \
  e2fsprogs-extra \
  dosfstools \
  gettext \
  lsblk \
  parted \
  udev \
  chrony \
  tzdata
RUN echo "root:root" | chpasswd
RUN \
  mkdir -p /var/lib/cloud/scripts/per-boot &&\
  mkdir -p /var/lib/cloud/data
RUN \
  rc-update add root &&\
  rc-update add sshd &&\
  # rc-update add chronyd &&\
  rc-update add cloud-init
RUN setup-cloud-init
RUN \
  touch /etc/network/interfaces &&\
  touch /etc/.default_boot_services
COPY 00_test.cfg /etc/cloud/cloud.cfg.d/00_test.cfg
COPY 10_digitalocean.cfg /etc/cloud/cloud.cfg.d/10_digitalocean.cfg
