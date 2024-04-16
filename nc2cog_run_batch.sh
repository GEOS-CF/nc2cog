#!/bin/bash
#SBATCH --time=03:00:00
#SBATCH --ntasks=1
#SBATCH --job-name=nc2cog
#SBATCH --account=s1866
#SBATCH --qos=chmdev

# Wrapper script to convert GEOS-CF netCDF output to cloud-optimized geotiffs.

# load modules
module use -a /home/mathomp4/modulefiles
module load python/GEOSpyD/Ana2019.10_py3.7

# set startdate and enddate
d=2020-01-01
end=2020-02-25

# loop over all days
while [ "$d" != $end ]; do
 Ymd=$(date -d "$d" +%Y%m%d)
 ./nc2cog_run_hindcast.sh $Ymd
 # go to next day
 d=$(date -I -d "$d + 1 day")
done

