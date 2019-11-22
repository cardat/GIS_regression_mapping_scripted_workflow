impsa <- "impervious_surfaces.impsa_mb_test01"

dbSendQuery(ch,
## cat(
##drop table ",unique_name,"_impsa1200m;
paste("
select t1.gid, t2.grid_code, t2.geom
into ",unique_name,"_impsa1200m
from ",unique_name,"_buffer1200 t1, ",impsa," t2
where st_intersects(t1.geom, t2.geom)
", sep = "")            
)
