#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to shake an image using the base image and moving it to the sides using transparency.
#
#	Version:	0.2
#
#	Modifications:	v0.1; first version.
#			v0.2; option for total shakeness.
#			v0.3; hardcoded binaries removed for which
#
#	Future imprv.:	
#

#Some variables
version=0.3
convert=$(which convert-im6)
identify=$(which identify-im6)


#Check if we have all the needed software
if [[ ! -e ${convert} ]] || [[ ! -e ${identify} ]]; then
	echo "You are missing all or parts of imagemagick package, please install it for your distribution"
	exit 1
fi

function stillness(){
#	local randomness=$(seq 5 20 | shuf -n 1)
	local randomness=$(seq 10 30 | shuf -n 1)
	echo ${randomness}
}

function shakeness(){
#	local randomness=$(seq 3 10 | shuf -n 1)
	local randomness=$(seq 3 9 | shuf -n 1)
	echo ${randomness}
}

function shake(){
	file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file}" ]]; then
		echo "There are no files to process at ${main}"
		exit 1
	fi
	if [[ -z "${shakeness}" ]]; then
		shakeness=4
	fi
	total_images=`ls -l ${dir} | grep DSC | wc -l`
	width=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
	height=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`
	let width_shake_perc=${width}*${shakeness}/100
	let height_shake_perc=${height}*${shakeness}/100

	still_rnd=$(stillness)
	shake_rnd=$(shakeness)

	st=1
	sh=1
	j=1
	for i in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
		echo -e -n "\rModifying image ${j}/${total_images}"

		if [[ "${st}" -lt "${still_rnd}" ]]; then
			let st=${st}+1
		elif [[ "${sh}" -lt "${shake_rnd}" ]]; then
			let sh=${sh}+1
			width_rnd=$(seq -${width_shake_perc} ${width_shake_perc} | shuf -n 1)
			height_rnd=$(seq -${height_shake_perc} ${height_shake_perc} | shuf -n 1)
			width_sign=`echo ${width_rnd} | cut -b 1-1`
			height_sign=`echo ${height_rnd} | cut -b 1-1`
			if [[ "${width_sign}" != "-" ]]; then
				width_rnd="+${width_rnd}"
			fi
			if [[ "${height_sign}" != "-" ]]; then
				height_rnd="+${height_rnd}"
			fi
			if [[ "${horizontal}" == "yes" ]]; then
				height_rnd="+0"
			fi
			if [[ "${total}" == "yes" ]]; then
				width_rnd=`echo ${width_rnd} | cut -b 2-3`
				height_rnd=`echo ${height_rnd} | cut -b 2-3`
				${convert} ${dir}/${i} -alpha set -channel A -evaluate subtract 70% ${dir}/mask.PNG
				${convert} ${dir}/${i} -page +${width_rnd}+${height_rnd} ${dir}/mask.PNG -flatten ${dir}/${i}
				${convert} ${dir}/${i} -page -${width_rnd}-${height_rnd} ${dir}/mask.PNG -flatten ${dir}/${i}
			else
	                        ${convert} ${dir}/${i} -alpha set -channel A -evaluate subtract 70% ${dir}/mask.PNG
        	                ${convert} ${dir}/${i} -page ${width_rnd}${height_rnd} ${dir}/mask.PNG -flatten ${dir}/${i}
			fi

		elif [[ "${st}" -ge "${still_rnd}" && "${sh}" -ge "${shake_rnd}" ]]; then
			still_rnd=$(stillness)
			shake_rnd=$(shakeness)
			st=1
			sh=1
		fi

#		this does not make sense with total randomness
#		if [[ "$preview" == "y" ]]; then
#			exit 0
#		fi
		let j=${j}+1

	done
	rm ${dir}/mask.PNG
	echo -e "\nDone!"
}

function check_args(){
	if [[ -z "${dir}" ]]; then
		echo "ERROR: directory is empty!"
		exit 1
	elif [[ ! -z "${total}" && ! -z "${horizontal}" ]]; then
		echo "ERROR: you're using horizontal and total shake at the same time!"
		exit 1
	elif [[ -z "${total}" && -z "${horizontal}" ]]; then
		echo "ERROR: use either horizontal (-z) or total (-t) shake!"
		exit 1
	fi
}

function version(){
	name=$(basename $0)
	echo -e "${name}: version ${version}"
	exit 0
}

function usage(){
	echo -e "\t./$(basename $0) -d <VALUE> -z -t -b -s <VALUE> -p"
	echo -e "\t-d directory where the files are"
	echo -e "\t-z horizontal shake"
	echo -e "\t-t total shake"
	echo -e "\t-s OPTIONAL: shakeness percentage"
	echo -e "\t-p OPTIONAL: preview"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

function main(){
#	check_args
	shake
}

while getopts "d:zts:phv?" arg; do
	case ${arg} in
		d)dir=${OPTARG}
		;;
		z)horizontal=yes
		;;
		b)total=yes
		;;
		s)shakeness=${OPTARG}
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
