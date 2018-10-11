#!/bin/bash

#
# release-cli comes from https://github.com/caicloud/rudder, we use following command to get it:
# $ go get -u github.com/caicloud/rudder/cmd/release-cli
# 
# Notice:
# *everytime* met error the script will exit.
#

function getdir() {
    for element in `ls $1`
    do  
        dir=$1"/"$element
        if [ -d $dir ]
        then 
            getdir $dir
        else
            release-cli lint -c $dir -t hack/lint/charts/templates/1.0.0 -s hack/lint/standard.yaml 2>stderr.txt
            if [ $? -ne 0 ] || [ -s stderr.txt ]
            then  
                echo "Error lint, please check following chart:"
                echo "-----------------------------------------"
                echo $dir
                echo "-----------------------------------------"
                cat stderr.txt
                exit 1
            fi
        fi  
    done
}

ADDONS_PATH=$1

if [ -d $1 ]
then
    getdir $ADDONS_PATH
    echo "Successfully lint directory $1."
else
    echo "Directory $1 not exists."
fi

if [ -f stderr.txt ]
then
  rm stderr.txt
fi
