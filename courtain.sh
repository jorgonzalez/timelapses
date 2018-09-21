#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to do a courtain transition between two sets of images.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#
#	Future imprv.:	Preview.
#			RTL, UTD, DTU.
#			Image size verification between folders.

#Some variables
version=0.1
identify=$(which identify-im6)
convert=$(which convert-im6)
composite=$(which composite-im6)
mogrify=$(which mogrify-im6)
bar=0
transition_images=10

#Check if we have all the needed software
if [[ ! -e "${composite}" ]] || [[ ! -e "${convert}" || ! -e "${identify}" ]]; then
	echo "You are missing all or parts of imagemagick package, please install it for your distribution"
	exit 1
fi

function courtain(){

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

	file_second=`ls -al ${second}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file_second}" ]]; then
		echo "There are no files to process at ${second}"
		exit 1
	fi
	total_images_second=`ls -l ${second} | grep DSC | wc -l`

	let total_images=${total_images_main}+${total_images_second}-${transition_images}

	#create the output directory
	mkdir -p ${output}

	color="black"

	#first create the output directory
	mkdir -p ${output}

	#copy as many images as needed, from main to output, to leave only those to work on
	photonum=1
	bar_pos_n=1
	let main_photos_to_copy=${total_images_main}-${transition_images}
	for image in `ls -al ${main} | grep JPG | awk '{ print $9 }'`; do
		if [[ ${photonum} -lt ${main_photos_to_copy} ]]; then
			echo -e -n "\r\bCopying image ${photonum}/${total_images}"
			cp ${main}/${image} ${output}/${image}
		else
			echo -e -n "\r\bModifying image ${photonum}/${total_images}"
			#create a canvas
			${convert} -size ${width_frame}x${height_frame} xc:none ${output}/BASE.PNG

			#calculate where the bar goes
			bar_pos=`echo "scale=0; (${width_frame}/${transition_images})*${bar_pos_n}" | bc`

			#add the chunk of main
			let pos_x=${width_frame}-${bar_pos}
			${convert} ${main}/${image} -crop ${pos_x}x${height_frame}+${bar_pos}+0 ${output}/main.PNG

			#add the chunk of second folder
			${convert} ${second}/DSC_$(printf "%04d" ${bar_pos_n}).JPG -crop ${bar_pos}x${height_frame}+0+0 ${output}/second.PNG

			#print the separating bar, if any
			#${convert} ${output}/BASE.PNG -fill ${color} -stroke ${color} -draw "rectangle 0,${vert_bar_pos_1} ${horiz_bar_pos_2},${vert_bar_pos_2}" -draw "rectangle ${horiz_bar_pos_1},0 ${horiz_bar_pos_2},${height_frame}" ${output}/BASE.PNG

			#stitch the images
			${composite} -geometry +0+0 ${output}/second.PNG ${output}/BASE.PNG ${output}/BASE1.PNG
			${composite} -geometry +${bar_pos}+0 ${output}/main.PNG ${output}/BASE1.PNG ${output}/${image}
	
			let bar_pos_n=${bar_pos_n}+1

sleep 2
		fi
		let photonum=${photonum}+1
	done

	#copy as many images as needed, from second folder to output
	let second_photos_to_copy=${total_images_second}-${transition_images}
	for image in `seq ${transition_images} ${second_photos_to_copy}`; do
		echo -e -n "\r\bCopying image ${photonum}/${total_images}"
		cp ${second}/DSC_$(printf "%04d" ${image}).JPG ${output}/DSC_${photonum}.JPG
		let photonum=${photonum}+1
	done

	#cleanup intermediate files
	rm ${output}/*.PNG

	echo -e "\nDone!"
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
	echo -e "\t./$(basename $0) -m <VALUE> -s <VALUE> -b <VALUE> -o <VALUE>"
	echo -e "\t-m directory where the files for the main scene are"
	echo -e "\t-s directory where the files for the second scene are"
	echo -e "\t-t transition betwen scenes (in frames; default 10)"
	echo -e "\t-b OPTIONAL width (in pixels) of the separation bar"
	echo -e "\t-o output directory"
#	echo -e "\t-p OPTIONAL (preview) applies the modifications to the first foto to see the result"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

function main(){
	check_args
	courtain
}

while getopts "m:s:b:o:t:aphv?" arg; do
	case $arg in
		m)main=${OPTARG}
		;;
		s)second=${OPTARG}
		;;
		t)transition_images=${OPTARG}
		;;
		b)bar=${OPTARG}
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
