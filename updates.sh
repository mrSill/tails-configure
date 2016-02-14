#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure update module
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'VERSION'

#BASEPATH=$( cd $(dirname $0); pwd -P);
pushd $( cd $(dirname $0); pwd -P) >/dev/null;

inc=functions ; source "$inc" ; if [ $? -ne 0 ] ; then echo "Fatal error! $a1 not found" 1>&2 ; exit 1 ; fi ;

## default values for user given parameters
DEBUG=false;

########## parse input parameters ##########
while [ $# -ge 1 ] ; do
    if [ ${1} = "--debug" ] ; then
        DEBUG=true;
        shift;
    else
        shift;
    fi;
done;

## Check updates
checkUpdates() {
    local currentVersion=$(git log -1 --name-only | grep commit | awk '{print $2}');
    local availableVersion=$(git ls-remote --heads | grep master | awk '{print $1}');

    if [[ $DEBUG = "true" ]]; then
        echo -e "\n########### DEBUG INFO ###########";
        echo "Current version:      ${currentVersion}";
        echo "Available version:    ${availableVersion}";
        echo -e "########### DEBUG INFO ###########\n";
    fi;

    echo -n "Check for updates...";
    if [[ $currentVersion != $availableVersion ]]; then
        echo -e "${cBlue}available${cNone}"; return 0;
    fi;
    echo -e "${cGray}nothing${cNone}"; return 1;
}

## Check updates and apply is available
if checkUpdates; then
    if $(askYN "Install updates?"); then
        git pull origin; git submodule update --init --recursive;
        sayWait;
    fi;
fi;
