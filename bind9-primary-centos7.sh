#!/bin/sh

[ -z "$1" ] && echo "Usage: $0 domain ns1-ip [ ns2-ip ]" && exit

DOMAIN="$1"
NS1_IP="$2"
NS2_IP="$3"

[ -z "$NS1_IP" ] && NS1_IP=$(ip addr show dev eth0 | grep -m1 'inet ' | awk '{ print $2 }' | cut -f1 -d/)
[ -z "$NS2_IP" ] && NS2_IP=$NS1_IP

yum -y update
yum -y install epel-release.noarch
yum -y install vim tmux htop bind bind-utils

mv /etc/named.conf /etc/named.conf.0
cat <<EOT > /etc/named.conf
options {
	listen-on port 53 { any; };
	listen-on-v6 port 53 { any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
	allow-query     { any; };

	recursion no;
	dnssec-enable yes;
	dnssec-validation yes;
	bindkeys-file "/etc/named.root.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
include "/etc/named/local.zones";
EOT

cat <<EOT > /etc/named/local.zones
include "/etc/named/zone-${DOMAIN}";
EOT

cat <<EOT > /etc/named/zone-${DOMAIN}
zone    "${DOMAIN}" {
        type master;
        file "/var/named/masters/${DOMAIN}";
        notify yes;
};
EOT

mkdir -p /var/named/masters
chown named:named /var/named/masters

cat <<EOT > /var/named/masters/${DOMAIN}
\$TTL 5m
@	IN SOA	@ root.${DOMAIN}. (
					1	; serial
					1d	; refresh
					1h	; retry
					1w	; expire
					3h )	; minimum
	NS	ns1
	NS	ns2

ns1 A	$NS1_IP
ns2 A	$NS2_IP
EOT

systemctl enable named
systemctl start named
