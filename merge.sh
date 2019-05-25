#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to merge two scenes into one using a number of frames from each.
#
#	Version:	0.2
#
#	Modifications:	v0.1; first version.
#			v0.2; added option to have a max. number of images in output scene
#
#	Future imprv.:
#

#Some variables
version=0.2
identify=$(which identify-im6)
convert=$(which convert-im6)
composite=$(which composite-im6)


#Check if we have all the needed software
if [[ ! -e "${composite}" ]] || [[ ! -e "${convert}" || ! -e "${identify}" ]]; then
	echo "You are missing all or parts of imagemagick package, please install it for your distribution"
	exit 1
fi

function section(){
	scene=${1}
	frames=${2}
	current_image=${3}
	final_image=${4}

	working_image=${current_image}
	for frame in $(seq 1 ${frames}); do
		image_file="DSC_"$(printf %04d ${working_image}).JPG
		final_image_file="DSC_"$(printf %04d ${final_image}).JPG
		cp ${scene}/${image_file} ${output}/${final_image_file}
		let working_image=${working_image}+1
		let final_image=${final_image}+1
	done
}

function merge(){
	file_main=`ls -al ${main}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file_main}" ]]; then
		echo "There are no files to process at ${main}"
		exit 1
	fi
	total_images_main=`ls -l ${main} | grep DSC | wc -l`
	width_main=`${identify} ${main}/${file_main} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
	height_main=`${identify} ${main}/${file_main} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`
	width_frame=${width_main}
	height_frame=${height_main}

	if [[ -z "${frames}" ]]; then
		frames=5
	fi

	file_second=`ls -al ${second}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file_second}" ]]; then
		echo "There are no files to process at ${second}"
		exit 1
	fi
	total_images_second=`ls -l ${second} | grep DSC | wc -l`
#	width_second=`${identify} ${main}/${file_second} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
#	height_second=`${identify} ${main}/${file_secodnary} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`

#	file_third=`ls -al ${third}/ | grep DSC | awk '{ print $9 }' | head -n 1`
#	if [[ -z "${file_third}" ]]; then
#		echo "There are no files to process at ${second}"
#		exit 1
#	fi
#	total_images_third=`ls -l ${third} | grep DSC | wc -l`

	#create the output directory
	mkdir -p ${output}

	let total_images=${total}/2
	if [[ "${total_images}" -gt "${total_images_second}" ]]; then
		total_images=${total_images_second}
	fi

	total_counter=1
	final_image=1
	current_image=1
	while [[ "${total_counter}" -lt "${total_images}" ]]; do
		#main scene processing
		section ${main} ${frames} ${current_image} ${final_image}

		#second scene processing
		section ${second} ${frames} ${current_image} ${final_image}

		#third scene processing
		#section ${third} ${frames} ${current_counter} ${final_counter}

		let current_image=${current_image}+${frames}
		let total_counter=${final_image}/2
		echo ${total_counter}" "${final_image}" "${total_images}
	done
}

function check_args(){
	if [[ -z "${output}" || -z "${main}" || -z "${second}" ]]; then
		echo "ERROR: some arguments are empty!"
		exit 1
	fi
}

function version(){
	name=$(basename $0)
	echo -e "${name}: version ${version}"
	exit 0
}

function usage(){
	echo -e "\t./$(basename $0) -m <VALUE> -s <VALUE> -f <VALUE> -o <VALUE>"
	echo -e "\t-m directory where the files for the first scene are"
	echo -e "\t-s directory where the files for the second scene are"
	echo -e "\t-t total number of images to have in the final scene"
	echo -e "\t-f frames to use from each scene before changing to another"
	echo -e "\t-o output directory"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

function main(){
	check_args
	merge
}

while getopts "m:s:t:f:o:phv?" arg; do
	case $arg in
		m)main=${OPTARG}
		;;
		s)second=${OPTARG}
		;;
		t)total=${OPTARG}
		;;
		f)frames=${OPTARG}
		;;
		o)output=${OPTARG}
		;;
		v)version && exit 0
		;;
		?)usage && exit 1
		;;
	esac
done

main
