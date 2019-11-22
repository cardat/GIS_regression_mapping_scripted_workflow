## declare inputs
yy <- 2007
omi <- paste("sat_omi_no2.omi_no2_",yy,"kr1_new", sep = "")

dbSendQuery(ch,
## cat(
paste("
select t1.gid, st_value(t2.rast, st_centroid(t1.geom))
into ",unique_name,"_omi_",yy,"
from ",recpt," t1, ",omi," t2
", sep = "")            
)
