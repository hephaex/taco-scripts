#!/bin/bash
(( EUID )) && echo You need to be root. && exit 1
set -ex

EXIP=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $7}')
EXGW=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $3}')
EXNIC=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $5}')

OS_DISTRO=$(cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/["]//g' | awk '{print $1}')
if [ $OS_DISTRO == Red ]; then
    MASK=$(ifconfig $EXNIC | awk '/netmask /{ print $4;}')
    CIDR=$(ipcalc -n $EXIP $MASK | cut -d'=' -f2)/$(ipcalc -p $EXIP $MASK | cut -d'=' -f2)
elif [ $OS_DISTRO == CentOS ]; then
    MASK=$(ifconfig $EXNIC | awk '/netmask /{ print $4;}')
    CIDR=$(ipcalc -n $EXIP $MASK | cut -d'=' -f2)/$(ipcalc -p $EXIP $MASK | cut -d'=' -f2)
elif [ $OS_DISTRO == Ubuntu ]; then
    CIDR=$(ipcalc -n $EXIP $EXGW | awk /'Network:'/'{print $2}')
fi
ARMADA_MANIFEST_DIR=~/apps/armada-manifests
if [ -d $ARMADA_MANIFEST_DIR ]; then
  rm -rf $ARMADA_MANIFEST_DIR
fi

cd ~/apps
git clone https://github.com/sktelecom-oslab/armada-manifests.git

armada apply ~/apps/armada-manifests/taco-aio-manifest.yaml \
	--set chart:ceph:values.network.public=$CIDR \
	--set chart:ceph:values.network.cluster=$CIDR \
	--set chart:neutron:values.network.interface.tunnel=$EXNIC
