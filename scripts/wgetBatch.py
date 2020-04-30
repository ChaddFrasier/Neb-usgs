#`
# File: wgetBatch.py
# Desc: uses argparser to download a list of files from an http source using wget. Can be downloaded into the
#  current directory or you can designate a download folder to place the files in the list.
# `
import os
import platform
import argparse

# Arg usage:
# python wgetBatch.py <path/to/input>
# or
# python wgetBatch.py <path/to/input> -o <path/to/output>
def main():
    # Init argparser
    args = argparse.ArgumentParser(description="Download Files using wget to a specified path")

    # add the path to the download file
    args.add_argument("input_file", help="The file that contains http download links")

    # add the argument for output path
    args.add_argument("-o", metavar="O", help='The output folder path', default='.')

    # parse the input string from the script
    argv = args.parse_args()

    # get the number of active CPUs
    cpu_count = os.cpu_count()

    print(platform.system())

    # run the download command depending on the OS
    if( platform.system() == "Linux"):
        # Linux OS
        # call wget with multiple processes ignore file that already exist
        os.system( "xargs -n 1 -P " + str(cpu_count) + " wget -nc -q < " +  str(argv.input_file) )
        return 0
    elif( platform.system() == "Windows" ):
        # Windows OS
        # TODO: find the command to download in parallel on windows
        print("RUN SOME COMMAND TO DOWNLOAD THE FILES ON WINDOWS OS")
        return 0
    elif( platform.system() == "Darwin" ):
        # Mac OS
        # TODO: find the command to download in parallel on MAC

        print("RUN SOME COMMAND TO DOWNLOAD THE FILES ON MAC OS")
        return 0
    else:
        # return unknown error
        print("Unknown OS")
        return -1

if __name__ == "__main__":
    status = main()
    print("Status from script run is:", status )