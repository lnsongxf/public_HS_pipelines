# -*- coding: utf-8 -*-
"""
Created on Fri 4 Dec 2015
Modified on Wed 3 Feb 2016
1. Unify Platts pipelines into single shapefiles
2. Calculate distance from each house to San Bruno pipeline (132) and 
   blast site

@author: Evan
"""

import os, sys, logging
# Directories
buildPath = r"/home/sweeneri/Projects/Pipelines/build"
dataPath = r"/home/sweeneri/Projects/Pipelines/Data"
os.chdir(r"{}/temp".format(buildPath))
sys.path.insert(0,  r"/home/sweeneri/Projects/Pipelines/utils")

# Start logging
LOG_FILENAME = r"{}/code/logs/dq_to_pipelines.log".format(buildPath)
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO)

from time import time
import pandas as pd
import pyproj
import pdb
from gisutils import reproject, unify_polyline, ctm_proj
from shapely.geometry import Point, shape
import fiona


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


    #####################################
    #   CHECK THESE EVERY TIME!
    #####################################

    outfile = r"{}/output/CA_assess_to_sanbruno.dta".format(buildPath)
    if os.path.exists(outfile) == False:
        print('Writing to a new output file. Script continues.')
    else:
        raise OSError('Output file already exists. Delete it manually to overwrite.')
	
    # San Bruno explosion location:
    sblat = 37.622460
    sblon = -122.441891
    sbproj = pyproj.Proj(ctm_proj())
    (sb_x,sb_y)  = sbproj(sblon,sblat)

    # Selections
    # To keep all of a type of pipeline: "1==1"
    # To keep none of a type of pipeline: ""
    # To keep all houses: ""
    selections = {}
    selections['crude'] = ""
    selections['ng'] = ("rec['properties']['OWNER']=='Pacific Gas and Electric Co.' and "
		       " rec['properties']['SYSTEM1']=='132'")
    selections['products'] = ""
        


    # Filepaths
    crude_utmCA = r"{}/output/crude_utmCA.shp".format(buildPath)
    ng_utmCA = r"{}/output/ng_utmCA.shp".format(buildPath)
    products_utmCA = r"{}/output/products_utmCA.shp".format(buildPath)
    dq_utmCA = r"{}/output/dq_utmCA.dta".format(buildPath)
    dq_selection = r"{}/output/dq_utmCA.dta".format(buildPath)

    # Temp files
    unified = "temp_unified.shp"
    temp_select = "temp_select.shp"

    # California Transverse Mercator Projection
    # (http://spatialreference.org/ref/sr-org/7098/)
    # Also known as UTM Zone 10.5
    ctm = ctm_proj()


    # Now merge reprojected house locations with selection of houses
    dfproj = pd.read_stata(dq_utmCA)
    dfselect = pd.read_stata(dq_selection)
    dfselect = dfselect.drop(['x_ctm','y_ctm'],axis=1)
    df = pd.merge(left=dfproj,right=dfselect, how='right',
	 left_on='sr_property_id', right_on='sr_property_id')

    # merge projected pipelines into one geometry
    if selections['ng'] != "":
        with fiona.open(ng_utmCA) as source:
            with fiona.open(temp_select,'w',
                        driver = source.driver,
                        schema = source.schema,
                        crs = source.crs) as sink:
                for rec in source:
                    if eval(selections['ng']):
                        sink.write({'properties': rec['properties'],
                                'geometry': rec['geometry']})
            unify_polyline(temp_select,unified)
        # Caluclate distances
        with fiona.open(unified) as sourceline:
            df['km_to_PGE132'] = dq_to_pipes(df,sourceline)/1000.0
        logging.info("km_to_ng calculated")
    
    # Create San Bruno point
    sb_point = Point(sb_x,sb_y)

    # Distance
    df['km_to_explosion'] = df[['x_ctm','y_ctm']].apply(
    lambda row: pt_function(row[0], row[1], sb_point),
        axis = 1)
    df['km_to_explosion'] = df['km_to_explosion']/1000

    df.to_stata(outfile)
    logging.info("distance datafile saved")
