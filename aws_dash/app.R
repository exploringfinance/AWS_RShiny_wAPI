###########################
# File: app.R in aws_dash
# Description: Chart of AWS Cost Data
# Date: 5/19/2021
# Author: Exploring Finance
# Notes: 
# To do: 
###########################

# Load Libraries
library(RPostgres)
library(shiny)
library(dplyr)
library(plotly)
library(httr)

# Connect o database
con <- dbConnect(RPostgres::Postgres(),dbname = 'rstudio', 
                 host = 'localhost', # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'
                 port = 5432, # or any other port specified by your DBA
                 user = 'rstudio',
                 password = 'rstudio')


# res0 <- dbSendQuery(con, "SELECT * FROM ga_test")
# res <- dbFetch(res0) %>% as_tibble()
# dbClearResult(res0)

bill0 <-  dbSendQuery(con, "SELECT * FROM aws_usage")
bill <- dbFetch(bill0) %>% as_tibble()
dbClearResult(bill0)


ui <- fluidPage(
  
  fluidRow(column(8,titlePanel('AWS - Sample R Shiny Dashboard')),
           tags$style('#refData{background-color:#002855;color:white}'),
           column(4)),
  tags$head(tags$style(HTML("hr {border-top: 1px solid #000000;}"))),
  tags$style(HTML('.navbar {background-image: linear-gradient(#04519b, #044687 60%, #033769);}
                  .navbar-default .navbar-nav > li > a {color:white;}
                  .navbar-default .navbar-nav > li > a:hover {background-color:#178acc; color:#ffffff}
                  .navbar-default .navbar-nav > .active > a {background-color:#178acc; color:#000000}
                  .navbar-default .navbar-nav > .active > a:focus {background-color:#178acc; color:#000000}
                  .navbar-default .navbar-nav > .active > a:hover {background-color:#178acc; color:#000000}')),
  
  navbarPage('', id = 'DebtBar', inverse = TRUE,
             tabPanel('AWS Billing Data',
                      includeMarkdown("Data/faq.md"),hr(),
                      plotlyOutput('billplot'),br(),hr(),
                      plotlyOutput('usage'),br(),
                      h4('Detailed Usage Table'),
                      reactableOutput('billtb')),
             tabPanel('Stock Returns'),
             tabPanel('Sample Analytics'),
                      # p('This is plotting Analytics data sample set'),
                     # selectInput('groupby','Select Grouping Variable:', choices = c('browser','operatingsystem','devicecategory',
                      #                                                                'date','continent'), selected = 'operatingsystem'),
                      # plotlyOutput('ga_plot')),
             tabPanel('Covid 19 Appointment finder',
                      includeMarkdown("Data/covid.md"),hr(),
                      verbatimTextOutput('pull'),
                      reactableOutput('covid'))
  ))


server <- function(input, output, session) {
  
  
  observeEvent(input$groupby,{
    
    # grpby = 'browser'
    # grpby = input$groupby
    # 
    # res %>%
    #   mutate(grpcol = get(grpby)) %>%
    #   group_by(grpcol) %>%
    #   summarise(ct = n()) -> plot_ga
    # 
    # output$ga_plot = renderPlotly({
    #   plot_ly(plot_ga) %>%
    #     add_trace(x = ~grpcol, y = ~ct, color = ~grpcol, type = 'bar') %>%
    #     layout(title = paste0('Analytics Sample Data - Grouped by: ',grpby),
    #            margin = list(l = 25, r = 75, b = 25, t = 25),
    #            xaxis = list(title = 'Grouping Column'),
    #            yaxis = list(title = 'Session Count'))
    # })
    # 
    
    ######## Billing
    bill %>% as_tibble() %>% #arrange(desc(amount_in_pricing_units))
      group_by(key) %>%
      summarise(cost = sum(as.numeric(unblendedcost.amount))) %>%
      arrange(desc(cost)) -> billpt
    
    output$billplot = renderPlotly({
      plot_ly(billpt) %>%
        add_trace(x = ~key, y = ~cost, color = ~key, type = 'bar') %>%
        layout(title = paste0('AWS Test: Cost by Category'),
               margin = list(l = 25, r = 75, b = 25, t = 25),
               xaxis = list(title = 'Billing Category'),
               yaxis = list(title = 'Amount billed (in dollars)'))
    })
    
    bill %>% as_tibble() %>% #arrange(desc(amount_in_pricing_units))
      group_by(start,key) %>%
      summarise(cost = sum(as.numeric(unblendedcost.amount))) %>%
      arrange((start)) %>%
      mutate(cumcost= cumsum(cost),
             start = as.Date(start)) ->usagetime
    
    output$usage = renderPlotly({
      plot_ly(usagetime) %>%
        add_trace(x = ~start, y = ~cost, type = 'bar', color = ~key) %>%
        add_trace(x = ~start, y = ~cumcost, type = 'scatter', mode = 'lines', 
                  name = 'Cum Cost',  yaxis = "y2") %>%
        
        layout(title = paste0('AWS Test: Cost and Usage Over Time'),
               barmode = 'relative',
               hovermode = 'x-unified',
               legend = list(traceorder='reversed',orientation = "h"),
               margin = list(l = 25, r = 75, b = 25, t = 25),
               xaxis = list(title = 'Date/Time'),
               yaxis = list(title = 'Amount billed and credits (in dollars)'),
               yaxis2 = list(side = 'right', overlaying = 'y' , title='Cumulative cost/credit',
                             zeroline = F,showgrid = F))
    })
    
    
    bill %>% as_tibble() %>% #arrange(desc(amount_in_pricing_units))
      group_by(sdesc,skudesc) %>%
      summarise(cost = sum(cost),
                netcredict = sum(amount, na.rm = T),
                amount_in_pricing_units = sum(amount_in_pricing_units)) %>%
      arrange(desc(cost)) -> billtable
    
    
    output$billtb = renderReactable({reactable(billtable,outlined = TRUE, filterable = TRUE,  wrap = FALSE,
                                               showPageSizeOptions = TRUE, defaultPageSize = 10,
                                               defaultColDef = colDef(headerStyle = list(backgroundColor = '#42adf5',color='black'), #width = 200,
                                                                      format = colFormat(separators = TRUE, digits = 2)))})
    
    
    
    wg_zip_tbl = tribble(~zip, ~lat, ~long, ~town,
                         20001, 38.912068, -77.0190228, 'Washington DC',
                         10001, 40.75368539999999, -73.9991637, 'New York City',
                         94040, 37.3785351, -122.086585, 'Mountain View')
    
    
    wg_all = NULL
    for(wgr in 1:nrow(wg_zip_tbl)) {
      
      wg = POST('https://www.walgreens.com/hcschedulersvc/svc/v1/immunizationLocations/availability',
                add_headers(cookie = 'XSRF-TOKEN=wmFjkAcfQoe1+Q==.bq2BAy9RVAQld3yDaMz3QbG9hfCsczcGy1ZYW7ho/fQ=',
                            'x-xsrf-token' = 'B0kDfndIhYL9VA==.XfhJ5F9O2lqiKiUvjrAoD7/2+anzBnc4pAMdSYnmUcA='),
                body = list(appointmentAvailability = list(startDateTime = Sys.Date()),
                            position = list(latitude = wg_zip_tbl$lat[wgr], longitude = wg_zip_tbl$long[wgr]),
                            radius = 25, serviceId = '99'), encode = 'json')
      
      if(status_code(wg)==200) {wg_temp = content(wg)} else {wg_temp = NULL}
      wg_all = rbind(wg_all, as.data.frame(t(wg_temp)))
      Sys.sleep(.2)
    }
    colnames(wg_all) = c('Apt Available','Group','State','State Code','Zip','Radius','Days')
    
    output$pull = renderPrint({Sys.time()})
    output$covid = renderReactable({reactable(wg_all,outlined = TRUE, filterable = TRUE,  wrap = FALSE,
                                              showPageSizeOptions = TRUE, defaultPageSize = 10,
                                              defaultColDef = colDef(headerStyle = list(backgroundColor = '#42adf5',color='black'), #width = 200,
                                                                     format = colFormat(separators = TRUE, digits = 2)))})
    
  })
  
}


shinyApp(ui = ui, server = server)