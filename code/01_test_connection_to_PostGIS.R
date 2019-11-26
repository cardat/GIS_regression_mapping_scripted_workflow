#### 01 connection to postgis ####
if(!require("RPostgreSQL")) install.packages("RPostgreSQL"); library("RPostgreSQL")

source("code/function_get_pgpass.R")
pwd <- get_pgpass(database = "postgis_car", host = "swish4.tern.org.au", user = username, savePassword = FALSE)

drv <- dbDriver("PostgreSQL")
ch <- dbConnect(drv, dbname = pwd[,3],
                host = pwd[,1], port = 5432,
                user = pwd[,4], password = pwd[,5])
rm(pwd) # removes the password

dbGetQuery(ch, "select * from public.dbsize ")

#### load receptor locations ####
# TODO

