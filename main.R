## GIS_regression_mapping_scripted_workflow
## ivanhanigan

## load libraries and functions
source("code/function_get_pgpass.R")
source("code/function_pgListTables.R")
library(raster)
library(rgdal)

#### 01 Connect to postGIS database ####
## TODO 1) should we ask pgpass function to storePassword? 2) need to explain that some data is restricted and postgis_user can only do demo with public data, for full satellite implementation need to get permission and logon as specified username 
username <- "postgis_user"
source("code/01_test_connection_to_PostGIS.R")

## create a random label to identify the working files for this run
unique_name <- basename(tempfile())

## now load the spatial data of the estimation nodes

ll_corner <- c(150.913, -33.938)
smidge <- 0.03
extent <- list(xmin = ll_corner[1], xmax = ll_corner[1] + smidge, ymin = ll_corner[2], ymax = ll_corner[2] + smidge)
extent

res <- 0.0001

cnts_x <- seq(extent[[1]] , extent[[2]], res)
cnts_x
cnts_y <- seq(extent[[3]] , extent[[4]], res)
cnts_y

cnts <- merge(cnts_x, cnts_y)
##plot(ecosystem_bound[ecosystem_bound@data$Id == 1,])
##points(cnts)
##axis(1); axis(2)
dir()
pts <- SpatialPointsDataFrame(cnts, data.frame(Id = 1:nrow(cnts), xcoord = cnts[,1], ycoord = cnts[,2]), proj4string = CRS("+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs"))

## set your favourite output directory, or use getwd() to dump results to the current dir
outdir <- "~/projects/GIS_regression_mapping_scripted_workflow/working_temporary"
dir(outdir)
outfile <- "subset_liverpool_10m" # set a good name for the output file
writeOGR(pts,
         outdir,
         outfile,
         driver = "ESRI Shapefile", overwrite = T)

## shp2pgis
setwd(outdir)
dir()
srid <- 4283 # this is GDA94, a standard coordinate system across Aust
infile <- outfile

## TODO, the upload to the server is not easy from R for some reason, use the shell
schema <- "public"
host <- "swish4.tern.org.au"
d <- "postgis_car"
u <- "postgis_user"
txt <- paste("/usr/bin/shp2pgsql -s ", srid, " -D ", infile, ".shp ",
             schema, ".", infile, " > ", infile, ".sql", sep = "")
cat(txt)
system(txt)
txt <- paste("/usr/bin/psql  -d ", d, " -U ", u, " -W -h ", host,
             " -f ", infile, ".sql", sep = "")
cat(txt)
dbSendQuery(ch, sprintf("drop table %s", infile))
system(txt,)
infile
setwd("..")

## now run the scripts in order


strt <- Sys.time()
## declare inputs
## Make sure you include SCHEMA.and.TABLE
recpt <- sprintf("public.%s", infile)
## if the SRID is differnt need to st_transform to the GDA94 projection
namlist <- dbGetQuery(ch, paste("select * from ",recpt," limit 1"))
namlist2 <- paste(names(namlist), sep = "", collapse = ", ")
#namlist2 <- gsub("geom", "st_transform(geom, 4283) as geom", namlist2)
dbSendQuery(ch,
            ## cat(
            paste("drop table if exists ",recpt,"_V2;
select ",namlist2," 
into ",recpt,"_v2
from ",recpt," t1
", sep = "")            
)
# and so update the recpt name
recpt <- paste(recpt, "_v2", sep = "")

#### 02 create buffers ####
radii <- c(400,500,1000,1200,10000)
## note we are using the australian albers equal area projection
## so set this srid. this ensures computations are in metres
srid <- 3577
## if you need to check it exists:
# dbGetQuery(ch,
# sprintf("select * from spatial_ref_sys where auth_srid = %s", srid)           
#            )
source("code/02_buffers.R")                          

#### 03 extract OMI satellite data ####
## THIS IS RESTRCTED DATA
## declare inputs
## note that old is original, new was provided during the 45andUp experiment
yy <- 2016
omi <- paste("sat_omi_no2.omi_no2_",yy,"kr1_new", sep = "")
## TODO should this compute the average of pixels within polygons (and if so should it be weighted by area of overlap?)
source("code/03_extract_OMI.R")

#### 04 impervious_surfaces ####
impsa <- "impervious_surfaces.impsa_437_10K"
## first test  "impervious_surfaces.impsa_mb_test_01"
## TODO we should generalise this so it is not necessarily the 1200 buffer
source("code/04_overlay_IMPSA_with_1200M.R")         

#### 05 major roads ####
## this is restricted data
majrds <- "roads_psma.majrds_437_10k"
## NB we reproject this into metres albers equal area

source("code/05_majrds_intersect_with_500m_buffer.R")

#### 06 NPI ####
npi <- "npinox.npinox_2008_2009"
coast <- "abs_ste.ste_2011_aus_albers_simple"
radii_todo <- c(1000, 400)

source("code/06_NPINOX_extract.R")

#### 07 industrial and openspace_buffer ####
ind <- "abs_mb.mb_2011_nsw_albers"
radii_todo <- 10000

source("code/07_industrial_or_open_in_buffer.R")
ed <- Sys.time()
ed - strt

#### 08 Merge master table ####
# Note that some of these are centred and standardised 
predicted <- dbGetQuery(ch,
                        ##cat(
                        paste("
select gid, xcoord as x, ycoord as y, 4.563 + ((0.701 * ((grid_code-10)/10))) + (1.203 * RASTERVALU) + (0.828 *((case when RDS_500M is null then 0 else RDS_500M end /1000) - 0.65)) + (-0.17 * ((OPENSPACE_10000M-10)/10)) + (2.629 * NPI_DENS_400) + (4.083 * NPI_DENS_1000) + (0.451 * ((INDUSTRIAL_10000M - 10)/10)) + (-0.14 * (year-2008)) as predicted, main_merge.*
from (
select t1.gid, t7.xcoord, t7.ycoord, t1.grid_code, t2.RASTERVALU, t3.RDS_500M, t4.area_ind as INDUSTRIAL_10000M, t4.area_open as OPENSPACE_10000M, t5.npi_dens_400, t6.npi_dens_1000, ",yy," as year
from ",unique_name,"_impsa1200m t1
left join 
",unique_name,"_omi_",yy," t2
on t1.gid = t2.gid
left join 
",unique_name,"_majrds500mAlbers_total_road_length t3
on t1.gid = t3.gid
left join 
",unique_name,"_ind_insct_buffer_area t4
on t1.gid = t4.gid
left join 
",unique_name,"_npinox400m_dens t5
on t1.gid = t5.gid
left join 
",unique_name,"_npinox1000m_dens t6
on t1.gid = t6.gid
left join ",recpt," t7
on t1.gid = t7.gid
) main_merge
", sep = "")
)
summary(predicted)
predicted[1:10,]
predicted[1:10,1:4]
t(predicted[1,])
##write.csv(predicted, "working_temporary/gis_no2_2007_437_qc_predicted.csv", row.names = F)
pred <- predicted[,c("x", "y", "predicted")]

gridded(pred) <- ~x+y

plot(pred)
dir()
dir.create("working_temporary")
pred <- raster(pred)
#writeRaster(pred, "working_temporary/gis_no2_2007_sa2_test01.tif", format = "GTiff")
#writeRaster(pred, "working_temporary/gis_no2_2007_438.tif", format = "GTiff", overwrite=T)
#writeRaster(pred, "working_temporary/gis_no2_2007_437.tif", format = "GTiff", overwrite=T)
#writeRaster(pred, "working_temporary/gis_no2_2016_437_50m.tif", format = "GTiff", overwrite=T)
writeRaster(pred, "working_temporary/gis_no2_2016_liverpool_10m.tif", format = "GTiff", overwrite=T)

## clean up the database for the working tables while developing this run?
tbls <- pgListTables(ch, "public")
tbls_todo <- tbls[grep(unique_name, tbls$relname),]
tbls_todo
for(tb in tbls_todo$relname){
  dbSendQuery(ch, sprintf("drop table %s", tb))
}
