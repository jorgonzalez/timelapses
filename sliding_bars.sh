#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to fade-in fade-out a video using bars of adjustable size that dissapear/appear.
#
#	Version:	0.4
#
#	Modifications:	v0.1; first version.
#			v0.2; check that input/output dirs are different.
#			v0.3; bar direction left-to-right and right-to-left.
#			v0.4; fade out.
#
#
#	Future imprv.:	preview; better check of width/bar_numer.
#

#Some variables
version=0.4
identify=$(which identify-im6)
convert=$(which convert-im6)
composite=$(which composite-im6)
bar_number=16
fps=4
fade="in"
direction="ltr"

#Check if we have all the needed software
if [[ ! -e "${composite}" ]] || [[ ! -e "${convert}" || ! -e "${identify}" ]]; then
	echo "You are missing all or parts of imagemagick package, please install it for your distribution"
	exit 1
fi

function merge_bars(){
	echo -e "\nMerging the bars into single images..."
	#soooo many counters
	#for sure this should be easier and more elegant
	rest=1
	count=1
	final=1
	k=1

	process=${bar_number}
	total_bars_processed=0
	while [[ "${process}" -gt 0 ]]; do
		let total_bars_processed=${total_bars_processed}+${process}*${fps}
		let process=${process}-1
	done

	posa=1
	posb=${total_bars_processed}
	sign="+"
	j=1
	processing_bars=${bar_number}
	for i in `seq ${posa} ${sign}1 ${posb}`; do
		images="${images} ${output}/bar_${j}_${k}.PNG"
		let j=${j}${sign}1
		k=1
		if [[ "${j}" -gt "${bar_number}" ]]; then
			j=${rest}
			let count=${count}+1
			k=${count}
			if [[ "${k}" -gt "${fps}" ]]; then
				k=1
				count=1
				let rest=${rest}+1
				j=${rest}
			fi
		${convert} ${output}/base.PNG -page +0+0 ${images} -background none -flatten ${output}/bar_${final}.PNG
		let final=${final}+1
		images=""
		fi
	done
}

function slide_bars(){

	file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file}" ]]; then
		echo "There are no files to create the sliding bars!"
		exit 1
	fi
	width=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
	height=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`

	total_images=`ls -l ${dir} | grep DSC | wc -l`

	#delete and create the output directory
	rm -rf ${output} 2>/dev/null
	mkdir -p ${output}

	#create the base transparent image
	${convert} -size ${width}x${height} xc:none ${output}/base.PNG

	#create the bars
	#bar color
	color=black
	let bar_width=${width}/${bar_number}
	if [[ "${direction}" == "ltr" ]]; then
		xpos1=0
		xpos2=${bar_width}
		sign="+"
	elif [[ "${direction}" == "rtl" ]]; then
		let xpos1=${width}
		xpos2=${bar_width}
		xpos2=0
		sign="-"
	fi
	i=0
	for i in `seq 1 ${bar_number}`; do
		echo -e -n "\rCreating base image ${i}/${bar_number}"
		${convert} ${output}/base.PNG -fill ${color} -stroke ${color} -draw "rectangle ${xpos1},0 ${xpos2},${height}" ${output}/bar_tmp_${i}.PNG
		let xpos1=${xpos1}${sign}${bar_width}
		let xpos2=${xpos2}${sign}${bar_width}
		let i=${i}+1
	done

	echo ""

	#create as many bars as needed per fps and bar_number, and apply transparency if necessary
	perc=`echo "100/(${fps}-1)" | bc`
	for i in `seq 1 ${bar_number}`; do
		echo -e -n "\rCreating bar image ${i}/${bar_number}"
		if [[ "${transparency}" == "yes" ]]; then
			sign="+"
			curr_perc=0
		fi
		for j in `seq 1 ${fps}`; do
			if [[ "${transparency}" == "yes" ]]; then
				${convert} ${output}/bar_tmp_${i}.PNG -alpha set -channel A -evaluate subtract ${curr_perc}% ${output}/bar_${i}_${j}.PNG
				let curr_perc=${curr_perc}${sign}${perc}
			else
				cp ${output}/bar_tmp_${i}.PNG ${output}/bar_${i}_${j}.PNG
			fi
		done
		rm ${output}/bar_tmp_${i}.PNG
	done

	#merge the bar files into a single one per bar
	merge_bars

	#merge the original image with the necessary layers
	i=1
	let total_bars=${bar_number}*${fps}
	j=${total_bars}
	let final_bars=${total_images}-${total_bars}
	for file in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
		if [[ "${fade}" == "in" ]]; then
			if [[ "${i}" -lt "${total_bars}" ]]; then
				echo -e -n "\rMerging bar into image ${i}/${file}"
				${convert} ${dir}/${file} -page +0+0 ${output}/bar_${i}.PNG -flatten ${output}/${file}
			else
				echo -e -n "\rCopying original image ${i}/${file}"
				cp ${dir}/${file} ${output}/${file}
			fi
		elif [[ "${fade}" == "out" ]]; then
			if [[ "${i}" -gt "${final_bars}" ]]; then
				echo -e -n "\rMerging bar into image ${j}/${file}"
				${convert} ${dir}/${file} -page +0+0 ${output}/bar_${j}.PNG -flatten ${output}/${file}
				let j=${j}-1
			else
				echo -e -n "\rCopying original image ${i}/${file}"
				cp ${dir}/${file} ${output}/${file}
			fi
		fi
		let i=${i}+1
	done

	#cleanup the rest of the PNG files
	rm ${output}/*.PNG

	echo ""
}

function version(){
	name=$(basename $0)
	echo -e "${name}: version ${version}"
	exit 0
}

function check_args(){
	if [[ "${dir}" == "${output}" ]]; then
		echo "ERROR: input and output directories cannot be the same!"
		exit 1
	fi
	if [[ "${fade}" != "in" && "${fade}" != "out" ]]; then
		echo "ERROR: fade has to be either \"in\" or \"out\""
		exit 1
	fi
}

function usage(){
	echo -e "\t./$(basename $0) -d <VALUE> -o <VALUE> -b <VALUE> -a <VALUE> -f <VALUE> -t <VALUE> -r <VALUE>"
	echo -e "\t-d directory where the files are"
	echo -e "\t-o output directory"
	echo -e "\t-b OPTIONAL number of separating bars (default ${bar_number})"
	echo -e "\t-a OPTIONAL frames per bar (default is ${fps})"
	echo -e "\t-f OPTIONAL (fade) fade in or fade out (default in)"
	echo -e "\t-t OPTIONAL direction of the bars ltr or rtl (default left-to-right)"
	echo -e "\t-e OPTIONAL apply transparency to the bars"
#	echo -e "\t-p OPTIONAL (preview) applies the modifications to the first foto to see the result"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

function main(){
	check_args
	slide_bars
}

while getopts "d:o:b:a:f:t:ephv?" arg; do
	case ${arg} in
		d)dir=${OPTARG}
		;;
		o)output=${OPTARG}
		;;
		b)bar_number=${OPTARG}
		;;
		a)fps=${OPTARG}
		;;
		f)fade=${OPTARG}
		;;
		t)direction=${OPTARG}
		;;
		e)transparency=yes
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
