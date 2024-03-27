FROM amd64/alpine:3.13.5
RUN apk update 
RUN apk add linux-virt openrc
RUN echo "root:root" | chpasswd
RUN rc-update add root
