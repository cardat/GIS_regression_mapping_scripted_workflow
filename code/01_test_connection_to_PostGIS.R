
if(!require("RPostgreSQL")) install.packages("RPostgreSQL"); library("RPostgreSQL")

source("code/function_get_pgpass.R")
pwd <- get_pgpass(database = "postgis_car", host = "130.56.248.13", user = "postgis_user", savePassword = FALSE)

drv <- dbDriver("PostgreSQL")
ch <- dbConnect(drv, dbname = "postgis_car",
                host = "130.56.248.13", port = 5432,
                user = "ivan_hanigan", password = pwd[,5])
rm(pwd) # removes the password

dbGetQuery(ch, "select * from public.dbsize ")
