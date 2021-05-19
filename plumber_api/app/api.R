
# sudo docker run --rm -p 8000:8000 -v `pwd`AWS_RShiny_wAPI/plumber_api/app:/app customdock /app/api.R 


#* List of Symbols
#* @get /symbols
function() {

  # data = readRDS('/home/rstudio/AWS_RShiny_wAPI/plumber_api/app/index.rds')
  data = readRDS('/app/index.rds')
  
  unique(data$sym_short)

}

#* Historical Pull for Symbol
#* @param sumbol the symbol to pull data for
#* @get /data
function(sym = 'SP') {
  
  library(dplyr)
  # data = readRDS('/home/rstudio/AWS_RShiny_wAPI/plumber_api/app/index.rds')
  data = readRDS('/app/index.rds')
  
  data %>%
    filter(tolower(sym_short) %in% tolower(strsplit(sym,',')[[1]]))

  # jsonlite::toJSON(jsonprep)
  
}