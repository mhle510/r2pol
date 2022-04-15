################################################################################
# Author : Manh-Hung Le, Hong Xuan Do                                      #
################################################################################                                                       #
# Updates: 14-Apr-2022                                                        #
#                                                                  #
################################################################################
## FUNCTIONS
crop_2_region_smooth = function(rawRas, rawShp){
  rasCropfine = projectRaster(rawRas, res = 0.05, crs = "+init=epsg:4326",
                              method="ngb")
  rasMaskFin = mask(rasCropfine,mask = rawShp )
  rasCropFin = crop(rasMaskFin,y = rawShp )
  
  return(rasCropFin)
}

parallel_calc_areal_value_weights = function(cl, croppedRas, aoiShp){
  library(parallel)
  library(doParallel)
  library(tictoc)
  tic()
  
  clusterExport(cl, 'aoiShp')
  
  nd = length(croppedRas)
  arealVal  = parLapply(cl = cl, 1:nd,
                        function(ll,croppedRas){
                          # note that we need to explicitly declare all "external" variables used inside clusters
                          rawRas = croppedRas[[ll]] # read raster in this step
                          t = data.frame(raster::extract(rawRas, aoiShp, weights = TRUE, normalizeWeights= TRUE))
                          t = t[complete.cases(t),]
                          if(sum(t[,2]) != 1){ # check weight is equal to 1
                            t[,2] = t[,2]*1/(sum(t[,2]))
                            sum(t[,1]*t[,2])  
                          } else {
                            sum(t[,1]*t[,2])  
                          }
                        }, croppedRas # you need to pass these variables into the clusters
  )
  toc()
  arealVal = unlist(arealVal)
  return(arealVal)
}


ras_2_shp_in_timeseries = function(mainPath, shpPath, rawrasPath, noCores, flagwriteRas, outputName){
  
  # packages
  library(rgdal)
  library(raster)
  library(tidyverse)
  library(doParallel)
  library(parallel)
  
  # create processing folder
  dir.create(file.path(mainPath,'proccesed'), showWarnings = F)
  processedPath = file.path(mainPath,'proccesed')
  
  # read shapefile
  aoiShp = readOGR(shpPath)
  
  
  # read raster files (raster)
  listrawRas = list.files(rawrasPath, pattern = '.tif', 
                          recursive = T, full.names = T)
  n = length(listrawRas)
  
  # obtain date informaiton
  dates = substr(basename(listrawRas),8,15)
  
  cl = makeCluster(noCores)
  
  clusterExport(cl,
                c('crop_2_region_smooth','aoiShp'),
                envir=environment())
  # export library raster to all cores
  clusterEvalQ(cl, library("raster"))
  rawRas = parLapply(cl, listrawRas, raster)
  
  if(flagwriteRas == 'TRUE'){
    cat('crop raster to region','\n')
    dir.create(file.path(processedPath, 'ras'))
    rprocessedPath = file.path(processedPath, 'ras')
    cropRas = parLapply(cl, rawRas, 
                         function(x) crop_2_region_smooth(x, aoiShp))
    
    
    for(ir in 1 : length(cropRas)){
      opPath = paste(rprocessedPath,'/', outputName,'_',dates[ir],'.tif', sep = '')
      writeRaster(cropRas[[ir]], opPath, 
                  format = 'GTiff', overwrite = T)
      
    }
  }
  
  
  # calculate time series using weighted area method
  opDat = data.frame(dates = dates,
                     arealVal = parallel_calc_areal_value_weights(cl, croppedRas = rawRas, aoiShp = aoiShp))
  stopCluster(cl)
  
  
  opPath = paste(processedPath, '/',outputName,'_arealts.csv', sep = '')
  write.csv(opDat, opPath,row.names = F)
}