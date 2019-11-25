## declare inputs
recpt <- "public.mb_test01_bldngs"
radii <- c(400,500,1000,1200,10000)
## convert metres to decimal degrees
radiiV2 <- radii/100000


for(ir in 1:length(radii)){
##  ir = 1
i <- radii[ir]
idd <- radiiV2[ir]
## check for primary key
suppressWarnings(chck <- dbGetQuery(ch, sprintf("select * from %s limit 1", recpt)))
if(length(grep("gid", names(chck))) == 0) stop("no variable called gid. is there a primarey key?")


## note we are using the albers srid to ensure computations are in metres
srid <- 3577
## check it exists
# dbGetQuery(ch,
# sprintf("select * from spatial_ref_sys where auth_srid = %s", srid)           
#            )

## TODO should this buffer be around the centroid?
dbSendQuery(ch,
## cat(
paste("select gid, st_buffer(st_centroid(st_transform(geom,",srid,")), ",i,") as geom
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


