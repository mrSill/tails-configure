#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure
## @package   Startup
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   0.1

set -o nounset
set -o errexit

################ parameters ################
BASEPATH=$( cd $(dirname $0); pwd -P);  # Current path
## default values for user given parameters
KEEP_FILES=true;
DEBUG=false;

inc=$BASEPATH/functions.sh ; source "$inc" ; if [ $? -ne 0 ] ; then echo "Fatal error! $inc not found" 1>&2 ; exit 1 ; fi ;

################## config ##################
getSettings $BASEPATH/config/default.conf;

########## parse input parameters ##########
while [ $# -ge 1 ] ; do
    if [ ${1} = "--debug" ]; then
        DEBUG=true
        shift
    elif [ ${1} = "-k" -o ${1} = "--keep" ]; then
        KEEP_FILES=true
        shift
    else
        if [ ${1} != "-h" -a ${1} != "--help" ] ; then
            echo "[ERROR] Unknown parameter \"${1}\""
            echo ""
        fi

        # print help
        printHelp
        exit 1
    fi
done;

############ print debug output ############
if [ $DEBUG = "true" ]; then
    echo "########### DEBUG INFO ###########";
    logmessage -n "Parameters:                 : ${params}";
    logmessage -n "debug:                      : ${DEBUG}";
    logmessage -n "keep files                  : ${KEEP_FILES}";
    echo "";
fi;

############### prepare step ###############
createDir $pathToSave;

## Run update module
if [ "${checkUpdate}" = 'true' ]; then
    ${BASEPATH}/updates.sh $@;
fi;

## Clear terminal
if [ $DEBUG = 'false' ]; then clear; fi;

################ print logo ################
printLogo $BASEPATH/ascii-logo.txt;

################ print menu ################
echo ""
echo "Please select menu item"
echo ""
echo "1) Setup persistent packages"
echo "2) Install/Run Teamviewer"
echo "3) Install/Run Tox chat"
echo ""
echo "Select [1-3] to choise menu item. Press other key to exit."
read -n 1 doing;

case $doing in
	1) echo "To continue, you need root.";
	   sudo $BASEPATH/persistent.sh $@;;
	2) $BASEPATH/teamviewer.sh $@;;
	3) $BASEPATH/toxchat.sh $@;;
	*) exit 1;;
esac;

############### cleanup step ###############
## remove download dir
if [[ $KEEP_FILES == false ]]; then
    removeDir $pathToSave;
    remove $LOGFILE;
fi;

## TEMPORALY ACTIONS
# Remove old settings
if [ -f "${BASEPATH}/settings.cfg" ] ; then
    rm -f ${BASEPATH}/settings.cfg;
fi;
