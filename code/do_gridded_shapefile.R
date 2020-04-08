## this is the bounding box extent and in dec degs
extent <- list(xmin = xmn - smidge, xmax = xmx + smidge, ymin = ymn - smidge, ymax = ymx + smidge)

cnts_x <- seq(extent[[1]] , extent[[2]], res)
cnts_y <- seq(extent[[3]] , extent[[4]], res)

cnts <- merge(cnts_x, cnts_y)


pts <- SpatialPointsDataFrame(cnts, data.frame(Id = 1:nrow(cnts), xcoord = cnts[,1], ycoord = cnts[,2]), proj4string = CRS("+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs"))

# writeOGR(pts,
#          outdir,
#          outfile,
#          driver = "ESRI Shapefile", overwrite = T)
