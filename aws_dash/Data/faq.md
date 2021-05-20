This dashboard was built by Tony Trevisan to demonstrate the capabilities of the AWS offering. The dashboard itself is hosted on an AWS VM. The dashboard includes visualizations and tables onBilling data, portfolio returns, and an example API data query for Covid Vaccine appointments. The following steps were taken to build this site:
* Create a Google Cloud account and set up a Virtual Machine under Compute Engine
* Stand up an Ubuntu server and install the necessary software (PostgresSQL, R, RStudio Server, Shiny Server)
* Remove all Firewall rules to allow general access
  * It is understood that this is NOT best practice, but was necessary to share the dashboard
  * Download this data into the local Postgres database each day using a scheduled CRON job
  * Plot this data by category and overtime in a dashboard example
* Set up a shiny dashboard, connect the dashboard to the local Postgres Database, pull the data down
* It is understood that these are very simple data visualizations and examples. More complex dashboards and data wrangling examples/exercises can be provided upon request with Git Repositories
* This exercise was completed to better understand the end user experience of Google Cloud. Only a few services/APIs were used
* A third tab "Covid 19 Appointment finder" has also been included as an example of how Tony used data to help people find Covid Vaccine Appointments