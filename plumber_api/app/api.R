
# sudo docker run --rm -p 8000:8000 -v `pwd`AWS_RShiny_wAPI/plumber_api/app:/app customdock /app/api.R 


#* List of Symbols
#* @get /symbols
function() {

  # data = readRDS('/home/rstudio/AWS_RShiny_wAPI/plumber_api/app/index.rds')
  data = readRDS('/app/index.rds')
  
  syms = unique(data$symbol)
  gsub(' .*','',gsub("[[:punct:]]", "", syms))
}

#* Historical Pull for Symbol
#* @param sumbol the symbol to pull data for
#* @get /data
function(sym = 'SP') {
  
  library(dplyr)
  # data = readRDS('/home/rstudio/AWS_RShiny_wAPI/plumber_api/app/index.rds')
  data = readRDS('/app/index.rds')
  
  data %>%
    mutate(sym_short = gsub(' .*','',gsub("[[:punct:]]", "", symbol))) %>%
    filter(sym_short == sym)
  
  # jsonlite::toJSON(jsonprep)
  
}