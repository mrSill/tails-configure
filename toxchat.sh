#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure tox
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'bootstrap.sh'

inc=$(dirname $0)/functions ; source "$inc" ; if [ $? -ne 0 ] ; then echo "Fatal error! $a1 not found" 1>&2 ; exit 1 ; fi ;

################## config ##################
getSettings $(dirname $0)/config/default.conf;

toxPkgDepends='libc6-dev_2.19-22_i386.deb';
toxHome="/home/amnesia/.config/tox";
toxHomePersistence="/live/persistence/TailsData_unlocked/dotfiles/.config/tox";

################ parameters ################
defaultInstall="qtox";
#DEPRECATED
defaultToxPackage="qtox";
offline=false;

configureNetfilter()
{
    #allow traffic going specific outbound ports
    iptables -A OUTPUT -p udp --dport 33445 -j ACCEPT;
    iptables -A INPUT -p udp --sport 33445 -j ACCEPT;
}
setToxSource()
{
    local toxPkgHost="https://pkg.tox.chat/debian";
    local toxPkgKey="/pkg.gpg.key";

    sudo apt-get update 1>&2;

    echo "deb ${toxPkgHost} nightly release" | sudo tee /etc/apt/sources.list.d/tox.list 1>&2
    sudo chmod 655 /etc/apt/sources.list.d/tox.list;
    wget -qO - ${toxPkgHost}/${toxPkgKey} | sudo apt-key add - 1>&2;
    sudo apt-get -y install apt-transport-https 1>&2;
}
downloadToxPackage()
{
    local packageName=$1;
        sudo torsocks apt-get update 1>&2;

        echo -n "Download ${defaultInstall}...";
        torsocks apt-get download ${packageName} 1>&2
        echo -e "${cGreen}complete${cNone}.";
}
qToxConfigure()
{
    local qToxConfig="${toxHome}/qtox.ini";

    ## check tox config dir
    if ! [ -d "$toxHome" ] ; then
        ## create tox dir
        createDir "${toxHome}";
    fi;

    if ! [ -f qToxConfig ] ; then
        cp $BASEPATH/config/qtox.ini $toxHome/qtox.ini;
    else
        cat $qToxConfig | sed 's/^proxyAddr=.*/proxyAddr=127.0.0.1/g' > $qToxConfig;
        cat $qToxConfig | sed 's/^proxyPort=.*/proxyAddr=9050/g' > $qToxConfig;
        cat $qToxConfig | sed 's/^proxyType=.*/proxyAddr=1/g' > $qToxConfig;
    fi;

    if [[ "$(id -u)" == 0 ]]; then
        chown -R amnesia:amnesia $toxHome;
    fi;
}

if [ "$(id -u)" != "0" ]; then
    echo -e -n "Select installing Tox package: ${cGray}[q] - qTox (default)${cNone}/${cGeen}u - uTox${cNone}:";
    read -n 1 answer;

    if [[ "${answer}" = "q" ]]; then
        defaultInstall="qtox";
    fi;

    logmessage -n "Check saved packages...";
    cd $pathToSave 1>&2;

    #echo -e -n " - check depend package libc6..."
    #find libc6*.deb >/dev/null;

    #if [ $? -ne 0 ] ; then
    #    echo -e -n "${cRed}not found${cNone}. Downloading libc6...";
    #    apt-get -t jessie download libc6 1>&2;
    #    echo -e "${cGreen}complete${cNone}.";
    #else
    #    echo -e -n "${cGreen}found${cNone} (";
    #    echo "`find libc6*.deb`)";
    #fi;

    echo -e -n " - check ${defaultInstall} package..."
    find ${defaultInstall}*.deb >/dev/null;

    if [ $? -ne 0 ] ; then
        echo -e "${cRed}not found${cNone}.";
        echo "Setting up APT sources. To continue, you need root";

        setToxSource;
        #sudo ferm $BASEPATH/ferm.conf;

        sayWait;

        downloadToxPackage $defaultInstall;
    else
        echo -e -n "${cGreen}found${cNone} (";
        echo "`find ${defaultInstall}*.deb`)";
    fi;

    askYNE "Who will install the package ${defaultInstall}. To continue, you need root";

    sudo $BASEPATH/toxchat.sh $defaultInstall;

    if [[ "${defaultInstall}" == qtox ]] ; then
        qToxConfigure;
    fi;

    askYNE "Tox alredy install. Save tox settings to persistance?:";

    ## check tox config dir
    if ! [ -d "$toxHome" ] ; then
        if ! [ -d "${toxHomePersistence}" ] ; then
            ## create tox dir
            createDir "${toxHomePersistence}";
        fi;
    else
        if ! [ -d "${toxHomePersistence}" ] ; then
             ## move exist tox dir
            cp $toxHome /live/persistence/TailsData_unlocked/dotfiles/.config/ 2>&1;
        fi;
    fi;

    if ! [ -e "$toxHome" ] ; then
        if [ -d "${toxHomePersistence}" ] ; then
            ## create symlink config dir
            ln -s "${toxHomePersistence}" ~/.config 2>&1;
            logmessage -n "Tox config saved in persistence volume"
        fi;
    fi;

else
    defaultInstall=$1;
    echo -n "Install depend package: ${package}..";
    apt-get -t jessie -y install libc6 2>&1;
    $BASEPATH/toxdepends.sh;
    echo -e "${cGreen}Complete${cNone}";

    package=$(find $defaultInstall*.deb 2>&1);
    if [ -f $pathToSave/$package ]; then
        echo -n "Install package ${package}";
        dpkg -i $pathToSave/$package 2>&1;
        echo -e "${cGreen}Complete${cNone}";

        echo -n "Configure netfilter";
        configureNetfilter;
        echo -e "${cGreen}Complete${cNone}";
        exit 0;
    else
        logmessage -n "Tox package not found. ";
        exit 1;
        ## apt-get installing
    fi;
fi;

exit 1;

########## parse input parameters ##########
while [ $# -ge 1 ] ; do
    if [ ${1} = "--qtox" ] ; then
        defaultToxPackage="qtox";
        shift;
    elif [ ${1} = "--offline" ] ; then
        offline=true;
        shift;
    else
        if [ ${1} = "-h" -a ${1} = "--help" ] ; then
            # print help
            echo "Use this script to install/update Tox chat"
            echo ""
            echo "usage:"
            echo "    ${0} PARAMETERS"
            echo ""
            echo "parameters:"
            echo "    --qtox                 : install qTox (default installing uTox)"
            echo "    --offline              : don't use apt-get, installing with local copied packages"
            echo "    -h|--help              : displays this help"

            echo "    -k|--keep              : keep files after installation/update"
            echo ""
            echo "example usages:"
            echo "    ${0}    -- install utox"
            exit 1
        else
            break;
        fi;
    fi;
done;
