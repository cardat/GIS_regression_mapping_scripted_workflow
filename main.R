## GIS_regression_mapping_scripted_workflow
## ivanhanigan

## load libraries and functions
source("code/function_get_pgpass.R")
source("code/function_pgListTables.R")

#### 01 Connect to postGIS database ####
## TODO storePassword?
source("code/01_test_connection_to_PostGIS.R")

## create a random label to identify the working files for this run
unique_name <- basename(tempfile())
## unique_name <- "file314c66f3cbb3"

## run the scripts in order

#### 02 create buffers ####
## declare inputs
recpt <- "public.mb_test01_bldngs"
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
## declare inputs
yy <- 2007
omi <- paste("sat_omi_no2.omi_no2_",yy,"kr1_new", sep = "")
## TODO should this compute the average of pixels within polygons (and if so should it be weighted by area of overlap?)
source("code/03_extract_OMI.R")

#### 04 impervious_surfaces ####
impsa <- "impervious_surfaces.impsa_mb_test01"
## TODO we should generalise this so it is not necessarily the 1200 buffer
source("code/04_overlay_IMPSA_with_1200M.R")         

#### 05 major roads ####
majrds <- "roads_psma.majrds_bankstown_mb_test01"
## NB we reproject this into metres albers equal area

source("code/05_majrds_intersect_with_500m_buffer.R")

#### 06 NPI ####
npi <- "npinox.npinox_2008_2009"
coast <- "abs_ste.ste_2011_aus_albers"
radii_todo <- c(1000, 400)

source("code/06_NPINOX_extract.R")

#### 07 industrial and openspace_buffer ####
ind <- "abs_mb.mb_2011_nsw_albers"
radii_todo <- 10000

source("code/07_industrial_or_open_in_buffer.R")

#### 08 Merge master table ####
predicted <- dbGetQuery(ch,
##cat(
paste("
select gid, 4.563 + ((0.701 * ((grid_code-10)/10))) + (1.203 * RASTERVALU ) + (0.828 *(RDS_500M - 0.65)) + (-0.17 * ((OPENSPACE_10000M-10)/10)) + (2.629 * NPI_DENS_400) + (4.083 * NPI_DENS_1000) + (0.451 * ((INDUSTRIAL_10000M - 10)/10)) + (-0.14 * (year-2008)) as predicted
from (
select t1.gid, t1.grid_code, t2.RASTERVALU, t3.RDS_500M, t4.area_ind as INDUSTRIAL_10000M, t4.area_open as OPENSPACE_10000M, t5.npi_dens_400, t6.npi_dens_1000, ",yy," as year
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
) main_merge
", sep = "")
)
predicted

## from Luke 
## ("4.563 + ((0.701 * (([grid_code]-10)/10))) + (1.203 * [RASTERVALU] ) + (0.828 *([Sum_RDS_50]-0.65)) + (-0.17 *(([OPENSPACE_10000M]-10)/10)) + (2.629 * [NPI_DENS_4]) + (4.083 * [NPI_DENS_1]) + (0.451 *(([INDUSTRIAL_10000M]-10)/10)) + (-0.14 * ([YEAR_2007]-2008))")

## clean up the database for the working tables while developing this run?
tbls <- pgListTables(ch, "public")
tbls_todo <- tbls[grep(unique_name, tbls$relname),]
tbls_todo
for(tb in tbls_todo$relname){
  dbSendQuery(ch, sprintf("drop table %s", tb))
}
