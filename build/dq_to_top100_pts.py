# -*- coding: utf-8 -*-
"""
Created on Fri 4 Dec 2015
Modified on Sun 15 Jul 2016
1. Calculate distance to PGE "Top 100"
-- Now using PGE's own points from their map

@author: Evan
"""

import os, sys, logging, re
# Directories
buildPath = r"/home/sweeneri/Projects/Pipelines/build"
dataPath = r"/home/sweeneri/Projects/Pipelines/Data"
os.chdir(r"{}/temp".format(buildPath))
sys.path.insert(0,  r"/home/sweeneri/Projects/Pipelines/utils")

os.chdir(r"{}/temp".format(buildPath))
sys.path.insert(0,  r"/home/sweeneri/Projects/Pipelines/utils")

# Start logging
LOG_FILENAME = r"{}/output/logs/dq_to_top100_pts.log".format(buildPath)
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO)

from time import time
import pandas as pd
import pyproj
import rtree
from gisutils import reproject, unify_polyline, ctm_proj
from shapely.geometry import Point, shape
import fiona

def dq_to_feats(df,feats):
    dataout = df[['x_ctm','y_ctm','sr_property_id']].apply(
                lambda row: pt_feats(row[0], row[1], feats, row[2]),
                axis = 1)
    return dataout

def pt_feats(x,y,feats,pointid):
    pt = Point(x,y)
    dist = 999999
    isect_pt_x = 999999
    isect_pt_y = 999999
    close_FID = -1
    for feat1 in feats:
        geom1 = shape(feat1['geometry'])
        t_dist = pt.distance(geom1)
        # If this is the best match so far, replace info
        if t_dist < dist:
            dist = t_dist
            close_FID =int(feat1['id'])
            
    return pd.Series([dist,close_FID])

if __name__ == '__main__':


    #####################################
    #   CHECK THESE EVERY TIME!
    #####################################

    outfile = r"{}/output/CA_assess_to_top100_pts.dta".format(buildPath)
    if os.path.exists(outfile) == False:
        print('Writing to a new output file. Script continues.')
    else:
        raise OSError('Output file already exists. Delete it manually to overwrite.')
    
    # Filepaths
    top100_pts_raw = r"{}/GeographicShapefiles/PGE_Top100_100925.shp".format(dataPath)
    pts_utmCA = r"{}/output/PGE_Top100_pts_utmCA.shp".format(buildPath)
    dq_utmCA = r"{}/output/dq_utmCA.dta".format(buildPath)
    # Property selection should only have one variable: sr_property_id
    dq_selection = ""

    # Temp files
    temp_select = "temp_select.shp"
    unified = "temp_unified.shp"
    dist_temp = "temp_top100_pts.csv"

    # California Transverse Mercator Projection
    # (http://spatialreference.org/ref/sr-org/7098/)
    # Also known as UTM Zone 10.5
    ctm = ctm_proj()

    # Now merge reprojected house locations with selection of houses
    dfproj = pd.read_stata(dq_utmCA)
    if dq_selection != "":
        dfselect = pd.read_stata(dq_selection)
        df = pd.merge(left=dfproj,right=dfselect, how='right',
            left_on='sr_property_id', right_on='sr_property_id')
    else:
        df = dfproj

    print('df read')

    # Reproject top 100
    reproject(top100_pts_raw,pts_utmCA,ctm)

    # Caluclate distances
    with fiona.open(pts_utmCA) as source:
        dataout_pts = dq_to_feats(df,source)

    dataout_pts = dataout_pts.rename(columns={0:"dist_top100_pts",1:"close_top100_pt_FID"})
    dataout_pts["dist_top100_pts"] = dataout_pts["dist_top100_pts"]/1000.0
    dataout_pts.to_csv(dist_temp)

    df = df.join(dataout_pts)

    logging.info("distance calculated")
    df.drop(['sa_x_coord','sa_y_coord'], inplace=True, axis=1)
    df.to_stata(outfile)
    logging.info("distance datafile saved")
