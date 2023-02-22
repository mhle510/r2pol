##############################
# Objectives
# - Extract time series from a set of rasters given shapefile


##############################

# step 1- path setup
mainPath = 'D:/ABinh'
setwd(mainPath)

# step 2 - package calling 
source(file.path(mainPath,'ras_2_shp_in_timeseries_vs2.r'))
library(rgdal)
library(raster)
library(tictoc)

# step 3 - path load

# path to region (in shapefile format)
rawshpPath = file.path(mainPath, 'input','aoi','SGDN_SubBasinsByStations.shp')
checkshp = readOGR(rawshpPath)
checkshp
# need to convert shp as WGS 84
adjshp = spTransform(checkshp, CRS("+proj=longlat +datum=WGS84"))
shapefile(adjshp, file.path(mainPath, 'input','aoi','SGDN_SubBasinsByStations_wgs84.shp'), overwrite=TRUE)
np = nrow(adjshp@data) # check how many sub-basins

# path to raw raster folder
raw.chirps.path = 'C:/Users/manhh/Dropbox/vnbasins_globaldatasets/gridP/Merged/CHIRPS/'
yrs = seq(1981,1982,1) # adjust yrs to extract specific periods !!!
adj.chirps.path = paste0(raw.chirps.path, yrs)
listrawRas = list.files(adj.chirps.path, pattern = '.tif', 
                       recursive = T, full.names = T)
dates = substr(basename(listrawRas),1,8) #extract dates in forms of yyyymmdd. For CHIRPS datasets, letter 1 to 8 are the date information

# step 4 - run -single run if aoi is a single polygon
# tic()
# ras_2_shp_in_timeseries(mainPath = mainPath, # main folder path
#                         shpPath = shpPath, # path to area of interest
#                         rawrasPath = rawrasPath, # path to raw raster folder
#                         noCores = 10,# number of cores to run parallel
#                         flagwriteRas = FALSE, # if TRUE, the program crops raw raster to shapefile and export in "ras" folder
#                         outputName = 'banyen') # name of output
# toc()

# step 4 - run - multiple runs if aoi is a multiple polygon
for(ip in 1 : np){
  tic()
  subShp = adjshp[ip,]
  outputName = adjshp@data$NameSubBas[ip]
  cat(ip, '---',outputName,'\n')
  
  ras_2_shp_in_timeseries(mainPath = mainPath, # main folder path
                          aoiShp = subShp, # area of interest
                          listrawRas = listrawRas, # list raw raster
                          dates = dates, # date information
                          flagwriteRas = TRUE, # if TRUE, the program crops raw raster to shapefile and export in "ras" folder
                          outputName = outputName) # name of output
  toc()

  
}

