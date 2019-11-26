## 05 major roads

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_majrds500m;
select clipped.gid, SUBTYPE_CD, clipped_geom as geom
into ",unique_name,"_majrds500m
from (
  select trails.gid as gid_roads, SUBTYPE_CD, country.gid as gid, 
  (ST_Dump(ST_Intersection(country.geom, trails.geom))).geom clipped_geom
  from ",unique_name,"_buffer500 as country
  inner join 
  (select gid, subtype_cd, st_transform(geom, ",srid,") as geom from ",majrds,") as trails 
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
# select t1.gid, SUBTYPE_CD, st_length(t1.geom) as len, t1.geom
# into ",unique_name,"_majrds500mAlbersGID1
# from ",unique_name,"_majrds500m t1
# where gid = 1
# ", sep = "")
#            )


dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_majrds500mAlbers_length;
select t1.gid, SUBTYPE_CD, st_length(t1.geom) as len, t1.geom
into ",unique_name,"_majrds500mAlbers_length
from ",unique_name,"_majrds500m t1
", sep = "")
)

## do 
## slect ("SUBTYPE_CD" =2 OR "SUBTYPE_CD" =3) these are multilane roads

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_majrds500mAlbers_total_road_length;
select t1.gid, 
SUBTYPE_CD,
case when subtype_cd in (2,3) then sum(len)/2 else sum(len) end as RDS_500M 
into ",unique_name,"_majrds500mAlbers_total_road_length
from ",unique_name,"_majrds500mAlbers_length t1
group by gid, subtype_cd
order by gid
", sep = "")
)

