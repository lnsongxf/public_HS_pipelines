# -*- coding: utf-8 -*-
"""
Created on Sun 13 Mar 2016

1. Maps DQ properties into the proper 2010 tract for Geolytics merge

@author: Evan
"""

import os, sys, logging
# Directories
buildPath = r"/home/sweeneri/Projects/Pipelines/build"
dataPath = r"/home/sweeneri/Projects/Pipelines/Data"
os.chdir(r"{}/temp".format(buildPath))
sys.path.insert(0,  r"/home/sweeneri/Projects/Pipelines/utils")

# Start logging
LOG_FILENAME =r"{}/output/logs/dq_to_2010tracts.log".format(buildPath)
try:
    os.remove(LOG_FILENAME)
except OSError:
    pass
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO)

from time import time
import pandas as pd
import pyproj
import rtree
from gisutils import reproject, unify_polyline, ctm_proj
from shapely.geometry import Point, shape
import fiona

def dq_to_tracts(df,spindex,tracts):
    dfnew = df
    dfnew['GEOID10'] = df[['x_ctm','y_ctm']].apply(
                lambda row: pt_poly(row[0], row[1], spindex, tracts),
                axis = 1)
    return dfnew

def pt_poly(x,y,spindex,poly):
    pt = Point(x,y)
    GEO_ID = -99
    for fid in list(index.intersection((x,y,x,y))):
        feat1 = poly[int(fid)]
        geom1 = shape(feat1['geometry'])
        if geom1.contains(pt):
            GEO_ID = feat1['properties']['GEOID10']
            break

    return GEO_ID

if __name__ == '__main__':

    # Filepaths
    tracts_raw = r"{}/GeographicShapefiles/tl_2010_06_tract10.shp".format(dataPath)
    dq_utmCA = r"{}/output/dq_utmCA.dta".format(buildPath)
    outfile = r"{}/output/CA_assess_to_2010tracts.dta".format(buildPath)

    # Temp files
    tracts_prj = r"{}/temp/tl_2010_06_tract10_ctm.shp".format(buildPath)

    # California Transverse Mercator Projection
    # (http://spatialreference.org/ref/sr-org/7098/)
    # Also known as UTM Zone 10.5
    ctm = ctm_proj()

    # Reproject census tracts
    reproject(tracts_raw,tracts_prj,ctm)

    # Now read in reprojected all house locations
    df = pd.read_stata(dq_utmCA)	
                
    logging.info("data projected: creating spatial index")

    # Set up spatial index for tracts
    with fiona.open(tracts_prj) as source:
        index = rtree.index.Index()
        for tract in source:
            fid = int(tract['id'])
            geom = shape(tract['geometry'])
            index.insert(fid, geom.bounds)

        logging.info("spatial index complete")

        # Identify first tract that the property intersects
        dftract=dq_to_tracts(df,index,source)

    logging.info("houses mapped to tracts")

    dftract = dftract[['sr_property_id','GEOID10']].astype(str)
    dftract.to_stata(outfile)

    logging.info("DQ to tract datafile saved")
