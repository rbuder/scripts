#!/bin/bash

# This script will provision floating IP's for a tenancy


display_usage() {
	echo "This script batch creates floating IPs"
	echo -e "\nUsage:\nmultifips domain username password network-id number-of-fips\n"
	}

# if less than five arguments supplied, display usage
if [  $# -le 4 ]
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

domain=$1
echo $domain
user=$2
password=$3
netid=$4
numfips=$5
url=$6

echo Allocating $numfips from network ID $netid
counter=1
while [ $counter -le $numfips ]
do
        symp -k --url=$url -d $domain -u $user -p $password virt-network floatingip-create $netid
        ((counter++))
done

echo All Done

