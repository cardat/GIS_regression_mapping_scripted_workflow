## GIS_regression_mapping_scripted_workflow
## ivanhanigan

## load libraries and functions
source("code/function_get_pgpass.R")
source("code/function_pgListTables.R")

## Connect to postGIS database
## TODO storePassword?
source("code/01_test_connection_to_PostGIS.R")

## create a random label to identify the working files for this run
unique_name <- basename(tempfile())
## unique_name <- "file314c66f3cbb3"

## clean up the database for the working tables while developing this run?
recreate <- TRUE
tbls <- pgListTables(ch, "public")
tbls_todo <- tbls[grep(unique_name, tbls$relname),]
tbls_todo
for(tb in tbls_todo$relname){
  dbSendQuery(ch, sprintf("drop table %s", tb))
}

## run the scripts in order
source("code/02_buffers.R")                          
source("code/03_extract_OMI.R")
source("code/04_overlay_IMPSA_with_1200M.R")         
source("code/05_majrds_intersect_with_500m_buffer.R")
source("code/06_NPINOX_extract.R")
source("code/07_industrial_in_10000m_buffer.R")

("4.563 + ((0.701 * (([grid_code]-10)/10))) + (1.203 * [RASTERVALU] ) + (0.828 *([Sum_RDS_50]-0.65)) + (-0.17 *(([OPENSPACE_10000M]-10)/10)) + (2.629 * [NPI_DENS_4]) + (4.083 * [NPI_DENS_1]) + (0.451 *(([INDUSTRIAL_10000M]-10)/10)) + (-0.14 * ([YEAR_2007]-2008))")
