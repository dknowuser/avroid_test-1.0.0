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

# It is bettter for unprivileged processes to be able to run the script
debootstrap bookworm $INSTALL_PATH $MIRROR

# /etc/apt/sources.list does not contain deb-src entry initially
echo "deb-src $MIRROR bookworm main" >> $INSTALL_PATH/etc/apt/sources.list

# Needed to build packages
mount --make-rslave --rbind /dev $INSTALL_PATH/dev
mount --make-rslave --rbind /proc $INSTALL_PATH/proc

chroot $INSTALL_PATH /bin/bash <<"EOT"
UNPRIVILEGED_USER=builder

# Update after modifying /etc/apt/sources.list
apt-get update

# Required for apt-get source
apt-get -y install dpkg-dev devscripts locales

touch /etc/default/locale
echo LANG=en_US.UTF-8 >> /etc/default/locale

apt-get -y build-dep bash gawk sed firefox-esr

# Create an unprivileged user which builds bash, gawk, sed, firefor-esr
useradd -p $UNPRIVILEGED_USER $UNPRIVILEGED_USER
mkdir /home/$UNPRIVILEGED_USER
chown $UNPRIVILEGED_USER /home/$UNPRIVILEGED_USER
EOT

# Build packages as non-root
chroot --userspec=$UNPRIVILEGED_USER $INSTALL_PATH /bin/bash <<"EOT"
UNPRIVILEGED_USER=builder

cd /home/$UNPRIVILEGED_USER
apt-get source gawk sed bash firefox-esr

cd /home/$UNPRIVILEGED_USER/gawk-*
dpkg-buildpackage -b -uc -us

cd /home/$UNPRIVILEGED_USER/sed-*
dpkg-buildpackage -b -uc -us

cd /home/$UNPRIVILEGED_USER/bash-*
dpkg-buildpackage -b -uc -us

cd /home/$UNPRIVILEGED_USER/firefox-esr-*
dpkg-buildpackage -b -uc -us
EOT

umount -l $INSTALL_PATH/proc
umount -l $INSTALL_PATH/dev

exit 0
