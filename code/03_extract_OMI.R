## 03 omi

## check they are in same projection
srid_omi <- dbGetQuery(ch,
##cat(
paste("select st_srid(rast)
from ",omi," where rid = 1
", sep = "")
)

srid_rcpt <-dbGetQuery(ch,
##cat(
paste("select find_srid('",strsplit(recpt, "\\.")[[1]][1],"', '",strsplit(recpt, "\\.")[[1]][2],"', 'geom')
", sep = "")
)

srid_omi == srid_rcpt

dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_omi_",yy,";
select t1.gid, st_value(t2.rast, st_centroid(t1.geom)) as RASTERVALU
into ",unique_name,"_omi_",yy,"
from ",recpt," t1, ",omi," t2
", sep = "")            
)
