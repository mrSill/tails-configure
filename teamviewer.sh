#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure
## @package   Teamviewer
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'VERSION'

readonly _PATH_=$( cd $(dirname $0); pwd -P);  # Current path

inc=$_PATH_/functions ; source "$inc" ; if [ $? -ne 0 ] ; then echo "Fatal error! $inc not found" 1>&2 ; exit 1 ; fi ;
getSettings $_PATH_/config/default.conf;

################ parameters ################
readonly TEAMVIEWER_DOWNLOAD_PATH="http://download.teamviewer.com/download"
readonly TEAMVIEWER_VERSION="9x"
readonly TEAMVIEWER_REMOTE_PACKAGE_NAME="teamviewer_linux.deb"
readonly TEAMVIEWER_LOCAL_PACKAGE_NAME="teamviewer${TEAMVIEWER_VERSION}_linux.deb"

readonly DPKG="${PATHTOSAVE}/${TEAMVIEWER_LOCAL_PACKAGE_NAME}"

if isRoot; then
    dpkg -i $DPKG;
    netfilterSetDefault $BASEPATH/config/ferm.conf;
    configureNetfilter tcp 5938;
else
    ############# download package #############
    if [ ! -e ${DPKG} ]; then
        echo -n "Download Teamviewer ${TEAMVIEWER_VERSION} package..";
        downloadFile ${TEAMVIEWER_DOWNLOAD_PATH}/version_${TEAMVIEWER_VERSION}/${TEAMVIEWER_REMOTE_PACKAGE_NAME} $PATHTOSAVE;
        mv $PATHTOSAVE/$TEAMVIEWER_REMOTE_PACKAGE_NAME $DPKG;
    fi

    sudo $BASEPATH/teamviewer.sh;
fi;
