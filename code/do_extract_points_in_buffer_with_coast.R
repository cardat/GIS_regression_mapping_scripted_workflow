
for(ri in radii_todo){
## ri <- radii_todo[1]

## DEPRECATED this one adds empty buffers
# dbSendQuery(ch,
# ## cat(
# paste("drop table if exists ",unique_name,"_",source_lyr_nam,ri,"m;
# select foo.*, case when bar.count_",source_lyr_nam," is null then 0 else bar.count_npinox end
# into ",unique_name,"_",source_lyr_nam,ri,"m
# from ",unique_name,"_buffer_",ri," foo
# left join
# ( 
# select t1.gid, count(t2.gid) as count_",source_lyr_nam,", t1.geom 
# from ",unique_name,"_buffer_",ri," t1,
# ",source_lyr," t2
# where st_contains(t1.geom, t2.geom_albers)
# group by t1.gid, t1.geom
# ) bar
# on foo.gid = bar.gid", sep = "")
# )

buff_todo <- ri
lyr_out_suffix <- paste(source_lyr_nam, ri, "m", sep = "")
out_colname <- "count_gid"

sql_txt <- extract_points_in_buffer(
  source_lyr = source_lyr
  ,
  source_lyr_geom_col = "geom_albers"
  ,
  src_var = "gid"
  ,
  buff_todo = buff_todo
  ,
  out_table = paste(unique_name,"_",lyr_out_suffix, sep = "")
  ,
  out_colname = out_colname
  ,
  buffer_table = paste(unique_name,"_buffer_",buff_todo, sep = "")
  ,
  fun = "count"
)

dbSendQuery(ch,
# cat(
  sql_txt
)
  
  
## we don't want to divide by the total area of buffers if some of the area is in the ocean!
## so calculate the area of land
dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_npinox",ri,"m_insct_buffer;
select t1.gid, st_intersection(t1.geom, t2.geom) as geom
into ",unique_name,"_",source_lyr_nam,ri,"m_insct_buffer
from ",unique_name,"_buffer_",ri," t1,
",coast," t2
where st_intersects(t1.geom, t2.geom)", sep = "")
)

## CALCULATE AREA IN KM2

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_",source_lyr_nam,ri,"m_denom;
select t1.gid, st_area(t1.geom)/1000000 as area
into ",unique_name,"_",source_lyr_nam,ri,"m_denom
from ",unique_name,"_",source_lyr_nam,ri,"m_insct_buffer t1", sep = "")
)
  
#### CALC DENS ####

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_",source_lyr_nam,ri,"m_dens;
select t1.gid, ",out_colname,"/area as ",output_name,"_",ri,"
into ",unique_name,"_",source_lyr_nam,ri,"m_dens
from ",unique_name,"_",source_lyr_nam,ri,"m t1
left join
",unique_name,"_",source_lyr_nam,ri,"m_denom t2
on t1.gid = t2.gid", sep = "")
)
  
}
