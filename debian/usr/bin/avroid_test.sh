#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
	echo "avroid_test expects only one argument: a path to chroot a system into."
fi

INSTALL_PATH=$1

if [ ! -d "$INSTALL_PATH" ]; then
	echo "$INSTALL_PATH does not exist."
fi
