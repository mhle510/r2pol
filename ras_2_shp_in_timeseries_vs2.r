
## FUNCTIONS
crop_2_region_smooth = function(rawRas, rawShp){
  rasCropfine = projectRaster(rawRas, res = 0.05, crs = "+init=epsg:4326",
                              method="ngb")
  rasMaskFin = mask(rasCropfine,mask = rawShp )
  rasCropFin = crop(rasMaskFin,y = rawShp )
  
  return(rasCropFin)
}


ras_2_shp_in_timeseries = function(mainPath, aoiShp, listrawRas, dates, flagwriteRas, outputName){
  
  # packages
  library(rgdal)
  library(raster)
  library(tidyverse)
  library(doFuture)
  library(doRNG)
  
  # create processing folder
  dir.create(file.path(mainPath,'proccesed'), showWarnings = F)
  processedPath = file.path(mainPath,'proccesed')
  
  # read shapefile
  # aoiShp = readOGR(shpPath)
  
  
  # read raster files (raster)
  # listrawRas = list.files(rawrasPath, pattern = '.tif', 
  #                        recursive = T, full.names = T)
  n = length(listrawRas)
  
  ## parallel computing
  # register with do future
  registerDoFuture()
  plan(multisession(workers = 10))
  options(future.globals.maxSize= 3e9)
  
  outputs = 
    foreach(jj = 1:n ) %dorng% {  
      
      rawRas = raster(listrawRas[[jj]])
      
      if(flagwriteRas == 'TRUE'){
        cat('crop raster to region','\n')
        dir.create(file.path(processedPath, 'ras'))
        rprocessedPath = file.path(processedPath, 'ras')
        
        cropRas =  crop_2_region_smooth(rawRas, aoiShp)
        oprasPath = paste(rprocessedPath,'/', outputName,'_',dates[jj],'.tif', sep = '')
        writeRaster(cropRas, oprasPath, 
                    format = 'GTiff', overwrite = T)
      }
      
      t = data.frame(raster::extract(rawRas, aoiShp, weights = TRUE, normalizeWeights= TRUE))
      t = t[complete.cases(t),]
      if(sum(t[,2]) != 1){ # check weight is equal to 1
        t[,2] = t[,2]*1/(sum(t[,2]))
        arealval = sum(t[,1]*t[,2])  
      } else {
        arealval = sum(t[,1]*t[,2])  
      }
      
      arealval
    }
  
  
  opDat = do.call(rbind, outputs)
  opDat = data.frame(dates = dates,
                     opDat)
  
  opPath = paste(processedPath, '/',outputName,'_arealts.csv', sep = '')
  write.csv(opDat, opPath,row.names = F)
}


