## GIS_regression_mapping_scripted_workflow
## codes = ivanhanigan, regression map = luke knibbs

#### load libraries and functions ####
if(!require("raster")) install.packages("raster"); library(raster)
if(!require("rgdal")) install.packages("rgdal"); library(rgdal)
if(!require("devtools")) install.packages("devtools"); library(devtools)
if(!require(swishdbtools)){
  install_github("swish-climate-impact-assessment/swishdbtools")
}
library("swishdbtools")
if(!require("RPostgreSQL")) install.packages("RPostgreSQL"); library("RPostgreSQL")

## load bespoke functions for PostGIS work
source("code/function_create_buffers.R")
source("code/function_extract_raster_in_buffer.R")
source("code/function_extract_points_in_buffer.R")
source("code/function_extract_lines_in_buffer.R")
source("code/function_intersect_polygons_in_buffer.R")


##### set up ####
## set a username that exists on the database server (email to car.data@sydney.edu for access)
username <- "ivan_hanigan"

## set the year that is of interest for this run
yy <- 2006

## set your favourite output directory, or use getwd() to dump results to the current dir
outdir <- "working_temporary"
if(!file.exists(outdir)) dir.create(outdir)

#### connect to postGIS database ####
## TODO need to explain that some data is restricted and postgis_user can only do demo with public data, for full satellite implementation need to get permission and logon as specified username
source("code/do_connection_to_PostGIS.R")

## now run the scripts in order
## start a timer
strt <- Sys.time()

#### load data ####
## set up the estimation points data
## 1) enter the name of a ESRI shapefile that has points where you want to estimate pollution
## 2) don't include the file extension '.shp'
## 3) if you don't want this, set to NA
estimation_points_filename <- "data_provided/liverpool_sensitive_bld_labs"

## set the names of the columns that contain the x and y (if not using a shp file, this will be required for the grid defined below)
xcoord <- "x"
ycoord <- "y"

## if you don't have a estimation_points file, you can create a grid
## if you want to create a regular grid of points, set this to TRUE otherwise FALSE
estimation_grid <- TRUE
## NB this is hard coded to assume GDA94, which is a safe bet for Australian datasets
est_grid_srid <- 4283

## set the output grid resolution (in dec degs)
res <- 0.001
smidge <- 0.0075 # a constant to expand the edge of the estimation grid by (in dec degs)

## you can override the creation of a grid from the points by selecting dimensions 
custom_grid <- TRUE
# These are just an example, you should replace this with your own
xmn <- 150.92865
xmx <- 150.9665
ymn <- -33.9414
ymx <- -33.9238

## set a name for the output
run_label <- "demo_case_study_region"

## now load the spatial data of the estimation nodes
source("code/do_load_estimation_points_to_database.R")
## note this returns a warning about 'unrecognized PostgreSQL field type geometry'
## it is safe to ignore this

#### create buffers ####
radii <- c(400,500,1000,1200,10000)
source("code/do_buffers.R")

#### extract OMI satellite data ####
sql_txt <- extract_raster_in_buffer(
  out_table = paste(unique_name,"_omi_",yy, sep ="")
  ,
  source_lyr_name = paste("sat_omi_no2.omi_no2_",yy,"kr1_new_albers", sep = "")
  ,
  source_lyr_label = "omi"
  ,
  source_lyr_col_name = "RASTERVALU"
)

dbSendQuery(ch,
# cat(
sql_txt
)

#### impervious_surfaces _IMPSA_with_1200M ####
buff_todo <- 1200
lyr_out_suffix = sprintf("impsa%sm", buff_todo)

sql_txt <- extract_points_in_buffer(
  source_lyr = "impervious_surfaces.impsa"
  ,
  source_lyr_geom_col = "geom_albers"
  ,
  src_var = "grid_code"
  ,
  buff_todo = buff_todo
  ,
  out_table = paste(unique_name,"_",lyr_out_suffix, sep = "")
  ,
  out_colname = "grid_code"
  ,
  buffer_table = paste(unique_name,"_buffer_",buff_todo, sep = "")
  ,
  fun = "avg"
)

dbSendQuery(ch,
# cat(
sql_txt
)

#### major roads ####
buff_todo <- 500
source_lyr_nam = "majrds"
out_table <- paste(unique_name,"_",source_lyr_nam, buff_todo,"m", sep = "")
buff_lyr <- paste(unique_name,"_buffer_",buff_todo, sep = "")
source_lyr_var <- "subtype_cd"

sql_txt <- extract_lines_in_buffer(
  source_lyr = "roads_psma.majrds"
  ,
  source_lyr_nam = "majrds"
  ,
  buff_lyr = buff_lyr
  ,
  source_lyr_var = source_lyr_var
  ,
  source_geom_col = "geom_albers"
  ,
  out_table = out_table
)

dbSendQuery(ch,
# cat(
sql_txt
)
            
## do additional calculation specific to the psma majrds layer
## slect (subtype_cd =2 OR subtype_cd =3) these are multilane roads
## we want to treat them as single line lengths (divide by 2)

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

#### NPI ####
## TODO why is this not like the impsa code?
# maybe change extract pts in buff to take avg vs count? also the coastline...
source_lyr <- "npi.npinox_2008_2009"
source_lyr_nam <- "npinox"
coast <- "abs_ste.ste_2011_aus_albers_simple"
radii_todo <- c(1000, 400)
output_name <- "npi_dens"

source("code/do_extract_points_in_buffer_with_coast.R")

#### industrial and openspace_buffer ####
source_lyr <- "abs_mb.mb_2011_aus_albers"
lyr_out_suffix <- "ind_insct_buffer"
buff_todo <- 10000
landuse_categories <- data.frame(rbind(
  c("Industrial", "where mb_cat11 = 'Industrial'", "ind"),
  c("Open", "where mb_cat11 in ('Water', 'Parkland', 'Agricultural')", "open")
))
names(landuse_categories) <- c("type", "sql", "label")

source("code/do_extract_polygons_in_buffer.R")

ed <- Sys.time()
print(ed - strt)

#### Merge master table ####
## Use the coeefficients as per Knibbs et al 2014
## Knibbs, L. D., Hewson, M. G., Bechle, M. J., Marshall, J. D., & Barnett, A. G. (2014). A national satellite-based land-use regression model for air pollution exposure assessment in Australia. Environmental Research, 135, 204–211. https://doi.org/10.1016/j.envres.2014.09.011
## Note that some of these are centred and standardised
coeffs <- data.frame(rbind(
  c("Intercept","4.563", "intercept", "",""),
  c("Impervious surfaces (1200 m)", "0.701", "((case when grid_code is null then 0 else grid_code end-10)/10)", "grid_code", "impsa1200m"),
  c("OMI column NO2","1.203","RASTERVALU", "RASTERVALU", paste0("omi_",yy)),
  c("Major roads (500 m)", "0.828", "((case when RDS_500M is null then 0 else RDS_500M end /1000) - 0.65)", "RDS_500M", "majrds500mAlbers_total_road_length"),
  c("Open space (10,000 m)","-0.170","((OPENSPACE_10000M-10)/10)", "area_open as OPENSPACE_10000M", "ind_insct_buffer_area"),
  c("Industrial NOX emission site density (400 m)","2.629","case when NPI_DENS_400 is null then 0 else NPI_DENS_400 end", "NPI_DENS_400", "npinox400m_dens"),
  c("Industrial NOX emission site density (1000 m)","4.083","case when NPI_DENS_1000 is null then 0 else NPI_DENS_1000 end","NPI_DENS_1000","npinox1000m_dens"),
  c("Industrial land use (10,000 m)","0.451","((INDUSTRIAL_10000M - 10)/10)","area_ind as INDUSTRIAL_10000M", "ind_insct_buffer_area"),
  c("Calendar year", "-0.140", paste0("(",yy,"-2008)"), "year", yy)
))
names(coeffs) <- c("name", "coefficient", "variable", "var_name", "table_name")
coeffs

source("code/do_main_merge.R")

predicted <- dbGetQuery(ch,
# cat(
sql
)

# summary(predicted)
# predicted[1:10,]
# predicted[1:10,1:4]
# predicted[,1:4]
# t(predicted[1,])
# write.csv(predicted, "working_temporary/qc_predicted.csv", row.names = F)

if(estimation_grid){
pred <- predicted[,c("x", "y", "predicted")]

gridded(pred) <- ~x+y

# plot(pred)
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

