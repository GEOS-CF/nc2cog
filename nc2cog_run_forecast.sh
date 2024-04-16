#/bin/bash

# DESCRIPTION:
# Generate cloud optimized geotiffs for the GEOS-CF forecasts initialized on the specified day.
# 
# EXAMPLE:
# ./nc2cog_run_forecast.sh 20190101

# settings
collection="GEOS-CF.v01.fcst.chm_tavg_1hr_g1440x721_v1"
rootdir="/discover/nobackup/projects/gmao/geos_cf/pub/GEOS-CF_NRT/forecast"
outpath="/discover/nobackup/projects/gmao/geos_cf_dev/cog/tif/forecast"

# Extract dates
Ymd=$1
Y=`echo ${Ymd} | cut -c1-4`
M=`echo ${Ymd} | cut -c5-6`
D=`echo ${Ymd} | cut -c7-8`

# create cog files for every file. Will be saved in temporary directory. 
ipath="${rootdir}/Y${Y}/M${M}/D${D}/H12"
for ifile in ${ipath}/${collection}*.nc4; do
 printf "working on ..${ifile}"
 /discover/nobackup/projects/gmao/geos_cf_dev/cog/nc2cog/nc2cog.sh $ifile
 printf "\n"
done

# move to final location
opath="${outpath}/Y${Y}/${Ymd}"
if [ ! -d $opath ]; then
 /bin/mkdir -p $opath
fi
# Move files
if [ -d $opath ]; then
 /bin/mv /discover/nobackup/projects/gmao/geos_cf_dev/cog/nc2cog/tmpdir/*.tif $opath
else
 echo "Something went wrong, could not move files to final location - they are still in the tmp folder!"
fi

exit
