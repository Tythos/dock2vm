FROM alpine:3.19
RUN apk update 
RUN apk add linux-virt openrc cloud-init bash openssh cloud-utils cloud-utils-growpart
RUN echo "root:root" | chpasswd
RUN chown root /var/empty
RUN chgrp root /var/empty
RUN chmod 744 /var/empty
RUN rc-update add root
RUN rc-update add sshd
COPY syslinux.cfg /boot/syslinux.cfg
COPY 10_digitalocean.cfg /etc/cloud/cloud.cfg.d/