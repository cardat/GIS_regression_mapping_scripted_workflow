## 02 buffers

for(ir in 1:length(radii)){
##  ir = 1
i <- radii[ir]

## check for primary key
suppressWarnings(chck <- dbGetQuery(ch, sprintf("select * from %s limit 1", recpt)))
if(length(grep("gid", names(chck))) == 0) stop("no variable called gid. is there a primarey key?")




## TODO should this buffer be around the centroid?
dbSendQuery(ch,
## cat(
paste("drop table if exists ",unique_name,"_buffer",i,";
select gid, st_buffer(st_centroid(st_transform(geom,",srid,")), ",i,") as geom
into ",unique_name,"_buffer",i,"
from ", recpt, sep = "")
            )

## index to speed up spatial queries
dbSendQuery(ch,
##cat(
paste("CREATE INDEX \"buffer",i,"_",unique_name,"_gist\"
ON public.",unique_name,"_buffer",i,"
USING gist
(geom)", sep = "")
)
dbSendQuery(ch,
##cat(
paste("ALTER TABLE public.",unique_name,"_buffer",i," CLUSTER ON \"buffer",i,"_",unique_name,"_gist\";\n",sep="")
)

}


