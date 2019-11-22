
if(!require("RPostgreSQL")) install.packages("RPostgreSQL"); library("RPostgreSQL")
load("~/private/postgres_pwd.Rdata")
drv <- dbDriver("PostgreSQL")
ch <- dbConnect(drv, dbname = "postgis_car",
                host = "130.56.248.13", port = 5432,
                user = "username", password = postgres_pwd)
rm(postgres_pwd) # removes the password
