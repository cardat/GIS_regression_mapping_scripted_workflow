#### getPassword ####
getPassword <- function(remote = F){
  if(remote == F){
    require(tcltk)
    tt <- tktoplevel()
    pass=tclVar('')
    label.widget <- tklabel(tt, text='Enter Password')
    password.widget <- tkentry(tt,show='*',textvariable=pass)
    ok <- tkbutton(tt,text='Ok',command=function()tkdestroy(tt))
    tkpack(label.widget, password.widget,ok)
    tkwait.window(tt)
    return(tclvalue(pass))
  } else {
    pass <- readline('Type your password into the console: ')
    return(pass)
  }
}

#### LinuxOperatingSystem ####
LinuxOperatingSystem <- function(){
  if(length(grep('linux',sessionInfo()[[1]]$os)) == 1)
  {
    #print('Linux')
    os <- 'linux' 
    OsLinux <- TRUE
  }else if (length(grep('ming',sessionInfo()[[1]]$os)) == 1)
  {
    #print('Windows')
    os <- 'windows'
    OsLinux <- FALSE
  }else
  {
    # don't know, do more tests
    print('Non linux or windows os detected. Assume linux-alike.')
    os <- 'linux?'
    OsLinux <- TRUE
  }
  
  return (OsLinux)
}

#### get_pgpass ####
get_pgpass <- function(database, host, user, savePassword = FALSE){
  
  linux <- LinuxOperatingSystem()
  if(linux)
  {
    fileName <- "~/.pgpass"
  } else
  {
    directory <- Sys.getenv("APPDATA")
    fileName <- file.path(directory, "postgresql", "pgpass.conf")
  }
  #    passwordTable <- get_passwordTable(fileName = fileName)
  exists <- file.exists(fileName)
  if (!exists & !linux)
  {
    dir.create(file.path(directory, "postgresql"))
  } else {
    if(!exists){ 
      passwordTable <- data.frame("host:port:database:user:pwd\n")
      write.table(passwordTable, fileName, row.names = F, col.names = F, quote = F)
    } 
    passwordTable <- read.table(fileName, sep = ":", stringsAsFactors=FALSE)
    
    #return(passwordTable)
  }
  if(exists('passwordTable'))
  {
    hostColumn <- 1
    databaseColumn <- 3
    userColumn <- 4
    passwordColumn <- 5
    
    recordIndex <- which(passwordTable[,hostColumn] == host &
                           passwordTable[,databaseColumn] == database & passwordTable[,userColumn] == user)
    
    if (length(recordIndex > 0) > 0)
    {
      pwd <- passwordTable[recordIndex, passwordColumn]
      pwd <- as.character(pwd)
      
      
    } else {
      
      pwd <- getPassword()
    }
  } else {
    pwd <- getPassword()
    recordIndex <- NULL
  }
  record <- c(V1 = host, V2 = "5432", V3 = database, V4 = user, V5 = pwd)
  #record <- paste(host, ":5432:*:",  user,":",  pgpass, collapse = "", sep = "")
  record <- t(record)
  #TODO get user ok here, also on linux need to add
  "WARNING: You have opted to save your password. It will be stored in plain text in your project files and in your home directory on Unix-like systems, or in your user profile on Windows. If you do not want this to happen, please press the Cancel button."
  
  #savePassword = TRUE
  
  if (savePassword & length(recordIndex > 0) == 0)
  {
    
    if (!exists("passwordTable"))
    {
      passwordTable <- as.data.frame(record)
    }else
    {
      passwordTable = rbind(passwordTable, record)
    }
    
    write.table(x = passwordTable, file = fileName, sep = ":", eol =
                  "\r\n", row.names = FALSE, col.names = FALSE, quote = FALSE)
  }
  
  return (record)
}