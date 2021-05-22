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
library(reactable)
library(lubridate)

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
bill <- dbFetch(bill0) %>% as_tibble() %>% #arrange(desc(amount_in_pricing_units))
  mutate(category = gsub(':.*','',key),
         category = gsub('-.*','',category),
         start = as.Date(start),
         Day = start,
         Week = lubridate::floor_date(start,unit = 'week'),
         Month = lubridate::floor_date(start,unit = 'month'))
dbClearResult(bill0)

# Make initial pull from database
res0 <- dbSendQuery(con, "SELECT * FROM index")
res <- dbFetch(res0) %>% as_tibble()
dbClearResult(res0)



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
                      dateRangeInput('awsdts','Select Date Range for Bills',start = '2020-07-01', end = Sys.Date()),
                      plotlyOutput('billplot'),br(),hr(),
                      selectInput('grpby','Select Date Grouping',choices = c('Day','Week','Month'), selected = 'Week'),
                      plotlyOutput('cost'),hr(),
                      selectInput('usgtype','Select Metric to view usage', choices = unique(bill$category)),
                      plotlyOutput('usage'),hr(),
                      p('Detailed Billing Table'),
                      reactableOutput('billtb')
                      ),
             tabPanel('Index Returns',
                      p('The main purpose of this tab is to demonstrate the API and local database both hosted on this server. ',
                        "This tab compares the returns of select Index Data. The information was scraped from ",
                      a('www.investing.com', href = 'www.investing.com'),'. A more complex version of financial portfolio ',
                      'construction can be found ',a('here',href = 'https://exploringfinance.shinyapps.io/PortfolioCompare/'),'.'),
                      sidebarLayout(
                        
                        # Sidebar to demonstrate various slider options ----
                        sidebarPanel(
                          
                          # Input: Select Indexes  ----
                          selectInput('index','Select Index',choices = unique(res$symbol), selected = unique(res$symbol)[1], multiple = TRUE),
                          
                          # Input: Set Date Range  ----
                          dateRangeInput('dtrng','Select Date Range',start = '2000-01-01',end = Sys.Date()),
                          helpText('Data is only available monthly'),
                          
                          # Input: Choose data Source  ----
                          radioButtons('dbapi','Choose where to source data', choices = c('Postgres','API')),
                          
                          # Action button for refresh
                          actionButton('refresh','Refresh Chart')),
                        
                        # Main panel for displaying outputs ----
                        mainPanel(
                          
                          # Output: Plot summary ----
                          plotlyOutput("plot")
                          
                        )))
  ))


server <- function(input, output, session) {
  
  
  
    observeEvent(c(input$awsdts),{
    ######## Billing
      # strt = '2020-07-01'; end_dt = Sys.Date(); grp = 'Week'; usg = bill$category[1]
      strt = as.Date(input$awsdts[1]); end_dt =  as.Date(input$awsdts[2]); grp = input$grpby
      
    bill %>%
      filter(Day >= strt, Day <= end_dt) %>%
      group_by(category) %>%
      summarise(cost = sum(as.numeric(unblendedcost.amount))) %>%
      arrange(desc(cost)) -> billpt

    output$billplot = renderPlotly({
      plot_ly(billpt) %>%
        add_trace(x = ~category, y = ~cost, color = ~category, type = 'bar') %>%
        layout(title = paste0('AWS Test: Cost by Category'),
               margin = list(l = 25, r = 75, b = 25, t = 25),
               xaxis = list(title = 'Billing Category'),
               yaxis = list(title = 'Amount billed (in dollars)'))
    })

    observeEvent(c(input$grpby,input$usgtype),{
      
      strt = as.Date(input$awsdts[1]); end_dt =  as.Date(input$awsdts[2]); grp = input$grpby;  usg = input$usgtype

    bill %>%
      filter(Day >= strt, Day <= end_dt) %>%
      mutate(GrpDate = get(grp)) %>%
      group_by(GrpDate,category) %>%
      summarise(cost = sum(as.numeric(unblendedcost.amount))) %>%
      arrange((GrpDate)) %>%
      mutate() -> costamt

    costamt %>%
      group_by(GrpDate) %>%
      summarise(cost = sum(cost)) %>%
      mutate(cumcost = cumsum(cost)) -> cumcost
   
    
    output$cost = renderPlotly({
      plot_ly(costamt) %>%
        add_trace(x = ~GrpDate, y = ~cost, type = 'bar', color = ~category) %>%
        add_trace(data = cumcost, x = ~GrpDate, y = ~cumcost, type = 'scatter', mode = 'lines',
                  name = 'Cum Cost',  yaxis = "y2") %>%
        
        layout(title = paste0('AWS Test: Cost Over Time by ',grp),
               barmode = 'relative',
               hovermode = 'x-unified',
               #legend = list(traceorder='reversed',orientation = "h"),
               margin = list(l = 25, r = 75, b = 25, t = 25),
               xaxis = list(title = 'Date/Time'),
               yaxis = list(title = 'Amount billed (in dollars)'),
               yaxis2 = list(side = 'right', overlaying = 'y' , title='Cumulative cost',
                             zeroline = F,showgrid = F))
    })

    
    #### Usage
    bill %>%
      filter(Day >= strt, Day <= end_dt,category == usg) %>%
      mutate(GrpDate = get(grp)) %>%
      group_by(GrpDate,category) %>%
      summarise(usg = sum(as.numeric(usagequantity.amount))) %>%
      arrange((GrpDate)) %>%
      mutate() -> usagetime
    
    usagetime %>%
      group_by(GrpDate) %>%
      summarise(usg = sum(usg)) %>%
      mutate(cumusg = cumsum(usg)) -> cumusg
    
    bill %>%
      filter(Day >= strt, Day <= end_dt,category == usg) %>%
      pull(usagequantity.unit) %>% unique() -> metric
    
    output$usage = renderPlotly({
      plot_ly(usagetime) %>%
        add_trace(x = ~GrpDate, y = ~usg, type = 'bar', name = 'Usage') %>%
        add_trace(data = cumusg, x = ~GrpDate, y = ~cumusg, type = 'scatter', mode = 'lines',
                  name = 'Cum Usage',  yaxis = "y2") %>%
        
        layout(title = paste0('AWS Test: Usage of ',usg,' Over Time by ',grp,' and in ',metric),
               barmode = 'relative',
               hovermode = 'x-unified',
               #legend = list(traceorder='reversed',orientation = "h"),
               margin = list(l = 25, r = 75, b = 25, t = 25),
               xaxis = list(title = 'Date/Time'),
               yaxis = list(title = paste0('Amount in ',metric)),
               yaxis2 = list(side = 'right', overlaying = 'y' , title='Cumulative Usage',
                             zeroline = F,showgrid = F))
    })



    bill %>%
      filter(Day >= strt, Day <= end_dt) %>%
      mutate(GrpDate = get(grp)) %>%
      group_by(GrpDate,category,usagequantity.unit) %>%
      summarise(cost = sum(as.numeric(unblendedcost.amount)),
                usage = sum(as.numeric(usagequantity.amount))) %>%
      arrange(GrpDate) -> billtable


    output$billtb = renderReactable({
      reactable(billtable,outlined = TRUE, filterable = TRUE,  wrap = FALSE,
                 showPageSizeOptions = TRUE, defaultPageSize = 10,
                 defaultColDef = colDef(headerStyle = list(backgroundColor = '#42adf5',color='black'), #width = 200,
                                        format = colFormat(separators = TRUE, digits = 2)))

      })
    
    })
    
    })
    
  
  ############### Index
  # symlist = c('SP','Dow'); st_dt = '2000-01-01'; end_dt = Sys.Date()
  
  observeEvent(input$refresh,{
    
  symlist = input$index; st_dt = input$dtrng[1]; end_dt = input$dtrng[2]


  # Use API and plug in IP address if selected
  if(input$dbapi == 'API'){
    
    ipaddr = 'http://ec2-54-158-91-129.compute-1.amazonaws.com'
    apidt = GET(paste0(ipaddr,':8000/data?sym=',paste0(unique(res$sym_short),collapse = ',')))
    res = bind_rows(lapply(content(apidt),as.data.frame))
    
  } else {
    
    res0 <- dbSendQuery(con, "SELECT * FROM index")
    res <- dbFetch(res0) %>% as_tibble()
    dbClearResult(res0)
    
  }
  
  # Wrangle the Result
  res %>%
    arrange(symbol,date) %>%
    group_by(symbol) %>%
    mutate(date = as.Date(date),
           return = ifelse(is.na(lag(value)),0,log(value/lag(value)))) %>%
    filter(symbol %in% symlist, date >= st_dt, date <= end_dt) %>%
    mutate(cumreturn = exp(cumsum(return))-1) -> plot_return
  
  

  # Plot the output
  output$plot = renderPlotly({

    plot_ly(plot_return) %>%
      add_trace(x = ~date, y = ~cumreturn, color = ~symbol, type = 'scatter', mode = 'lines', hoverinfo = 'text',
                text = ~paste0(date,
                               '\n',symbol,
                               '\nMonth Return: ',paste0(round(return*100,2),'%'),
                               '\nCum Return: ',paste0(round(cumreturn*100,2),'%'))) %>%
      layout(title = 'Compare Cumulative Returns of selected indexes',
             hovermode = 'x-unified',
             legend = list(orientation = "h"),
             # barmode = 'overlay',
             margin = list(l = 75, r = 75, b = 100, t = 50, pad = 4),
             xaxis = list(title=''),
             yaxis = list(title='Cumulative Return', tickformat = '.1%'))


  })
  
})
  

 
  
}


shinyApp(ui = ui, server = server)