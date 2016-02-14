#!/bin/bash

BASEPATH=$( cd $(dirname $0); pwd -P);

if [ "$(id -u)" != "0" ]; then
    echo "Root privileges required";
    exit 1;
else
    cp $BASEPATH/config/tox_depends.tar.gz /tmp;

    cd /tmp;

    tar -xf tox_depends.tar.gz;

    cd tox_depends;

    packages=(`find . -name '*.deb'`)

    for package in "${packages[@]}"; do
	dpkg -i -B $package;
    done;

    cd $BASEPATH;

    exit 0;
fi;
