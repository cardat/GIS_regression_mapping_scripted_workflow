create_buffers <- function(
  out_table = paste(unique_name,"buffer",i, sep = "_")
  ,
  recpt = recpt
){

sql_txt0 <- paste("drop table if exists ",out_table,";
select gid, st_buffer(geom, ",i,") as geom
into ",out_table,"
from ", recpt, ";", sep = "")

## index to speed up spatial queries
sql_txt1 <- paste("CREATE INDEX \"",out_table,"_gist\"
ON public.",out_table,"
USING gist
(geom)",  ";", sep = "")

sql_txt2 <- paste("ALTER TABLE public.",out_table," CLUSTER ON \"",out_table,"_gist\";\n",sep="")

sql_txt <- paste(sql_txt0, sql_txt1, sql_txt2, sep = "\n")

sql_txt
}