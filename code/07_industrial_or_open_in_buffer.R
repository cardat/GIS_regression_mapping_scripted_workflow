## 07 industrial and open space land types
## industrial (ind)
dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_ind_insct_buffer;
select t1.gid, st_area(st_intersection(t1.geom, t2.geom)) as area_ind
into ",unique_name,"_ind_insct_buffer
from ",unique_name,"_buffer",radii_todo," t1,
(select * from ",ind," where mb_cat11 = 'Industrial') t2
where st_intersects(t1.geom, t2.geom)", sep = "")
)

## open space (open)
dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_open_insct_buffer;
select t1.gid, st_area(st_intersection(t1.geom, t2.geom)) as area_open
into ",unique_name,"_open_insct_buffer
from ",unique_name,"_buffer",radii_todo," t1,
(select * from ",ind," where mb_cat11 in ('Water', 'Parkland', 'Agricultural')) t2
where st_intersects(t1.geom, t2.geom)", sep = "")
)

## 10000M INTERSECT WITH COASTLINE

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_buffer",radii_todo,"_insct_coast;
select t1.gid, st_area(st_intersection(t1.geom, t2.geom)) as area_denom
into ",unique_name,"_buffer",radii_todo,"_insct_coast
from ",unique_name,"_buffer",radii_todo," t1,
",coast," t2
where st_intersects(t1.geom, t2.geom)", sep = "")
)


## calc area (converting into square kms)
## drop table ",unique_name,"_ind_insct_buffer_area;
dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_ind_insct_buffer_area;
select foo.gid, bar.area_ind/1000000 as area_ind, baz.area_open/1000000 as area_open, 
    area_denom/1000000 as area_denom
into ",unique_name,"_ind_insct_buffer_area
from ",unique_name,"_buffer",radii_todo,"_insct_coast foo
left join 
(
select t1.gid, sum(area_ind) as area_ind
from ",unique_name,"_ind_insct_buffer t1
group by t1.gid
) bar     
on foo.gid = bar.gid
left join 
(
select t1.gid, sum(area_open) as area_open
from ",unique_name,"_open_insct_buffer t1
group by t1.gid
) baz     
on foo.gid = baz.gid
", sep = "")
)

