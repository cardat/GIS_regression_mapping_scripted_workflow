
extract_raster_in_buffer <- function(
  out_table = out_table
  ,
  source_lyr_name = paste("sat_omi_no2.omi_no2_",yy,"kr1_new_albers", sep = "")
  ,
  source_lyr_label = "omi"
  ,
  source_lyr_col_name = "RASTERVALU"
){
sql_txt <- paste("drop table if exists ",out_table,";
select t1.gid, st_value(t2.rast, t1.geom) as ",source_lyr_col_name,"
into ",out_table,"
from ",recpt," t1, ",source_lyr_name," t2
", sep = "")
sql_txt
}
