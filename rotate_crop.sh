#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to align rotate and crop batches of images in the same directory.
#
#	Version:	0.4
#
#	Modifications:	v0.1; first version.
#			v0.2; added option to cut pixels from output.
#			v0.3; grouped in pairs pxiel cut.
#			v0.4; hardcoded binaries removed for which.
#
#	Future imprv.:
#

#Some variables
version=0.4
convert=$(which convert-im6)
identify=$(which identify-im6)


#Check if we have all the needed software
if [[ ! -e "${convert}" || ! -e "${identify}" ]]; then
	echo "You are missing all or parts of imagemagick package, please install it for your distribution"
	exit 1
fi

function rotate_crop(){

	file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file}" ]]; then
		echo "There are no files to rotate-crop!"
		exit 1
	fi
	width=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
	height=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`

	if [[ "$preview" == "y" ]]; then
		${convert} -rotate "${rotation}" ${dir}/${file} ${dir}/A_preview.JPG
		${convert} ${dir}/A_preview.JPG -crop +${horizontal}+${vertical} -crop -${horizontal}-${vertical} ${dir}/A_preview.JPG
		${convert} ${dir}/A_preview.JPG -resize ''${width}'x'${height}'!' ${dir}/A_preview.JPG
	else
		rm ${dir}/A_preview.JPG 2>/dev/null
		total_images=`ls -l ${dir} | grep DSC | wc -l`

		j=1
		for i in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
			echo -e -n "\rModifying image ${j}/${total_images}"
			${convert} -rotate "${rotation}" ${dir}/${i} ${dir}/${i}
			${convert} ${dir}/${i} -crop +${horizontal}+${vertical} -crop -${horizontal}-${vertical} ${dir}/${i}
			${convert} ${dir}/${i} -resize ''${width}'x'${height}'!' ${dir}/${i}
			let j=${j}+1
		done
		echo -e "\nDone!"
	fi
}

function version(){
	name=$(basename $0)
	echo -e "${name}: version ${version}"
	exit 0
}

function usage(){
	echo -e "\t./$(basename $0) -d <VALUE> -r <VALUE> -z <VALUE> -t <VALUE>"
	echo -e "\t-d directory where the files are"
	echo -e "\t-r rotate the picture (- is anti-h; + is h)"
	echo -e "\t-z pixels to crop horizontally"
	echo -e "\t-t pixels to crop vertically"
	echo -e "\t-p OPTIONAL (preview) applies the modifications to the first foto to see the result"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

function main(){
        rotate_crop
}

while getopts "d:r:z:t:phv?" arg; do
	case $arg in
		d)dir=${OPTARG}
		;;
		r)rotation=${OPTARG}
		;;
		z)horizontal=${OPTARG}
		;;
		t)vertical=${OPTARG}
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
