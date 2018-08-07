#!/bin/bash
# Author: Aries Youssefian
# This script will take a volume ID, clone it, attach it to a host, convert that volume to a qcow2, detach, then using Symp CLI will upload it to a remote cluster
# Upon completion it should then delete the volume.
# 
# Must be run from a Symphony node. 
# SCRIPT ASSUMES SOURCE NODE HAS ENOUGH SPACE ON mancala0
# Script also assumes only 1 project exists per source and destination domain (eg, default)
# if more projects exist, specify -r flag for the project 
#
# Todo: Add flags for SSL
#


display_usage() {
	echo "This script will clone a volume, attach it to a host, convert it to a qcow2, and push it to a remote Symp cluster"
	echo -e "\nUsage:\nsource-user-name source-domain source-password source-cluster-address source-volume-id destination-user destination-domain destination-password destination-cluster destination-image-name\n"
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
destuser=$6
destdomain=$7
destpassword=$8
destcluster=$9
destimagename=${10}
sourcehostname="$(hostname)"

echo Cloning $sourcevolid 

sourceclonedvolid="$(symp -k --url $sourcecluster -d $sourcedomain -u $sourceuser -p $sourcepassword volume create --source-id $sourcevolid tempvol_toexport -f value -c id)"

echo Cloning successful, cloned volume ID is $sourceclonedvolid

echo Attaching cloned volume $sourceclonedvolid to host $sourcehostname

sourcedevaddress="$(mancala volumes attach-to-host $sourceclonedvolid $sourcehostname --json | jq -r .attachments[].mountpoint)"

echo Successfully mounted cloned volume $sourceclonedvolid to host $sourcehostname at $sourcedevaddress

echo Beginning qemu-img conversion 

qemu-img convert -f raw -O qcow2 -p $sourcedevaddress /mnt/mancala0/exportedvm.qcow2

echo Successfully completed conversion to /mnt/mancala0

echo Unattaching cloned volume $sourceclonevolid from host $sourcehostname

mancala volumes detach-from-host $sourceclonedvolid $sourcehostname

echo Successfully detached cloned volume $sourceclonevolid from host $sourcehostname

echo Deleting cloned volume $sourceclonedvolid 

symp -k --url $sourcecluster -d $sourcedomain -u $sourceuser -p $sourcepassword volume remove $sourceclonedvolid

echo Successfully deleted cloned volume

echo Creating image $destimagename on destination cluster $destcluster

destimageid="$(symp -k --url $destcluster -d $destdomain -u $destuser -p $destpassword image create $destimagename -f value -c id)"

echo Successfully created image $destimagename with ID $destimageid

echo Uploading image..

symp -k --url $destcluster -d $destdomain -u $destuser -p $destpassword image upload $destimageid /mnt/mancala0/exportedvm.qcow2

echo Successfully uploaded image. 

echo Deleting qcow2 file

rm -f /mnt/mancala0/exportedvm.qcow2

echo Deleted qcow2 file. 

echo All done. 




