for(ir in 1:length(radii)){
##  ir = 1
i <- radii[ir]

sql_txt <- create_buffers(
  out_table = paste(unique_name,"buffer",i, sep = "_")
  ,
  recpt = recpt
)

dbSendQuery(ch,
## cat(
sql_txt
)

}


