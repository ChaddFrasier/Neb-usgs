#!/bin/sh : script for downloading all files given by 'bash getDL.sh <path/to/filename.txt>
# ** ONLY FOR LINUX **

# get cores present in machine
usablecores=$(echo $(nproc --all))

# echo cores being used
echo "Bash: Using $usablecores Cores For Download" && echo

# move to $LUNARDATA path and then call wget with multiple processes ignore file that already exist
cd $LUNARDATA && xargs -n 1 -P $usablecores wget -nc -q < $1