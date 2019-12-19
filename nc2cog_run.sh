#!/bin/bash
#SBATCH --time=06:00:00
#SBATCH --ntasks=1
#SBATCH --job-name=nc2cog
#SBATCH --account=s1866
#SBATCH --qos=chmdev

# Wrapper script to convert GEOS-CF netCDF output to cloud-optimized geotiffs.

# load modules
module use -a /home/mathomp4/modulefiles
module load python/GEOSpyD/Ana2019.10_py3.7

# set startdate and enddate
d=2019-02-20
end=2019-03-01

# loop over all days
while [ "$d" != $end ]; do
 year=$(date -d "$d" +%Y)
 month=$(date -d "$d" +%_m)
 day=$(date -d "$d" +%_d)
 echo "working on $(date -d "$d" +%F) ..."
 # create cog files for every hour of the day
 for ihr in {0..23}; do
  printf "..${ihr}"
  ./nc2cog.sh $year $month $day $ihr
 done
 printf "\n"
 # go to next day
 d=$(date -I -d "$d + 1 day")
done
