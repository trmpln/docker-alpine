FROM alpine:latest
MAINTAINER Giampaolo Mancini <giampaolo@trampolineup.com>

COPY qemu-user-static-2.5-r1.apk .
RUN apk add --update --allow-untrusted qemu-user-static-2.5-r1.apk
RUN rm qemu-user-static-2.5-r1.apk 
