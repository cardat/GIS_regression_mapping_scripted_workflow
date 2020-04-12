if(!is.na(estimation_points_filename)){
  estimation_points <- readOGR(dirname(estimation_points_filename), basename(estimation_points_filename))
  str(estimation_points@data)
}

## set the names of the columns that contain the x and y (if not using a shp file, this will be required for the grid defined below)
xcoord <- "x"
ycoord <- "y"

## if you don't have a estimation_points file, you can create a grid
## if you want to create a regular grid of points, set this to TRUE otherwise FALSE
estimation_grid <- TRUE
## NB this is hard coded to assume GDA94, which is a safe bet for Australian datasets
est_grid_srid <- 4283
## set the resolution (in dec degs)
res <- 0.005
smidge <- 0.0075 # a constant to expand the edge of the estimation grid by (in dec degs)

## set a name for the output
run_label <- "demo_case_study_region"
if(estimation_grid){
  outfile <- sprintf("%s_%s_res%s", run_label, yy, format(res, scientific = FALSE)) 
} else {
  outfile <- sprintf("%s_%s", run_label, yy) 
}

## create a random label to identify the working files for this run in the database
unique_name <- basename(tempfile())
## don't change it here, it is used to keep track of your run, and clean up after

## and set the longitudes and latitudes (use bbox or numerics), resolution and a buffer zone around the edge
## IF YOU WANT A DIFFERENT GRID YOU CAN SET THE XMIN, XMAX, YMIN, YMAX HERE INSTEAD (in dec dgs, gda94)
if(exists("estimation_points")){
  xmn <- estimation_points@bbox[1,1]
  xmx <- estimation_points@bbox[1,2]
  ymn <- estimation_points@bbox[2,1]
  ymx <- estimation_points@bbox[2,2]
  
  ## now create the grid
  if(estimation_grid){
    source("code/do_gridded_shapefile.R")
    names(pts) <- c("Id", "x", "y")
    plot(pts, cex = 0.01)
    plot(estimation_points, add = T, col = 'red')
  }
} else {
  print("you'll need to add xmin, xmax, ymin and max because estimation_points is NA")
}

## and now the final selection of estimation points, use the grid if it exists
if(estimation_grid){
  ##exists("pts")
  est_pts <- pts@data
} else {
  est_pts <- estimation_points@data
}
# head(est_pts)
# with(est_pts, plot(x, y))
# dev.off()

est_pts_tbl <- sprintf("%s_est_pts", unique_name)
names(est_pts) <- tolower(names(est_pts))
dbWriteTable(ch, est_pts_tbl, est_pts, row.names = F)
dbSendQuery(ch, sprintf("alter table public.%s add column gid serial primary key", est_pts_tbl))

dbSendQuery(ch,
            # cat(
            paste("SELECT AddGeometryColumn('public', '",est_pts_tbl,"', 'geom', ",est_grid_srid,", 'POINT', 2);
  ALTER TABLE public.",est_pts_tbl," ADD CONSTRAINT geometry_valid_check CHECK (ST_isvalid(geom));
  UPDATE public.",est_pts_tbl," SET geom=ST_GeomFromText('POINT('|| ",xcoord," ||' '|| ",ycoord," ||')',",est_grid_srid,");", sep = "")
)

#dbGetQuery(ch, sprintf("select * from %s limit 1", est_pts_tbl))

# TODO do we check the input srid? this next bit is really all about transforming the SRID, we could enforce a SRID check first and remove this bit? Therefore only correct projections allowed in?
## note we are using the australian albers equal area projection
## so set this srid. this ensures computations are in metres
srid <- 3577
## TODO if you need to check it exists:
# dbGetQuery(ch,
# sprintf("select * from spatial_ref_sys where auth_srid = %s", srid)
#             )

## now we transform the esteimation points to albers
## if the SRID is differnt need to st_transform to the GDA94 projection
namlist <- dbGetQuery(ch, paste("select * from public.",est_pts_tbl," limit 10"))
## ignore the warning about unrecognised field type
namlist2 <- paste(names(namlist), sep = "", collapse = ", ")

namlist2 <- gsub("geom", sprintf("st_transform(geom, %s) as geom", srid), namlist2)
dbSendQuery(ch,
            ## cat(
            paste("drop table if exists public.",est_pts_tbl,"_V2;
select ",namlist2,"
into public.",est_pts_tbl,"_v2
from public.",est_pts_tbl," t1
", sep = "")
)
# and so update the recpt name
recpt <- sprintf("public.%s_v2", est_pts_tbl)

## need to alert the system to the new srid
dbSendQuery(ch,
            # cat(
            paste("ALTER TABLE ",recpt,"
 ALTER COLUMN geom TYPE geometry(POINT,",srid,")
  USING ST_SetSRID(geom,", srid, ")", sep = "")
)

## check for primary key
suppressWarnings(chck <- dbGetQuery(ch, sprintf("select * from %s limit 1", recpt)))
if(length(grep("gid", names(chck))) == 0) stop("no variable called gid. is there a primarey key?")
