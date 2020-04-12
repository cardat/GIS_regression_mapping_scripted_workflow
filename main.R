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
yy <- 2006
## set your favourite output directory, or use getwd() to dump results to the current dir
outdir <- "working_temporary"
if(!file.exists(outdir)) dir.create(outdir)

## set up the estimation points data
## 1) enter the name of a ESRI shapefile that has points where you want to estimate pollution
## 2) don't include the file extension '.shp'
## 3) if you don't want this, set to NA
estimation_points_filename <- "data_provided/SatLUR_NO2_06_case_study_sydney_absmb11_centroids" #"liverpool_sensitive_bld_labs"
if(!is.na(estimation_points_filename)){
estimation_points <- readOGR(dirname(estimation_points_filename), basename(estimation_points_filename))
str(estimation_points@data)
}

## set the names of the columns that contain the x and y (if not using a shp file, this will be required for the grid defined below)
xcoord <- "x"
ycoord <- "y"

## if you don't have a estimation_points file, you can create a grid
## if you want to create a regular grid of points, set this to TRUE otherwise FALSE
estimation_grid <- TRUE
## NB this is hard coded to assume GDA94, which is a safe bet for Australian datasets
est_grid_srid <- 4283
## set the resolution (in dec degs)
res <- 0.005
smidge <- 0.0075 # a constant to expand the edge of the estimation grid by (in dec degs)

## set a name for the output
run_label <- "demo_case_study_region"
if(estimation_grid){
  outfile <- sprintf("%s_%s_res%s", run_label, yy, format(res, scientific = FALSE)) 
} else {
  outfile <- sprintf("%s_%s", run_label, yy) 
}

## create a random label to identify the working files for this run in the database
unique_name <- basename(tempfile())
## don't change it here, it is used to keep track of your run, and clean up after

## and set the longitudes and latitudes (use bbox or numerics), resolution and a buffer zone around the edge
## IF YOU WANT A DIFFERENT GRID YOU CAN SET THE XMIN, XMAX, YMIN, YMAX HERE INSTEAD (in dec dgs, gda94)
if(exists("estimation_points")){
xmn <- estimation_points@bbox[1,1]
xmx <- estimation_points@bbox[1,2]
ymn <- estimation_points@bbox[2,1]
ymx <- estimation_points@bbox[2,2]

## now create the grid
if(estimation_grid){
source("code/do_gridded_shapefile.R")
names(pts) <- c("Id", "x", "y")
plot(pts, cex = 0.01)
plot(estimation_points, add = T, col = 'red')
}
} else {
  print("you'll need to add xmin, xmax, ymin and max because estimation_points is NA")
}

## and now the final selection of estimation points, use the grid if it exists
if(estimation_grid){
  ##exists("pts")
  est_pts <- pts@data
} else {
  est_pts <- estimation_points@data
}
# head(est_pts)
# with(est_pts, plot(x, y))
# dev.off()

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
  UPDATE public.",est_pts_tbl," SET geom=ST_GeomFromText('POINT('|| ",xcoord," ||' '|| ",ycoord," ||')',",est_grid_srid,");", sep = "")
)

#dbGetQuery(ch, sprintf("select * from %s limit 1", est_pts_tbl))

## now run the scripts in order
strt <- Sys.time()

# TODO do we check the input srid? this next bit is really all about transforming the SRID, we could enforce a SRID check first and remove this bit? Therefore only correct projections allowed in?
## note we are using the australian albers equal area projection
## so set this srid. this ensures computations are in metres
srid <- 3577
## TODO if you need to check it exists:
# dbGetQuery(ch,
# sprintf("select * from spatial_ref_sys where auth_srid = %s", srid)
#             )

## now we transform the esteimation points to albers
## if the SRID is differnt need to st_transform to the GDA94 projection
namlist <- dbGetQuery(ch, paste("select * from public.",est_pts_tbl," limit 10"))
## ignore the warning about unrecognised field type
namlist2 <- paste(names(namlist), sep = "", collapse = ", ")

namlist2 <- gsub("geom", sprintf("st_transform(geom, %s) as geom", srid), namlist2)
dbSendQuery(ch,
            ## cat(
            paste("drop table if exists public.",est_pts_tbl,"_V2;
select ",namlist2,"
into public.",est_pts_tbl,"_v2
from public.",est_pts_tbl," t1
", sep = "")
            )
# and so update the recpt name
recpt <- sprintf("public.%s_v2", est_pts_tbl)

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
## TODO maybe this is where we can do the intersect with coastline?

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
source_lyr <- "roads_psma.majrds"
## NB we reproject this into metres albers equal area
source_lyr_nam <- "majrds"
buff_todo <- 500
source_lyr_var <- "subtype_cd"
source_geom_col <- "geom_albers"
source("code/do_extract_lines_in_buffer.R")
## do additional calculation specific to the psma majrds layer
## slect (subtype_cd =2 OR subtype_cd =3) these are multilane roads

dbSendQuery(ch,
            ## cat(
            paste("drop table if exists ",unique_name,"_",source_lyr_nam, buff_todo,"mAlbers_total_road_length;
select gid, sum(RDS_",buff_todo,"M) as RDS_",buff_todo,"M
into ",unique_name,"_",source_lyr_nam, buff_todo,"mAlbers_total_road_length
from (
select t1.gid, 
",source_lyr_var,",
case when ",source_lyr_var," in (2,3) then sum(len)/2 else sum(len) end as RDS_",buff_todo,"M 

from ",unique_name,"_",source_lyr_nam, buff_todo,"mAlbers_length t1
group by gid, ",source_lyr_var,"
order by gid
) foo
group by gid
", sep = "")
)

#### 06 NPI ####
## TODO why is this not like the impsa code?
# maybe change extract pts in buff to take avg vs count? also the coastline...
source_lyr <- "npi.npinox_2008_2009"
source_lyr_nam <- "npinox"
coast <- "abs_ste.ste_2011_aus_albers_simple"
radii_todo <- c(1000, 400)
output_name <- "npi_dens"
source("code/do_extract_points_in_buffer_with_coast.R")

#### 07 industrial and openspace_buffer ####
source_lyr <- "abs_mb.mb_2011_aus_albers"
radii_todo <- 10000
landuse_categories <- data.frame(rbind(
  c("Industrial", "where mb_cat11 = 'Industrial'", "ind"),
  c("Open", "where mb_cat11 in ('Water', 'Parkland', 'Agricultural')", "open")
))
names(landuse_categories) <- c("type", "sql", "label")

source("code/do_extract_polygons_in_buffer.R")
## TODO remove the insct with coast from this, put into the buffers script
ed <- Sys.time()
print(ed - strt)

#### 08 Merge master table ####
## Use the coeefficients as per Knibbs et al 2014
## Knibbs, L. D., Hewson, M. G., Bechle, M. J., Marshall, J. D., & Barnett, A. G. (2014). A national satellite-based land-use regression model for air pollution exposure assessment in Australia. Environmental Research, 135, 204–211. https://doi.org/10.1016/j.envres.2014.09.011
## Note that some of these are centred and standardised
coeffs <- data.frame(rbind(
  c("Intercept","4.563", "intercept", "",""),
  c("Impervious surfaces (1200 m)", "0.701", "((grid_code-10)/10)", "grid_code", "impsa1200m"),
  c("OMI column NO2","1.203","RASTERVALU", "RASTERVALU", paste0("omi_",yy)),
  c("Major roads (500 m)", "0.828", "((case when RDS_500M is null then 0 else RDS_500M end /1000) - 0.65)", "RDS_500M", "majrds500mAlbers_total_road_length"),
  c("Open space (10,000 m)","-0.170","((OPENSPACE_10000M-10)/10)", "area_open as OPENSPACE_10000M", "ind_insct_buffer_area"),
  c("Industrial NOX emission site density (400 m)","2.629","NPI_DENS_400","NPI_DENS_400", "npinox400m_dens"),
  c("Industrial NOX emission site density (1000 m)","4.083","NPI_DENS_1000","NPI_DENS_1000","npinox1000m_dens"),
  c("Industrial land use (10,000 m)","0.451","((INDUSTRIAL_10000M - 10)/10)","area_ind as INDUSTRIAL_10000M", "ind_insct_buffer_area"),
  c("Calendar year", "-0.140", paste0("(",yy,"-2008)"), "year", yy)
))
names(coeffs) <- c("name", "coefficient", "variable", "var_name", "table_name")
coeffs

for(ty in 1:nrow(coeffs)){
  #  ty = 3
  coeff_i <- coeffs[ty,"coefficient"]
  var1 <- coeffs[ty,"variable"]
  var <- ifelse(var1 == "intercept", "", paste(" * ", var1))
  var2 <- coeffs[ty,"var_name"]
  tbl <- coeffs[ty,"table_name"]
  
  txt0 <- paste("(",coeff_i,var,")", sep  = "")
if(ty == 1){
  txt <- txt0
} else {
  txt <- paste0(txt, " + \n", txt0)
}

  if(var2 == "year") next ## this is a constant, not a table
  main_merge0 <- paste0("t",ty-1, ".", var2)
if(ty == 2){
  main_merge <- paste0("select t1.gid, ",xcoord,", ",ycoord,", ", main_merge0)
} else {
  main_merge <- paste0(main_merge, ", ", main_merge0)
}

  main_merge0_tbls <- paste0(unique_name, "_", tbl, " as t",ty-1)
  if(ty == 2){
    main_merge_tbls <- paste0(main_merge0_tbls)
  } else {
    main_merge_tbls <- paste0(main_merge_tbls, "\nleft join ", main_merge0_tbls, "\non t1.gid = t",ty-1,".gid")
  }
  
}
cat(txt)
cat(main_merge)
main_merge_tbls <- paste0(main_merge_tbls, "\nleft join ",recpt," t",ty+1,"\non t1.gid = t",ty+1,".gid")
cat(main_merge_tbls)

sql <- paste0("select gid, ",xcoord," as x, ",ycoord," as y,\n",txt,"\nas predicted,\nmain_merge.*\nfrom (",main_merge,"\nfrom\n",main_merge_tbls,") main_merge")
cat(sql)
predicted <- dbGetQuery(ch,sql)

# summary(predicted)
# predicted[1:10,]
# predicted[1:10,1:4]
# predicted[,1:4]
# t(predicted[1,])
# write.csv(predicted, "working_temporary/qc_predicted.csv", row.names = F)

if(estimation_grid){
pred <- predicted[,c("x", "y", "predicted")]

gridded(pred) <- ~x+y

#plot(pred)
#dir(outdir)

pred <- raster(pred)
writeRaster(pred, sprintf("%s/%s.tif", outdir, outfile), format = "GTiff", overwrite=T)
}

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
