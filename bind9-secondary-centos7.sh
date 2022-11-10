#!/bin/sh

[ -z "$2" ] && echo "Usage: $0 domain master-ip" && exit

DOMAIN="$1"
MASTER_IP="$2"

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
        type slave;
        file "/var/named/slaves/${DOMAIN}";
        masters { ${MASTER_IP}; };  
        masterfile-format text;
};
EOT
