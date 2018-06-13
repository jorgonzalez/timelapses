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
#	Version:	0.4
#
#	Modifications:	v0.1; first version.
#			v0.2; rudimentary preview passing a second argument.
#			v0.3; use optarg
#                       v0.4; hardcoded binaries removed for which
#			v0.5; allow dots and commas as coordinate separator (easier if using keypad).
#			v0.6; remove resizing option if there is no crop. Use original size if cropping instead of hardcoded value.
#
#	Future imprv.:	Beter argument check and validation.
#

#Some variables
version=0.6
convert=$(which convert-im6)
identify=$(which identify-im6)


function perspective(){

	A1="600,1000"
	B1="600,2500"
	C1="3600,2500"
	D1="3600,1000"
	#D2=231,2038
	#D2=46,2124

	#Change dots for commas in the entry coordenates
	A2=`echo ${A2} | tr "." ","`
	B2=`echo ${B2} | tr "." ","`
	C2=`echo ${C2} | tr "." ","`
	D2=`echo ${D2} | tr "." ","`

	#Pixels to cut from the output image
	Q=0	#X1 From left
	P=0	#Y1 From up
	Z=0	#X2 From right
	M=0	#Yw From down

	if [[ -z "${dir}" ]]; then
		exit 1
	else
		total_images=`ls -l ${dir} | grep DSC | wc -l`

		file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
		if [[ -z "${file}" ]]; then
                	echo "There are no files to change their perspective!"
			exit 1
		else
			echo "Working on \"${dir}\"..."
		fi

		width=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
		height=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`


		if [[ "${force}" == "y" ]]; then
			let height=${width}*9/16

			A2="600,1078"
			B2="600,2342"
			C2="3600,2342"
			D2="3600,1078"

			Q=0
			P=235
			Z=0
			M=235
		fi

		j=1
		if [[ ! -z "${preview}" ]]; then
			cp ${dir}/DSC_0001.JPG ${dir}/A_preview.JPG
		else
			rm ${dir}/A_preview.JPG 2>/dev/null
		fi
		for photo in `ls -l ${dir} | grep JPG | awk '{print $9}'`; do
			echo -e -n "\rModifying image ${j}/${total_images}"

#			Five point transformation
#			${convert} ${dir}/${photo} -filter point -virtual-pixel tile -mattecolor DodgerBlue -distort Perspective "${A1} ${A2}  ${B1} ${B2}  ${C1} ${C2}  ${D1} ${D2}" ${dir}/${photo};

#			Four point transformation
			${convert} ${dir}/${photo} -filter point -virtual-pixel tile -mattecolor DodgerBlue -distort Perspective "${A1} ${A2}  ${B1} ${B2}  ${C1} ${C2}  ${D1} ${D2}  ${E1} ${E2}" ${dir}/${photo};

			if [[ "${Q}" -ne 0 || "${P}" -ne 0 || "${Z}" -ne 0 || "${M}" -ne 0 ]]; then
				${convert} ${dir}/${photo} -crop +${Q}+${P} -crop -${Z}-${M} ${dir}/${photo}; convert-im6 ${dir}/${photo} -resize ''${width}'x'${height}'!' ${dir}/${photo};
			fi

			let j=${j}+1
			if [[ ! -z "${preview}" ]]; then
				break
			fi
		done
		echo -e "\nDone!"
	fi
}

function usage(){
        echo -e "\t./$(basename $0) -d <VALUE> -A <VALUE> -B <VALUE> -C <VALUE> -D <VALUE>"
        echo -e "\t-d directory where the files are"
	echo -e "\t-A -B -C -D pairs of coordinates to be mapped from (A1=600,1000;B1=600,2500;C1=3600,2500;D1=3600,1000)"
        echo -e "\t-p OPTIONAL (preview) applies the modifications to the first photo to see the result"
	echo -e "\t-f OPTIONAL force 16:9 perspective"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
        perspective
}

while getopts "d:A:B:C:D:fphv?" arg; do
        case $arg in
                d)dir=${OPTARG}
                ;;
                A)A2=${OPTARG}
                ;;
                B)B2=${OPTARG}
                ;;
                C)C2=${OPTARG}
                ;;
                D)D2=${OPTARG}
		;;
		p)preview=y
                ;;
		f)force=y
		;;
                v)version && exit 0
                ;;
                ?)usage && exit 1
                ;;
            esac
done

main
