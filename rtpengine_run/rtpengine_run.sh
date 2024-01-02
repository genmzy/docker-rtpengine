#! /bin/sh
set -x

table=0
[ -z "$TABLE" ] || table=$TABLE

local_ip=""
if [ -e "/usr/bin/ip" ]; then
  local_ip=`ip addr|grep inet|grep -v inet6|grep -v "172.17.0.1"|grep -v "127.0.0.1"|awk -F ' ' '{print $2}' | awk -F '/' '{print $1}'`
else
  local_ip=`hostname -I|sed -e "s/ /\n/g"|tr -s "\n"|grep -v "172.17.0.1"`
fi
[ -z "$LOCAL_IP" ] || local_ip=$LOCAL_IP

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

if lsmod | grep xt_RTPENGINE || modprobe xt_RTPENGINE; then
  echo "rtpengine kernel module already loaded."
else
  if [ -e /usr/bin/apt-get ] ; then
    # Build the kernel module for the docker run host
    apt-get update -y
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y linux-headers-$(uname -r) linux-image-$(uname -r)

    module-assistant update
    module-assistant auto-install ngcp-rtpengine-kernel-source
    modprobe xt_RTPENGINE
  else
    cd /rtpengine/iptables-extension
    make
    if [ ! $? -ne 0 ]; then
      exit 1;
    fi
    cp -u libxt_RTPENGINE.so /lib64/xtables
    cd /rtpengine/kernel-module
    make
    if [ ! $? -ne 0 ]; then
      exit 1;
    fi
    cp -u xt_RTPENGINE.ko "/lib/modules/$(uname -r)/extra"
    depmod -a
    modprobe xt_RTPENGINE
  fi
fi

set +e
if [ -e /proc/rtpengine/control ]; then
  echo "del $table" > /proc/rtpengine/control 2>/dev/null
fi
# Freshly add the iptables rules to forward the udp packets to the iptables-extension "RTPEngine":
# Remember iptables table = chains, rules stored in the chains
# -N (create a new chain with the name rtpengine)
iptables -N rtpengine 2> /dev/null

# -D: Delete the rule for the target "rtpengine" if exists. -j (target): chain name or extension name 
# from the table "filter" (the default -without the option '-t') 
iptables -D INPUT -j rtpengine 2> /dev/null
# Add the rule again so the packets will go to rtpengine chain after the (filter-INPUT) hook point.
iptables -I INPUT -j rtpengine
# Delete and Insert a rule in the rtpengine chain to forward the UDP traffic 	
iptables -D rtpengine -p udp -j RTPENGINE --id "$table" 2>/dev/null
iptables -I rtpengine -p udp -j RTPENGINE --id "$table"
iptables-save > /etc/iptables.rules

set -x
ulimit -n 65535
rtpengine --interface=$local_ip --listen-http=127.0.0.1:22222 --listen-ng=$local_ip:2223 -m 50000 -M 65535 --tos=184 --table=$table --pidfile=/usr/local/rtpengine/run/rtpengine.pid --foreground --log-level=4 --recording-method=all --recording-dir=/usr/local/fs_record/spool
