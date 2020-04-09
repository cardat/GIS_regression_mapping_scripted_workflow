## extract points in buffer (average values overlapping)
dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_",lyr_out_suffix,";
select t1.gid, avg(t2.",src_var,") as ",src_var,"
into ",unique_name,"_",lyr_out_suffix,"
from ",unique_name,"_buffer",buff_todo," t1, ",source_lyr," t2
where st_intersects(t1.geom, t2.",source_lyr_geom_col,")
group by t1.gid
", sep = "")            
)
