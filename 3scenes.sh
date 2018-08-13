#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to compose a batch of images using three directories as a source.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#
#	Future imprv.:	Preview.
#			Option to have the secondaries scenes on the right.
#

#Some variables
version=0.1
identify=$(which identify-im6)
convert=$(which convert-im6)
composite=$(which composite-im6)
mogrify=$(which mogrify-im6)

#Check if we have all the needed software
if [[ ! -e "${composite}" ]] || [[ ! -e "${convert}" || ! -e "${identify}" ]]; then
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
		let bar=${height_main}*2/100
		#The math is right but if I don't substract 1 the rectangles do not end up as expected!
		let bar=${bar}-1
	fi

	file_second=`ls -al ${second}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file_second}" ]]; then
		echo "There are no files to process at ${second}"
		exit 1
	fi
	total_images_second=`ls -l ${second} | grep DSC | wc -l`

	file_third=`ls -al ${third}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file_third}" ]]; then
		echo "There are no files to process at ${third}"
		exit 1
	fi
	total_images_third=`ls -l ${third} | grep DSC | wc -l`

	if [[ "${total_images_main}" -ge "${total_images_second}" ]] && [[ "${total_images_second}" -ge "${total_images_third}" ]]; then
		total_images=${total_images_third}
		folder=${third}
	elif [[ "${total_images_main}" -ge "${total_images_second}" ]] && [[ "${total_images_main}" -le "${total_images_third}" ]]; then
		total_images=${total_images_second}
		folder=${second}
	else
		total_images=${total_images_main}
		folder=${main}
	fi

	#create the output directory
	mkdir -p ${output}

	color="black"

	#first create the base image
	mkdir -p ${output}
	${convert} -size ${width_main}x${height_main} xc:none ${output}/BASE.PNG

	#create the separating bars
	main_scene_width=`echo "scale=2; (${width_main}*${width}/100)-${bar}" | bc`
	main_scene_width=`echo ${main_scene_width} | awk -F"." '{print $1}'`
	main_scene_height=${height_main}

	secondaries_scene_width=`echo "scale=0; ${width_frame}-${main_scene_width}-${bar}" | bc`
	secondaries_scene_height=`echo "scale=0; (${height_frame}/2)-(${bar}/2)" | bc`

	#find the positions of the separating rectangles
	let horiz_bar_pos_1=${secondaries_scene_width}
	let horiz_bar_pos_2=${secondaries_scene_width}+${bar}
	vert_bar_pos_1=`echo "scale=0; (${height_frame}/2)+(${bar}/2)" | bc`
	let vert_bar_pos_2=${vert_bar_pos_1}-${bar}

	#print the separating bars over the base image
	${convert} ${output}/BASE.PNG -fill ${color} -stroke ${color} -draw "rectangle 0,${vert_bar_pos_1} ${horiz_bar_pos_2},${vert_bar_pos_2}" -draw "rectangle ${horiz_bar_pos_1},0 ${horiz_bar_pos_2},${height_frame}" ${output}/BASE.PNG

	#find out the size of each scene
	# ${main_scene_width}
	#ugly code for rounding the proportions of the image
	orig_prop=`echo "${width_main}/${height_main}" | bc -l | cut -c -6`

	#scene widths
	#main_scene_width; main_scene_height
	#secondaries_scene_width; secondaries_scene_height

	j=1;
	for i in `ls -al ${folder} | grep JPG | awk '{ print $9 }'`; do
		echo -e -n "\rModifying image ${j}/${total_images}"

		#take the correspondant portion of the main scene
		let bar_pos_1=`echo "scale=0; (${width_frame}-${main_scene_width})/2" | bc`
		${convert} ${main}/${i} -crop ${main_scene_width}x${main_scene_height}+${bar_pos_1}+0 ${output}/main.PNG

		#resize second and third scenes to appropriate sizes
		secondaries_scene_width_by_prop=`echo "scale=0; (${secondaries_scene_height}*${orig_prop})/1" | bc`
		mod_ops="-resize ${secondaries_scene_width_by_prop}"x"${secondaries_scene_height}!"
		cp ${second}/${i} ${output}/${i}.second.PNG
		cp ${third}/${i} ${output}/${i}.third.PNG
		${mogrify} ${mod_ops} ${output}/${i}.second.PNG ${output}/${i}.third.PNG
		let bar_pos_1=`echo "(${width_frame}-${main_scene_width})/2" | bc`

		#take the correspondant portion of the secondary scenes
		bar_pos_1=`echo "scale=0; (${secondaries_scene_width_by_prop}-${secondaries_scene_width})/2" | bc`
		${convert} ${output}/${i}.second.PNG -crop ${secondaries_scene_width}x${secondaries_scene_height}+${bar_pos_1}+0 ${output}/second.PNG
		${convert} ${output}/${i}.third.PNG  -crop ${secondaries_scene_width}x${secondaries_scene_height}+${bar_pos_1}+0 ${output}/third.PNG

		#calculate the coordinates for the stiches
		let bar_pos_3=${secondaries_scene_height}+${bar}
		let bar_pos_4=${secondaries_scene_width}+${bar}

		#stitch the three images together
		${composite} -geometry +0+0 ${output}/second.PNG ${output}/BASE.PNG ${output}/BASE1.PNG
		${composite} -geometry +0+${bar_pos_3} ${output}/third.PNG ${output}/BASE1.PNG ${output}/BASE2.PNG
		${composite} -geometry +${bar_pos_4}+0 ${output}/main.PNG ${output}/BASE2.PNG ${output}/${i}

		let j=${j}+1
	done
	rm ${output}/*.PNG

	echo -e "\nDone!"
}

function check_args(){
	if [[ -z "${width}" || -z "${output}" || -z "${main}" || -z "${second}" || -z "${third}" ]]; then
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
	echo -e "\t./$(basename $0) -m <VALUE> -s <VALUE> -t <VALUE> -b <VALUE> -w <VALUE> -o <VALUE>"
	echo -e "\t-m directory where the files for the main scene are"
	echo -e "\t-s directory where the files for the second scene are"
	echo -e "\t-t directory where the files for the third scene are"
	echo -e "\t-w width of the main scene (in percentage)"
	echo -e "\t-o output directory"
	echo -e "\t-b OPTIONAL pixels of the separation bar"
#	echo -e "\t-p OPTIONAL (preview) applies the modifications to the first foto to see the result"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

function main(){
	check_args
	split
}

while getopts "m:s:t:bw:o:aphv?" arg; do
	case $arg in
		m)main=${OPTARG}
		;;
		s)second=${OPTARG}
		;;
		t)third=${OPTARG}
		;;
		b)bar=${OPTARG}
		;;
		w)width=${OPTARG}
		;;
		o)output=${OPTARG}
		;;
#		p)preview=y
#		;;
		v)version && exit 0
		;;
		?)usage && exit 1
		;;
	esac
done

main
