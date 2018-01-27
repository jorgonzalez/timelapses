#!/bin/bash
#
#	Author:		Jorge González
#
# 	Description:	Script to deflicker a video.
#
#	Version:	0.1
#
#	Modifications:	v0.1; first version.
#
#	Future imprv.:	Preview.
#

#Some variables
version=0.1
mencoder=/usr/bin/mencoder
mplayer=/usr/bin/mplayer

#Check if we have all the needed software
if [[ ! -e ${mencoder} ]]; then
        echo "You are missing ${mencoder}, please install it for your distribution"
        exit 1
fi
if [[ ! -e ${mplayer} ]]; then
        echo "You are missing ${mplayer}, please install it for your distribution"
        exit 1
fi

function deflicker(){
	if [[ -e ${source_video} ]]; then
		echo -e "Deflickering video..."
		directory=`dirname ${source_video}`
		filename=`basename ${source_video}`
		file=`echo ${source_video} | rev | cut -b 5- | rev`
		extension=`echo ${source_video} | rev | cut -b -3 | rev`
		tmp_video="${filename}_tmp.${extension}"
		VIDEO_BITRATE=`${mplayer} -vo null -ao null -identify -frames 0 ${source_video} 2>/dev/null | grep ID_VIDEO_BITRATE | awk -F"=" '{print $2}'`
		${mencoder} ${source_video} -quiet -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=15000000:abitrate=48 -oac copy -vf hqdn3d -o ${tmp_video} 2>&1 2>/dev/null
		mv ${tmp_video} ${source_video}
		echo -e "Video ${source_video} deflickered"
	fi
}

function version(){
        name=$(basename $0)
        echo -e "${name}: version $version"
        exit 0
}

function usage(){
        echo -e "\t./$(basename $0) -s <VALUE>"
        echo -e "\t-s source video to deflicker"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
	deflicker
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
