# -*- coding: utf-8 -*-
"""
Created on Fri 4 Dec 2015
Modified on Wed 3 Feb 2016
1. Unify Platts pipelines into single shapefiles
2. Calculate distance from each house to crude, products, NG pipelines
3. Calculate distance from each house to any pipeline
4. Spit out shapefiles of selected pipelines
@author: Evan
"""

import os, sys, logging
# Directories
buildPath = r"/home/sweeneri/Projects/Pipelines/build"
dataPath = r"/home/sweeneri/Projects/Pipelines/Data"
os.chdir(r"{}/temp".format(buildPath))
sys.path.insert(0,  r"/home/sweeneri/Projects/Pipelines/utils")

# Start logging
LOG_FILENAME = r"{}/output/logs/dq_to_pipelines_nodistr_pge.log".format(buildPath)
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO)

from time import time
import re
import pandas as pd
import pyproj
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

    outfile = r"{}/output/CA_assess_to_pipes_nodistr_pge.dta".format(buildPath)
    ng_select = "{}/output/ng_nodistr_pge.shp".format(buildPath)
    crude_select = "temp_select.shp"
    products_select = "temp_select.shp"	

    if os.path.exists(outfile) == False:
        print('Writing to a new output file. Script continues.')
    else:
        raise OSError('Output file already exists. Delete it manually to overwrite.')

    # Selections
    # To keep all of a type of pipeline: "1==1"
    # To keep none of a type of pipeline: ""
    # To keep all houses: ""
    selections = {}
    selections['crude'] = ""
    selections['products'] = ""
    selections['ng'] = ""

    # PGE only!
    selections['ng'] = selections['ng'] + """rec['properties']['ShortName'] == 'PG&E' and """
    # No "distribution" lines
    selections['ng'] = selections['ng'] + "not re.search('Gcust|Dcust|Dreg|Distribution',str(rec['properties']['SYSTEM1'])) and "
    # No lines less than 6 inches
    selections['ng'] = selections['ng'] + "(rec['properties']['DIAMETER'] > 6 or "
    # Lines with missing diameter allowed only if they have some system information or inter/intrastate info
    selections['ng'] = selections['ng'] + "((rec['properties']['DIAMETER'] == -99 or rec['properties']['DIAMETER'] == 0)"
    selections['ng'] = selections['ng'] + "and not (rec['properties']['SYSTEM1'] == None and "
    selections['ng'] = selections['ng'] + "rec['properties']['SYSTEM2'] == None and rec['properties']['TYPE'] == None)))"

    # Filepaths
    crude_utmCA = r"{}/output/crude_utmCA.shp".format(buildPath)
    ng_utmCA = r"{}/output/ng_utmCA.shp".format(buildPath)
    products_utmCA = r"{}/output/products_utmCA.shp".format(buildPath)
    dq_utmCA = r"{}/output/dq_utmCA.dta".format(buildPath)
    dq_selection = r"{}/output/dq_utmCA.dta".format(buildPath)

    # Temp files
    unified = "temp_unified.shp"

    # California Transverse Mercator Projection
    # (http://spatialreference.org/ref/sr-org/7098/)
    # Also known as UTM Zone 10.5
    ctm = ctm_proj()

    # Now merge reprojected house locations with selection of houses
    if dq_utmCA == dq_selection:
        df = pd.read_stata(dq_utmCA)
    else:
        dfproj = pd.read_stata(dq_utmCA)
        dfselect = pd.read_stata(dq_selection)
        df = pd.merge(left=dfproj,right=dfselect, how='right',
	     left_on='sr_property_id', right_on='sr_property_id')

    # merge projected pipelines into one geometry
    iter = 0
    if selections['crude'] != "":
	with fiona.open(crude_utmCA) as source:
	    with fiona.open(crude_select,'w',
                        driver = source.driver,
                        schema = source.schema,
                        crs = source.crs) as sink:
                for rec in source:    
	            if eval(selections['crude']):
                        sink.write({'properties': rec['properties'],
                                'geometry': rec['geometry']})
            unify_polyline(crude_select,unified)
        # Caluclate distances                        
        with fiona.open(unified) as sourceline:
            df['km_to_crude'] = dq_to_pipes(df,sourceline)/1000.0
        logging.info("km_to_crude calculated")
	iter = iter+1

    if selections['ng'] != "":
        with fiona.open(ng_utmCA) as source:
            with fiona.open(ng_select,'w',
                        driver = source.driver,
                        schema = source.schema,
                        crs = source.crs) as sink:
                for rec in source:
                    if eval(selections['ng']):
                        sink.write({'properties': rec['properties'],
                                'geometry': rec['geometry']})
            unify_polyline(ng_select,unified)
        # Caluclate distances
        with fiona.open(unified) as sourceline:
            df['km_to_ng_nodistr_pge'] = dq_to_pipes(df,sourceline)/1000.0
        logging.info("km_to_ng_nodistr_pge calculated")

    if selections['products'] != "":
        with fiona.open(products_utmCA) as source:
            with fiona.open(products_select,'w',
                        driver = source.driver,
                        schema = source.schema,
                        crs = source.crs) as sink:
                for rec in source:
                    if eval(selections['products']):
                        sink.write({'properties': rec['properties'],
                                'geometry': rec['geometry']})
            unify_polyline(products_select,unified)
        # Caluclate distances
        with fiona.open(unified) as sourceline:
            df['km_to_products'] = dq_to_pipes(df,sourceline)/1000.0
        logging.info("km_to_products calculated")

    df.drop(['sa_x_coord','sa_y_coord'], inplace=True, axis=1)
    df.to_stata(outfile)
    logging.info("distance datafile saved")
