#!/usr/bin/env python
#
#  Description: Update metadata of a geotiff file 
#  History:     12/19/2019 - christoph.a.keller@nasa.gov - Initial version 
##########################################################################
"""
Update geotiff metadata and possibly apply a scale factor to the raster data.

All existing metadata is removed and replaced with selected entries from the 
original file as well as additional information to be specified in an external 
YAML file. This routine is designed to be used for conversion of GEOS-CF netCDF 
output to cloud-optimized geotiff raster files. 
"""

import numpy as np
import yaml
import rasterio
import datetime as dt
import argparse
import os


def main(args):
    '''
    Main driver.
    '''
    # check inputs
    if not os.path.isfile(args.ifile):
        print('Error: input tif file not found: {}'.format(args.ifile))
        return
    if not os.path.isfile(args.yaml_file):
        print('Error: yaml file not found: {}'.format(args.yaml_file))
        return
    # read settings
    with open(args.yaml_file,'r') as f:
        metalist = yaml.load(f, Loader=yaml.FullLoader)
    if args.spec not in metalist.keys():
        print('Warning: no meta data specified for {}'.format(args.spec))
    # read input tif
    src = rasterio.open(args.ifile)
    arr = src.read(1)
    # create output tif
    dst = rasterio.open(args.ofile,'w',driver='Gtiff',height=arr.shape[0],width=arr.shape[1],count=1,dtype=arr.dtype,crs=src.crs,transform=src.transform)
    # eventually scale data
    if args.spec in metalist.keys():
        if 'scal' in metalist[args.spec].keys():
            scal = np.float(metalist[args.spec]['scal'])
            arr  = arr *scal 
    # write data
    dst.write(arr,1)
#---Meta data
    otags = src.tags()
    # Attempt to get dates from original metadata if they are not provided
    if args.year is None or args.month is None or args.day is None or args.hour is None:
        assert('NC_GLOBAL#RangeBeginningDate' in otags.keys())
        bdate = dt.datetime.strptime(otags['NC_GLOBAL#RangeBeginningDate'],'%Y-%m-%d')
        assert('NC_GLOBAL#RangeBeginningTime' in otags.keys())
        btime = dt.datetime.strptime(otags['NC_GLOBAL#RangeBeginningTime'],'%H:%M:%S.000000')
        assert('NC_GLOBAL#RangeEndingDate' in otags.keys())
        edate = dt.datetime.strptime(otags['NC_GLOBAL#RangeEndingDate'],'%Y-%m-%d')
        assert('NC_GLOBAL#RangeEndingTime' in otags.keys())
        etime = dt.datetime.strptime(otags['NC_GLOBAL#RangeEndingTime'],'%H:%M:%S.000000')
        # set datetimes for both dates
        d1 = dt.datetime(bdate.year,bdate.month,bdate.day,btime.hour,btime.minute,btime.second)
        d2 = dt.datetime(edate.year,edate.month,edate.day,etime.hour,etime.minute,etime.second)
        idate = d1+(d2-d1)/2.
        if args.year is None:
            args.year = idate.year 
        if args.month is None:
            args.month = idate.month
        if args.day is None:
            args.day = idate.day
        if args.hour is None:
            args.hour = idate.hour
        if args.minute is None:
            args.minute = idate.minute
    # preserve some original metadata
    dst.update_tags(History='File created on '+dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    dst.update_tags(Contact='geos-cf@lists.nasa.gov')
    if 'NC_GLOBAL#Filename' in otags.keys():
        dst.update_tags(Original_file_name=otags['NC_GLOBAL#Filename'])
    if 'NC_GLOBAL#History' in otags.keys():
        dst.update_tags(Original_file_history=otags['NC_GLOBAL#History'])
    if 'NC_GLOBAL#References' in otags.keys():
        dst.update_tags(References=otags['NC_GLOBAL#References'])
    # additional metadata
    if 'meta' in metalist.keys():
        for k,v in metalist['meta'].items():
            v = v.replace('%y4',str(args.year)).replace('%m2',str(args.month).zfill(2)).replace('%d2',str(args.day).zfill(2)).replace('%h2',str(args.hour).zfill(2)).replace('%n2',str(args.minute).zfill(2))
            tag = {k:v}
            dst.update_tags(**tag)
    # band metadata
    if args.spec in metalist.keys():
        if 'meta' in metalist[args.spec].keys():
            for k,v in metalist[args.spec]['meta'].items():
                v = v.replace('%y4',str(args.year)).replace('%m2',str(args.month).zfill(2)).replace('%d2',str(args.day).zfill(2)).replace('%h2',str(args.hour).zfill(2)).replace('%n2',str(args.minute).zfill(2))
                tag = {k:v}
                dst.update_tags(1,**tag)
    # cleanup 
    src.close()
    dst.close()
    if args.verbose>0:
        print('{} converted to {}'.format(args.ifile,args.ofile))
    return


def parse_args():
    p = argparse.ArgumentParser(description='Undef certain variables')
    p.add_argument('-i','--ifile',type=str,help='input geotif file', default='tmp.tif')
    p.add_argument('-o','--ofile',type=str,help='output geotif file', default='tmp_edit.tif')
    p.add_argument('-s','--spec',type=str,help='species name',default='o3')
    p.add_argument('-c','--yaml-file',type=str,help='YAML file containing metadata information for the file to be created. The key,value pairs must be stored in a dictionary labeled `meta`. Metadata on a band level must have the species name as key label', default='config/cog_meta.yaml')
    p.add_argument('-y','--year',type=int,help='year for timestamp of the data on file',default=None)
    p.add_argument('-m','--month',type=int,help='month for timestamp of the data on file',default=None)
    p.add_argument('-d','--day',type=int,help='day for timestamp of the data on file',default=None)
    p.add_argument('-hr','--hour',type=int,help='hour for timestamp of the data on file',default=None)
    p.add_argument('-mn','--minute',type=int,help='minute for timestamp of the data on file',default=30)
    p.add_argument('-v','--verbose',type=int,help='verbose level', default=0)
    return p.parse_args()


if __name__ == '__main__' :
    main(parse_args())
