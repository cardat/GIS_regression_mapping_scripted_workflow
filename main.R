## GIS_regression_mapping_scripted_workflow
## ivanhanigan

#### load libraries and functions ####
source("code/function_get_pgpass.R")
source("code/function_pgListTables.R")
library(raster)
library(rgdal)

##### set up ####
## TODO need to explain that some data is restricted and postgis_user can only do demo with public data, for full satellite implementation need to get permission and logon as specified username
username <- "ivan_hanigan"

## set the year that is of interest for this run
yy <- 2016

## 1) enter the name of a ESRI shapefile that has points where you want to estimate pollution
## 2) don't include the file extension '.shp'
## 3) if you don't want this, set to NA 
estimation_points_filename <- "data_provided/liverpool_sensitive_bld_labs"
if(!is.na(estimation_points_filename)){
estimation_points <- readOGR(dirname(estimation_points_filename), basename(estimation_points_filename))
}

## if you don't have a estimation_points file, you can create a grid 
## if you want to create a regular grid of points, set this to TRUE otherwise FALSE
estimation_grid <- TRUE 
## NB this assumes GDA94
est_grid_srid <- 4283

## and set the longitudes and latitudes (use bbox or numerics), resolution and a buffer zone around the edge
## IF YOU WANT A DIFFERENT GRID YOU CAN SET THE XMIN, XMAX, YMIN, YMAX HERE INSTEAD (in dec dgs, gda94)
if(exists("estimation_points")){
xmn <- estimation_points@bbox[1,1] 
xmx <- estimation_points@bbox[1,2] 
ymn <- estimation_points@bbox[2,1]
ymx <- estimation_points@bbox[2,2]
## set the resolution (in dec degs)
res <- 0.001 
smidge <- 0.0075 # a constant to expand the edge of the estimation grid by (in dec degs)

## now create the grid
if(estimation_grid){
source("code/do_gridded_shapefile.R")


plot(pts, cex = 0.01)
plot(estimation_points, add = T, col = 'red')
}
} else {
  print("you'll need to add xmin, xmax, ymin and max because estimation_points is NA")
}

## and now the final selection of estimation points, use the grid if it exists 
if(exists("pts")){ 
  est_pts <- pts@data
} else {
  est_pts <- estimation_points@data
}

## set your favourite output directory, or use getwd() to dump results to the current dir
outdir <- "working_temporary"
if(!file.exists(outdir)) dir.create(outdir)

run_label <- "demo2_liverpool"
outfile <- sprintf("%s_%s_res%s", run_label, yy, format(res, scientific = FALSE)) # set a good name for the output file

## create a random label to identify the working files for this run in the database
unique_name <- basename(tempfile())
## don't change it here, it is used to keep track of your run, and clean up after

#### 01 Connect to postGIS database ####
## TODO 1) should we ask pgpass function to storePassword? 2) need to explain that some data is restricted and postgis_user can only do demo with public data, for full satellite implementation need to get permission and logon as specified username

source("code/do_connection_to_PostGIS.R")

#### load data ####
## now load the spatial data of the estimation nodes
est_pts_tbl <- sprintf("%s_est_pts", unique_name)
names(est_pts) <- tolower(names(est_pts))
dbWriteTable(ch, est_pts_tbl, est_pts, row.names = F)
dbSendQuery(ch, sprintf("alter table public.%s add column gid serial primary key", est_pts_tbl))

dbSendQuery(ch, 
# cat(            
paste("SELECT AddGeometryColumn('public', '",est_pts_tbl,"', 'geom', ",est_grid_srid,", 'POINT', 2);
  ALTER TABLE public.",est_pts_tbl," ADD CONSTRAINT geometry_valid_check CHECK (ST_isvalid(geom));
  UPDATE public.",est_pts_tbl," SET geom=ST_GeomFromText('POINT('|| xcoord ||' '|| ycoord ||')',",est_grid_srid,");", sep = "")
)

#dbGetQuery(ch, sprintf("select * from %s limit 1", est_pts_tbl))

## now run the scripts in order
strt <- Sys.time()

# TODO do we check the input srid? this next bit is really all about transforming the SRID, we could enforce a SRID check firset and remove this bit? Therefore only correct projections allowed in?
## note we are using the australian albers equal area projection
## so set this srid. this ensures computations are in metres
srid <- 3577
## TODO if you need to check it exists:
# dbGetQuery(ch,
# sprintf("select * from spatial_ref_sys where auth_srid = %s", srid)
#             )

## now we transform the esteimation points to albers
recpt <- sprintf("public.%s", est_pts_tbl)
## if the SRID is differnt need to st_transform to the GDA94 projection
namlist <- dbGetQuery(ch, paste("select * from ",recpt," limit 10"))
## ignore the warning about unrecognised field type
namlist2 <- paste(names(namlist), sep = "", collapse = ", ")

namlist2 <- gsub("geom", sprintf("st_transform(geom, %s) as geom", srid), namlist2)
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
## need to alert the system to the new srid
dbSendQuery(ch,
# cat(
paste("ALTER TABLE ",recpt,"
 ALTER COLUMN geom TYPE geometry(POINT,",srid,") 
  USING ST_SetSRID(geom,", srid, ")", sep = "")            
            )

#### 02 create buffers ####
radii <- c(400,500,1000,1200,10000)
source("code/do_buffers.R")

#### 03 extract OMI satellite data ####
## THIS IS RESTRCTED DATA
## declare inputs
## note that old is original, new was provided during the 45andUp experiment
##yy <- 2016
omi <- paste("sat_omi_no2.omi_no2_",yy,"kr1_new_albers", sep = "")
## TODO should this compute the average of pixels within polygons (and if so should it be weighted by area of overlap?)
source("code/do_extract_raster_in_buffer.R")

#### 04 impervious_surfaces _IMPSA_with_1200M ####
source_lyr <- "impervious_surfaces.impsa"
source_lyr_geom_col <- "geom_albers"
src_var <- "grid_code"
## TODO this should be a raster?
## TODO we should generalise this so it is not necessarily the 1200 buffer
##_IMPSA_with_1200M
buff_todo <- 1200
lyr_out_suffix <- sprintf("impsa%sm", buff_todo)

source("code/do_extract_points_in_buffer.R")

#### 05 major roads ####
## this is restricted data
majrds <- "roads_psma.majrds"
## NB we reproject this into metres albers equal area
source_lyr_nam <- "majrds"
buff_todo <- 500
source_lyr_var <- "subtype_cd"
source("code/do_extract_lines_in_buffer.R")

#### 06 NPI ####
## TODO why is this not like the impsa code?
# maybe change extract pts in buff to take avg vs count? also the coastline...
npi <- "npinox.npinox_2008_2009"
coast <- "abs_ste.ste_2011_aus_albers_simple"
radii_todo <- c(1000, 400)

source("code/06_NPINOX_extract.R")

#### 07 industrial and openspace_buffer ####
ind <- "abs_mb.mb_2011_aus_albers"
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
", sep = ""))
summary(predicted)
predicted[1:10,]
predicted[1:10,1:4]
t(predicted[1,])
##write.csv(predicted, "working_temporary/gis_no2_2007_437_qc_predicted.csv", row.names = F)
pred <- predicted[,c("x", "y", "predicted")]

gridded(pred) <- ~x+y

plot(pred)
dir()
#dir.create("working_temporary")
pred <- raster(pred)
writeRaster(pred, sprintf("%s/%s.shp", outdir, outfile), format = "GTiff", overwrite=T)


#### clean up ####
## clean up the database for the working tables while developing this run?
tbls <- pgListTables(ch, "public")
tbls_todo <- tbls[grep("file", tbls$relname),] #tbls[grep(unique_name, tbls$relname),]
tbls_todo
for(tb in tbls_todo$relname){
  dbSendQuery(ch, sprintf("drop table %s", tb))
}
dbDisconnect(ch)
#lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
