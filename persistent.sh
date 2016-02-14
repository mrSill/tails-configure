#!/bin/bash

## @author    Aliaksandr Sidaruk
## @project   Tails configure persistent
## @copyright 2015 <github.com/mrsill>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/mrsill/tails-configure
## @version   Look in 'tails-setup.sh'

################## config ##################
persistentPkgConfig="/live/persistence/TailsData_unlocked/live-additional-software.conf";
persistentPkg=('apt-transport-https');

cNone='\e[0m'; cYel='\e[1;33m'; cRed='\e[1;31m';

echo -e "${cYel}Hint${cNone}: This is an experimental feature which does not appear in the assistant.\n";

echo "When this feature is enabled, a list of additional software of your choice is automatically installed \
at the beginning of every working session. The corresponding software packages are stored in the persistent \
volume. They are automatically upgraded for security after a network connection is established.";

echo -e "${cYel}Hint${cNone}: To use this feature you need to enable both the APT Lists and APT Packages features.\n";

echo -e "If you are offline and your additional software packages ${cRed}don't install${cNone}, it might be caused by \
outdated APT Lists. The issue will be fixed next time you connect Tails to Internet with persistence activated.\n";

for package in "${persistentPkg[@]}"; do
    if [ "$(id -u)" != "0" ]; then
	echo "${package}" | sudo tee ${persistentPkgConfig} >/dev/null 2>&1;
    else
	echo "${package}" | tee ${persistentPkgConfig} >/dev/null 2>&1;
    fi;
done;

echo -e "\n${cGray}Persistent package list:${cNone}\n";

if [ "$(id -u)" != "0" ]; then
    sudo cat ${persistentPkgConfig};
else
    cat ${persistentPkgConfig};
fi;
