## extract lines in buffer

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_",source_lyr_nam, buff_todo,"m;
select clipped.gid, ",source_lyr_var,", clipped_geom as geom
into ",unique_name,"_",source_lyr_nam, buff_todo,"m
from (
  select trails.gid as gid_roads, ",source_lyr_var,", country.gid as gid, 
  (ST_Dump(ST_Intersection(country.geom, trails.geom))).geom clipped_geom
  from ",unique_name,"_buffer",buff_todo," as country
  inner join 
  (select gid, ",source_lyr_var,", geom from ",majrds,") as trails 
  on ST_Intersects(country.geom, trails.geom)
) as clipped
where ST_Dimension(clipped.clipped_geom) = 1;
", sep = "")
)
## from https://postgis.net/docs/ST_Intersection.html

## to test one
# dbSendQuery(ch,
# ## cat(
# paste("
# select t1.gid, ",source_lyr_var,", st_length(t1.geom) as len, t1.geom
# into ",unique_name,"_majrds500mAlbersGID1
# from ",unique_name,"_majrds500m t1
# where gid = 1
# ", sep = "")
#            )


dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_",source_lyr_nam, buff_todo,"mAlbers_length;
select t1.gid, ",source_lyr_var,", st_length(t1.geom) as len, t1.geom
into ",unique_name,"_",source_lyr_nam, buff_todo,"mAlbers_length
from ",unique_name,"_",source_lyr_nam, buff_todo,"m t1
", sep = "")
)

## do 
## slect ("",source_lyr_var,"" =2 OR "",source_lyr_var,"" =3) these are multilane roads

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_",source_lyr_nam, buff_todo,"mAlbers_total_road_length;
select t1.gid, 
",source_lyr_var,",
case when ",source_lyr_var," in (2,3) then sum(len)/2 else sum(len) end as RDS_",buff_todo,"M 
into ",unique_name,"_",source_lyr_nam, buff_todo,"mAlbers_total_road_length
from ",unique_name,"_",source_lyr_nam, buff_todo,"mAlbers_length t1
group by gid, ",source_lyr_var,"
order by gid
", sep = "")
)

