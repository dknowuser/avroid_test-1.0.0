#!/usr/bin/env bash

# Check input arguments

# The first argument is a local path to install into.
# The second argument is a mirror URL to download from. This argument is optional
# and if it is not set download will be performed from http://ftp.ru.debian.org/debian.

if [ "$#" -gt 2 ]; then
	echo "Too many arguments."
 	# Is it useful here to check return status?
 	exit -1
 fi

if [ "$#" -lt 1 ]; then
	echo "avroid_test expects at least one argument: a path to chroot a system into."
 	exit -1
fi

INSTALL_PATH=$1

if [ ! -d "$INSTALL_PATH" ]; then
	echo "$INSTALL_PATH does not exist."
 	exit -1
fi

MIRROR="http://ftp.ru.debian.org/debian/"

if [ "$#" -eq 2 ]; then
	MIRROR=$2
fi

if wget --spider "${MIRROR}" 2>/dev/null; then
	echo "$MIRROR exists."
else
	echo "$MIRROR does not exist."
	exit -1;
fi

# Unprivileged processes should be able to run the script
fakechroot fakeroot debootstrap --variant=fakechroot bookworm $INSTALL_PATH $MIRROR
# /etc/apt/sources.list does not contain deb-src entry initially
echo "deb-src $MIRROR bookworm main" >> $INSTALL_PATH/etc/apt/sources.list

fakechroot fakeroot chroot $INSTALL_PATH /bin/bash <<"EOT"
# Update after modifying /etc/apt/sources.list
apt-get update

# Required for apt-get source
apt-get -y install dpkg-dev devscripts

cd /home
mkdir ./temp_build
cd ./temp_build

apt-get source bash gawk sed firefox-esr
apt-get -y build-dep bash gawk sed firefox-esr

# Build packages
cd ./bash-*
dpkg-buildpackage -b -uc -us &

cd ../gawk-*
dpkg-buildpackage -b -uc -us &

cd ../sed-*
dpkg-buildpackage -b -uc -us &

cd ../firefox-esr-*
dpkg-buildpackage -b -uc -us &
EOT

exit 0
