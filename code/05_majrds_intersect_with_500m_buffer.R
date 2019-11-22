majrds <- "roads_psma.majrds_bankstown_mb_test01"

dbSendQuery(ch,
"select clipped.gid, clipped_geom
into file314c66f3cbb3_majrds500m
from (
  select trails.gid, 
  (ST_Dump(ST_Intersection(country.geom, trails.geom))).geom clipped_geom
  from file314c66f3cbb3_buffer500 as country
  inner join 
  roads_psma.majrds_bankstown_mb_test01 as trails 
  on ST_Intersects(country.geom, trails.geom)
) as clipped
where ST_Dimension(clipped.clipped_geom) = 1;
")
## from https://postgis.net/docs/ST_Intersection.html
