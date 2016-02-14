#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure teamviewer
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'bootstrap.sh'

inc=$(dirname $0)/functions ; source "$inc" ; if [ $? -ne 0 ] ; then echo "Fatal error! $inc not found" 1>&2 ; exit 1 ; fi ;

################## config ##################
getSettings $(dirname $0)/config/default.conf;

configureNetfilter()
{
    #set default
    netfilterSetDefault $BASEPATH/config/ferm.conf;

    #allow traffic going specific outbound ports
    iptables -A OUTPUT -p tcp --dport 5938 -j ACCEPT
    iptables -A INPUT -p tcp --sport 5938 -j ACCEPT
}

################ parameters ################
TEAMVIEWER_DOWNLOAD_PATH="http://download.teamviewer.com/download"
TEAMVIEWER_VERSION="9x"
TEAMVIEWER_REMOTE_PACKAGE_NAME="teamviewer_linux.deb"
TEAMVIEWER_LOCAL_PACKAGE_NAME="teamviewer${TEAMVIEWER_VERSION}_linux.deb"

DPKG="${pathToSave}/${TEAMVIEWER_LOCAL_PACKAGE_NAME}"

if [ "$(id -u)" != "0" ]; then

############# download package #############

	if [ ! -e ${DPKG} ]; then
	    echo -n "Download Teamviewer ${TEAMVIEWER_VERSION} package..";
		downloadFile ${TEAMVIEWER_DOWNLOAD_PATH}/version_${TEAMVIEWER_VERSION}/${TEAMVIEWER_REMOTE_PACKAGE_NAME} $pathToSave;
		mv $pathToSave/$TEAMVIEWER_REMOTE_PACKAGE_NAME $DPKG;
	fi

	sudo $BASEPATH/teamviewer.sh;
else

############## install package #############
	dpkg -i $DPKG;

############## iptables setup ##############
    echo -n "Configure netfilter...";
    configureNetfilter;
    echo -e "${cGreen}Complete${cNone}";
fi;
