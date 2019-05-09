# -*- coding: utf-8 -*-
"""
Created on Fri 4 Dec 2015

Reproject Platts pipelines and DataQuick to CTM

@author: Evan
"""
import os, sys, logging
# Directories
buildPath = r"/home/sweeneri/Projects/Pipelines/build"
dataPath = r"/home/sweeneri/Projects/Pipelines/Data"
os.chdir(r"{}/temp".format(buildPath))
sys.path.insert(0,  r"/home/sweeneri/Projects/Pipelines/utils")

# Start logging
LOG_FILENAME = r"{}/output/logs/project_platts_dq_utmCA.log".format(buildPath)
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO)


from time import time
import pandas as pd
import pyproj
from gisutils import reproject, unify_polyline, ctm_proj
from shapely.geometry import Point, shape
import fiona

if __name__ == '__main__':

    # Filepaths
    crude_raw = r"{}/Platts_CA_maps/Crude_Oil_Pipelines.shp".format(dataPath)
    ng_raw = r"{}/Platts_CA_maps/Natural_Gas_Pipelines.shp".format(dataPath)
    products_raw = r"{}/Platts_CA_maps/NGL_Pipelines.shp".format(dataPath)
    house_ll = r"{}/output/CA_property_xy_assess.dta".format(buildPath)

    # Temp files
    temp_prj = "temp_prj.shp"
    dq_temp = "dq_temp.shp"
    crude_utmCA = r"{}/output/crude_utmCA.shp".format(buildPath)
    ng_utmCA = r"{}/output/ng_utmCA.shp".format(buildPath)
    products_utmCA = r"{}/output/products_utmCA.shp".format(buildPath)
    dq_utmCA = r"{}/output/dq_utmCA.dta".format(buildPath)

    # California Transverse Mercator Projection
    # (http://spatialreference.org/ref/sr-org/7098/)
    # Also known as UTM Zone 10.5
    ctm = ctm_proj()

    # Reproject all pipelines
    reproject(crude_raw,crude_utmCA,ctm)
    logging.info("crude done")

    reproject(ng_raw,ng_utmCA,ctm)
    logging.info("ng done")

    reproject(products_raw,products_utmCA,ctm)
    logging.info("products done")

    # Now read in and reproject all house locations
    df = pd.read_stata(house_ll)
    df = df[['sr_property_id','sa_x_coord','sa_y_coord']]
    if df['sa_x_coord'][0] > 0:
        df['sa_x_coord'] = -df['sa_x_coord']

    myproj = pyproj.Proj(ctm)
    df['x_ctm'],df['y_ctm'] = zip(*df[['sa_x_coord','sa_y_coord']].apply(
                lambda row: myproj(row[0], row[1]),
                axis = 1))
    df.to_stata(dq_utmCA)
    logging.info("DataQuick projected")
               
