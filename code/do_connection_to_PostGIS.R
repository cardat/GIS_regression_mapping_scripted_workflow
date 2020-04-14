#### do connection to postgis ####
pwd <- get_pgpass(database = "postgis_car", host = "swish4.tern.org.au", user = username, remote = TRUE, savePassword = TRUE)

drv <- dbDriver("PostgreSQL")
ch <- dbConnect(drv, dbname = pwd[,3],
                host = pwd[,1], port = 5432,
                user = pwd[,4], password = pwd[,5])
rm(pwd) # removes the password

##dbGetQuery(ch, "select * from public.dbsize ")
