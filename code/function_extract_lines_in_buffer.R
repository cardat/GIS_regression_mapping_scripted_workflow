## extract lines in buffer
extract_lines_in_buffer <- function(
  source_lyr = "roads_psma.majrds"
  ,
  source_lyr_nam = "majrds"
  ,
  buff_lyr = buff_lyr
  ,
  source_lyr_var ="subtype_cd"
  ,
  source_geom_col = "geom_albers"
  ,
  out_table = out_table
){

sql_txt0 <- paste("drop table if exists ",out_table,";
select clipped.gid, ",source_lyr_var,", clipped_geom as geom
into ",out_table,"
from (
  select trails.gid as gid_roads, ",source_lyr_var,", country.gid as gid, 
  (ST_Dump(ST_Intersection(country.geom, trails.geom))).geom clipped_geom
  from ",buff_lyr," as country
  inner join 
  (select gid, ",source_lyr_var,", ",source_geom_col," as geom from ",source_lyr,") as trails 
  on ST_Intersects(country.geom, trails.geom)
) as clipped
where ST_Dimension(clipped.clipped_geom) = 1;
", sep = "")

sql_txt1 <- paste("drop table if exists ",out_table,"Albers_length;
select t1.gid, ",source_lyr_var,", st_length(t1.geom) as len, t1.geom
into ",out_table,"Albers_length
from ",out_table," t1
", sep = "")

sql_txt <- paste(sql_txt0, sql_txt1, sep = "\n")

sql_txt
}
