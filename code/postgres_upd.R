###########################
# File: postgres_upd.R
# Description:  Sweep files into the database. Create tables if needed
# Date: 5/7/2021
# Author: Exploring Finance
# Notes: Will delete files after load. Use _ts_(timestamp).rds for multiple files between loads.
# Cron: /usr/bin/Rscript /home/rstudio/AWS_RShiny_wAPI/code/postgres_upd.R
###########################

# Load Packages and connect to database
library(DBI)
library(RPostgres)
library(dplyr)
con <- dbConnect(RPostgres::Postgres())

# Check for files to load
load_files = tibble(file = list.files('/home/rstudio/AWS_RShiny_wAPI/db_stg')) %>%
  mutate(table = gsub('_ts_.*','',gsub('.rds','',file)))

# Get Table Names
tables = unique(load_files$table)


### Check for new tables and Create primary and staging if they don't exist
new_table = tables[!(tables %in% dbListTables(con))]
for(nt in new_table){
  
  fl = paste0('/home/rstudio/AWS_RShiny_wAPI/db_stg/',load_files$file[load_files$table==nt][1])
  r_file = readRDS(fl) %>%
    relocate(prim_key, .before = everything())
  colnames(r_file) = tolower(colnames(r_file))
  # Check Unique
  # nrow(r_file %>% distinct(prim_key)) == nrow(r_file)
  dbWriteTable(con, paste0(nt,'_stg'), r_file, overwrite = TRUE)
  dbWriteTable(con, nt, r_file)
  
  pk = dbSendStatement(con, paste0('ALTER TABLE ',nt,' ADD PRIMARY KEY(prim_key)'))
  dbClearResult(pk)
  pk = dbSendStatement(con, paste0('ALTER TABLE ',paste0(nt,'_stg'),' ADD PRIMARY KEY(prim_key)'))
  dbClearResult(pk)
  
  print(nt)
  
}
# dbRemoveTable(con, tn)


### Add data to table
for(i in 1:nrow(load_files)) {
  tn = load_files$table[i]
  
  fl = paste0('/home/rstudio/AWS_RShiny_wAPI/db_stg/',load_files$file[i])
  slc = paste0('SELECT * FROM ',tn,' limit 10')
  slc = dbSendStatement(con, slc)
  cur_table = dbFetch(slc)
  dbClearResult(slc)
  r_file = readRDS(fl) 
  colnames(r_file) = tolower(colnames(r_file))
  r_file = r_file %>%
    relocate(prim_key, .before = everything()) %>%
    select(colnames(cur_table)) %>%
    distinct()
  
  # Save data into staging
  dbWriteTable(con, paste0(tn,'_stg'), as.data.frame(r_file), overwrite = TRUE)
  
  # Create Queries
  dlt = paste0('DELETE FROM ',tn,
               ' WHERE prim_key IN (SELECT prim_key FROM ',
               paste0(tn,'_stg'),')')
  ins = paste0('INSERT INTO ',tn,
               ' SELECT * FROM ',paste0(tn,'_stg'))
  
  # Execute queries
  dltq = dbSendStatement(con, dlt)
  dbClearResult(dltq)
  insq = dbSendStatement(con, ins)
  dbClearResult(insq)
  
  file.remove(fl)
  
  print(fl)
  
}


