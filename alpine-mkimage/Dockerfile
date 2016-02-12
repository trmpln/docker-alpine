FROM trmpln/alpine-qemu-static

RUN apk add --update curl xz

COPY mkimage-alpine.sh .

ENTRYPOINT ["./mkimage-alpine.sh"]
