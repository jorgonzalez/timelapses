#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to play a directory of images.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#
#	Future imprv.:	Beter argument check and validation.
#			Proper option function.
#			Option to change frames per second.
#

#Some variables
version=0.1
mplayer=/usr/bin/mplayer

DIR=${1}

#Check if we have all the needed software
if [[ ! -e ${mplayer} ]]; then
        echo "You are missing ${mplayer}, please install it for your distribution"
        exit 1
fi

mplayer mf://${DIR}/*.JPG -mf fps=25
