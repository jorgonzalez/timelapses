#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to apply a mask to a set of pictures in an directory.
#
#	Version:	0.2
#
#	Modifications:	v0.1; first version.
#			v0.2; option progressive application of the mask; reverse progression of the mask.
#
#	Future imprv.:	Preview.
#

#Some variables
version=0.2
mogrify=/usr/bin/mogrify-im6
convert=/usr/bin/convert-im6
identify=/usr/bin/identify-im6

#Check if we have all the needed software
if [[ ! -e ${mogrify} ]] || [[ ! -e ${convert} ]] || [[ ! -e ${identify} ]]; then
        echo "You are missing all or parts of imagemagick package, please install it for your distribution"
        exit 1
fi

function check_files(){
        file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file}" ]]; then
		echo "There are no files to apply the mask"
			exit 1
	else
		echo "Working on \"${dir}\"..."
	fi
}

function mask(){
	total_images=`ls -l ${dir} | grep DSC | wc -l`
	check_files
	j=0

	if [[ "${progressive}" != "y" && "${reverse}" != "y" ]]; then
		for i in `ls -al ${dir} | grep JPG | grep DSC | awk '{ print $9 }'`; do
			echo -e -n "\rModifying image ${j}/${total_images}"
			${convert} ${dir}/${i} -page +0+0 ${mask} -flatten ${dir}/${i}
			let j=${j}+1
		done
	elif [[ "${progressive}" == "y" ]]; then
		perc=`echo "100/(${total_images}-1)" | bc -l | cut -c -4`
		j=${total_images}
		for i in `ls -al ${dir} | grep JPG | grep DSC | awk '{ print $9 }'`; do
			echo -e -n "\rModifying image ${j}/${total_images}"
			file_num=`echo ${i} | cut -b 5-8`
			curr_perc=`echo "${j}*${perc}" | bc -l | cut -c -4`
			${convert} ${mask} -alpha set -channel A -evaluate subtract ${curr_perc}% ${dir}/mask_${file_num}.PNG
			let j=${j}-1
			${convert} ${dir}/${i} -page +0+0 ${dir}/mask_${file_num}.PNG -flatten ${dir}/${i}
			rm ${dir}/mask_${file_num}.PNG
			let j=${j}+1
		done
	elif [[ "${reverse}" == "y" ]]; then
		perc=`echo "100/(${total_images}-1)" | bc -l | cut -c -4`
		j=0
		for i in `ls -al ${dir} | grep JPG | grep DSC | awk '{ print $9 }'`; do
			echo -e -n "\rModifying image ${j}/${total_images}"
			file_num=`echo ${i} | cut -b 5-8`
			curr_perc=`echo "${j}*${perc}" | bc -l | cut -c -4`
			${convert} ${mask} -alpha set -channel A -evaluate subtract ${curr_perc}% ${dir}/mask_${file_num}.PNG
			let j=${j}+1
			${convert} ${dir}/${i} -page +0+0 ${dir}/mask_${file_num}.PNG -flatten ${dir}/${i}
			rm ${dir}/mask_${file_num}.PNG
			let j=${j}+1
		done
	fi
	echo -e "\nDone!"
}

function version(){
        name=$(basename $0)
        echo -e "${name}: version ${version}"
        exit 0
}

function usage(){
        echo -e "./$(basename $0) -d <VALUE> -m <VALUE> -p -r"
        echo -e "\t-d directory where the files are"
	echo -e "\t-m path to the mask file"
	echo -e "\t-p OPTIONAL: progressive, will apply mask from 100% transparency to 0%"
	echo -e "\t-r OPTIONAL: reverse, will apply mask from 0% transparency to 100%"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
        mask
}

while getopts "d:m:prhv?" arg; do
        case ${arg} in
		d)dir=${OPTARG}
		;;
		m)mask=${OPTARG}
		;;
		p)progressive=y
		;;
		r)reverse=y
		;;
                v)version && exit 0
		;;
                ?)usage && exit 1
                ;;
            esac
done

main
