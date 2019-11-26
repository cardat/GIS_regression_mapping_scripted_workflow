## 06 NPI

for(ri in radii_todo){
## ri <- radii_todo[1]

#### 06.0 NPINOX EXTRACT ####

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_npinox",ri,"m;
select foo.*, case when bar.count_npinox is null then 0 else bar.count_npinox end
into ",unique_name,"_npinox",ri,"m
from ",unique_name,"_buffer",ri," foo
left join
( 
select t1.gid, count(t2.gid) as count_npinox, t1.geom 
from ",unique_name,"_buffer",ri," t1,
",npi," t2
where st_contains(t1.geom, st_transform(t2.geom, 3577))
group by t1.gid, t1.geom
) bar
on foo.gid = bar.gid", sep = "")
)

#### 06.1 NPINOX INTERSECT COASTLINE ####
## we don't want to divide by the total area of buffers if some of the area is in the ocean!
## so calculate the area of land
dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_npinox",ri,"m_insct_buffer;
select t1.gid, st_intersection(t1.geom, t2.geom) as geom
into ",unique_name,"_npinox",ri,"m_insct_buffer
from ",unique_name,"_buffer",ri," t1,
",coast," t2
where st_intersects(t1.geom, t2.geom)", sep = "")
)

#### 06.1.1 NPINOX CALC AREA ####
## CALCULATE AREA IN KM2

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_npinox",ri,"m_denom;
select t1.gid, st_area(t1.geom)/1000000 as area
into ",unique_name,"_npinox",ri,"m_denom
from ",unique_name,"_npinox",ri,"m_insct_buffer t1", sep = "")
)
  
#### 06.1.2 CALC DENS ####

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_npinox",ri,"m_dens;
select t1.gid, count_npinox/area as npi_dens_",ri,"
into ",unique_name,"_npinox",ri,"m_dens
from ",unique_name,"_npinox",ri,"m t1
left join
",unique_name,"_npinox",ri,"m_denom t2
on t1.gid = t2.gid", sep = "")
)
  
}
