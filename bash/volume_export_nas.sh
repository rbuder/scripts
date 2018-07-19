#!/bin/bash
# Author: Aries Youssefian
# This script will take a volume ID, clone it, convert it to qcow2, push it to a remote NAS via rsync 
# 
# Must be run from a Symphony node. 
# SCRIPT ASSUMES SOURCE NODE HAS ENOUGH SPACE ON mancala0
#
# Requirements for NAS: User login/password specified via string, no key, and enough space on destination directory
#
# Note: This method is not the most secure as we are sending password in plaintext. 
#
#
# Todo: Add flags for SSL. Add key-based logins. 
#
# NEED TO LOG IN VIA SSH FIRST TO ACCEPT HANDSHAKE BEFORE RUNNING
# needs rsync installed on NAS 


display_usage() {
	echo "This script will clone a volume, attach it to a host, convert it to a qcow2, and push it to a remote NAS via rsync"
	echo -e "\nUsage:\nsource-user-name source-domain source-password source-cluster-address source-volume-id nas-username nas-password nas-host nas-directory image-name\n"
	}

# if less than 9 arguments supplied, display usage
if [  $# -le 9 ]
then
	display_usage
	exit 1
fi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $# == "--help") ||  $# == "-h" ]]
then
	display_usage
	exit 0
fi

# Variables 

sourceuser=$1
sourcedomain=$2
sourcepassword=$3
sourcecluster=$4
sourcevolid=$5
nasuser=$6
naspassword=$7
nashost=$8
nasdir=$9
imagename=${10}
sourcehostname="$(hostname)"

# Clone vol, attach to host, convert to qcow2

echo Cloning $sourcevolid 

sourceclonedvolid="$(symp -k --url $sourcecluster -d $sourcedomain -u $sourceuser -p $sourcepassword volume create --source-id $sourcevolid tempvol_toexport -f value -c id)"

echo Cloning successful, cloned volume ID is $sourceclonedvolid

echo Attaching cloned volume $sourceclonedvolid to host $sourcehostname

sourcedevaddress="$(mancala volumes attach-to-host $sourceclonedvolid $sourcehostname --json | jq -r .attachments[].mountpoint)"

echo Successfully mounted cloned volume $sourceclonedvolid to host $sourcehostname at $sourcedevaddress

echo Beginning qemu-img conversion 

qemu-img convert -f raw -O qcow2 $sourcedevaddress /mnt/mancala0/$imagename.qcow2

echo Successfully completed conversion to /mnt/mancala0

echo Unattaching cloned volume $sourceclonevolid from host $sourcehostname

mancala volumes detach-from-host $sourceclonedvolid $sourcehostname

echo Successfully detached cloned volume $sourceclonevolid from host $sourcehostname

echo Deleting cloned volume $sourceclonedvolid 

symp -k --url $sourcecluster -d $sourcedomain -u $sourceuser -p $sourcepassword volume remove $sourceclonedvolid

echo Successfully deleted cloned volume $sourceclonedvolid on $sourcecluster

echo Now we will rsync $imagename to $nashost 

# From here we can move the qcow2 to the NAS

sshpass -p $naspassword rsync -avz -e ssh /mnt/mancala0/$imagename.qcow2 $nasuser@$nashost:/$nasdir/$imagename.qcow2 

echo Done moving $imagename.qcow2 to $nashost 

echo Deleting $imagename.qcow2 from $sourcehostname on mancala0 

rm -f /mnt/mancala0/$imagename.qcow2

echo Deleted qcow2 file. 

echo All done. 




