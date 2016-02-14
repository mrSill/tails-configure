#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure
## @package   Include Functions
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'bootstrap.sh'

cRed='\e[1;31m'; cGreen='\e[0;32m'; cNone='\e[0m'; cYel='\e[1;33m';
cBlue='\e[1;34m'; cGray='\e[1;30m'; cMagenta='\e[;35m'
msgOk="${cGreen}Ok${cNone}"; msgErr="${cRed}Error${cNone}";

############# helper functions #############
## Ask user 'y' or any key
askYN()
{
    ## $1 = (not required) question
    local AMSURE;
    if [ -n "$1" ] ; then
       read -n 1 -p "$1 (y/[a]): " AMSURE;
    else
       read -n 1 AMSURE;
    fi
    echo "" 1>&2;
    if [ "$AMSURE" = "y" ] ; then
       return 0;
    else
       return 1;
    fi
}

## Ask user 'y' or exit
askYNE()
{
    askYN "$1" || exit;
}

## Pause while not pressed any key
sayWait()
{
   local AMSURE
   [ -n "$1" ] && echo "$@" 1>&2
   read -n 1 -p "(press any key)" AMSURE
   echo "" 1>&2
}

## Clear terminal
cls()
{
    echo -en "\ec";
}

checkParm()
{
   if [ -z "$1" ] ; then
      echo "!!$2. Продолжение невозможно.  Выходим." 1>&2
      exit 1
   fi
}

## Print Logo
printLogo()
{
    if [ -f ${1} ] ; then
        local logoContent=$(cat ${1});
        echo -e "${cMagenta}${logoContent}${cNone}";
    fi;
}
## Print helpe
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

############ logging functions #############
## Show log message in console
logmessage()
{
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = message to output

  flag=''; outtext='';
  if [ "$1" == "-n" ]; then
    flag="-n "; outtext=$2;
  else
    outtext=$1;
  fi;

  echo -e $flag[$(date +%H:%M:%S)] "$outtext\n";
}

## Write log file (if filename setted)
writeLog()
{
  if [ ! -z "$LOGFILE" ]; then
    echo "[$(date +%Y-%m-%d/%H:%M:%S)] [$(basename $0)] - $1" >> "$LOGFILE";
  fi;
}

############ settings functions ############
## Load settings
getSettings()
{
    ## $1 = settings filename
    local settingsFile=$1;

    ## Load setting from file
    if [ -f "$settingsFile" ]; then source $settingsFile; else
        echo -e "\e[1;31mCannot load settings ('$settingsFile') file. Exit\e[0m"; exit 1;
    fi;
}

############ download functions ############
downloadFile()
{
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = URL to download
  ## $3 = save to file PATH

  flag=''; url=''; saveto='';
  if [ "$1" == "-n" ]; then
    flag="-n "; url=$2; saveto=$3;
  else
    url=$1; saveto=$2;
  fi;

  if [ -n "$wgetDelay" ] || [ -z "$wgetDelay" ]; then
    wgetDelay='0';
  fi;

  if [ -n "$wgetLimitSpeed" ] || [ -z "$wgetLimitSpeed" ]; then
    wgetLimitSpeed='102400k';
  fi;

  ## wget manual <http://www.gnu.org/software/wget/manual/wget.html>
  ##
  ## --cache=off    When set to off, disable server-side cache
  ## --timestamping Only those new files will be downloaded in the place
  ##                of the old ones.
  ## -v -d          Verbose and Debud output
  ## -U             Identify as agent-string to the HTTP server
  ## --limit-rate   Limit the download speed to amount bytes per second
  ## -e robots=off
  ## -w             Wait the specified number of seconds between the
  ##                retrievals
  ## --random-wait  This option causes the time between requests to vary
  ##                between 0 and 2 * wait seconds
  ## -P             Path to save file (dir)

  ## Save wget output to vareable and..
  wgetResult=$(wget \
    --cache=off \
    --timestamping \
    -v -d \
    -U "$USERAGENT" \
    --http-user="$USERNAME" \
    --http-password="$PASSWD" \
    --limit-rate=$wgetLimitSpeed \
    -e robots=off \
    -w $wgetDelay \
    --random-wait \
    -P $saveto \
    $url 2>&1);

  ## ..if we found string 'not retrieving' - download skipped..
  if [[ $wgetResult == *not\ retrieving* ]]; then
    echo -e $flag "${cYel}Skipped${cNone}";
    return 1;
  fi;

  ## ..also - if we found 'saved' string - download was executed..
  if [[ $wgetResult == *saved* ]]; then
    echo -e $flag "${cGreen}Complete${cNone}";
    return 1;
  fi;

  ## ..or resource not found
  if [[ $wgetResult == *ERROR\ \4\0\4* ]]; then
    echo -e $flag "${cRed}Not found${cNone}";
    return 1;
  fi;

  ## if no one substring founded - maybe error?
  echo -e $flag "${cRed}Error =(${cNone}\nWget debug info: \
    \n\n${cYel}$wgetResult${cNone}\n\n";
  return 0;
}

########## filesystem functions ############
## Create some directory
createDir()
{
  local dirPath=$1;
  if [ ! -d $dirPath ]; then
    logmessage -n "Create $dirPath..\c "; mkdir -p $dirPath >/dev/null 2>&1;
    if [ -d "$dirPath" ]; then
      echo -e $msgOk; else echo -e $msgErr;
    fi;
  fi;
}

## Remove some directory
removeDir()
{
  local dirPath=$1;
  if [ -d $dirPath ]; then
    logmessage -n "Remove $dirPath..\c "; rm -R -f $dirPath >/dev/null 2>&1;
    if [ ! -d "$dirPath" ]; then
      echo -e $msgOk; else echo -e $msgErr;
    fi;
  fi;
}

## Remove some file
removeFile()
{
  local filePath=$1;
  if [ -f $filePath ]; then
    logmessage -n "Remove $filePath..\c "; rm -f $filePath >/dev/null 2>&1;
    if [ ! -f "$filePath" ]; then
      echo -e $msgOk; else echo -e $msgErr;
    fi;
  fi;
}

## Clear file
clearFile()
{
  local filePath=$1;
  if [ -f $filePath ]; then
    logmessage -n "Clear $filePath..\c "; echo -n "">$filePath;
    if [ $(stat -c%s "$filePath" == '0') ]; then
      echo -e $msgOk; else echo -e $msgErr;
    fi;
  fi;
}

 cdAndCheck()
{
   cd "$1"
   if ! [ "$(pwd)" = "$1" ] ; then
      echo "!!Не могу встать в директорию $1 - продолжение невозможно. Выходим." 1>&2
      exit 1
   fi
}

 checkDir()
{
   if ! [ -d "$1" ] ; then
      if [ -z "$2" ] ; then
         echo "!!Нет директории $1 - продолжение невозможно. Выходим." 1>&2
      else
         echo "$2" 1>&2
      fi
      exit 1
   fi
}
checkFile()
{
   if ! [ -f "$1" ] ; then
      if [ -z "$2" ] ; then
         echo "!!Нет файла $1 - продолжение невозможно. Выходим." 1>&2
      else
         echo "$2" 1>&2
      fi
      exit 1
   fi
}

############# helper functions #############
netfilterSetDefault()
{
    if [ -f ${1} ] ; then
        ferm ${1} 1>&2;
    fi;
}
