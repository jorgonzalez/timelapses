#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to blend two videos together.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#			v0.2; option progressive application of the mask; reverse progression of the mask.
#
#	Future imprv.:	Beter argument check and validation.
#			Output filename.
#			Proper option function.
#			Software dependencies.
#

#Some variables
version=0.2

#Some arguments
vid1=${1}
vid2=${2}

ffmpeg2 -i ${vid1} -i ${vid2} -filter_complex "[1:v:0]pad=iw*2:ih[bg]; [bg][1:v:0]overlay=w" merged.avi

