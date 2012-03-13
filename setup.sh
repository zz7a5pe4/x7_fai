#!/bin/bash

HOSTIP=192.168.1.4
TOPDIR=`pwd`
CONFDIR=$TOPDIR/config

# install package
sudo apt-get install fai-quicksetup

# dhcp config
sudo cp -f $CONFDIR/etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf

# dns setup/config

# tftp config
sudo cp -f $CONFDIR/etc/default/tftpd-hpa /etc/default/tftpd-hpa
sudo /etc/init.d/tftpd-hpa restart

# fai config
sudo rm -rf /srv/fai/config /etc/fai
sudo cp -rf $CONFDIR/srv/fai/config /srv/fai/config
sudo cp -rf $CONFDIR/etc/fai /etc/fai

# fai nfs creation

# nfs setup



