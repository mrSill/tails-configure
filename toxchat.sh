#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure
## @package   Tox
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'tails-setup.sh'

readonly _PATH_=$( cd $(dirname $0); pwd -P);  # Current path

inc=$_PATH_/functions ; source "$inc" ; if [ $? -ne 0 ] ; then echo "Fatal error! $inc not found" 1>&2 ; exit 1 ; fi ;
getSettings $_PATH_/config/default.conf;

readonly TOX_HOMEPATH='/home/amnesia/.config/tox';
readonly TOX_PERSISTANCEHOMEPATH=$PERSISTENCE/dotfiles/.config/tox;

################ parameters ################
readonly defaultClient='qtox';
readonly silent=false;

client=$defaultClient;

############## helper functions ############
toxModuleHelloMessage()
{
    if [[ "${silent}" == false ]]; then
        echo "Tox is easy-to-use software that connects you with friends and family \
without anyone else listening in. While other big-name services require you to \
pay for features, Tox is completely free and comes without advertising — forever.";
        echo "";
        echo -e "${cGray}Tox Clients:${cNone}";
        echo "------------";
        echo -e "${cGray}qTox${cNone}: A Qt graphical user interface for Tox, written by tux3.";
        echo "";
        echo -e "${cGreen}uTox${cNone}: µTox is the lightweight client with minimal dependencies; \
it not only looks pretty, it runs fast!";
        echo "";
        echo -e "${cBlue}Toxic${cNone}: Toxic is a client with an ncurses interface, \
written entirely in C. It has support for all basic features, as well as 1-on-1 \
audio/video chats, and is capable of working on bare-bones systems that lack \
graphical interfaces.\n\n";
    fi;
}
toxModuleCheckInstalledClients()
{
    local existToxClients=[qtox utox toxic];

    for toxClient in "${existToxClients[@]}"; do
        if which toxClient 1>&2; then
            echo "${toxClient} - is exist in your system. Use: ${toxClient} to run it.";
            client=$toxClient;
        fi;
    done;
}
selectToxClient()
{
    local answer=$1;

    if [[ "${answer}" = "u" ]]; then
        client="utox";
    elif [[ "${answer}" = "t" ]]; then
        client="toxic";
    else
        client=$defaultClient;
    fi;

    return $client;
}
setToxSource()
{
    local toxSourceHost="tor+https://pkg.tox.chat/debian";
    local toxSourceDistridution='nightly';
    local toxSourceComponent='release';
    local toxSourceKeyHost="https://pkg.tox.chat/debian";
    local toxSourceGpgKey="pkg.gpg.key";

    # May be first run apt-get update)
    #echo "Update APT sources index...";
    #sudo apt-get update 1>&2;

    echo "Add tox source file to your system..."
    if aptAddSource 'tox.list' $toxSourceHost $toxSourceDistridution $toxSourceComponent; then
        echo "Add tox GPG key..."
        if aptAddKey $toxSourceKeyHost $toxSourceGpgKey; then
            return 0;
        else 
            echo "Unabe to add GPG key Tox sources";
            return 1;
        fi;
    else
        echo "Unabe to add Tox source file";
        return 1;
    fi;
}
downloadToxPackage()
{
    local packageName=$1;
    
    echo "Update list of packages...";
    sudo apt-get update 2>&1;
    echo -n "Download ${packageName}...";
    apt-get download ${packageName} 1>&2
    if [ $? -ne 0 ] ; then
        echo -e "${cRed}fail${cNone}";
        return 1;
    else
        echo -e "${cGreen}complete${cNone}.";
        return 0;
    fi;
}
qToxConfigure()
{
    local qToxConfig="${TOX_HOMEPATH}/qtox.ini";

    ## check tox config dir
    if ! [ -d "$TOX_HOMEPATH" ] ; then
        ## create tox dir
        createDir "${TOX_HOMEPATH}";
    fi;

    if ! [ -f qToxConfig ] ; then
        cp $BASEPATH/config/qtox.ini $TOX_HOMEPATH/qtox.ini;
    else
        cat $qToxConfig | sed 's/^proxyAddr=.*/proxyAddr=127.0.0.1/g' > $qToxConfig;
        cat $qToxConfig | sed 's/^proxyPort=.*/proxyAddr=9050/g' > $qToxConfig;
        cat $qToxConfig | sed 's/^proxyType=.*/proxyAddr=1/g' > $qToxConfig;
    fi;

    if isRoot; then
        chown -R amnesia:amnesia $TOX_HOMEPATH;
    fi;
}
persistanceToxSettings()
{
    ## check tox config dir
    if ! [ -d "$TOX_HOMEPATH" ] ; then
        if ! [ -d "${TOX_PERSISTANCEHOMEPATH}" ] ; then
            ## create tox dir
            createDir "${TOX_PERSISTANCEHOMEPATH}";
        fi;
    else
        if ! [ -d "${TOX_PERSISTANCEHOMEPATH}" ] ; then
             ## move exist tox dir
            cp $TOX_HOMEPATH /live/persistence/TailsData_unlocked/dotfiles/.config/ 2>&1;
        fi;
    fi;
}
############################################

if isRoot; then
    clientName=$1;

    cd $PATHTOSAVE 1>&2;
    package=$(find $clientName*.deb) &>/dev/null;

    if [ -f $PATHTOSAVE/$package ]; then
        echo -n "Install package ${package}";
        dpkg -i $PATHTOSAVE/$package &>$LOGFILE;
        echo -e "${cGreen}Complete${cNone}";    

        echo "Install tox depends packages...";
        apt-get install -f 1>&2;

        configureNetfilter udp 33445;
        exit 0;
    else
        echo "${clientName} package not found. ";

        askYNE "Install tox with internet?";
        sudo apt-get -f install ${clientName};
    fi;
else
    toxModuleHelloMessage;

    toxModuleCheckInstalledClients;

    echo "Select Tox package to install. Current select: ${client}.";
    echo -e -n "Available clients: ${cGray}[q] - qTox${cNone}/\
${cGeen}u - uTox${cNone}/${cBlue}t - Toxic:${cNone}";
    read -n 1 answer;
    selectToxClient $answer; #setup client var;

    #if which client 1>&2; then
    #    echo "${client} alredy exist. Use: $${client} to run it.";
    #    askYNE "Reinstall/upgrade installed tox client?";
    #fi;

    #cd $PATHTOSAVE 1>&2;

    #package=$(`find $client*.deb`);

    if find $PATHTOSAVE/$client*.deb &>/dev/null ; then
        echo "Setting up APT sources. To continue, you need root";
        setToxSource;

        echo "All done to download ${client} package..."
        sayWait;
        downloadToxPackage $client;
    else
        echo "Found local saved copy ${client} install package \
(`find ${PATHTOSAVE}/${client}*.deb`).";
        hint "If not will install this package, manualy delete this file";
    fi;

    askYNE "Who will install the package ${client} (to continue, you need root)?";

    sudo $BASEPATH/toxchat.sh $client;

    if [[ "${client}" == qtox ]] ; then
        qToxConfigure;
    fi;

    askYNE "Tox alredy install. Save tox settings to persistance?:";
    persistanceToxSettings
fi;

exit 0;

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