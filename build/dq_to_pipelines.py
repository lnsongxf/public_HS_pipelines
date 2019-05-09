# -*- coding: utf-8 -*-
"""
Created on Fri 4 Dec 2015
Modified on Wed 3 Feb 2016
1. Unify Platts pipelines into single shapefiles
2. Calculate distance from each house to crude, products, NG pipelines
3. Calculate distance from each house to any pipeline

@author: Evan
"""

import os,sys,logging
# Directories
buildPath = r"/home/sweeneri/Projects/Pipelines/build"
dataPath = r"/home/sweeneri/Projects/Pipelines/Data"
os.chdir(r"{}/temp".format(buildPath))
sys.path.insert(0,  r"/home/sweeneri/Projects/Pipelines/utils")

# Start logging
LOG_FILENAME = r"{}/output/logs/dq_to_pipelines.log".format(buildPath)
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO)

from time import time
import pandas as pd
import pyproj
from gisutils import reproject, unify_polyline, ctm_proj
from shapely.geometry import Point, shape
import fiona

LOG_FILENAME = 'logs/dq_to_pipelines.log'
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO)

def pt_function(x,y,unifiedpipes):
    pt = Point(x,y)
    dist = pt.distance(unifiedpipes)
    return dist       

def dq_to_pipes(df,lineshp):
    for line in lineshp:
        unifiedpipes = shape(line['geometry'])
    distdf = df[['x_ctm','y_ctm']].apply(
        lambda row: pt_function(row[0], row[1], unifiedpipes),
        axis = 1)
    return distdf

if __name__ == '__main__':

    # Filepaths
    crude_utmCA = r"{}/output/crude_utmCA.shp".format(buildPath)
    ng_utmCA = r"{}/output/ng_utmCA.shp".format(buildPath)
    products_utmCA = r"{}/output/products_utmCA.shp".format(buildPath)
    dq_utmCA = r"{}/output/dq_utmCA.dta".format(buildPath)
    outfile = r"{}/temp/CA_assess_to_pipes.dta".format(buildPath)

    # Temp files
    crude_unified = "temp_crude.shp"
    ng_unified = "temp_ng.shp"
    products_unified = "temp_prod.shp"

    # California Transverse Mercator Projection
    # (http://spatialreference.org/ref/sr-org/7098/)
    # Also known as UTM Zone 10.5
    ctm = ctm_proj()

    # merge projected pipelines into one geometry
    unify_polyline(crude_utmCA,crude_unified)
    logging.info("crude done")

    unify_polyline(ng_utmCA,ng_unified)
    logging.info("ng done")

    unify_polyline(products_utmCA,products_unified)
    logging.info("products done")

    # Now read in reprojected all house locations
    df = pd.read_stata(dq_utmCA)	
                
    # Caluclate distances                        
    with fiona.open(crude_unified) as sourceline:
       df['km_to_crude'] = dq_to_pipes(df,sourceline)/1000.0

    logging.info("km_to_crude calculated")

    with fiona.open(ng_unified) as sourceline:
       df['km_to_ng'] = dq_to_pipes(df,sourceline)/1000.0

    logging.info("km_to_ng calculated")

    with fiona.open(products_unified) as sourceline:
       df['km_to_productsngl'] = dq_to_pipes(df,sourceline)/1000.0

    logging.info("km_to_productsngl calculated")

    df.drop(['sa_x_coord','sa_y_coord'], inplace=True, axis=1)
    df.to_stata(outfile)

    logging.info("distance datafile saved")
