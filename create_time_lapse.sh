#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to create a video out of pictures. It can resize the pictures based on their width
#			keeping the proportion, crawl through directories of the target directory where the
#			pictures are, output a black and white movie, enhance the picutres by modifiying the
#			contrast, normalize the contrast in the pictures (by histogram), and fade in-out.
#			Requires imagemagick, ffmpeg and mencoder.
#
#	Version:	0.27
#
#	Modifications:	v0.1; fade in-out feature.
#			v0.2; crawl through directories in the output directory.
#			v0.3; output the movie to another directory.
#			v0.4; resize based on width keeping proportion.
#			v0.5; black and white movie output.
#			v0.6; enhace and normalize the pictures based on histogram.
#			v0.7; Variable to set the directories; Compatibility for other Linux distributions; Text.
#			v0.8; Enhance the pictures by brightness-contrast percentage.
#			v0.9; Javier "Awo" Blanco version to create the timelapse with mplayer.
#			v0.10; Zoom in the center of the image without losing image size.
#			v0.11; Slide the images from left-to-right and right-to-left if size allows it.
#			v0.12; Use all mogrify options at the same time to lose less quality.
#			v0.13; Slide the images from up-to-down and down-to-up if size allows it; include -v option.
#			v0.14; Zoom out in the center of the image without losing image size.
#			v0.15; Tilt-shift using predefined options; quiet output.
#			v0.16; Input slide/zoom parameters along the options, e.g.: -s ltr2 -z in3.
#			v0.17; Output the first image of the changes as a test if an option is passed.
#			v0.18; Option to input frames per second.
#			v0.19; More verbosed output (timers); variables between brackets.
#			v0.20; Include cores on Imagemagick processing
#			v0.21; Option for smoothing hyperlapse, requires ffmpeg2 (ffmpeg with -vf vidstab) https://launchpad.net/~mc3man/+archive/ubuntu/ffmpeg-test
#			v0.22; Change tint color
#			v0.23; Deflicker video; fix preview for tint
#			v0.24; Change levels of white point, black point.
#			v0.25; Added ugly code for rounidng image proportions when resizing.
#			v0.26; hardcoded binaries removed for which.
#			v0.27; meconder and ffmpeg2 binary substituted for which.
#
#	Future imprv.:	Beter argument check and validation.
#			Cancel video creation if dimensions exceed certain overlay.
#			Manual resize of height.
#

#Some variables
version=0.27
#Directory where the video will be written
OutDir=A_Done
#Original directory to search for the pictures
SourceDir=A
#Font for the text
FontFace=URW-Chancery-L-Medium-Italic
ProcNum=`cat /proc/cpuinfo | grep "cpu cores" | head -n 1 | awk '{print $4}'`
vectors="transform_vectors.trf"
mogrify=$(which mogrify-im6)
convert=$(which convert-im6)
identify=$(which identify-im6)
mencoderBin=$(which mencoder)
mpegTool="/usr/bin/ffmpeg"
mpegTool2="/usr/bin/ffmpeg2"


#Check if we have all the needed software
if [[ ! -e ${mpegTool} ]]; then
	echo "You are missing ${mpegTool}, please install ffmpeg/libav-tools for your distribution"
	exit 1
elif [[ ! -e ${mpegTool2} ]]; then
	echo "You are missing ${mpegTool2}, please install ffmpeg-static libfdk-aac1 libopenjpeg5 libvidstab1.0 libx265 transcode"
	exit 1
elif [[ ! -e ${mencoderBin} ]]; then
	echo "You are missing mencoder, please install it for your distribution"
	exit 1
elif [[ ! -e ${mogrify} ]] || [[ ! -e ${convert} ]] || [[ ! -e ${identify} ]]; then
	echo "You are missing all or parts of imagemagick package, please install it for your distribution"
	exit 1
fi

function timestamp(){
	time1=${1}
	time2=${2}
	label="${3}"
	let totalSecs=${time2}-${time1}
	let mins=${totalSecs}/60
	let secs=${totalSecs}%60
	if [[ -z "${label}" ]]; then
		echo -n -e " took ${mins}m${secs}s\n"
	else
		echo -n -e "${label} took ${mins}m${secs}s\n"
	fi
}

function create_video(){
	if [[ "${recurisve}" == "y" ]]; then
		for dir in `ls -ald ${SourceDir}/* | awk '{ print $9 }'`; do
			dir=`pwd`/${dir}
			create_timelapse ${dir}
		done
	else
		dir=`pwd`/${directory}
		create_timelapse ${dir}
	fi
}

function create_timelapse(){
	#timestamp
	timestamp1=`date +%s`

	outdir=${OutDir}
	outname=`basename ${dir}`

	outfile='timelapse_'${outname}'_'`date +"%Y_%m_%d_%H-%M-%S"`'.avi'
	outfile=${outdir}/${outfile}

	total_images=`ls -l ${dir} | grep DSC | wc -l`

	mod_ops="-limit thread ${ProcNum}"
	cnv_ops="-limit thread ${ProcNum}"

	file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
	if [[ -z "${file}" ]]; then
		echo "There are no files to create a timelapse!"
		exit 1
	else
		echo "Working on \"${dir}\"..."
	fi

	width=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $1 }'`
	height=`${identify} ${dir}/${file} | awk '{ print $3 }' | awk -F"x" '{ print $2 }'`

	if [[ "${preview}" == "y" ]]; then
		preview="a_preview.JPG"
		cp ${dir}/${file} ${dir}/${preview}
	else
		rm ${dir}/a_preview.JPG 2>/dev/null
	fi

	#Slide
	if [[ ! -z "${slide}" && -z "${preview}" ]]; then
		#timestamp
		timestamp2=`date +%s`

		step_factor=`echo "${slide: -1}"`
		if [[ ${step_factor} -gt 5 ]]; then
			step_factor=5
		elif [[ ${step_factor} -lt 1 ]]; then
			step_factor=1
		fi
		slide_side=`echo ${slide} | tr -d 0-9`

		prop=`echo "${width}/${height}" | bc -l | cut -c -4`

		#A step factor higher than 5 makes the video jump
		#Step factor 1 is OK
		#Step factor 2 is quick
		#Step factor 3 is very quick
		#Step factor >4 makes it jump too much

		if [[ "${slide_side}" == "ltr" ]]; then
			step=0
			let used_width=${step_factor}*${total_images}
			let new_width_s=${width}-${used_width}
			new_height=`echo "${new_width_s}/${prop}" | bc`
			height_index=`echo "(${height} - ${new_height}) / 2" | bc`

			j=1
			for i in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
				echo -e -n "\rSliding left-to-right image ${j}/${total_images}"
				${convert} ${cnv_ops} ${dir}/${i} -crop "${new_width_s}"x"${new_height}"+${step}+${height_index} ${dir}/"${i}"_tmp.JPG
				mv ${dir}/"${i}"_tmp.JPG ${dir}/${i}

				let step=${step}+${step_factor}
				let j=${j}+1
			done

		elif [[ "${slide_side}" == "rtl" ]]; then
                        let used_width=${step_factor}*${total_images}
                        let new_width_s=${width}-${used_width}
                        new_height=`echo "${new_width_s}/${prop}" | bc`
                        height_index=`echo "(${height} - ${new_height}) / 2" | bc`
			let step=${width}-${new_width_s}

			j=1
			for i in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
				echo -e -n "\rSliding right-to-left image ${j}/${total_images}"
				${convert} ${cnv_ops} ${dir}/${i} -crop "${new_width_s}"x"${new_height}"+${step}+${height_index} ${dir}/"${i}"_tmp.JPG
				mv ${dir}/"${i}"_tmp.JPG ${dir}/${i}

				let step=${step}-${step_factor}
				let j=${j}+1
			done

		elif [[ "${slide_side}" == "utd" ]]; then
			let used_height=${step_factor}*${total_images}
			let new_height=${height}-${used_height}
			let new_width_s=${width}*${new_height}/${height}
			let width_index=(${width}-${new_width_s})/2
			step=0

			j=1
			for i in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
				echo -e -n "\rSliding up-to-down image ${j}/${total_images}"
				${convert} ${cnv_ops} ${dir}/${i} -crop "${new_width_s}"x"${new_height}"+${width_index}+$step ${dir}/"${i}"_tmp.JPG
				mv ${dir}/"${i}"_tmp.JPG ${dir}/${i}

				let step=$step+${step_factor}
				let j=${j}+1
			done

		elif [[ "${slide_side}" == "dtu" ]]; then
			let used_height=${step_factor}*${total_images}
			let new_height=${height}-${used_height}
			let new_width_s=${width}*${new_height}/${height}
			let width_index=(${width}-${new_width_s})/2
			step=${used_height}

			j=1
			for i in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
				echo -e -n "\rSliding down-to-up image ${j}/${total_images}"
				${convert} ${cnv_ops} ${dir}/${i} -crop "${new_width_s}"x"${new_height}"+${width_index}+$step ${dir}/"${i}"_tmp.JPG
				mv ${dir}/"${i}"_tmp.JPG ${dir}/${i}

				let step=${step}-${step_factor}
				let j=${j}+1
			done
		fi

		#timestamp
		timestamp3=`date +%s`
		timestamp ${timestamp2} ${timestamp3}
	fi

	#Resize
	if [[ ! -z "${new_width}" ]]; then
		#ugly code for rounding the proportions of the image
		orig_prop=`echo "${width}/${height}" | bc -l | cut -c -6`
		prop=`echo "${width}/${height}" | bc -l | cut -c -4`
		orig_prop_h=`echo "(${orig_prop}+0.002)" | bc -l | cut -c -4`
		orig_prop_l=`echo "(${orig_prop}-0.002)" | bc -l | cut -c -4`
		if [[ "${orig_prop_h}" != "${prop}" && "${orig_prop_l}" == "${prop}" ]]; then
			prop=${orig_prop_h}
		elif [[ "${orig_prop_h}" == "${prop}" && "${orig_prop_l}" != "${prop}" ]]; then
			prop=${orig_prop_l}
		fi
		height=`echo "${new_width}/${prop}" | bc`
		width=${new_width}

		mod_ops="${mod_ops} -resize ${width}"x"${height}!"
	fi

	#Normalize options
	if [[ "${normalize}" == "y" ]]; then
		mod_ops="${mod_ops} -normalize"
	fi

	#Enhance contrast options
	if [[ ! -z "${enhance}" ]]; then
		mod_ops="${mod_ops} -channel RGB -contrast-stretch ${enhance}"
	fi

	#Enhance brighness-contrast options
	if [[ ! -z "${brightness}" ]]; then
		mod_ops="${mod_ops} -brightness-contrast ${brightness}"
	fi

	#Enhance levels
	#convert-im6 fol_dom_2017.jpg -level 0,35% fol_dom_2017_mod.jpg
	if [[ ! -z "${levels}" ]]; then
		mod_ops="${mod_ops} -level ${levels}"
	fi

	#Enhacance tinted color options
	if [[ ! -z "${tint_color}" ]]; then
		mod_ops="${mod_ops} -fill ${tint_color} -tint ${tint_value}"
	fi

	#Apply all the modifications but text and black and white
	if [[ ! -z "${mod_ops}" || ! -z "${zoom}" || ! -z "${tiltshift}" && ${mod_ops} != "-limit thread ${ProcNum}" ]]; then
		#timestamp
		timestamp4=`date +%s`

		if [[ ! -z "${zoom}" && -z "${preview}" ]]; then

			zoom_increase=`echo "${zoom: -1}"`
			if [[ ${zoom_increase} -gt 5 ]]; then
				zoom_increase=5
			elif [[ ${zoom_increase} -lt 1 ]]; then
				zoom_increase=1
			fi
			zoom_increase=`echo "scale=4;0.001*${zoom_increase}" | bc`
			zoom_type=`echo ${zoom} | tr -d 0-9`

			if [[ "${reverse}" == "yes" && "${zoom_type}" == "in" ]]; then
				zoom_type="out"
			elif [[ "${reverse}" == "yes" && "${zoom_type}" == "out" ]]; then
				zoom_type="in"
			fi

			if [[ "${zoom_type}" == "in" ]]; then
				#timestamp
				timestamp5=`date +%s`

				zoom_factor=1.001
				j=1
				for i in `ls -al ${dir} | grep DSC | awk '{ print $9 }'`; do
					echo -e -n "\rZooming in image ${j}/${total_images}"
					${mogrify} ${mod_ops} -distort SRT ${zoom_factor},0 ${dir}/${i}
					zoom_factor=`echo "scale=4;${zoom_factor}+${zoom_increase}" | bc`
					let j=${j}+1
				done

				#timestamp
				timestamp6=`date +%s`
				timestamp ${timestamp5} ${timestamp6}

			elif [[ "${zoom_type}" == "out" ]]; then
				#timestamp
				timestamp7=`date +%s`

		                total_images=`ls -l ${dir} | grep DSC | wc -l`
				zoom_factor=`echo "scale=4;${total_images}*${zoom_increase}+1-${zoom_increase}" | bc`
				j=1
				for i in `ls -al ${dir} | grep DSC | awk '{ print $9 }'`; do
					echo -e -n "\rZooming out image ${j}/${total_images}"
					${mogrify} ${mod_ops} -distort SRT ${zoom_factor},0 ${dir}/${i}
					zoom_factor=`echo "scale=4;${zoom_factor}-${zoom_increase}" | bc`
					let j=${j}+1
				done

				timestamp8=`date +%s`
				timestamp ${timestamp7} ${timestamp8}

			else
				echo -n "Not recognised."
				exit 2
			fi

		elif [[ ! -z "${mod_ops}" && -z "${preview}" && ${mod_ops} != "-limit thread ${ProcNum}" ]]; then
			#timestamp
			timestamp9=`date +%s`

			j=1
			for i in `ls -al ${dir} | grep DSC | awk '{ print $9 }'`; do
				echo -e -n "\rModifying image ${j}/${total_images}"
				${mogrify} ${mod_ops} ${dir}/${i}
				let j=${j}+1
			done

			timestamp10=`date +%s`
			timestamp ${timestamp9} ${timestamp10} "\nTotal modifications"

		elif [[ ! -z "${mod_ops}" && ! -z "${preview}" ]]; then
			${mogrify} ${mod_ops} ${dir}/${preview}
		fi

		#tilt-shift
		if [[ "${tiltshift}" == "y" && -z "${preview}" ]]; then
			#timestamp
			timestamp11=`date +%s`

			j=1
			for i in `ls -al ${dir} | grep DSC | awk '{ print $9 }'`; do
				echo -e -n "\rTilt-Shifting image ${j}/${total_images}"
#				convert ${dir}/${i} -sigmoidal-contrast 15x30% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${i}
#				convert ${cnv_ops} ${dir}/${i} -sigmoidal-contrast 15x30% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${i}
#				${convert} ${cnv_ops} ${dir}/${i} -sigmoidal-contrast 15x30% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${i}
#				The contrast is WAY TOO MUCH
				${convert} ${cnv_ops} ${dir}/${i} -sigmoidal-contrast 3x6% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${i}
				let j=${j}+1
			done

			timestamp12=`date +%s`
			timestamp ${timestamp11} ${timestamp12}

		elif [[ "${tiltshift}" == "y" && ! -z "${preview}" ]]; then
#			convert ${dir}/${preview} -sigmoidal-contrast 15x30% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${preview}
#			convert ${dir}/${preview} -sigmoidal-contrast 15x30% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${preview}
#			convert ${cnv_ops} ${dir}/${preview} -sigmoidal-contrast 15x30% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${preview}
#			${convert} ${cnv_ops} ${dir}/${preview} -sigmoidal-contrast 15x30% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${preview}
#			The contrast is WAY TOO MUCH
			${convert} ${cnv_ops} ${dir}/${preview} -sigmoidal-contrast 3x6% \( +clone -sparse-color Barycentric '0,0 black 0,%h gray80' -solarize 50% -level 50%,0 -write mpr:blur_map \) -compose Blur -set option:compose:args 10x0 -composite mpr:blur_map -compose Blur -set option:compose:args 0x10 -composite ${dir}/${preview}
		fi
	fi

	#THIS DOES NOT WORK FOR LONG TEXTS
	#Text
	if [[ ! -z "${text}" ]]; then
		#timestamp
		timestamp13=`date +%s`

		#Size for the text for 1280 is 60p
		FontSize=`echo "${width}*60/1280" | bc -l | awk -F"." '{ print $1 }'`
		#This FontFace has an average of 34px per character; we need to leave at least 35px for the right padding
		TextLength=${#text}
#		FontFaceWeight=24
#		The avg. proportion between FontSize and FontWeight in px is 82/201
		let FontFaceWeight=${FontSize}*82/201
		RightPadding=50
		let RightPos=${TextLength}*${FontFaceWeight}
		let RightPos=${width}-${RightPos}-${RightPadding}

		BottomPos=`echo "${width}*64/100" | bc -l | awk -F"." '{ print $1 }'`

		if [[ -z "${preview}" ]]; then
			j=1
			for i in `ls -al ${dir}| grep DSC | awk '{ print $9 }'`; do
				echo -e -n "\rAdding text \"${text}\" to image ${j}/${total_images}"
#				convert ${dir}/${i} -font ${FontFace} -pointsize ${FontSize} -fill rgba\(255,255,255,0.80\) -draw "text ${RightPos},${BottomPos} '${text}'" ${dir}/${i}
#				convert ${cnv_ops} ${dir}/${i} -font ${FontFace} -pointsize ${FontSize} -fill rgba\(255,255,255,0.80\) -draw "text ${RightPos},${BottomPos} '${text}'" ${dir}/${i}
				${convert} ${cnv_ops} ${dir}/${i} -font ${FontFace} -pointsize ${FontSize} -fill rgba\(255,255,255,0.80\) -draw "text ${RightPos},${BottomPos} '${text}'" ${dir}/${i}
				let j=${j}+1
			done
		elif [[ ! -z "${preview}" ]]; then
#			convert ${dir}/${preview} -font ${FontFace} -pointsize ${FontSize} -fill rgba\(255,255,255,0.80\) -draw "text ${RightPos},${BottomPos} '${text}'" ${dir}/${preview}
#			convert ${cnv_ops} ${dir}/${preview} -font ${FontFace} -pointsize ${FontSize} -fill rgba\(255,255,255,0.80\) -draw "text ${RightPos},${BottomPos} '${text}'" ${dir}/${preview}
			${convert} ${cnv_ops} ${dir}/${preview} -font ${FontFace} -pointsize ${FontSize} -fill rgba\(255,255,255,0.80\) -draw "text ${RightPos},${BottomPos} '${text}'" ${dir}/${preview}
		fi

		timestamp14=`date +%s`
		timestamp ${timestamp13} ${timestamp14}
	fi

	if [[ ! -z "${preview}" ]]; then
		echo "Preview done (${dir}/${preview})!"
		exit 0
	fi

	if [[ -z "${fps}" ]]; then
		fps=25
	fi
	if [[ -z "${killoutput}" ]]; then
		#timestamp
		timestamp15=`date +%s`
		echo -n "Encoding..."
		${mencoderBin} -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=${width}:${height} -mf type=jpeg:fps=${fps} mf://${dir}/*.JPG -o ${outfile} -really-quiet 2>/dev/null

		if [[ ! -z "${fade}" ]]; then
			frames=`ls -al ${dir}/ | grep DSC | wc -l`
			echo "Fading..."
			let frames=${frames}-${fade}
			${mpegTool} -i ${outfile} -filter:v 'fade=in:0:'${fade} -c:v libx264 -crf 22 -preset veryfast -c:a copy tmp.mp4 2>/dev/null
			rm ${outfile}
			${mpegTool} -i tmp.mp4 -filter:v 'fade=out:'${frames}':'${fade} -c:v libx264 -crf 22 -preset veryfast -c:a copy ${outfile} 2>/dev/null
			rm tmp.mp4
		fi

		if [[ "${momochrome}" == "y" ]]; then
			echo "Converting to grayscale..."
				${mencoderBin} ${outfile} -o ${outfile}"_bw" -vf hue=0:0 -oac copy -ovc lavc -really-quiet
				mv ${outfile}"_bw" ${outfile}
		fi

		if [[ ! -z "${new_width}" ]]; then
			width=${new_width}
		fi
		if [[ "${width}" -gt 4000 ]]; then
			quality="4k"
		elif [[ "${width}" -ge 3000 && "${width}" -lt 4000 ]]; then
	                quality="3k"
		elif [[ "${width}" -ge 2000 && "${width}" -lt 3000 ]]; then
	                quality="2k"
		elif [[ "${width}" -ge 1920 && "${width}" -lt 2000 ]]; then
	                quality="1k"
		elif [[ "${width}" -ge 720 && "${width}" -lt 1920 ]]; then
	                quality="720p"
		elif [[ "${width}" -ge 480 && "${width}" -lt 4000 ]]; then
	                quality="480p"
		elif [[ "${width}" -ge 360 && "${width}" -lt 480 ]]; then
	                quality="320p"
		elif [[ "${width}" -ge 240 && "${width}" -lt 320 ]]; then
	                quality="240p"
		else
			quality="shit"
		fi
		if [[ "${fps}" -ne 25 ]]; then
			finaloutfile='timelapse_'${outname}'_'${quality}'_'${fps}'fps_'`date +"%Y_%m_%d_%H-%M-%S"`'.avi'
		else
			finaloutfile='timelapse_'${outname}'_'${quality}'_'`date +"%Y_%m_%d_%H-%M-%S"`'.avi'
		fi
		finaloutfile=${outdir}/${finaloutfile}
		mv ${outfile} ${finaloutfile}

		#hyperlapse
		if [[ "${hyperlapse}" == "y" ]]; then
			echo -e "\nSmoothing hyperlapse..."
			timestamp17=`date +%s`
			if [[ "${fps}" -ne 25 ]]; then
				finaloutfile_hyperlapse=${outdir}'/hyperlapse_'${outname}'_'${quality}'_'${fps}'fps_'`date +"%Y_%m_%d_%H-%M-%S"`'.avi'
			else
				finaloutfile_hyperlapse=${outdir}'/hyperlapse_'${outname}'_'${quality}'_'`date +"%Y_%m_%d_%H-%M-%S"`'.avi'
			fi
			rm ${vectors}  2>/dev/null
			${mpegTool2} -v 0 -i ${finaloutfile} -vf vidstabdetect=stepsize=6:shakiness=8:accuracy=9:result=${vectors} -f null -
			${mpegTool2} -v 0 -i ${finaloutfile} -vf vidstabtransform=input=${vectors}:zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4 -vcodec libx264 -preset slow -tune film -crf 18 ${finaloutfile_hyperlapse}
			rm ${vectors} ${finaloutfile} 2>/dev/null
			timestamp18=`date +%s`
			timestamp ${timestamp17} ${timestamp18} "Smoothing hyperlapse"
		fi

		timestamp16=`date +%s`
		timestamp ${timestamp15} ${timestamp16}

		#deflicker
		if [[ "${deflicker}" == "y" ]]; then
			timestamp19=`date +%s`
			VIDEO_BITRATE=`mplayer -vo null -ao null -identify -frames 0 ${finaloutfile} 2>/dev/null | grep ID_VIDEO_BITRATE | awk -F"=" '{print $2}'`
			finaloutfile_deflickered=${outdir}'/timelapse_'${outname}'_deflickered_'${quality}'_'`date +"%Y_%m_%d_%H-%M-%S"`'.avi'
			${mencoderBin} ${finaloutfile} -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=15000000:abitrate=48 -oac copy -vf hqdn3d -o ${finaloutfile_deflickered}
			timestamp20=`date +%s`
			timestamp ${timestamp19} ${timestamp20}
		fi
	fi

	timestamp100=`date +%s`
	timestamp ${timestamp1} ${timestamp100} "Done!"
}

function version(){
	name=$(basename $0)
	echo -e "${name}: version ${version}"
	exit 0
}

function usage(){
	echo -e "\t./$(basename $0) -r <VALUE> -f <VALUE> -d -a <VALUE> -m -e <VALUE> -b <VALUE> -n -f <VALUE> -c <VALUE> -l <VALUE> -t <TEXT> -z <VALUE>"
	echo -e "\t-r OPTIONAL (resize) the value of the new width; new height will be in proportion (e.g.: 2560, 2048, 1920, 1600, 1440, 1280, 1024...)"
	echo -e "\t-f OPTIONAL (fade) the number of frames for the fade-in and fade-out"
	echo -e "\t-d OPTIONAL (directory) to execute this script"
	echo -e "\t-u OPTIONAL (recursive) recursively crawl through the directories to create videos"
	echo -e "\t-a OPTIONAL frames per second (default is 25)"
	echo -e "\t-m OPTIONAL (monochrome) grayscale video output"
	echo -e "\t-e OPTIONAL (enhance) modify image contrast stretching the range of intensity by black point white point percentage, e.g. <1x2%>"
	echo -e "\t-b OPTIONAL (brightness) modify the brightness-contrast in images by brightness contrast percentage, e.g. <0x3%>"
	echo -e "\t-w OPTIONAL (levels) modify the levels stretching the range of intensity by black point white point percentage, e.g. <0,90%>"
	echo -e "\t-n OPTIONAL (normalize) increase the image contrast stretching the range of intensity"
	echo -e "\t-c OPTIONAL (tint) use a color to tint the image; valid tints 'red', 'green' and 'blue' (requires tint value option -l <-200:200>)"
	echo -e "\t-t OPTIONAL (text) print a text in each picture (after applying the rest of the changes if any)"
	echo -e "\t-z OPTIONAL (zoom) zoom into an area with step; areas and step supported: <in1-5>, <out1-5>"
	echo -e "\t-s OPTIONAL (slide) move the focus -with step- of the images from <ltr1-2> to right, <rtl1-2> to left, <utd1-2> to down, <dtu1-2> to up"
	echo -e "\t-i OPTIONAL (tilt-shift) tilt-shift the images (very time consuming)"
	echo -e "\t-y OPTIONAL (hyperlapse) smooth the output of the hyperlapse"
	echo -e "\t-p OPTIONAL (preview) applies the modifications to the first photo to see the result"
	echo -e "\t-k OPTIONAL (kill output) no video output, just picture modification"
	echo -e "\t-x OPTIONAL Deflicker video"
	echo -e "\t-v show version number"
	echo -e "\t-h show this help"
	exit 0
}

#function check_args(){
#	if [[ -z "${new_width}" ]] && [[ -z "${fade}" ]]; then
#		usage && exit 0
#	fi
#
#	echo "d:${directories} m:${monochrome} e:${enhance} n:${normalize}"
#	exit 0
#}

function main(){
#	check_args
	create_video
}

while getopts "r:f:a:ud:mie:b:w:nc:l:t:z:s:R:ypkxhv?" arg; do
	case ${arg} in
		r)new_width=${OPTARG}
		;;
		f)fade=${OPTARG}
		;;
		d)directory=${OPTARG}
		;;
		u)recursive=y
		;;
		a)fps=${OPTARG}
		;;
		m)monochrome=y
		;;
		e)enhance=${OPTARG}
		;;
		b)brightness=${OPTARG}
		;;
		w)levels=${OPTARG}
		;;
		n)normalize=y
		;;
		c)tint_color=${OPTARG}
		;;
		l)tint_value=${OPTARG}
		;;
		i)tiltshift=y
		;;
		t)text=${OPTARG}
		;;
		z)zoom=${OPTARG}
		;;
		s)slide=${OPTARG}
		;;
		y)hyperlapse=y
		;;
		x)deflicker=y
		;;
		p)preview=y
		;;
		k)killoutput=y
		;;
		v)version && exit 0
		;;
		h|\?)usage && exit 0
		;;
		?)usage && exit 1
		;;
	esac
done

main
