impsa <- "impervious_surfaces.impsa_mb_test01"

dbSendQuery(ch,
## cat(
## drop table ",unique_name,"_impsa1200m;
paste("
select t1.gid, avg(t2.grid_code) as grid_code
into ",unique_name,"_impsa1200m
from ",unique_name,"_buffer1200 t1, ",impsa," t2
where st_intersects(t1.geom, st_transform(t2.geom,3577))
group by t1.gid
", sep = "")            
)
