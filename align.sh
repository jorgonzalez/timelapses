#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to align images in a directory. Uses align_image_stack binary from hugin.
#
#	Version:	0.6
#
#	Modifications:	v0.1; first version.
#			v0.2; changed alegned options to force given order.
#			v0.3; option to use the first image of each block as a base image.
#			v0.4; option to break the images in a rectangular grid for control points.
#			v0.5; option to define and use block processing.
#			v0.6; option to create a copy of the target directory before aligning.
#
#	Future imprv.:	Preview.
#

#Some variables
version=0.6
mogrify=/usr/bin/mogrify-im6
convert=/usr/bin/convert-im6
identify=/usr/bin/identify-im6
align=/usr/bin/align_image_stack

#Check if we have all the needed software
if [[ ! -e ${mogrify} ]] || [[ ! -e ${convert} ]] || [[ ! -e ${identify} ]]; then
        echo "You are missing all or parts of imagemagick package, please install it for your distribution"
        exit 1
fi
if [[ ! -e ${align} ]]; then
	echo "You are missing align_image_stack, part of hugin in debian/ubuntu; please install ir for your distribution"
	exit 1
fi

function rename_images(){
	for JPGFile in `ls -l | grep DSC | awk '{print $9}'`; do
		for alignedFile in `ls -l | grep aligned | head -n 1 | awk '{print $9}'`; do
			mv ${alignedFile} ${JPGFile}
		done;
	done
}

function convert_images(){
	for image in `ls -l | grep tif | awk '{print $9}'`; do
		filename=`echo ${image} | rev | cut -b 5- | rev`
		${convert} -quality 97 ${image} ${filename}.JPG 2>/dev/null
		${convert} ${filename}.JPG -crop +${horizontal}+${vertical} -crop -${horizontal}-${vertical} ${filename}.JPG 2>/dev/null
		${convert} ${filename}.JPG -resize ''${width}'x'${height}'!' ${filename}.JPG 2>/dev/null
	done
	rm *.tif 2>/dev/null
}

function align_images(){
	if [[ ! -z ${copy} ]]; then
		orig_dir_end=`echo ${dir} | rev | cut -b 1-1`
		if [[ "${orig_dir_end}" == / ]]; then
			dir=`echo ${dir} | rev | cut -b 2- | rev`
		fi
		rm -rf ${dir}_aligned
		echo "Copying ${dir}/ to ${dir}_aligned/..."
		cp -a ${dir} ${dir}_aligned
		dir="${dir}_aligned"
	fi

	if [[ -d "${dir}" ]]; then
		if [[ -z "${block}" ]]; then
			block=10
		fi
		if [[ -z "${points}" ]]; then
			points=15
		fi
		if [[ -z "${grid}" ]]; then
			grid=1
		fi

		cd ${dir}
		file=`ls -al | grep DSC | awk '{ print $9 }' | head -n 1`
		width=`${identify} ${file} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
		height=`${identify} ${file} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`
		horizontal=20
		vertical=20

	        total_images=`ls -l | grep DSC | wc -l`
		let counter=${total_images}/${block}
		let counter=${counter}+1
		rm -rf tmp/ aligned/ base/ >/dev/null 2>&1
		mkdir aligned/ tmp/ base/
		cp ${file} base/

		k=1
		let blocks=${total_images}/${block}
		let block_modulus=${total_images}%${block}
		if [[ "${block_modulus}" -ne 0 ]]; then
			let blocks=${blocks}+1
		fi
		for i in `seq 1 ${counter}`; do
			echo -e -n "\rAligning block (${block}) of images ${k}/${blocks}"
			if [[ "${first}" != "no" ]]; then
				cp base/${file} tmp/
			fi

			for j in `ls -l | grep JPG | head -n ${block} | awk '{print $9}'`;
				do mv ${j} tmp/
			done

			cd tmp

			${align} -a aligned_ -g ${grid} -c ${points} -t 2 --use-given-order *.JPG >/dev/null 2>&1
#			${align} -a aligned_ -g ${grid} -c ${points} -t 2 -i -s 1 --use-given-order *.JPG >/dev/null 2>&1
#			${align} -a aligned_ -g ${grid} -c ${points} -t 2 -i -s 1 -x -y --use-given-order *.JPG >/dev/null 2>&1
#			${align} -a aligned_ -g ${grid} -c ${points} -t 1 -x -y --use-given-order *.JPG >/dev/null 2>&1
#			${align} -a aligned_ -g ${grid} -c ${points} -t 1 -d --use-given-order *.JPG >/dev/null 2>&1
#			${align} -a aligned_ -g ${grid} -c ${points} -t 1 --use-given-order *.JPG >/dev/null 2>&1
			if [[ "${i}" -ne 1 && "${first}" != "no" ]]; then
				rm aligned_0000.tif ${file} 2>/dev/null
			fi
			convert_images
			rename_images
			mv *.JPG ../aligned/ >/dev/null 2>&1
			cd ..
			let k=${k}+1

		done
		mv aligned/* ./ >/dev/null 2>&1
		rm base/${file} >/dev/null 2>&1
		rmdir aligned/ tmp/ base/ >/dev/null 2>&1
		echo -e "\nDone!"
	fi
}

function version(){
        name=$(basename $0)
        echo -e "${name}: version ${version}"
        exit 0
}

function usage(){
        echo -e "\t./$(basename $0) -d <VALUE>"
        echo -e "\t-d directory where the files are"
        echo -e "\t-b (OPTIONAL) block number of images to process (default 10)"
	echo -e "\t-p (OPTIONAL) number of control points between images (default 15)"
	echo -e "\t-g (OPTIONAL) grid, break the image into a rectangular grid (default 1)"
	echo -e "\t-n (OPTIONAL) do not use first image as base model"
	echo -e "\t-y {OPTIONAL} copy original into ORIGINA_aligned"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
        align_images
}

while getopts "d:b:p:g:nyhv?" arg; do
        case ${arg} in
		d)dir=${OPTARG}
		;;
		b)block=${OPTARG}
		;;
		p)points=${OPTARG}
		;;
		g)grid=${OPTARG}
		;;
		n)first=no
		;;
		y)copy=y
		;;
                v)version && exit 0
		;;
                ?)usage && exit 1
                ;;
            esac
done

main
