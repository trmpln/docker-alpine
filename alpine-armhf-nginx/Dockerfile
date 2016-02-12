FROM trmpln/alpine-armhf

RUN apk add --update nginx
RUN mkdir -p /run/nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
