#!/bin/bash
# Wrapper script to generate cloud-optimized geotiff files for the latest GEOS-CF analyses and forecasts.
# This script is called from a cron-script once a day!

if [[ $# -eq 0 ]]; then
 DOFFSET=1
else
 DOFFSET=$1
fi
Y=$(/bin/date -d "-${DOFFSET} day" +%Y)
M=$(/bin/date -d "-${DOFFSET} day" +%m)
D=$(/bin/date -d "-${DOFFSET} day" +%d)
Ymd=$(/bin/date -d "-${DOFFSET} day" +%Y%m%d)

echo "Starting nc2cog_run_daily.sh..."
echo $Ymd

# Create hindcast files
/discover/nobackup/projects/gmao/geos_cf_dev/cog/nc2cog/nc2cog_run_hindcast.sh $Ymd

# Create forecast files
/discover/nobackup/projects/gmao/geos_cf_dev/cog/nc2cog/nc2cog_run_forecast.sh $Ymd

# Move latest hindcasts to aws
odir="/discover/nobackup/projects/gmao/geos_cf_dev/cog/tif/hindcast/latest"
idir="/discover/nobackup/projects/gmao/geos_cf_dev/cog/tif/hindcast/Y${Y}/${Ymd}"
if [ -d ${idir} ]; then
 /bin/rm -f ${odir}/*
 ifile="${idir}/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.${Ymd}_1130z.no2.tif"
 if [ -e ${ifile} ]; then
  /bin/cp ${ifile} "${odir}/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.latest.no2.tif"
 fi
 ifile="${idir}/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.${Ymd}_1130z.o3.tif"
 if [ -e ${ifile} ]; then
  /bin/cp ${ifile} "${odir}/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.latest.o3.tif"
 fi
 ifile="${idir}/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.${Ymd}_1130z.pm25.tif"
 if [ -e ${ifile} ]; then
  /bin/cp ${ifile} "${odir}/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.latest.pm25.tif"
 fi
 if [ -e ${odir}/GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1.latest.pm25.tif ]; then
  /home/cakelle2/bin/aws s3 rm s3://dh-eis-fire-usw2-shared/geos-cf-cog/latest/ --recursive
  /home/cakelle2/bin/aws s3 sync ${odir}/ s3://dh-eis-fire-usw2-shared/geos-cf-cog/latest/ --acl bucket-owner-full-control
 fi
 # also sync date-indexed files 
 /home/cakelle2/bin/aws s3 sync /discover/nobackup/projects/gmao/geos_cf_dev/cog/tif/hindcast/Y${Y}/ s3://dh-eis-fire-usw2-shared/geos-cf-cog/Y${Y}/ --acl bucket-owner-full-control 
fi

echo $Ymd
echo "All done!"
