#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to compose a batch of images using two directories as source.
#
#	Version:	0.3
#
#	Modifications:	v0.1; first version.
#			v0.2; option chunk: percentage of the first image to take.
#			v0.3; option compose: show whole main scene, then split in half showing both scenes, then show whole secondary scene.
#
#	Future imprv.:	Compose 3 scenes.
#			Transition from 1st scene to 2nd scene using the separation bar.
#

#Some variables
version=0.3

mogrify=/usr/bin/mogrify-im6
convert=/usr/bin/convert-im6
identify=/usr/bin/identify-im6
composite=/usr/bin/composite-im6


#Check if we have all the needed software
if [[ ! -e "${mogrify}" ]] || [[ ! -e "${convert}" || ! -e "${identify}" ]]; then
	echo "You are missing all or parts of imagemagick package, please install it for your distribution"
	exit 1
fi

function split(){
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

	if [[ -z "${bar}" ]]; then
		let bar=${width_main}*2/100
	fi

	file_secondary=`ls -al ${secondary}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file_secondary}" ]]; then
		echo "There are no files to process at ${secondary}"
		exit 1
	fi
	total_images_secondary=`ls -l ${main} | grep DSC | wc -l`
#	width_secondary=`${identify} ${main}/${file_secondary} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
#	height_secondary=`${identify} ${main}/${file_secodnary} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`

	if [[ "${total_images_main}" -ge "${total_images_secondary}" ]]; then
		total_images=${total_images_main}
	else
		total_images=${total_images_secondary}
	fi

	#create the output directory
	mkdir -p ${output}

	let bar_pos=${chunk}*${width_main}/100
	color="green"
	j=1

	if [[ -z "${compose}" ]]; then
		let first_rectangle_total_width=${width_main}-${bar_pos}
		let first_rectangle_pos=${first_rectangle_total_width}/2
		let second_rectangle_pos=${bar_pos}+${first_rectangle_pos}
		let third_rectangle_total_width=${bar_pos}
		let third_rectangle_pos=(${third_rectangle_total_width}/2)
		let fourth_rectangle_pos=${third_rectangle_pos}+${first_rectangle_total_width}

		for i in `ls -al ${main} | grep JPG | awk '{ print $9 }'`; do
                        echo -e -n "\rModifying image ${j}/${total_images}"
			${convert} ${main}/${i} -fill ${color} -stroke ${color} -draw "rectangle 0,0 ${first_rectangle_pos},${height_frame}" -draw "rectangle ${second_rectangle_pos},0 ${width_frame},${height_frame}" ${output}/${i}.m.PNG
			${convert} ${output}/${i}.m.PNG -transparent ${color} ${output}/main.PNG
			${convert} -page -${first_rectangle_pos}+0 ${output}/main.PNG -background none -flatten ${output}/main.PNG
			${convert} ${secondary}/${i} -fill ${color} -stroke ${color} -draw "rectangle 0,0 ${third_rectangle_pos},${height_frame}" -draw "rectangle ${fourth_rectangle_pos},0 ${width_frame},${height_frame}" ${output}/${i}.s.PNG
			${convert} ${output}/${i}.s.PNG -transparent ${color} ${output}/secondary.PNG
			${convert} -page +${third_rectangle_pos}+0 ${output}/secondary.PNG -background none -flatten ${output}/secondary.PNG
			${composite} -compose plus ${output}/main.PNG ${output}/secondary.PNG ${output}/final.PNG
			${convert} ${output}/final.PNG -fill none -stroke black -strokewidth ${bar} -draw "line ${bar_pos},0 ${bar_pos},${width_frame}" ${output}/${i}
			rm ${output}/${i}.m.PNG ${output}/${i}.s.PNG ${output}/main.PNG ${output}/secondary.PNG ${output}/final.PNG
			if [[ "$preview" == "y" ]]; then
				exit 0
			fi
			let j=${j}+1
			if [[ "${j}" -ge "${total_images}" ]]; then
				break
			fi
		done
		echo -e "\nDone!"
	else
		let third=${total_images}/3
		let two_thirds=${third}*2

		for i in `ls -al ${main} | grep JPG | awk '{ print $9 }'`; do
                        echo -e -n "\rModifying image ${j}/${total_images}"
			if [[ "${j}" -le "${third}" ]]; then
				cp ${main}/${i} ${output}/${i}
			elif [[ "${j}" -gt "${third}" && "${j}" -le "${two_thirds}" ]]; then
				${convert} ${main}/${i} -fill ${color} -stroke ${color} -draw "rectangle ${bar_pos},0 ${width_frame},${height_frame}" ${output}/${i}.m.PNG
				${convert} ${output}/${i}.m.PNG -transparent ${color} ${output}/main.PNG
				${convert} ${secondary}/${i} -fill ${color} -stroke ${color} -draw "rectangle 0,0 ${bar_pos},${height_frame}" ${output}/${i}.s.PNG
				${convert} ${output}/${i}.s.PNG -transparent ${color} ${output}/secondary.PNG
				${composite} -compose plus ${output}/main.PNG ${output}/secondary.PNG ${output}/final.PNG
				${convert} ${output}/final.PNG -fill none -stroke black -strokewidth ${bar} -draw "line ${bar_pos},0 ${bar_pos},${width_frame}" ${output}/${i}
				rm ${output}/${i}.m.PNG ${output}/${i}.s.PNG ${output}/main.PNG ${output}/secondary.PNG ${output}/final.PNG
			else
				cp ${secondary}/${i} ${output}/${i}
			fi
			let j=${j}+1
		done
		echo -e "\nDone!"
	fi
}

function check_args(){
	if [[ -z "${chunk}" || -z "${output}" || -z "${main}" || -z "${secondary}" ]]; then
		echo "ERROR: some arguments are empty!"
		exit 1
	fi
}

function version(){
	name=$(basename $0)
	echo -e "$name: version $version"
	exit 0
}

function usage(){
	echo -e "\t./$(basename $0) -m <VALUE> -s <VALUE> -b <VALUE> -t <VALUE> -o <VALUE>"
	echo -e "\t-m directory where the files for the main scene are"
	echo -e "\t-s directory where the files for the secondary scene are"
	echo -e "\t-b pixels of the separation bar"
	echo -e "\t-c chunk, percentage of the first image to take"
	echo -e "\t-o output directory"
	echo -e "\t-e OPTIONAL compose: show whole main scene, then split in half showing both scenes, then show whole secondary scene"
	echo -e "\t-p OPTIONAL (preview) applies the modifications to the first foto to see the result"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

function main(){
	check_args
	split
}

while getopts "m:s:bc:o:ephv?" arg; do
	case $arg in
		m)main=${OPTARG}
		;;
		s)secondary=${OPTARG}
		;;
		b)bar=${OPTARG}
		;;
		c)chunk=${OPTARG}
		;;
		o)output=${OPTARG}
		;;
		e)compose=yes
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
