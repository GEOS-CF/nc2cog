#/bin/bash
#
# DESCRIPTION:
# Generate cloud optimized geotiffs for the GEOS-CF analysis on the specified day.
# The files from 1230z of the previous day to 1130z of the specified day will be used.
# 
# EXAMPLE:
# ./nc2cog_run_hindcast.sh 20190101

# settings
collection="GEOS-CF.v01.rpl.chm_tavg_1hr_g1440x721_v1"
rootdir="/discover/nobackup/projects/gmao/geos_cf/pub/GEOS-CF_NRT/ana"
outpath="/discover/nobackup/projects/gmao/geos_cf_dev/cog/tif/hindcast"

# Extract date
tYmd=$1
tY=`echo ${tYmd} | cut -c1-4`
tM=`echo ${tYmd} | cut -c5-6`
tD=`echo ${tYmd} | cut -c7-8`

# Also need previous day
thisday="${tY}-${tM}-${tD}"
prevday=$(/bin/date -I -d "$thisday - 1 day")
pYmd=$(/bin/date -d "${prevday}" +%Y%m%d)
pY=`echo ${pYmd} | cut -c1-4`
pM=`echo ${pYmd} | cut -c5-6`
pD=`echo ${pYmd} | cut -c7-8`

# Previous day analysis, 12z forward
for hour in {12..23}; do
 H=`printf "%02d\n" $hour`
 ifile="${rootdir}/Y${pY}/M${pM}/D${pD}/${collection}.${pYmd}_${H}30z.nc4"
 printf "working on ..${ifile}"
 /discover/nobackup/projects/gmao/geos_cf_dev/cog/nc2cog/nc2cog.sh $ifile
 printf "\n"
 # move to final location
 opath="${outpath}/Y${pY}/${pYmd}"
 if [ ! -d $opath ]; then
  /bin/mkdir -p $opath
 fi
 # Move files
 if [ -d $opath ]; then
  /bin/mv /discover/nobackup/projects/gmao/geos_cf_dev/cog/nc2cog/tmpdir/*.tif $opath
 else
  echo "Something went wrong, could not move files to final location - they are still in the tmp folder!"
 fi
done

# Current day analysis, up to 12z 
for hour in {0..11}; do
 H=`printf "%02d\n" $hour`
 ifile="${rootdir}/Y${tY}/M${tM}/D${tD}/${collection}.${tYmd}_${H}30z.nc4"
 printf "working on ..${ifile}"
 /discover/nobackup/projects/gmao/geos_cf_dev/cog/nc2cog/nc2cog.sh $ifile
 printf "\n"
 # move to final location
 opath="${outpath}/Y${tY}/${tYmd}"
 if [ ! -d $opath ]; then
  /bin/mkdir -p $opath
 fi
 # Move files
 if [ -d $opath ]; then
  /bin/mv /discover/nobackup/projects/gmao/geos_cf_dev/cog/nc2cog/tmpdir/*.tif $opath
 else
  echo "Something went wrong, could not move files to final location - they are still in the tmp folder!"
 fi
done

exit
