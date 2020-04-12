## extract points in buffer (average values overlapping)

extract_points_in_buffer <- function(
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
  buffer_table = paste(unique_name,"_buffer_",buff_todo, sep = "")
){
sql_txt <- paste("drop table if exists ",out_table,";
select t1.gid, avg(t2.",src_var,") as ",src_var,"
into ",out_table,"
from ",buffer_table," t1, ",source_lyr," t2
where st_intersects(t1.geom, t2.",source_lyr_geom_col,")
group by t1.gid
", sep = "")
sql_txt
}
