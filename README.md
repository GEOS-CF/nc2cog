# nc2cog
Convert GEOS-CF netCDF output to cloud optimized geotiff

This repository contains scripts to convert selected GEOS-CF netCDF output (hourly averaged surface concentrations of O3, NO2, and PM2.5) to cloud-optimized geotiff raster images. nc2cog.sh is the main driver routine, which invokes update_metadata_cog.py to clean up the metadata and scale O3 and NO2 by 1.0e9 in order to conver to units of ppbv.
