##############################
# Objectives
# - Extract time series from a set of rasters given shapefile


##############################


# step 1- path setup
mainPath = "D:/r2pol"
setwd(mainPath)

# step 2 - package calling 
source(file.path(mainPath,'ras_2_shp_in_timeseries.r'))
library(rgdal)
library(tictoc)

# step 3 - path load
# path to region (in shapefile format)
shpPath = file.path(mainPath, 'input','shp','mk_banyen.shp')

# path to raw raster folder
rawrasPath = file.path(mainPath, 'input','rawras')

# step 4 - run
tic()
ras_2_shp_in_timeseries(mainPath = mainPath, # main folder path
                        shpPath = shpPath, # path to area of interest
                        rawrasPath = rawrasPath, # path to raw raster folder
                        noCores = 10,# number of cores to run parallel
                        flagwriteRas = FALSE, # if TRUE, the program crops raw raster to shapefile and export in "ras" folder
                        outputName = 'banyen') # name of output
toc()

