#!/bin/bash
###
## reload haproxy only if configurations valid
###
HAPROXY_RELOAD_STRATEGY="${HAPROXY_RELOAD_STRATEGY:-socket}";

HAPROXY_CONF="${HAPROXY_CONF:-/etc/haproxy/haproxy.cfg}";
HAPROXY_CONFD="${HAPROXY_CONFD:-$(dirname ${HAPROXY_CONF})/cfg.d}";

echo "Checking configurations...";
haproxy -c -V \
    -f "${HAPROXY_CONF}" \
    -f "${HAPROXY_CONFD}" \
&& { \
    echo "Reloading configurations...";
    case "${HAPROXY_RELOAD_STRATEGY^^}" in
        "S6")
            s6-svc -r /var/run/service/svc-haproxy;
            # requires root if container is running as root
        ;;
        "SOCKET")
            HAPROXY_MASTERSOCK="${HAPROXY_MASTERSOCK:-/var/run/haproxy/master.sock}";
            # requires
            #  haproxy to be started in master-worker mode (-W)
            #  with a master socket path specified (-S /var/run/haproxy-master.sock)
            #  and the user running the script permitted to write to the socket
            socat ${HAPROXY_MASTERSOCK} - <<< "reload";
        ;;
        *) echo "Nothing to do."; ;;
    esac \
    && echo "Done." || echo "Failed.";
} || echo "Test Failed. Won't reload.";
