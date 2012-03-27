#!/bin/bash -e

export INTERFACE=$1

source ./addrc

echo ${HOSTADDR:?"empty host addr"}
echo ${MASKADDR:?"empty mask addr"}
echo ${GATEWAY:?"empty gateway"}
echo ${NETWORK:?"empty network"}

if [ -z "$MYID" ]; then
    export MYID=`whoami`
fi 
echo "$MYID"
TOPDIR=`pwd`
CONFDIR=$TOPDIR/config

chk_root () {

  if [ ! $( id -u ) -eq 0 ]; then
    echo "Please enter root's password."
    exec sudo -E su -m -c "${0} ${1}" # Call this prog as root
    exit ${?}  # sice we're 'execing' above, we wont reach this exit
               # unless something goes wrong.
  fi

}

update () {
  ./notify_status.py "$1" "$2"
  echo $1 $2
}


chk_root $1

# install package
update log "install fai"
update prog 10
apt-get install -y --assume-yes fai-quickstart


# dhcp config
update log "setup dhcp"
cp -f $CONFDIR/etc/dhcp/dhcpd.conf.template $CONFDIR/etc/dhcp/dhcpd.conf
sed -i "s|%NETADDR%|$NETWORK|g" $CONFDIR/etc/dhcp/dhcpd.conf
sed -i "s|%MASKADDR%|$MASKADDR|g" $CONFDIR/etc/dhcp/dhcpd.conf
sed -i "s|%GATEWAY%|$GATEWAY|g" $CONFDIR/etc/dhcp/dhcpd.conf
sed -i "s|%HOSTADDR%|$HOSTADDR|g" $CONFDIR/etc/dhcp/dhcpd.conf
cp -f $CONFDIR/etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf
/etc/init.d/isc-dhcp-server restart
# dns setup/config
update prog 20

# tftp config
update log "setup tftp"
cp -f $CONFDIR/etc/default/tftpd-hpa.template  $CONFDIR/etc/default/tftpd-hpa
cp -f $CONFDIR/etc/default/tftpd-hpa /etc/default/tftpd-hpa

cp -f $CONFDIR/etc/fai/apt/sources.list.template $CONFDIR/etc/fai/apt/sources.list
sed -i "s|%HOSTADDR%|$HOSTADDR|g" $CONFDIR/etc/fai/apt/sources.list


# fai config
rm -rf /srv/fai/config /etc/fai
cp -rf $CONFDIR/srv/fai/config /srv/fai/config
cp -rf $CONFDIR/etc/fai /etc/fai

update prog 30
# fai nfs creation
update log "setup nfs root"
export SERVERINTERFACE=$INTERFACE
fai-setup -v
#ssh-keygen -P "" -f /home/$MYID/.ssh/id_rsa
cp -f /home/$MYID/.ssh/id_rsa.pub /srv/fai/nfsroot/live/filesystem.dir/root/id_rsa.pub

# hosts config
cp $CONFDIR/etc/hosts.template $CONFDIR/etc/hosts
sed -i "s|%HOSTADDR%|$HOSTADDR|g" $CONFDIR/etc/hosts
sed -i "s|%HOSTNAME%|$HOSTNAME|g" $CONFDIR/etc/hosts
cp -f $CONFDIR/etc/hosts /srv/fai/nfsroot/live/filesystem.dir/etc/hosts
# nfs setup
echo $HOSTADDR
grep "/srv/fai/config $HOSTADDR/24" /etc/exports > /dev/null && true
if [ "$?" -ne "0" ]; then
    echo "/srv/fai/config $HOSTADDR/24(async,ro,no_subtree_check,no_root_squash)" >>  /etc/exports
else
    echo ""
fi

update log "setup nfs"
/etc/init.d/nfs-kernel-server restart
mkdir -p /srv/instances
chmod 777 /srv/instances
grep "/srv/instances $HOSTADDR/24" /etc/exports > /dev/null  && true
if [ "$?" -ne "0" ]; then
    echo "/srv/instances $HOSTADDR/24(async,rw,no_subtree_check,no_root_squash)" >>  /etc/exports
    echo "/srv/instances 127.0.0.1(async,rw,no_subtree_check,no_root_squash)" >>  /etc/exports
else
    echo ""
fi

chmod -R +r /srv/tftp/fai/*

update log "start listen monitor daemon"
killall faimond
faimond -d -b -T
# chboot, chmod, tftp-restart
# chmod +r /srv/tftp/fai/*
# /etc/init.d/tftpd-hpa restart
# fai-chboot -f verbose,sshd,createvt,reboot -I -v 
update prog 40
