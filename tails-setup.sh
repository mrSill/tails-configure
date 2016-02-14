#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure
## @package   Setup
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   0.1

set -o nounset
set -o errexit

################ parameters ################
readonly DIRNAME="tails-configure";             # Tails configure root dir name
readonly _PATH_=$( cd $(dirname $0); pwd -P);  # Current path
readonly DEBUG=false;
############################################

################ debug info ################
if [[ "$DEBUG" == true ]]; then
    echo "############### debug info ###############"
    echo "Command: $0 $@";
    echo "Current path:        $_PATH_";
    echo "Working dir name:    $DIRNAME";
    echo "##########################################"
fi;
############################################

if [[ "$(basename $_PATH_)" != $DIRNAME ]] ; then
## [1] Находимся за пределами рабочей папки
    if [ -d "$DIRNAME" ] ; then
    ## [1.1] Рабочая директория найдена
        if [ -f "$_PATH_/$DIRNAME/tails-setup.sh" ] ; then
            cd $_PATH_/$DIRNAME 1>&2;
            ./tails-setup.sh; ## Go-to [2]
        else
            echo "Directory $_PATH_/$DIRNAME found, but can not be used. Delete $BASEPATH/$DIRNAME and run now $0";
            exit 1;
        fi;
    else
    ## [1.2] Рабочая деректория не найдена, копируем файлы
    echo "Download working scripts...";
    git clone --recursive https://github.com/mrsill/tails-configure.git;
    if [ $? -ne 0 ] ; then echo "Error copying files from a remote server. Continued impossible. Try again later"; exit 1; fi;

    $_PATH_/tails-setup.sh $@;
    fi;
else
## [2] Находимся в рабочей папке
    git status 1>&2;
    if [ $? -ne 0 ] ; then echo "Could not find a local repository. Continued impossible. Save $0 and delete $DIRNAME dir. After run now $0"; exit 1; fi;

    if ! [ -f "bootstrap.sh" ] ; then echo "File $_PATH_/bootstrap.sh not found. Continued impossible. Delete $DIRNAME dir and run now $0"; exit 1; fi;

    $_PATH_/bootstrap.sh $@;
fi;

## Код возврата
if [ $? -ne 0 ] ; then exit 1; fi; ## Error

exit 0; ## Success