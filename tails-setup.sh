#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure
## @package   Setup
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'VERSION'

set -o nounset
set -o errexit

readonly _PATH_=$( cd $(dirname $0); pwd -P);  # Path to parent dir

################ parameters ################
tailsDirname="tails-configure";             # Tails configure root dir name
debug=false;
############################################

## Print help
printHelp()
{
    echo "Use this script to initialize/runing working scripts"
    echo ""
    echo "usage:"
    echo "    ${0} PARAMETERS"
    echo ""
    echo "parameters:"
    echo "    --debug                : force set debug mode"
    echo "    -d|--dir               : directory name. Example: -p=my_dir"
    echo "    -v|--version           : show current version"

    echo "    -h|--help              : displays this help"
    echo ""
    echo "example usages:"
    echo "    ${0}"
}
############################################

########## parse input parameters ##########
while [ $# -ge 1 ] ; do
    if [ ${1} = "--debug" ]; then
        debug=true
        shift
    elif [ ${1} = "-d" -o ${1} = "--dir" ]; then
        #tailsDirname=...
        shift
    elif [ ${1} = "-h" -o ${1} = "--help" ]; then
        printHelp
        exit 1
    else
        echo "[ERROR] Unknown parameter \"${1}\""
        echo "See all available parameters: ${0} --help"
    fi
done;
############################################

################ debug info ################
if [[ "$debug" == true ]]; then
    echo "############### debug info ###############"
    echo "Command: $0 $@";
    echo "Current path:        $_PATH_";
    echo "Working dir name:    $tailsDirname";
    echo "##########################################"
fi;
############################################

if [[ "$(basename $_PATH_)" != $tailsDirname ]] ; then
## [1] Находимся за пределами рабочей папки
    if [ -d "$tailsDirname" ] ; then
    ## [1.1] Рабочая директория найдена
        if [ -f "$_PATH_/$tailsDirname/tails-setup.sh" ] ; then
            cd $_PATH_/$tailsDirname 1>&2;
            ./tails-setup.sh $@; ## Go-to [2]
        else
            echo "Directory $_PATH_/$tailsDirname found, but can not be used. Delete $BASEPATH/$tailsDirname and run now $0";
            exit 1;
        fi;
    else
    ## [1.2] Рабочая деректория не найдена, копируем файлы
    echo "Download working scripts...";
    git clone --recursive https://github.com/mrsill/tails-configure.git $tailsDirname;
    if [ $? -ne 0 ] ; then echo "Error copying files from a remote server. Continued impossible. Try again later"; exit 1; fi;

    $_PATH_/tails-setup.sh $@;
    fi;
else
## [2] Находимся в рабочей папке
    git status 1>&2;
    if [ $? -ne 0 ] ; then echo "Could not find a local repository. Continued impossible. Save $0 and delete $tailsDirname dir. After run now $0"; exit 1; fi;

    if ! [ -f "bootstrap.sh" ] ; then echo "File $_PATH_/bootstrap.sh not found. Continued impossible. Delete $tailsDirname dir and run now $0"; exit 1; fi;

    $_PATH_/bootstrap.sh $@;
fi;

## Код возврата
if [ $? -ne 0 ] ; then exit 1; fi; ## Error

exit 0; ## Success