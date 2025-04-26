# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE}
#
ARG DPASRCARCH
ARG DPAVERSION
#
RUN set -xe \
    && apk add --no-cache --purge -uU \
        ca-certificates \
        curl \
        haproxy \
        # haproxy-dataplaneapi \
        openssl \
        # socat \
        tzdata \
    && mkdir -p /defaults \
    && mv /etc/haproxy/haproxy.cfg /defaults/haproxy.cfg.default \
#
    && echo "Using DataPlaneAPI version: $DPASRCARCH / $DPAVERSION" \
    && curl -jSLN \
        -o /tmp/dataplaneapi_${DPAVERSION}_${DPASRCARCH}.tar.gz \
        https://github.com/haproxytech/dataplaneapi/releases/download/v${DPAVERSION}/dataplaneapi_${DPAVERSION}_${DPASRCARCH}.tar.gz \
    && tar -xzf /tmp/dataplaneapi_${DPAVERSION}_${DPASRCARCH}.tar.gz -C /usr/local/bin \
    && mv /usr/local/bin/dataplaneapi.yml.dist /defaults/ \
#
    && apk del --purge curl \
    && rm -rf /var/cache/apk/* /tmp/*
#
COPY root/ /
#
VOLUME /etc/haproxy/ /var/lib/haproxy/
#
EXPOSE 80/tcp 443/tcp 8080/tcp 8080/tcp 8405/tcp
#
HEALTHCHECK \
    --interval=2m \
    --retries=5 \
    --start-period=5m \
    --timeout=10s \
    CMD \
    wget --quiet --tries=1 --no-check-certificate --spider ${HEALTHCHECK_URL:-"http://localhost:80/"} \
    || exit 1
    # && nc -z -i 1 -w 1 localhost 8080 \
    #
#
ENTRYPOINT ["/init"]
