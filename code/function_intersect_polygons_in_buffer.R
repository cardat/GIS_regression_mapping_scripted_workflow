#lyr_out_suffix <- "ind_insct_buffer"
intersect_polygons_in_buffer <- function(
  source_lyr = "(select * from abs_mb.mb_2011_aus_albers where mb_cat11 = 'Industrial')"
  ,
  source_lyr_geom_col = "geom"
  ,
  buff_todo = buff_todo
  ,
  out_table = paste(unique_name,"_",lyr_out_suffix, sep = "")
  ,
  out_colname = "area_ind"
  ,
  buffer_table = paste(unique_name,"_buffer_",buff_todo, sep = "")
){
sql_txt <- paste("drop table if exists ",out_table,";
select t1.gid, st_area(st_intersection(t1.geom, t2.",source_lyr_geom_col,")) as ",out_colname,"
into ",out_table,"
from ",buffer_table," t1, ",source_lyr," t2
where st_intersects(t1.geom, t2.",source_lyr_geom_col,")
", sep = "")
sql_txt
}
# 
# ,
# src_var = "grid_code"
# ,
# fun = "avg"
# group by t1.gid