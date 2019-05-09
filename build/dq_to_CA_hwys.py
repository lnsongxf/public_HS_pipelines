# -*- coding: utf-8 -*-
"""
Created on Fri 4 Dec 2015
Modified on Sun 15 Jul 2016
1. Calculate distance to interstate/US/state highways

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
LOG_FILENAME = r"{}/output/logs/dq_to_CA_hwys.log".format(buildPath)
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO)

from time import time
import pandas as pd
import pyproj
import rtree
from gisutils import reproject, unify_polyline, ctm_proj
from shapely.geometry import Point, shape
import fiona



def pt_function(x,y,unifiedlines):
    pt = Point(x,y)
    dist = pt.distance(unifiedlines)
    return dist       

def dq_to_lines(df,lineshp):
    for line in lineshp:
        unifiedlines = shape(line['geometry'])
        distdf = df[['x_ctm','y_ctm']].apply(
        lambda row: pt_function(row[0], row[1], unifiedlines),
        axis = 1)
    return distdf

if __name__ == '__main__':


    #####################################
    #   CHECK THESE EVERY TIME!
    #####################################

    outfile = r"{}/output/CA_assess_to_highways.dta".format(buildPath)
    if os.path.exists(outfile) == False:
        print('Writing to a new output file. Script continues.')
    else:
        raise OSError('Output file already exists. Delete it manually to overwrite.')
    
    # Selections
    selections = ""
    selections = selections + """rec['properties']['STFIPS'] == '06' and """
    selections = selections + """(rec['properties']['SIGNT1'] == 'I' or rec['properties']['SIGNT1'] == 'U' or rec['properties']['SIGNT1'] == 'S')"""

    # Filepaths
    hwy_raw = r"{}/GeographicShapefiles/nhpn.shp".format(dataPath)
    hwy_CA_utmCA = r"{}/output/hwy_CA_utmCA.shp".format(buildPath)
    dq_utmCA = r"{}/output/dq_utmCA.dta".format(buildPath)
    # Property selection should only have one variable: sr_property_id
    dq_selection = ""

    # Temp files
    temp_select = "temp_select.shp"
    unified = "temp_unified.shp"

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

    # merge selected out roads
    if selections != "":
        with fiona.open(hwy_raw) as source:
            with fiona.open(temp_select,'w',
                        driver = source.driver,
                        schema = source.schema,
                        crs = source.crs) as sink:
                for rec in source:
                    if eval(selections):
                        sink.write({'properties': rec['properties'],
                                'geometry': rec['geometry']})

    # Reproject/unify selected roads
    reproject(temp_select,hwy_CA_utmCA,ctm)
    unify_polyline(hwy_CA_utmCA,unified)

    # Caluclate distances
    with fiona.open(unified) as sourceline:
        df['km_to_roads'] = dq_to_lines(df,sourceline)/1000.0
        logging.info("km_to_roads calculated")

    df.drop(['sa_x_coord','sa_y_coord'], inplace=True, axis=1)
    df.to_stata(outfile)
    logging.info("distance datafile saved")
