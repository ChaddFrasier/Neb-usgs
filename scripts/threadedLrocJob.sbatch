#!/bin/bash
# This script demonstrates how to call ISIS functions on more than 1 file and have each file be processed on a different core
# this process is much faster than the LrocJob.sbatch files because this script utilizes multithreading to process each file
# faster than using a single processing core.

# Nebula Config
# -------------
# set the job name
#SBATCH --job-name=lunar-thread

# Set a time max to 50 Days
#SBATCH --time=50-00:00:00
#SBATCH --partition=longall

# send output to a log file
#SBATCH --output=lunar-thread-test-%j.out      # standard output file; includes job array id,  array index, and node name in filename
#SBATCH --error=lunar-thread-test-%j.err       # standard error file; includes job array id, array index, and node name in filename

# -- THIS IS WHERE THE CORES ARE CONFIGURED --
#SBATCH --nodes=1                           # Use 1 processing node
#SBATCH --ntasks-per-node=1                 # Allow only 1 file per node
#SBATCH --cpus-per-task=4                   # give the node 4 cores to use

# give +2GB of memory to the cpus from the default ( default = 2GB )
#SBATCH --mem-per-cpu=4G

# Send an email when the job begins and ends.
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=cfrasier@contractor.usgs.gov
# -------------

# init env variables
path=/scratch/cfrasier/live
proc=${path}/proc

# set ouptut path to isis/ and isis/text folders
output=/work/projects/photometry/LROC/WAC/Apollo16

# copy the files from Apollo16 into the work dir
rsync -a /work/projects/photometry/LROC/WAC/Apollo16/ --files-from=../res/download40.lis ${proc}

# make a list of all the images that need to be processed and pipe the list to the parallel command
ls ${proc}/*IMG | parallel "lrowac2isis from={} to={//}/isis/{/.}.cub"
# init data for all cubs in the isis folder using pipe
ls ${proc}/isis/*.cub | parallel "spiceinit from={}"
# then calibrate using same names list
ls ${proc}/isis/*.cub | parallel "lrowaccal from={} to={//}/{/.}.cal.cub"

# remove the uneeded files
rm ${proc}/isis/*even.cub
rm ${proc}/isis/*odd.cub

# find all cal.cub's and then pipe the list to the parallel function to run ISIS specpix
ls ${proc}/isis/*.cal.cub | parallel "specpix from={} to={//}/{/.}.noneg.cub nullmin=-1.0 nullmax=0.0"

# remove the uneeded files
rm ${proc}/isis/*.cal.cub

# call the map phase
ls ${proc}/isis/*.noneg.cub | parallel "cam2map from={} map=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub to={//}/{/.}.map.cub interp=bilinear"
ls ${proc}/isis/*.map.cub | parallel "map2map from=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub map={} to={//}/{/.}.geomap.cub matchmap=TRUE interp=nearestNeighbor"

# remove the uneeded cubes+
rm ${proc}/isis/*.noneg.cub

# list the geomaps by band and then call mask for each file on the 3 bands
ls ${proc}/isis/*.geomap.cub| sed 's|\(.*\)noneg.*|\1|' | parallel "mask mask={//}/{/.}noneg.map.geomap.cub minimum=4 maximum=4 from={//}/{/.}noneg.map.cub to={//}/{/.}noneg.map.unit4.cub"
ls ${proc}/isis/*.geomap.cub| sed 's|\(.*\)noneg.*|\1|' | parallel "mask mask={//}/{/.}noneg.map.geomap.cub minimum=23 maximum=23 from={//}/{/.}noneg.map.cub to={//}/{/.}noneg.map.unit23.cub"
ls ${proc}/isis/*.geomap.cub| sed 's|\(.*\)noneg.*|\1|' | parallel "mask mask={//}/{/.}noneg.map.geomap.cub minimum=39 maximum=39 from={//}/{/.}noneg.map.cub to={//}/{/.}noneg.map.unit39.cub"

# remove unneeded cubs
rm ${proc}/isis/*map.cub

# crop as much as possible
# all unit 4
ls ${proc}/isis/*unit4.cub | parallel "cropspecial from={} to={//}/{/.}.crop.cub"
# all unit 23
ls ${proc}/isis/*unit23.cub | parallel "cropspecial from={} to={//}/{/.}.crop.cub"
# all unit 39
ls ${proc}/isis/*unit39.cub | parallel "cropspecial from={} to={//}/{/.}.crop.cub"

# remove unneeded cubs
rm ${proc}/isis/*unit23.cub
rm ${proc}/isis/*unit39.cub
rm ${proc}/isis/*unit4.cub

# run the function on all uv unit 4 cubs -> run phocube for each cube that is found. Loop 2 times calling it both times band 1 and 2
ls ${proc}/isis/*uv.*unit4.crop.cub | parallel "phocube from={}+1 to={//}/{/.}.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*uv.*unit4.crop.cub | parallel "phocube from={}+2 to={//}/{/.}.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"

# find all vis.*.unit4 cubs and pipe list to the phocube function 5 times for all five bands
ls ${proc}/isis/*vis.*unit4.crop.cub | parallel "phocube from={}+1 to={//}/{/.}.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit4.crop.cub | parallel "phocube from={}+2 to={//}/{/.}.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit4.crop.cub | parallel "phocube from={}+3 to={//}/{/.}.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit4.crop.cub | parallel "phocube from={}+4 to={//}/{/.}.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit4.crop.cub | parallel "phocube from={}+5 to={//}/{/.}.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"

# unit 23s
ls ${proc}/isis/*uv.*unit23.crop.cub | parallel "phocube from={}+1 to={//}/{/.}.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*uv.*unit23.crop.cub | parallel "phocube from={}+2 to={//}/{/.}.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"

# find all vis.*.unit4 cubs and pipe list to the phocube function 5 times for all five bands
ls ${proc}/isis/*vis.*unit23.crop.cub | parallel "phocube from={}+1 to={//}/{/.}.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit23.crop.cub | parallel "phocube from={}+2 to={//}/{/.}.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit23.crop.cub | parallel "phocube from={}+3 to={//}/{/.}.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit23.crop.cub | parallel "phocube from={}+4 to={//}/{/.}.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit23.crop.cub | parallel "phocube from={}+5 to={//}/{/.}.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"

# unit 39s
ls ${proc}/isis/*uv.*unit39.crop.cub | parallel "phocube from={}+1 to={//}/{/.}.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*uv.*unit39.crop.cub | parallel "phocube from={}+2 to={//}/{/.}.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"

# find all vis.*.unit4 cubs and pipe list to the phocube function 5 times for all five bands
ls ${proc}/isis/*vis.*unit39.crop.cub | parallel "phocube from={}+1 to={//}/{/.}.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit39.crop.cub | parallel "phocube from={}+2 to={//}/{/.}.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit39.crop.cub | parallel "phocube from={}+3 to={//}/{/.}.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit39.crop.cub | parallel "phocube from={}+4 to={//}/{/.}.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"
ls ${proc}/isis/*vis.*unit39.crop.cub | parallel "phocube from={}+5 to={//}/{/.}.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE"

# remove uneeded cubs
rm ${proc}/isis/*crop.cub

# running bandtrim on which ever files made it through
ls ${proc}/isis/*.pho.cub | parallel "bandtrim from={} to={//}/{/.}.trim.cub"

# remove phocube output
rm ${proc}/isis/*.pho.cub

# running the ascii extraction to text file in folder text
ls ${proc}/isis/*.trim.cub | parallel "isis2ascii from={} to={//}/text/{/.}.txt setpixelvalues=yes nullvalue=-999 lisvalue=-999 hisvalue=-999"

# zip all cubes to the output folder
ls ${proc}/isis/*.cub | parallel "gzip -c {}  > ${output}/isis/{/.}.cub.gz"
ls ${proc}/isis/text/*.txt | parallel "gzip -c {}  > ${output}/isis/text/{/.}.txt.gz"
