FROM nginx:1.18.0-alpine AS builder

WORKDIR /usr/local

RUN set -x \
&& apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  curl \
  gnupg \
  libxslt-dev \
  gd-dev \
  geoip-dev \
  git\
&& wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"  \
&& tar xvf nginx-$NGINX_VERSION.tar.gz \
&& git clone https://github.com/Naereen/Nginx-Fancyindex-Theme.git \
&& git clone https://github.com/aperezdc/ngx-fancyindex.git \
&& cd ./nginx-$NGINX_VERSION \
&& CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
&& CONFARGS=${CONFARGS/-Os -fomit-frame-pointer/-Os}  \
&&  ./configure --with-compat $CONFARGS --add-module='../ngx-fancyindex' \
&& make && make install 

FROM nginx:1.18.0-alpine
ENV TZ=Asia/Shanghai

RUN set -x \
&& mkdir  -p /etc/nginx/theme/Nginx-Fancyindex-Theme-light \
&& mkdir  /etc/nginx/shared \
&& rm /etc/nginx/conf.d/default.conf \
&& ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
&& echo $TZ > /etc/timezone 

COPY --from=builder /usr/local/nginx-$NGINX_VERSION/objs/nginx /usr/sbin/nginx
COPY --from=builder /usr/local/Nginx-Fancyindex-Theme/Nginx-Fancyindex-Theme-light/ /etc/nginx/theme/Nginx-Fancyindex-Theme-light
COPY autoindex.conf /etc/nginx/conf.d/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
