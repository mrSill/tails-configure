#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure
## @package   Startup
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'tails-setup.sh'

set -o nounset
set -o errexit

readonly VERSION="0.1";
readonly _PATH_=$( cd $(dirname $0); pwd -P);  # Current path

inc=$_PATH_/functions ; source "$inc" ; if [ $? -ne 0 ] ; then echo "Fatal error! $inc not found" 1>&2 ; exit 1 ; fi ;
getSettings $_PATH_/config/default.conf;

################ parameters ################
## default values for user given parameters
KEEP_FILES=true;
DEBUG=false;
############################################

############# helper functions #############
## Print Logo
printLogo()
{
    if [ -f ${1} ] ; then
        local logoContent=$(cat ${1});
        echo -e "${cMagenta}${logoContent}${cNone}";
    fi;
}
## Print help
printHelp()
{
    echo "Use this script to install/update Tails system"
    echo ""
    echo "usage:"
    echo "    ${0} PARAMETERS"
    echo ""
    echo "parameters:"
    echo "    --debug                : force set debug mode"

    echo "    -h|--help              : displays this help"
    echo "    -k|--keep              : keep files after installation/update"
    echo ""
    echo "example usages:"
    echo "    ${0}"
}
############################################

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
            echo "See all available parameters: ${0} --help"
        fi

        # print help
        printHelp
        exit 1
    fi
done;
############################################

################ debug info ################
if [[ $DEBUG == true ]]; then
    echo "########### DEBUG INFO ###########";
    echo "Parameters:                 : $@";
    echo "debug:                      : ${DEBUG}";
    echo "keep files                  : ${KEEP_FILES}";
    echo "############################################";
fi;
############################################

############### prepare step ###############
createDir $PATHTOSAVE;

## Run update module
if [[ "${CHECK_UPDATE}" == true ]]; then
    ${BASEPATH}/updates.sh $@;
fi;

## Clear terminal
if [[ $DEBUG = false ]]; then clear; fi;

## Print logo
printLogo $BASEPATH/ascii-logo.txt;

################ print menu ################
echo ""
echo "Please select menu item"
echo ""
echo "1) Setup persistent packages"
echo "2) Install teamviewer package"
echo "3) Install tox package"
echo ""
echo "Select [1-3] to choise menu item. Press other key to exit."
read -n 1 doing;

case $doing in
    1) echo -e "\nTo continue, you need root.\n";
       sudo $BASEPATH/persistent.sh $@;;
    2) echo -e "\n";
       $BASEPATH/teamviewer.sh $@;;
    3) echo -e "\n";
       $BASEPATH/toxchat.sh $@;;
    *) exit 1;;
esac;
############################################

############### cleanup step ###############
## remove download dir
if [[ $KEEP_FILES == false ]]; then
    removeDir $PATHTOSAVE;
    remove $LOGFILE;
fi;
############################################