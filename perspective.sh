#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to change the perspective of a batch of images.
#			Based on four points in the original image (A1, B1, C1, D1) that will be
#			distorted (A2, B2, C2, D2). These points need to be input manually for each
#			directory to be processed.
#			Takes the directory to work on as argument.
#			If there is a second argument, only generates the preview of the output.
#
#	Version:	0.2
#
#	Modifications:	v0.1; first version.
#			v0.2; rudimentary preview passing a second argument.
#
#	Future imprv.:	Preview.
#			Beter argument check and validation.
#			Proper option function.
#

#Some variables
A1=600,1000
A2=
B1=600,2500
B2=
C1=3600,2500
C2=
D1=3600,1000
D2=
#D2=231,2038
#D2=46,2124

#Pixels to cut from the output image
Q=0	#X1 From left
P=0	#Y1 From up
Z=0	#X2 From right
M=0	#Yw From down

dir=${1}
preview=${2}

if [[ -z "${dir}" ]]; then
	exit 1
else
	total_images=`ls -l ${dir} | grep DSC | wc -l`
	j=1
	if [[ ! -z "${preview}" ]]; then
		cp ${dir}/DSC_0001.JPG ${dir}/A_preview.JPG
	else
		rm ${dir}/A_preview.JPG 2>/dev/null
	fi
	for foto in `ls -l ${dir} | grep JPG | awk '{print $9}'`; do
		echo -e -n "\rModifying image ${j}/${total_images}"

#		Five point transformation
#		convert-im6 ${dir}/${foto} -filter point -virtual-pixel tile -mattecolor DodgerBlue -distort Perspective "${A1} ${A2}  ${B1} ${B2}  ${C1} ${C2}  ${D1} ${D2}" ${dir}/${foto};
#
#		Four point transformation
		convert-im6 ${dir}/${foto} -filter point -virtual-pixel tile -mattecolor DodgerBlue -distort Perspective "${A1} ${A2}  ${B1} ${B2}  ${C1} ${C2}  ${D1} ${D2}  ${E1} ${E2}" ${dir}/${foto};

		convert-im6 ${dir}/${foto} -crop +${Q}+${P} -crop -${Z}-${M} ${dir}/${foto}; convert-im6 ${dir}/${foto} -resize '4288x2848!' ${dir}/${foto};
		let j=${j}+1
		if [[ ! -z "${preview}" ]]; then
			break
		fi
	done
	echo -e "\nDone!"
fi
