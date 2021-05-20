###########################
# File: AWS_Cost_pull.R
# Description: Get AWS Cost Data
# Date: 5/19/2021
# Author: Exploring Finance
# Notes: Runs in a cron job to collect AWS Data
# To do: /usr/bin/Rscript /home/rstudio/AWS_RShiny_wAPI/code/AWS_Cost_pull.R
###########################


# install.packages("paws")
library(paws)
library(dplyr)

## Get Key Data
awskey = readRDS('/home/rstudio/keys/bill.rds')

### Connect to cost explorer
    ca = paws:: costexplorer(
      config = list(
        credentials = list(
          creds = list(
            access_key_id = awskey$sc,
            secret_access_key = awskey$sa)),
        region = "us-east-1"))

### Get Cost Data
    cost = ca$get_cost_and_usage(TimePeriod = list(
      Start = Sys.Date()-lubridate::days(60),
      End = Sys.Date()
    ),
    Granularity = "DAILY",
    Metrics = list(
      "UsageQuantity","UnblendedCost"
    ),
    GroupBy = list(
      list(
        Type = "DIMENSION",
        
        Key = "USAGE_TYPE"
      )
    ))

### Loop through and extract data
    alldf = NULL
    for(t in 1:length(cost$ResultsByTime)){
      
      for(g in 1:length(cost$ResultsByTime[t][[1]]$Groups)){
        
        df = as.data.frame(cost$ResultsByTime[t][[1]]$Groups[[g]]$Metrics)
        df$start = cost$ResultsByTime[t][[1]]$TimePeriod$Start
        df$end = cost$ResultsByTime[t][[1]]$TimePeriod$End
        df$key = cost$ResultsByTime[t][[1]]$Groups[[g]]$Keys
        alldf = rbind(alldf,df)
        
      }
      print(t)
    }

   alldf = alldf %>% mutate(prim_key = paste0(key,start))
  
# Load Data to Databases
saveRDS(alldf,'/home/rstudio/AWS_RShiny_wAPI/db_stg/aws_usage.rds')    
source('/home/rstudio/AWS_RShiny_wAPI/code/postgres_upd.R')
