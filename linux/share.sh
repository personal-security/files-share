#!/bin/bash

echo "
#####################################
### Site api https://transfer.sh/ ###
### Version 0.1 #####################
#####################################
"

PATHZIP=$1
FILENAME=""

msg_ok(){
	echo -e "\e[32m$1\e[0m"
}

msg_fail() {
	echo -e "\e[31m$1\e[0m"
}

rand_string(){
	echo $(date +%s | sha256sum | base64 | head -c $1)
}

### check installed software
if [ "$(which curl)" == "" ]; then
	msg_fail "Curl not found!"
	exit 1
fi

if [ "$(which tor)" == "" ] && [ $2 == "" ] ; then
        msg_fail "Tor not found!"
        exit 1
fi

if [ -f $1 ]; then
	FILENAME=${PATHZIP##*/}
	PATHZIP=$(dirname $1)
fi

if [ -d $1 ] || [ -f $1 ]; then

	### check tor connect if need
	TORANSWER=$(curl -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs)
	if [ "${TORANSWER}" == "Congratulations. This browser is configured to use Tor." ] && [ "$2" == "" ]; then
		msg_fail "Tor not work. Please run it!"
		exit 1
	fi

	### generate temp zip file name
	PATHTMP='/tmp/'

        FILENAMEZIP="$(rand_string 6)"
        FILENAMEZIP+='.zip'

        msg_ok "Temp zip path : ${PATHTMP}${FILENAMEZIP}"

	### generate new password
	PASS="$(rand_string 32)"
	msg_ok "Random password : ${PASS}"

	### zip files
	if [ -d $1 ]; then
		cd ${PATHZIP}; zip -erqX -9 --password ${PASS} ${PATHTMP}${FILENAMEZIP} .;cd - > /dev/null;
	fi
	if [ -f $1 ]; then
                cd ${PATHZIP}; zip -eqX -9 --password ${PASS} ${PATHTMP}${FILENAMEZIP} ${FILENAME};cd - > /dev/null;
        fi

	### send files
	if [ "$2" == "--no-proxy" ]; then
		curl -# -T ${PATHTMP}${FILENAMEZIP} https://transfer.sh/${FILENAMEZIP}
	else
		curl --socks5-hostname 127.0.0.1:9050 -# -T ${PATHTMP}${FILENAMEZIP} https://transfer.sh/${FILENAMEZIP}
	fi
	echo ""

	###remove temp files
	rm ${PATHTMP}${FILENAMEZIP}

	msg_ok "Upload good!"
else
	msg_fail "Bad file!!!"
fi
