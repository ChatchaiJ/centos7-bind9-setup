# centos7-bind9-setup

This project has two scripts

- bind9-primary-centos7.sh
- bind9-secondary-centos7.sh

which can be run on the primary DNS server, and secondary DNS server respectively.

On the primary server

```
# sh bind9-primary-centos7.sh $DOMAIN $primary_server_ip $secondary_server_ip
```

On the secondary server

```
# sh bind9-secondary-centos7.sh $DOMAIN $primary_server_ip
```
