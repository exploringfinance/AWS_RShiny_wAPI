###########################
# File: app.R in example
# Description: Pull a quick chart of data for multiple indexes
# Date: 5/19/2021
# Author: Exploring Finance
# Notes: Needs the API to be running in order to use the API pull
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


# Make initial pull from database
res0 <- dbSendQuery(con, "SELECT * FROM index")
res <- dbFetch(res0) %>% as_tibble()
dbClearResult(res0)


# Define UI 
ui <- fluidPage(
  
  # App title ----
  titlePanel("Compare Index Performance"),
  
  
  # Sidebar layout with input and output definitions ----
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
      helpText('In order to pull from the API, it has to be running on this server'),
      
      # Input: Enter IP Address ----
      textInput('ipaddr','Enter your IP address if you pull from the API',
                placeholder = 'http://ec1-23-456-78-90.compute-1.amazonaws.com'),
      helpText('Be sure to end the IP address as if it is expecting a colon, similar to the placeholder'),
      
      # Action button for refresh
      actionButton('refresh','Refresh Data')),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Plot summary ----
      plotlyOutput("plot")
      
    ))
  )


# Define server logic for slider examples ----
server <- function(input, output) {
  
  # Oberve Event for data pull ----
  observeEvent(input$refresh,{
    
    # symlist = c('SP','Dow'); st_dt = '2000-01-01'; end_dt = Sys.Date()
    symlist = input$index; st_dt = input$dtrng[1]; end_dt = input$dtrng[2]
    
    # Use API and plug in IP address if selected
    if(input$dbapi == 'API'){
    
      ipaddr = input$ipaddr
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

# Create Shiny app ----
shinyApp(ui, server)