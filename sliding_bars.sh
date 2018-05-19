#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to fade-in fade-out a video using bars of adjustable size that dissapear/appear.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#
#	Future imprv.:	0.2 bar direction left-to-right and right-to-left; fade out; preview
#

#Some variables
version=0.1
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
	#soooo many counters
	#for sure this should be easier and more elegant
	rest=1
	count=1
	final=1
	j=1
	k=1

	process=${bar_number}
	total_bars_processed=0
	while [[ "${process}" -gt 0 ]]; do
		let total_bars_processed=${total_bars_processed}+${process}*${fps}
		let process=${process}-1
	done

	for i in `seq 1 ${total_bars_processed}`; do
		images="${images} ${output}/bar_${j}_${k}.PNG"
		let j=${j}+1
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
	
	#cleanup 
	#rm bar_*_*.PNG
}

function slide_bars(){

	file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file}" ]]; then
		echo "There are no files to create the sliding bars!"
		exit 1
	fi
	width=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
	height=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`

	total_images_main=`ls -l ${dir} | grep DSC | wc -l`

	#create the output directory
	mkdir -p ${output}

	#create the base transparent image
	${convert} -size ${width}x${height} xc:none ${output}/base.PNG

	#create the bars
	#bar color
	color=black
	let bar_width=${width}/${bar_number}
	xpos1=0
	xpos2=${bar_width}
	i=0
	for i in `seq 1 ${bar_number}`; do
		${convert} ${output}/base.PNG -fill ${color} -stroke ${color} -draw "rectangle ${xpos1},0 ${xpos2},${height}" ${output}/bar_tmp_${i}.PNG
		let xpos1=${xpos1}+${bar_width}
		let xpos2=${xpos2}+${bar_width}
		let i=${i}+1
	done

	#create as many bars as needed per fps and bar_number, and apply transparency if necessary
	perc=`echo "100/(${fps}-1)" | bc`
	for i in `seq 1 ${bar_number}`; do
		curr_perc=0
		for j in `seq 1 ${fps}`; do
			if [[ "${transparency}" == "yes" ]]; then
				${convert} ${output}/bar_tmp_${i}.PNG -alpha set -channel A -evaluate subtract ${curr_perc}% ${output}/bar_${i}_${j}.PNG
				let curr_perc=${curr_perc}+${perc}
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
	for file in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
		if [[ "${i}" -lt "${total_bars}" ]]; then
			${convert} ${dir}/${file} -page +0+0 ${output}/bar_${i}.PNG -flatten ${output}/${file}
		else
			cp ${dir}/${file} ${output}/${file}
		fi
		let i=${i}+1
	done
	
	#cleanup the rest of the PNG files
	rm ${output}/*.PNG
}

function version(){
        name=$(basename $0)
        echo -e "${name}: version ${version}"
        exit 0
}

function usage(){
        echo -e "\t./$(basename $0) -d <VALUE> -o <VALUE> -b <VALUE> -a <VALUE> -f <VALUE> -t <VALUE> -r <VALUE>"
	echo -e "\t-d directory where the files are"
	echo -e "\t-o output directory"
	echo -e "\t-b OPTIONAL number of separating bars (default ${bar_number})"
	echo -e "\t-a OPTIONAL frames per bar (default is ${fps})"
#	echo -e "\t-f OPTIONAL (fade) fade in or fade out (default in)"
#	echo -e "\t-t OPTIONAL direction of the bars (default left-to-right)"
	echo -e "\t-e OPTIONAL apply transparency to the bars"
#	echo -e "\t-p OPTIONAL (preview) applies the modifications to the first foto to see the result"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
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
