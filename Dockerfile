FROM alpine:3.19
RUN apk update 
RUN apk add linux-virt openrc
RUN echo "root:root" | chpasswd
RUN rc-update add root
