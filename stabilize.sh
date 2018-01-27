#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to stabilize a shaky video.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#
#	Future imprv.:	Preview.
#

#Some variables
version=0.1

#Set the software depending on the Linux Distribution
if [[ `uname -a | egrep -i "debian|ubuntu" | wc -l` -eq 1 ]]; then
        mpegTool="/usr/bin/avconv"
        mpegTool2="/usr/bin/ffmpeg2"
elif [[ `uname -a | egrep -i "redhat|fedora|centos" | wc -l` -eq 1 ]]; then
        mpegTool="/usr/bin/ffmpeg"
        mpegTool2="/usr/bin/ffmpeg2"
fi

#Check if we have all the needed software
if [[ ! -e ${mpegTool} ]]; then
        echo "You are missing ${mpegTool}, please install libav-tools for your distribution"
        exit 1
elif [[ ! -e ${mpegTool2} ]]; then
        echo "You are missing ${mpegTool2}, please install ffmpeg-static libfdk-aac1 libopenjpeg5 libvidstab1.0 libx265 transcode"
        exit 1
fi

function stabilize(){
	if [[ -e ${source_video} ]]; then
		echo -e "Stabilizing video..."
		directory=`dirname ${source_video}`
		filename=`basename ${source_video}`
		vectors="transform_vectors_${filename}.trf"
		rm ${vectors} 2>/dev/null
		file=`echo ${source_video} | rev | cut -b 5- | rev`
		extension=`echo ${source_video} | rev | cut -b -3 | rev`
		tmp_video="${filename}_tmp.${extension}"
		ffmpeg2 -v 0 -i ${source_video} -vf vidstabdetect=stepsize=6:shakiness=8:accuracy=9:result=${vectors} -f null -
		ffmpeg2 -v 0 -i ${source_video} -vf vidstabtransform=input=${vectors}:zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4 -vcodec libx264 -preset slow -tune film -crf 18 ${tmp_video}
		rm ${vectors} 2>/dev/null
		mv ${tmp_video} ${source_video}
		echo -e "Video ${source_video} stabilized"
	fi
}

function version(){
        name=$(basename $0)
        echo -e "${name}: version $version"
        exit 0
}

function usage(){
        echo -e "\t./$(basename $0) -s <VALUE>"
        echo -e "\t-s source video to stabilize"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
	stabilize
}

while getopts "s:hv?" arg; do
        case ${arg} in
		s)source_video=${OPTARG}
		;;
                v)version && exit 0
		;;
                ?)usage && exit 1
                ;;
            esac
done

main
