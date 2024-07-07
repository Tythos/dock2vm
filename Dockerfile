FROM alpine:3.19
RUN apk update 
RUN apk add linux-virt openrc cloud-init bash openssh cloud-utils cloud-utils-growpart
RUN echo "root:root" | chpasswd
RUN rc-update add root
RUN rc-update add sshd
COPY 10_digitalocean.cfg /etc/cloud/cloud.cfg.d/