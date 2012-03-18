#!/bin/bash

HOSTADDR=192.168.1.3
MASKADDR=255.255.255.0
GATEWAY=192.168.1.1
NETWORK=192.168.1.0

TOPDIR=`pwd`
CONFDIR=$TOPDIR/config

# install package
sudo apt-get install fai-quickstart approx

# dhcp config
cp -f $CONFDIR/etc/dhcp/dhcpd.conf.template $CONFDIR/etc/dhcp/dhcpd.conf
sed -i "s|%NETADDR%|$NETWORK|g" $CONFDIR/etc/dhcp/dhcpd.conf
sed -i "s|%MASKADDR%|$MASKADDR|g" $CONFDIR/etc/dhcp/dhcpd.conf
sed -i "s|%GATEWAY%|$GATEWAY|g" $CONFDIR/etc/dhcp/dhcpd.conf
sed -i "s|%HOSTADDR%|$HOSTADDR|g" $CONFDIR/etc/dhcp/dhcpd.conf
sudo cp -f $CONFDIR/etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf

# dns setup/config


# tftp config
cp -f $CONFDIR/etc/default/tftpd-hpa.template  $CONFDIR/etc/default/tftpd-hpa
sudo cp -f $CONFDIR/etc/default/tftpd-hpa /etc/default/tftpd-hpa
sudo /etc/init.d/tftpd-hpa restart



# approx setup
cp -f $CONFDIR/etc/approx/approx.conf.template $CONFDIR/etc/approx/approx.conf
cp -f $CONFDIR/etc/fai/apt/sources.list.template $CONFDIR/etc/fai/apt/sources.list
sed -i "s|%HOSTADDR%|$HOSTADDR|g" $CONFDIR/etc/fai/apt/sources.list
sudo cp -f $CONFDIR/etc/approx/approx.conf /etc/approx/approx.conf

# fai config
sudo rm -rf /srv/fai/config /etc/fai
sudo cp -rf $CONFDIR/srv/fai/config /srv/fai/config
sudo cp -rf $CONFDIR/etc/fai /etc/fai

# fai nfs creation
sudo fai-setup -v

# hosts config
cp $CONFDIR/etc/hosts.template $CONFDIR/etc/hosts
sed -i "s|%HOSTADDR%|$HOSTADDR|g" $CONFDIR/etc/hosts
sed -i "s|%HOSTNAME%|$HOSTNAME|g" $CONFDIR/etc/hosts
sudo cp -f $CONFDIR/etc/hosts /srv/fai/nfsroot/live/filesystem.dir/etc/hosts
# nfs setup
sudo sed -i '$a /srv/fai/config $HOSTIP/24(async,ro,no_subtree_check,no_root_squash)'  /etc/exports



