#!/bin/sh : script for downloading all files given by 'bash getDL.sh <path/to/filename.txt>
# ** ONLY FOR LINUX **

# THIS COULD BE DONE USING PYTHON for any OS with python env
# TODO: allow this script to download the files from the list to either $pwd or a new location
# USAGE: download to path -> python ./downloadHTTP.txt -o <output/folder/location>
# USAGE: download to pwd -> python ./downloadHTTP.txt

# get cores present in machine
usablecores=$(echo $(nproc --all))

# echo cores being used
echo "Bash: Using $usablecores Cores For Download" && echo

# call wget with multiple processes ignore file that already exist
xargs -n 1 -P $usablecores wget -nc -q < $1