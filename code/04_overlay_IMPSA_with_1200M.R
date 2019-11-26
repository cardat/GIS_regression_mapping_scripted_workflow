## 04 impervious
dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_impsa1200m;
select t1.gid, avg(t2.grid_code) as grid_code
into ",unique_name,"_impsa1200m
from ",unique_name,"_buffer1200 t1, ",impsa," t2
where st_intersects(t1.geom, st_transform(t2.geom,3577))
group by t1.gid
", sep = "")            
)
