#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to resize of a batch of images.
#			Based on size as entry points.
#			Takes the directory to work on as argument.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#
#	Future imprv.:	Beter argument check and validation.
#

#Some variables
version=0.1
mogrify=$(which mogrify-im6)

#Check if we have all the needed software
if [[ ! -e ${mogrify} ]]; then
        echo "You are missing all or parts of imagemagick package, please install it for your distribution"
        exit 1
fi


function perspective(){

	if [[ -z "${dir}" || -z "${width}" || -z "${height}" ]]; then
		exit 1
	else
		total_images=`ls -l ${dir} | grep DSC | wc -l`

		file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
		if [[ -z "${file}" ]]; then
                	echo "There are no files to change the size!"
			exit 1
		else
			echo "Working on \"${dir}\"..."
		fi

		if [[ ! -z ${copy} ]]; then
			orig_dir_end=`echo ${dir} | rev | cut -b 1-1`
			suffix="${width}x${height}"
			if [[ "${orig_dir_end}" == / ]]; then
				dir=`echo ${dir} | rev | cut -b 2- | rev`
			fi
			rm -rf ${dir}_${suffix}
			echo "Copying ${dir}/ to ${dir}_${suffix}/..."
			cp -a ${dir} ${dir}_${suffix}
			dir="${dir}_${suffix}"
		fi

		j=1
		if [[ ! -z "${preview}" ]]; then
			cp ${dir}/DSC_0001.JPG ${dir}/A_preview.JPG
		else
			rm ${dir}/A_preview.JPG 2>/dev/null
		fi

		mod_ops="-resize ${width}"x"${height}!"
		for photo in `ls -l ${dir} | grep JPG | awk '{print $9}'`; do
			echo -e -n "\rModifying image ${j}/${total_images}"

			${mogrify} ${mod_ops} ${dir}/${photo}

			let j=${j}+1
			if [[ ! -z "${preview}" ]]; then
				break
			fi
		done
		echo -e "\nDone!"
	fi
}

function usage(){
        echo -e "\t./$(basename $0) -d <VALUE> -w <VALUE> -h <VALUE>"
        echo -e "\t-d directory where the files are"
	echo -e "\t-w new width of the image"
	echo -e "\t-h new height of the image"
        echo -e "\t-y OPTIONAL copy original into ORIGINAL_NEW-WIDTHxNEW-HEIGHT"
        echo -e "\t-p OPTIONAL (preview) applies the modifications to the first photo to see the result"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
        perspective
}

while getopts "d:h:w:yphv?" arg; do
	case $arg in
		d)dir=${OPTARG}
		;;
		h)height=${OPTARG}
		;;
		w)width=${OPTARG}
		;;
		y)copy=y
		;;
		p)preview=y
		;;
		v)version && exit 0
		;;
		?)usage && exit 1
		;;
	esac
done

main
