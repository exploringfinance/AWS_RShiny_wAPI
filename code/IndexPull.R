###########################
# File: IndexPull.R
# Description: Get Index Data
# Date: 10/7/2020
# Author: Exploring Finance
# Notes: Runs in a cron job to collect index data
# To do: /usr/bin/Rscript /home/rstudio/AWS_RShiny_wAPI/code/IndexPull.R
###########################


library(httr)
library(dplyr)


# List of Indexes pulled from www.investing.com
index_list = c('fcb55c965d22c2a1f1ba4ce2788c1de1',
               'd5f35207ae3dfc721a517a541dbba7d8',
               '4642bbffbb2f93817031cce6a459701d',
               '06620ff894868f010dafb51493836e71',
               'd565a7612f2d571d32033540114babb3')

# Function to get Index Data
get_index = function(index_id){
  
  # Call to pull data from website (data is monthly)
  index_dt = content(GET(paste0('https://sbcharts.investing.com/charts_xml/',index_id,'_max.json')))
  
  # Parse out data and date
  indx_df = as.data.frame(matrix(unlist(index_dt$candles), ncol = 2, byrow = T)) 
  
  # Create Final Table
  colnames(indx_df) = c('date','value')
  indx_df %>%
    mutate(date = lubridate::as_datetime(date/1000),
           symbol = index_dt$attr$symbol)
  
}

# Apply function to list of indexes
all_index = bind_rows(lapply(index_list,get_index)) %>%
  mutate(prim_key = paste0(symbol,date),
         sym_short = gsub(' .*','',gsub("[[:punct:]]", "", symbol)))

# Save Index data to be swept to database and docker file
saveRDS(all_index,'/home/rstudio/AWS_RShiny_wAPI/plumber_api/app/index.rds')
saveRDS(all_index,'/home/rstudio/AWS_RShiny_wAPI/db_stg/index.rds')

