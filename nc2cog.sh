#!/bin/bash
#
# Description: 
# Converts selected GEOS-CF surface fields to cloud-optimized geotiff files.
# Takes as input argument the year, month, day, and hour of the data of 
# interest, then converts the model surface concentrations of O3, NO2 and 
# PM2.5 for that date&time from the standard netCDF output to geotiff files. 
# A separate geotiff file is generated for each species.
# The original netCDF files are expected to exist locally, with their location 
# and file name defined below. Similarly, the output file location and 
# filename are also specified below.
#
# Example: 
# ./nc2cog.sh 2019 1 1 0
# 
# History:
# 2019/12/19 - christoph.a.keller@nasa.gov - Initial version
##############################################################################

# ---Settings:
year=$1
month=$2
day=$3
hour=$4
# set datestamp
Y=`printf "%04d\n" $year`
M=`printf "%02d\n" $month`
D=`printf "%02d\n" $day`
H=`printf "%02d\n" $hour`
datestamp="${Y}${M}${D}_${H}30z"

# Path with netCDF files
ipath="/discover/nobackup/projects/gmao/geos_cf/pub/GEOS-CF_NRT/ana/Y${Y}/M${M}/D${D}"
# Path to write geotiffs
opath="/discover/nobackup/projects/gmao/geos_cf_dev/cog/tif"

# Define input file
ifile="${ipath}/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.${datestamp}.nc4"
if [ ! -f $ifile ]; then
 echo "Error - file does not exist: ${ifile}"
 exit
fi

# Write all files into temporary directory
if [ ! -d tmpdir ]; then
 /bin/mkdir tmpdir
fi

# Create COG for each species
allspecs=(o3 no2 pm25)
for spec in "${allspecs[@]}"; do
 if [ ${spec} = "o3" ]; then
  ncspec="O3"
 elif [ ${spec} = "no2" ]; then
  ncspec="NO2"
 elif [ ${spec} = "pm25" ]; then
  ncspec="PM25_RH35_GCC"
 fi
 ofile="tmpdir/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.${datestamp}.${spec}.tif"
 gdal_translate -q NETCDF:${ifile}:${ncspec} -of 'Gtiff' -a_srs "+proj=latlong" tmp.tif
 python update_metadata_cog.py -v 0 -i 'tmp.tif' -o 'tmp2.tif' -y $year -m $month -d $day -hr $hour -s $spec 
 gdaladdo -q -r average tmp2.tif 2 4 8 16 32
 gdal_translate -q tmp2.tif ${ofile} -co COMPRESS=LZW -co TILED=YES -co COPY_SRC_OVERVIEWS=YES
 /bin/rm -r tmp.tif tmp2.tif
done

# Move to final location
if [ ! -d $opath ]; then
 echo "Error - cannot move files because main output path does not exist: ${opath}"
 exit
fi
opath="${opath}/Y${Y}/M${M}/D${D}"
if [ ! -d $opath ]; then
 /bin/mkdir -p $opath
fi
# Move files
if [ -d $opath ]; then
 /bin/mv tmpdir/*.tif $opath
else
 echo "Something went wrong, could not move files to final location - they are still in the tmp folder!"
fi
