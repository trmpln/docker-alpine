FROM trmpln/alpine-qemu-static
MAINTAINER Giampaolo Mancini <giampaolo@trampolineup.com>

RUN apk add --update curl xz

COPY mkimage-alpine.sh .

ENTRYPOINT ["./mkimage-alpine.sh", "-s"]
