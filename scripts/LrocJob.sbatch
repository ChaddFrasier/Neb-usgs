#!/bin/bash
# This script uses a single processor to process a list of files in a batch format
# ISIS -batchlist is serial. This process will take about an hour per file.

# set the job name
#SBATCH --job-name=lunar-serial

# Set a time limit for 72 hour
#SBATCH --time=72:00:00
#SBATCH --partition=longall

# send output to a log file
#SBATCH --output=lunar-serial-test-%j.out      # standard output file; includes job array id ( %j )
#SBATCH --error=lunar-serial-test-%j.err       # standard error file; includes job array id ( %j )

# In this example, we want to run a script that is only using 1 processor for each file
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G  # +2GB

# Send an email when the job begins and ends
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=cfrasier@contractor.usgs.gov

path=/scratch/cfrasier/testing
list_file=../res/ArrayBatch40.lis
path=${path}/proc

# copy the files from the list into the work dir
rsync -a /work/projects/photometry/LROC/WAC/Apollo16/ --files-from=../res/download40.lis ${path}

# call isis
lrowac2isis -batchlist=${list_file} from=${path}/\$1\$2 to=${path}/isis/\$1.cub

spiceinit -batchlist=${list_file} from=${path}/isis/\$1.uv.even.cub
spiceinit -batchlist=${list_file} from=${path}/isis/\$1.uv.odd.cub
spiceinit -batchlist=${list_file} from=${path}/isis/\$1.vis.even.cub
spiceinit -batchlist=${list_file} from=${path}/isis/\$1.vis.odd.cub

# then calibrate
lrowaccal -batchlist=${list_file} from=${path}/isis/\$1.uv.even.cub to=${path}/isis/\$1.uv.even.cal.cub
lrowaccal -batchlist=${list_file} from=${path}/isis/\$1.uv.odd.cub to=${path}/isis/\$1.uv.odd.cal.cub
lrowaccal -batchlist=${list_file} from=${path}/isis/\$1.vis.even.cub to=${path}/isis/\$1.vis.even.cal.cub
lrowaccal -batchlist=${list_file} from=${path}/isis/\$1.vis.odd.cub to=${path}/isis/\$1.vis.odd.cal.cub

# remove unneeded cubs
rm ${path}/isis/*.even.cub
rm ${path}/isis/*.odd.cub

# remove null data
specpix -batchlist=${list_file} from=${path}/isis/\$1.uv.even.cal.cub to=${path}/isis/\$1.uv.even.cal.noneg.cub nullmin=-1.0 nullmax=0.0
specpix -batchlist=${list_file} from=${path}/isis/\$1.uv.odd.cal.cub to=${path}/isis/\$1.uv.odd.cal.noneg.cub nullmin=-1.0 nullmax=0.0
specpix -batchlist=${list_file} from=${path}/isis/\$1.vis.even.cal.cub to=${path}/isis/\$1.vis.even.cal.noneg.cub nullmin=-1.0 nullmax=0.0
specpix -batchlist=${list_file} from=${path}/isis/\$1.vis.odd.cal.cub to=${path}/isis/\$1.vis.odd.cal.noneg.cub nullmin=-1.0 nullmax=0.0

# remove all unneeded cubes
rm ${path}/isis/*.cal.cub

# get map data
cam2map -batchlist=${list_file} from=${path}/isis/\$1.uv.even.cal.noneg.cub map=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub to=${path}/isis/\$1.uv.even.cal.noneg.map.cub interp=bilinear
map2map -batchlist=${list_file} from=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub map=${path}/isis/\$1.uv.even.cal.noneg.map.cub to=${path}/isis/\$1.uv.even.geomap.cub matchmap=TRUE interp=nearestNeighbor

cam2map -batchlist=${list_file} from=${path}/isis/\$1.uv.odd.cal.noneg.cub map=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub to=${path}/isis/\$1.uv.odd.cal.noneg.map.cub interp=bilinear
map2map -batchlist=${list_file} from=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub map=${path}/isis/\$1.uv.odd.cal.noneg.map.cub to=${path}/isis/\$1.uv.odd.geomap.cub matchmap=TRUE interp=nearestNeighbor

cam2map -batchlist=${list_file} from=${path}/isis/\$1.vis.even.cal.noneg.cub map=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub to=${path}/isis/\$1.vis.even.cal.noneg.map.cub interp=bilinear
map2map -batchlist=${list_file} from=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub map=${path}/isis/\$1.vis.even.cal.noneg.map.cub to=${path}/isis/\$1.vis.even.geomap.cub matchmap=TRUE interp=nearestNeighbor

cam2map -batchlist=${list_file} from=${path}/isis/\$1.vis.odd.cal.noneg.cub map=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub to=${path}/isis/\$1.vis.odd.cal.noneg.map.cub interp=bilinear
map2map -batchlist=${list_file} from=/work/projects/photometry/GeoMap/GeoMapUnitsCrop.cub map=${path}/isis/\$1.vis.odd.cal.noneg.map.cub to=${path}/isis/\$1.vis.odd.geomap.cub matchmap=TRUE interp=nearestNeighbor

rm ${path}/isis/*.noneg.cub

# mask the data by geologic unit
mask -batchlist=$list_file mask=${path}/isis/\$1.uv.even.geomap.cub minimum=23 maximum=23 from=${path}/isis/\$1.uv.even.cal.noneg.map.cub to=${path}/isis/\$1.uv.even.cal.noneg.map.unit23.cub
mask -batchlist=$list_file mask=${path}/isis/\$1.uv.even.geomap.cub minimum=39 maximum=39 from=${path}/isis/\$1.uv.even.cal.noneg.map.cub to=${path}/isis/\$1.uv.even.cal.noneg.map.unit39.cub
mask -batchlist=$list_file mask=${path}/isis/\$1.uv.even.geomap.cub minimum=4 maximum=4 from=${path}/isis/\$1.uv.even.cal.noneg.map.cub to=${path}/isis/\$1.uv.even.cal.noneg.map.unit4.cub

mask -batchlist=$list_file mask=${path}/isis/\$1.uv.odd.geomap.cub minimum=23 maximum=23 from=${path}/isis/\$1.uv.odd.cal.noneg.map.cub to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit23.cub
mask -batchlist=$list_file mask=${path}/isis/\$1.uv.odd.geomap.cub minimum=39 maximum=39 from=${path}/isis/\$1.uv.odd.cal.noneg.map.cub to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit39.cub
mask -batchlist=$list_file mask=${path}/isis/\$1.uv.odd.geomap.cub minimum=4 maximum=4 from=${path}/isis/\$1.uv.odd.cal.noneg.map.cub to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit4.cub

mask -batchlist=$list_file mask=${path}/isis/\$1.vis.even.geomap.cub minimum=23 maximum=23 from=${path}/isis/\$1.vis.even.cal.noneg.map.cub to=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.cub
mask -batchlist=$list_file mask=${path}/isis/\$1.vis.even.geomap.cub minimum=39 maximum=39 from=${path}/isis/\$1.vis.even.cal.noneg.map.cub to=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.cub
mask -batchlist=$list_file mask=${path}/isis/\$1.vis.even.geomap.cub minimum=4 maximum=4 from=${path}/isis/\$1.vis.even.cal.noneg.map.cub to=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.cub

mask -batchlist=$list_file mask=${path}/isis/\$1.vis.odd.geomap.cub minimum=23 maximum=23 from=${path}/isis/\$1.vis.odd.cal.noneg.map.cub to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.cub
mask -batchlist=$list_file mask=${path}/isis/\$1.vis.odd.geomap.cub minimum=39 maximum=39 from=${path}/isis/\$1.vis.odd.cal.noneg.map.cub to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.cub
mask -batchlist=$list_file mask=${path}/isis/\$1.vis.odd.geomap.cub minimum=4 maximum=4 from=${path}/isis/\$1.vis.odd.cal.noneg.map.cub to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.cub

# remove unneeded cubs
rm ${path}/isis/*map.cub

# phocube unit 4
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.even.cal.noneg.map.unit4.cub+1 to=${path}/isis/\$1.uv.even.cal.noneg.map.unit4.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.even.cal.noneg.map.unit4.cub+2 to=${path}/isis/\$1.uv.even.cal.noneg.map.unit4.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.uv.odd.cal.noneg.map.unit4.cub+1 to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit4.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.odd.cal.noneg.map.unit4.cub+2 to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit4.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.cub+1 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.cub+2 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.cub+3 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.cub+4 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.cub+5 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit4.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.cub+1 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.cub+2 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.cub+3 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.cub+4 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.cub+5 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit4.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

# phocube unit 23
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.even.cal.noneg.map.unit23.cub+1 to=${path}/isis/\$1.uv.even.cal.noneg.map.unit23.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.even.cal.noneg.map.unit23.cub+2 to=${path}/isis/\$1.uv.even.cal.noneg.map.unit23.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.uv.odd.cal.noneg.map.unit23.cub+1 to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit23.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.odd.cal.noneg.map.unit23.cub+2 to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit23.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.cub+1 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.cub+2 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.cub+3 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.cub+4 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.cub+5 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit23.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.cub+1 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.cub+2 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.cub+3 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.cub+4 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.cub+5 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit23.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

# phocube unit 39
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.even.cal.noneg.map.unit39.cub+1 to=${path}/isis/\$1.uv.even.cal.noneg.map.unit39.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.even.cal.noneg.map.unit39.cub+2 to=${path}/isis/\$1.uv.even.cal.noneg.map.unit39.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.uv.odd.cal.noneg.map.unit39.cub+1 to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit39.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.uv.odd.cal.noneg.map.unit39.cub+2 to=${path}/isis/\$1.uv.odd.cal.noneg.map.unit39.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.cub+1 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.cub+2 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.cub+3 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.cub+4 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.cub+5 to=${path}/isis/\$1.vis.even.cal.noneg.map.unit39.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.cub+1 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.band1.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.cub+2 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.band2.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.cub+3 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.band3.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.cub+4 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.band4.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE
phocube -batchlist=$list_file from=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.cub+5 to=${path}/isis/\$1.vis.odd.cal.noneg.map.unit39.band5.pho.cub dn=TRUE phase=TRUE emission=TRUE incidence=TRUE localEmission=TRUE localIncidence=TRUE latitude=TRUE longitude=TRUE sunAzimuth=TRUE spacecraftAzimuth=TRUE

# remove unneeded cubs
rm ${path}/isis/*.unit39.cub
rm ${path}/isis/*.unit23.cub
rm ${path}/isis/*.unit4.cub

# make a list of phocube files
ls ${path}/isis/*.pho.cub | sed s/.cub// > phofiles.lis

# trim the phocube output to remove values for pixels without valid DN values
bandtrim -batchlist=phofiles.lis from=${path}/isis/\$1.cub to=${path}/isis/\$1.trim.cub

# remove unneeded cubs
rm ${path}/isis/*pho.cub

# save output in ascii format
isis2ascii -batchlist=phofiles.lis from=${path}/isis/\$1.trim.cub to=${path}/isis/text/\$1.trim.txt setpixelvalues=yes nullvalue=-999 lrsvalue=-999 lisvalue=-999 hisvalue=-999

# zip to output path
# TODO: this processes and finished in the same dirrectory
gzip ${path}/isis/M*.cub > ${path}/isis/

# zip to output path
# TODO: this processes and finished in the same dirrectory
gzip ${path}/isis/text/*.txt > ${path}/isis/text/

# remove list of phocubes
rm phofiles.lis