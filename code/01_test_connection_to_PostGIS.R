
if(!require("RPostgreSQL")) install.packages("RPostgreSQL"); library("RPostgreSQL")

source("code/function_get_pgpass.R")
pwd <- get_pgpass(database = "postgis_car", host = "130.56.248.13", user = "postgis_user", savePassword = FALSE)

drv <- dbDriver("PostgreSQL")
ch <- dbConnect(drv, dbname = pwd[,3],
                host = pwd[,1], port = 5432,
                user = pwd[,4], password = pwd[,5])
rm(pwd) # removes the password

dbGetQuery(ch, "select * from public.dbsize ")
