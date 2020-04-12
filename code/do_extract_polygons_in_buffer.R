for(ty in 1:nrow(landuse_categories)){
#  ty = 1

lu_label <- landuse_categories[ty,"label"]  
sql <- landuse_categories[ty,"sql"]  

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_",lu_label,"_insct_buffer;
select t1.gid, st_area(st_intersection(t1.geom, t2.geom)) as area_",lu_label,"
into ",unique_name,"_",lu_label,"_insct_buffer
from ",unique_name,"_buffer_",radii_todo," t1,
(select * from ",source_lyr," ",sql,") t2
where st_intersects(t1.geom, t2.geom)", sep = "")
)

}


## INTERSECT WITH COASTLINE

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_buffer_",radii_todo,"_insct_coast;
select t1.gid, st_area(st_intersection(t1.geom, t2.geom)) as area_denom
into ",unique_name,"_buffer_",radii_todo,"_insct_coast
from ",unique_name,"_buffer_",radii_todo," t1,
",coast," t2
where st_intersects(t1.geom, t2.geom)", sep = "")
)

## calc area (converting into square kms)
for(ty in 1:nrow(landuse_categories)){
  #  ty = 1
  
  lu_label <- landuse_categories[ty,"label"]  
  
txt0 <- paste("left join 
(
select t1.gid, sum(area_",lu_label,") as area_",lu_label,"
from ",unique_name,"_",lu_label,"_insct_buffer t1
group by t1.gid
) ",lu_label,"     
on foo.gid = ",lu_label,".gid
", sep  = "")
if(ty == 1){
  txt <- txt0
} else {
  txt <- paste(txt, txt0)
}

txt2 <- paste0(lu_label,".area_",lu_label,"/1000000 as area_",lu_label)
if(ty == 1){
  txt2p1 <- txt2
} else {
  txt2p1 <- paste(txt2p1, txt2, sep = ", ")
}

}
## cat(txt)
## cat(txt2p1)

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_ind_insct_buffer_area;
select foo.gid, ",txt2p1,", 
    area_denom/1000000 as area_denom
into ",unique_name,"_ind_insct_buffer_area
from ",unique_name,"_buffer_",radii_todo,"_insct_coast foo
",txt, sep = "")
)

