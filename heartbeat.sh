#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to create a heartbeat effect using the base image and zooming on it.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#
#	Future imprv.:	
#

#Some variables
version=0.1
convert=$(which convert-im6)
identify=$(which identify-im6)
mogrify=$(which mogrify-im6)

#Check if we have all the needed software
if [[ ! -e ${convert} ]] || [[ ! -e ${identify} ]] || [[ ! -e ${mogrify} ]]; then
	echo "You are missing all or parts of imagemagick package, please install it for your distribution"
	exit 1
fi

function stillness(){
#	local randomness=$(seq 5 20 | shuf -n 1)
	local randomness=$(seq 10 30 | shuf -n 1)
	echo ${randomness}
}

function heartbeatness(){
#	local randomness=$(seq 3 10 | shuf -n 1)
	local randomness=$(seq 3 9 | shuf -n 1)
	echo ${randomness}
}

function zoom(){
#	local randomness=$(seq 3 10 | shuf -n 1)
	local randomness=$(seq 20 40 | shuf -n 1)
	echo ${randomness}
}

function heartbeat(){
	file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file}" ]]; then
		echo "There are no files to process at ${main}"
		exit 1
	fi
	if [[ -z "${zoom_factor}" && "${zoom_random}" != "YES" ]]; then
		zoom_factor=1.01
	fi
	total_images=`ls -l ${dir} | grep DSC | wc -l`

	still_rnd=$(stillness)
	heartbeat_rnd=$(heartbeatness)

	st=1
	sh=1
	j=1
	for i in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
		echo -e -n "\rModifying image ${j}/${total_images}"

		if [[ "${st}" -lt "${still_rnd}" ]]; then
			let st=${st}+1
		elif [[ "${sh}" -lt "${heartbeat_rnd}" ]]; then
			let sh=${sh}+1
                        ${convert} ${dir}/${i} -alpha set -channel A -evaluate subtract 20% ${dir}/mask.PNG

			if [[ "${zoom_random}" == "YES" ]]; then
				zoom_factor=$(zoom)
				if [[ "${zoom_factor}" -lt 10 ]]; then
					zoom_factor=1.00${zoom_factor}
				else
					zoom_factor=1.0${zoom_factor}
				fi
			fi
			${mogrify} ${mod_ops} -distort SRT ${zoom_factor},0 ${dir}/mask.PNG
       	                ${convert} ${dir}/${i} ${dir}/mask.PNG -flatten ${dir}/${i}
		elif [[ "${st}" -ge "${still_rnd}" && "${sh}" -ge "${heartbeat_rnd}" ]]; then
			still_rnd=$(stillness)
			heartbeat_rnd=$(heartbeatness)
			st=1
			sh=1
		fi
		let j=${j}+1
	done
	rm ${dir}/mask.PNG
	echo -e "\nDone!"
}

function check_args(){
	if [[ -z "${dir}" ]]; then
		echo "ERROR: directory is empty!"
		exit 1
	fi
}

function version(){
	name=$(basename $0)
	echo -e "${name}: version ${version}"
	exit 0
}

function usage(){
	echo -e "\t./$(basename $0) -d <VALUE> -z <VALUE> -r"
	echo -e "\t-d directory where the files are"
	echo -e "\t-z Zoom factor"
	echo -e "\t-r Random zoom factor"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

function main(){
#	check_args
	heartbeat
}

while getopts "d:z:rhv?" arg; do
	case ${arg} in
		d)dir=${OPTARG}
		;;
		z)zoom_factor=${OPTARG}
		;;
		r)zoom_random=YES
		;;
		v)version && exit 0
		;;
		?)usage && exit 1
		;;
	esac
done

main
