# Dockerfile example for debian Signal Sciences agent container

#FROM srk:latest
# based on the original stable alpine image
# https://github.com/nginxinc/docker-nginx/blob/014e624239987a0a46bee5b44088a8c5150bf0bb/stable/alpine/Dockerfile

FROM alpine:3.14

ENV NGINX_VERSION 1.20.2
ENV NGINX_STICKY_MODULE_NG_VERSION 08a395c66e42
ENV NGINX_UPSTREAM_DYNAMIC_SERVERS_VERSION master
ENV LUA_NGINX_MODULE_VERSION 0.10.18
ENV SIGSCI_ACCESSKEYID="SIGSCI_ACCESSKEYID"
ENV SIGSCI_SECRETACCESSKEY="SIGSCI_ACCESSKEYID"

# Install LUAJIT and LUARestyCore
RUN apk update && apk add --no-cache luajit lua-resty-core

RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
	&& CONFIG="\
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/usr/lib/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-http_xslt_module=dynamic \
	--with-http_image_filter_module=dynamic \
	--with-http_geoip_module=dynamic \
	--with-http_perl_module=dynamic \
	--with-threads \
	--with-stream \
	--with-stream_ssl_module \
	--with-http_slice_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-file-aio \
	--with-http_v2_module \
	--with-cc-opt="-DNGX_HAVE_INET6=0" \
	--add-module=/usr/src/nginx-goodies-nginx-sticky-module-ng-$NGINX_STICKY_MODULE_NG_VERSION \
        --add-module=/tmp/lua-nginx-module-${LUA_NGINX_MODULE_VERSION} \
	--add-module=/usr/src/nginx-upstream-dynamic-servers-$NGINX_UPSTREAM_DYNAMIC_SERVERS_VERSION \
	" \
	&& addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
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
	perl-dev \
        luajit-dev \
        && export LUAJIT_LIB=/usr/lib \
        && export LUAJIT_INC=/usr/include/luajit-2.1 \
        && curl -fSL https://github.com/apache/incubator-pagespeed-ngx/archive/v1.13.35.2-stable.tar.gz -o v1.13.35.2-stable.tar.gz \
        && tar -xzvf v1.13.35.2-stable.tar.gz \
        && cd incubator-pagespeed-ngx-1.13.35.2-stable \
        && psol_url=https://dl.google.com/dl/page-speed/psol/1.13.35.2-x64.tar.gz \
        && wget ${psol_url} \
        && tar -xzvf 1.13.35.2-x64.tar.gz \
        && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_MODULE_VERSION}.tar.gz -o /tmp/lua-nginx.tar.gz \
        && tar -xvf /tmp/lua-nginx.tar.gz -C /tmp \
	&& curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
	&& curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
	&& curl -fSL https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/$NGINX_STICKY_MODULE_NG_VERSION.tar.gz -o nginx-sticky-module-ng.tar.gz \
	&& curl -fSL https://github.com/DawtCom/nginx-upstream-dynamic-servers/archive/$NGINX_UPSTREAM_DYNAMIC_SERVERS_VERSION.tar.gz -o nginx-upstream-dynamic-servers.tar.gz \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found=''; \
	for server in \
	ha.pool.sks-keyservers.net \
	hkp://keyserver.ubuntu.com:80 \
	hkp://p80.pool.sks-keyservers.net:80 \
	pgp.mit.edu \
	; do \
	echo "Fetching GPG key $GPG_KEYS from $server"; \
	gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
	gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
	&& rm -r "$GNUPGHOME" nginx.tar.gz.asc \
	&& mkdir -p /usr/src \
	&& tar -zxC /usr/src -f nginx.tar.gz \
	&& tar -zxC /usr/src -f nginx-sticky-module-ng.tar.gz \
	&& tar -zxC /usr/src -f nginx-upstream-dynamic-servers.tar.gz \
	&& rm nginx.tar.gz \
	&& rm nginx-sticky-module-ng.tar.gz \
	&& rm nginx-upstream-dynamic-servers.tar.gz \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure $CONFIG \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	&& rm -rf /usr/src/nginx-$NGINX_VERSION \
	&& rm -rf /usr/src/nginx-goodies-nginx-sticky-module-ng-$NGINX_STICKY_MODULE_NG_VERSION \
	&& rm -rf /usr/src/nginx-upstream-dynamic-servers-$NGINX_UPSTREAM_DYNAMIC_SERVERS_VERSION \
	\
	# Bring in gettext so we can get `envsubst`, then throw
	# the rest away. To do this, we need to install `gettext`
	# then move `envsubst` out of the way so `gettext` can
	# be deleted completely, then move `envsubst` back.
	&& apk add --no-cache --virtual .gettext gettext \
	&& mv /usr/bin/envsubst /tmp/ \
	\
	&& runDeps="$( \
	scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
	| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
	| sort -u \
	| xargs -r apk info --installed \
	| sort -u \
	)" \
	&& apk add --no-cache --virtual .nginx-rundeps $runDeps \
	&& apk del .build-deps \
	&& apk del .gettext \
	&& mv /tmp/envsubst /usr/local/bin/ \
	\
	# forward request and error logs to docker log collector
        && ls -ltr
#	&& ln -sf /dev/stdout /var/log/nginx/access.log \
#	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

#CMD ["nginx", "-g", "daemon off;"]
RUN apk update
RUN apk add wget
#RUN wget -q https://apk.signalsciences.net/sigsci_apk.pub ; mv sigsci_apk.pub /etc/apk/keys/
#RUN echo https://apk.signalsciences.net/3.19/main | tee -a /etc/apk/repositories && apk update
#RUN apk add sigsci-agent

# Start Nginx
#CMD ["nginx", "-g", "daemon off;"]
#CMD ["/usr/sbin/sigsci-agent", "start"]

RUN mkdir -p /opt/sigsci/nginx

COPY contrib/sigsci-module/MessagePack.lua /opt/sigsci/nginx/MessagePack.lua
COPY contrib/sigsci-module/SignalSciences.lua /opt/sigsci/nginx/SignalSciences.lua
COPY contrib/sigsci-module/sigsci_init.conf /opt/sigsci/nginx/sigsci_init.conf
COPY contrib/sigsci-module/sigsci_module.conf /opt/sigsci/nginx/sigsci_module.conf
COPY contrib/sigsci-module/sigsci.conf /opt/sigsci/nginx/sigsci.conf
COPY contrib/sigsci-agent/sigsci-agent /usr/sbin/sigsci-agent
COPY contrib/sigsci-agent/sigsci-agent-diag /usr/sbin/sigsci-agent-diag

#COPY contrib/nginx.conf /etc/nginx/nginx.conf

ADD . /app
RUN apk update && apk --no-cache add apr apr-util ca-certificates openssl && rm -rf /var/cache/apk/*
RUN chmod +x /usr/sbin/sigsci-agent; chmod +x /usr/sbin/sigsci-agent-diag; chmod +x /app/start.sh
CMD ["/bin/sh", "-c", "/usr/sbin/sigsci-agent start && nginx -g 'daemon off;'"]

#ENTRYPOINT ["/app/start.sh"]

