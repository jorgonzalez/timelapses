#!/bin/bash
#
#       Author:         Jorge González
#
#       Description:    Script to generate a given number of files out of a given directory and the number of wanted images.
#
#       Version:        0.1
#
#       Modifications:  v0.1; first version.

#Some variables
version=0.1

function repeat(){
        file=`ls -al ${dir}/ | grep DSC | awk '{ print $9 }' | head -n 1`
        if [[ -z "${file}" ]]; then
                echo "There are no files to repeat!"
                exit 1
        fi

	total_images=`ls -l ${dir} | grep DSC | wc -l`

	while [[ "${total_images}" -lt "${npictures}" ]]; do
		for i in `ls -al ${dir} | grep JPG | awk '{ print $9 }'`; do
			if [[ "${total_images}" -lt "${npictures}" ]]; then
				let next=${total_images}+1
				filename="DSC_"`printf %04d ${next}`".JPG"

				cp ${dir}/${i} ${dir}/${filename}
				total_images=`ls -l ${dir} | grep DSC | wc -l`
			fi
		done
	done
	echo -e "Done!"
}

function version(){
        name=$(basename $0)
        echo -e "${name}: version ${version}"
        exit 0
}

function usage(){
        echo -e "\t./$(basename $0) -d <VALUE> -n <VALUE>"
        echo -e "\t-d directory where the files are"
        echo -e "\t-n number of pictures to end up with"
        echo -e "\t-v show version number"
        echo -e "\t-h show this help"
        exit 0
}

function main(){
        repeat
}

while getopts "d:n:hv?" arg; do
        case $arg in
		d)dir=${OPTARG}
		;;
                n)npictures=${OPTARG}
                ;;
                v)version && exit 0
		;;
                ?)usage && exit 1
                ;;
            esac
done

main
