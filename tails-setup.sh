#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure
## @package   Setup
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'bootstrap.sh'

set -o nounset
set -o errexit

################ parameters ################
BASENAME="tails-configure";             # Tails configure root dir name
BASEPATH=$( cd $(dirname $0); pwd -P);  # Current path
DEBUG=true;

############# helper functions #############
## Debug INFO
debug()
{
    if [[ "$DEBUG" == true ]]; then
        echo -e "$@";
    fi;
}

debug "############### debug info ###############"
debug "BASENAME:    $BASENAME";
debug "BASEPATH:    $BASEPATH";
debug "##########################################"

if [[ "$(basename $BASEPATH)" != $BASENAME ]] ; then
## [1] Находимся за пределами рабочей папки
    if [ -d "$BASENAME" ] ; then
    ## [1.1] Рабочая директория найдена
        if [ -f "$BASEPATH/$BASENAME/tails-setup.sh" ] ; then
            cd $BASEPATH/$BASENAME 1>&2;
            ./tails-setup.sh; ## Go-to [2]
        else
            echo "Directory $BASEPATH/$BASENAME found, but can not be used. Delete $BASEPATH/$BASENAME and run now $0.";
            exit 1;
        fi;
    else
    ## [1.2] Рабочая деректория не найдена, копируем файлы
    echo "Download working scripts...";
    git clone --recursive https://github.com/mrsill/tails-configure.git;
    if [ $? -ne 0 ] ; then echo "Error copying files from a remote server. Continued impossible. Try again later"; exit 1; fi;

    $BASEPATH/tails-setup.sh
    fi;
else
## [2] Находимся в рабочей папке
    git status 1>&2;
    if [ $? -ne 0 ] ; then echo "Could not find a local repository. Continued impossible. Delete $BASENAME dir and run now ./tails-setup.sh"; exit 1; fi;

    if ! [ -f "bootstrap.sh" ] ; then echo "File $ BASEPATH/bootstrap.sh not found. Continued impossible. Delete $BASENAME dir and run now ./tails-setup.sh"; exit 1; fi;
    ./bootstrap.sh;
fi;

## Код возврата
if [ $? -ne 0 ] ; then exit 1; fi;
exit 0;