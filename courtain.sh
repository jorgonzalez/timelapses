#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to do a courtain transition between two sets of images.
#
#	Version:	0.4
#
#	Modifications:	v0.1; first version.
#			v0.2; right-to-left.
#			v0.3; Image size verification between folders.
#			v0.4; up-to-down, down-to-up.
#
#	Future imprv.:	Preview.
#			Separation bar.
#

#Some variables
version=0.4
identify=$(which identify-im6)
convert=$(which convert-im6)
composite=$(which composite-im6)
mogrify=$(which mogrify-im6)
bar=0
transition_images=10
direction="ltr"

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

	file_second=`ls -al ${second}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file_second}" ]]; then
		echo "There are no files to process at ${second}"
		exit 1
	fi
	total_images_second=`ls -l ${second} | grep DSC | wc -l`
	width_second=`${identify} ${main}/${file_main} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
	height_second=`${identify} ${main}/${file_main} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`

	if [[ ${width_main} -gt ${width_second} && ${height_main} -ge ${height_second} ]]; then
		width_frame=${width_second}
		height_frame=${height_main}
#		This alters the original files, do we want this?
#		mod_ops="${mod_ops} -resize ${width_frame}"x"${height_frame}!"
#		j=1
#		for image in `ls -al ${main} | grep DSC | awk '{ print $9 }'`; do
#			echo -e -n "\r\bModifying image ${j}/${total_images_main} from ${main} to match ${second}"
#			${mogrify} ${mod_ops} ${main}/${image}
#			let j=${j}+1
#		done
	elif [[ ${width_main} -lt ${width_second} && ${height_main} -le ${height_second} ]]; then
		width_frame=${width_main}
		height_frame=${height_main}
#		This alters the original files, do we want this?
#		mod_ops="${mod_ops} -resize ${width_frame}"x"${height_frame}!"
#		j=1
#		for image in `ls -al ${second} | grep DSC | awk '{ print $9 }'`; do
#			echo -e -n "\r\bResizing image ${j}/${total_images_second} from ${second} to match ${main}"
#			${mogrify} ${mod_ops} ${second}/${image}
#			let j=${j}+1
#		done
	else
		width_frame=${width_main}
		height_frame=${height_main}
		echo -e "Sets have the same image size, no need to resize"
	fi


	let total_images=${total_images_main}+${total_images_second}-${transition_images}

	#create the output directory
	mkdir -p ${output}

	color="black"

	#first create the output directory
	mkdir -p ${output}

	#copy as many images as needed, from main to output, to leave only those to work on
	photonum=1
	image_helper=1
	if [[ "${direction}" == "ltr" || "${direction}" == "utd" ]]; then
		bar_pos_n=1
	elif [[ "${direction}" == "rtl" || "${direction}" == "dtu" ]]; then
		let bar_pos_n=${transition_images}
	else
		echo "ERROR: direction ${direction} is not one of 'ltr', 'rtl', 'utd', 'dtu'."
		exit 1
	fi
	let main_photos_to_copy=${total_images_main}-${transition_images}

	#create a canvas
	${convert} -size ${width_frame}x${height_frame} xc:none ${output}/BASE.PNG

	for image in `ls -al ${main} | grep JPG | awk '{ print $9 }'`; do
		if [[ ${photonum} -lt ${main_photos_to_copy} ]]; then
			echo -e -n "\r\bCopying image ${photonum}/${total_images}"
			cp ${main}/${image} ${output}/${image}
		else
			echo -e -n "\r\bModifying image ${photonum}/${total_images}"

			#calculate where the bar goes
			if [[ "${direction}" == "ltr" ]]; then
				bar_pos=`echo "scale=0; (${width_frame}/${transition_images})*${bar_pos_n}" | bc`

				#add the chunk of main
				let pos=${width_frame}-${bar_pos}
				${convert} ${main}/${image} -crop ${pos}x${height_frame}+${bar_pos}+0 ${output}/main.PNG

				#add the chunk of second folder
				${convert} ${second}/DSC_$(printf "%04d" ${image_helper}).JPG -crop ${bar_pos}x${height_frame}+0+0 ${output}/second.PNG

				#print the separating bar, if any
				#${convert} ${output}/BASE.PNG -fill ${color} -stroke ${color} -draw "rectangle 0,${vert_bar_pos_1} ${horiz_bar_pos_2},${vert_bar_pos_2}" -draw "rectangle ${horiz_bar_pos_1},0 ${horiz_bar_pos_2},${height_frame}" ${output}/BASE.PNG

				#stitch the images
				${composite} -geometry +0+0 ${output}/second.PNG ${output}/BASE.PNG ${output}/BASE1.PNG
				${composite} -geometry +${bar_pos}+0 ${output}/main.PNG ${output}/BASE1.PNG ${output}/${image}

				let bar_pos_n=${bar_pos_n}+1
			elif [[ "${direction}" == "rtl" ]]; then
				bar_pos=`echo "scale=0; (${width_frame}/${transition_images})*${bar_pos_n}" | bc`

				#add the chunk of main
				let pos=${width_frame}-${bar_pos}
				${convert} ${second}/DSC_$(printf "%04d" ${image_helper}).JPG -crop ${pos}x${height_frame}+${bar_pos}+0 ${output}/main.PNG

				#add the chunk of second folder
				${convert} ${main}/${image} -crop ${bar_pos}x${height_frame}+0+0 ${output}/second.PNG

				#print the separating bar, if any
				#${convert} ${output}/BASE.PNG -fill ${color} -stroke ${color} -draw "rectangle 0,${vert_bar_pos_1} ${horiz_bar_pos_2},${vert_bar_pos_2}" -draw "rectangle ${horiz_bar_pos_1},0 ${horiz_bar_pos_2},${height_frame}" ${output}/BASE.PNG

				#stitch the images
				${composite} -geometry +0+0 ${output}/second.PNG ${output}/BASE.PNG ${output}/BASE1.PNG
				${composite} -geometry +${bar_pos}+0 ${output}/main.PNG ${output}/BASE1.PNG ${output}/${image}

				let bar_pos_n=${bar_pos_n}-1
                        elif [[ "${direction}" == "utd" ]]; then
				bar_pos=`echo "scale=0; (${height_frame}/${transition_images})*${bar_pos_n}" | bc`

				#add the chunk of main
				let pos=${height_frame}-${bar_pos}
				${convert} ${main}/${image} -crop ${width_frame}x${pos}+0+${bar_pos} ${output}/main.PNG

				#add the chunk of second folder
				${convert} ${second}/DSC_$(printf "%04d" ${image_helper}).JPG -crop ${width_frame}x${bar_pos}+0+0 ${output}/second.PNG

				#print the separating bar, if any
				#${convert} ${output}/BASE.PNG -fill ${color} -stroke ${color} -draw "rectangle 0,${vert_bar_pos_1} ${horiz_bar_pos_2},${vert_bar_pos_2}" -draw "rectangle ${horiz_bar_pos_1},0 ${horiz_bar_pos_2},${height_frame}" ${output}/BASE.PNG

				#stitch the images
				${composite} -geometry +0+0 ${output}/second.PNG ${output}/BASE.PNG ${output}/BASE1.PNG
				${composite} -geometry +0+${bar_pos} ${output}/main.PNG ${output}/BASE1.PNG ${output}/${image}

				let bar_pos_n=${bar_pos_n}+1
                        elif [[ "${direction}" == "dtu" ]]; then
				### FIXME
				bar_pos=`echo "scale=0; (${height_frame}/${transition_images})*${bar_pos_n}" | bc`

				#add the chunk of main
				let pos=${height_frame}-${bar_pos}
				${convert} ${second}/DSC_$(printf "%04d" ${image_helper}).JPG -crop ${width_frame}x${pos}+0+${bar_pos} ${output}/main.PNG

				#add the chunk of second folder
				${convert} ${main}/${image} -crop ${width_frame}x${bar_pos}+0+0 ${output}/second.PNG

				#print the separating bar, if any
				#${convert} ${output}/BASE.PNG -fill ${color} -stroke ${color} -draw "rectangle 0,${vert_bar_pos_1} ${horiz_bar_pos_2},${vert_bar_pos_2}" -draw "rectangle ${horiz_bar_pos_1},0 ${horiz_bar_pos_2},${height_frame}" ${output}/BASE.PNG

				#stitch the images
				${composite} -geometry +0+0 ${output}/second.PNG ${output}/BASE.PNG ${output}/BASE1.PNG
				${composite} -geometry +0+${bar_pos} ${output}/main.PNG ${output}/BASE1.PNG ${output}/${image}

				let bar_pos_n=${bar_pos_n}-1
			fi
		fi
		let photonum=${photonum}+1
		let image_helper=${image_helper}+1
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
	echo -e "\t-i transition images betwen scenes (in frames; default 10)"
	echo -e "\t-t OPTIONAL direction of the bars ltr, rtl, utd, dtu (default left-to-right)"
#	echo -e "\t-b OPTIONAL width (in pixels) of the separation bar"
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

while getopts "m:s:b:o:i:t:aphv?" arg; do
	case $arg in
		m)main=${OPTARG}
		;;
		s)second=${OPTARG}
		;;
		t)direction=${OPTARG}
		;;
		i)transition_images=${OPTARG}
		;;
#		b)bar=${OPTARG}
#		;;
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
