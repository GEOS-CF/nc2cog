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
# ./nc2cog.sh /discover/nobackup/projects/gmao/geos_cf/pub/GEOS-CF_NRT/forecast/Y2020/M02/D22/H12/GEOS-CF.v01.fcst.chm_tavg_1hr_g1440x721_v1.20200222_12z+20200227_1130z.nc4
# 
# History:
# 2019/12/19 - christoph.a.keller@nasa.gov - Initial version
# 2019/02/24 - christoph.a.keller@nasa.gov - Pass filename, distinguish hindcast & forecast 
##############################################################################

# Define input file
ifile=$1
if [ ! -f $ifile ]; then
 echo "Error - file does not exist: ${ifile}"
 exit
fi

# extract filename, prefix, and timestamp 
filename=${ifile##*/} 
prefix=${filename%.*}
timestamp=${prefix##*.}

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
 ofile="tmpdir/${prefix}.${spec}.tif"
 gdal_translate -q NETCDF:${ifile}:${ncspec} -of 'Gtiff' -a_srs "+proj=latlong" tmp.tif
 # update metadata. different for forecast vs hindcast data
 if [[ $timestamp == *"_12z+"* ]]; then
  initialtime=`echo $timestamp | cut -f1 -d+`
  filetime=`echo $timestamp | cut -f2 -d+`
  python update_metadata_cog.py -v 0 -i 'tmp.tif' -o 'tmp2.tif' -t $filetime -f $initialtime -s $spec -c 'config/cog_meta_forecast.yaml'
 else
  filetime=`echo $timestamp`
  python update_metadata_cog.py -v 0 -i 'tmp.tif' -o 'tmp2.tif' -t $filetime -s $spec -c 'config/cog_meta_hindcast.yaml'
 fi
 gdaladdo -q -r average tmp2.tif 2 4 8 16 32
 gdal_translate -q tmp2.tif ${ofile} -co COMPRESS=LZW -co TILED=YES -co COPY_SRC_OVERVIEWS=YES
 /bin/rm -r tmp.tif tmp2.tif
done

