#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to make a composition out of a base (static) image and a set of background images.
#
#	Version:	0.2
#
#	Modifications:	v0.1; first version.
#			v0.2; option to reverse background images.
#
#	Future imprv.:	Preview.
#

#Some variables
version=0.2
mogrify=/usr/bin/mogrify-im6
convert=/usr/bin/convert-im6
composite=/usr/bin/composite-im6
identify=/usr/bin/identify-im6

#Check if we have all the needed software
if [[ ! -e ${mogrify} ]] || [[ ! -e ${convert} ]] || [[ ! -e ${identify} ]] || [[ ! -e ${composite} ]]; then
        echo "You are missing all or parts of imagemagick package, please install it for your distribution"
        exit 1
fi

function translate(){
	source=${1}
	source=`echo ${source} | sed 's/^0*//'`
	let total=${2}+1
	let destination_image=${total}-${source}
	destination_image=`printf "%04d" ${destination_image}`
	return ${destination_image}
}

function compose(){
	if [[ -d "${background_dir}" && -e "${source_image}" ]]; then
		mkdir -p ${dir}
		if [[ "${reverse}" != "yes" ]]; then
			for background_image in `ls -l ${background_dir} | awk '{print $9}'`; do
				${composite} ${source_image} ${background_dir}/${background_image} ${dir}/${background_image}
			done
		else
			total_images=`ls -l ${background_dir} | grep DSC | wc -l`
			j=1
			for background_image in $(seq -f "%04g" ${total_images} -1 1); do
				echo -e -n "\rCreating image ${j}/${total_images}"
				translate ${background_image} ${total_images}
				${composite} ${source_image} ${background_dir}/DSC_${background_image}.JPG ${dir}/DSC_${destination_image}.JPG
				let j=${j}+1
			done
		fi
	fi
}

function version(){
        name=$(basename $0)
        echo -e "${name}: version ${version}"
        exit 0
}

function usage(){
        echo -e "\t./$(basename $0) -d <VALUE>"
        echo -e "\t-s source image (foreground image)"
        echo -e "\t-b directory with the background images"
	echo -e "\t-d output directory"
	echo -e "\t-r (OPTIONAL) reverse order of background images"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
        compose
}

while getopts "s:b:d:rhv?" arg; do
        case ${arg} in
		s)source_image=${OPTARG}
		;;
		b)background_dir=${OPTARG}
		;;
		d)dir=${OPTARG}
		;;
		r)reverse=yes
		;;
                v)version && exit 0
		;;
                ?)usage && exit 1
                ;;
            esac
done

main
