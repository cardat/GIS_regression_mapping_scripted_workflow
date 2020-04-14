
## from these coefficients in Luke's paper we can calculate the estimation predictions for each point
## TODO this doesn't need to be done in SQL, can simplify this and just return the predictors
## TODO #2 this has a bug now that the functions used are not returning all buffers in NPI_DENS

for(ty in 1:nrow(coeffs)){
  #  ty = 1
  coeff_i <- coeffs[ty,"coefficient"]
  var1 <- coeffs[ty,"variable"]
  var <- ifelse(var1 == "intercept", "", paste(" * ", var1))
  var2 <- coeffs[ty,"var_name"]
  tbl <- coeffs[ty,"table_name"]
  
  txt0 <- paste("(",coeff_i,var,")", sep  = "")
  if(ty == 1){
    txt <- txt0
  } else {
    txt <- paste0(txt, " + \n", txt0)
  }
  
  if(var2 == "year") next ## this is a constant, not a table
  main_merge0 <- paste0("t",ty, ".", var2)
  
  if(ty == 1) next
  
  if(ty == 2){
    main_merge <- paste0("select t1.gid, ",xcoord,", ",ycoord,", ", main_merge0)
  } else {
    main_merge <- paste0(main_merge, ", ", main_merge0)
  }
  
  
  main_merge0_tbls <- paste0(unique_name, "_", tbl, " as t",ty)
  if(ty == 2){
    main_merge_tbls <- paste0(main_merge0_tbls)
    main_merge_tbls <- paste0(recpt, " t1", "\nleft join ",main_merge_tbls,"\non t1.gid = t",ty,".gid")
    
  } else {
    main_merge_tbls <- paste0(main_merge_tbls, "\nleft join ", main_merge0_tbls, "\non t1.gid = t",ty,".gid")
  }
  
}
cat(txt)
cat(main_merge)
#main_merge_tbls <- paste0(main_merge_tbls, "\nleft join ",recpt," t",ty+1,"\non t1.gid = t",ty+1,".gid")
cat(main_merge_tbls)

sql <- paste0("select gid, ",xcoord," as x, ",ycoord," as y,\n",txt,"\nas predicted,\nmain_merge.*\nfrom (",main_merge,"\nfrom\n",main_merge_tbls,") main_merge")

