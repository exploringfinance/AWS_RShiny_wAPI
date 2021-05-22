This dashboard was built by Tony Trevisan to demonstrate some of the capabilities of the AWS services. The dashboard itself is hosted on an AWS EC2 Instance. The dashboard includes visualizations and tables on Billing data and a second tab to plot data scraped from [www.inesting.com](www.investing.com). The data is made available to the dashboard through a local database or through an API hosted on this server. The following steps were taken to build this site:
* Launch an EC2 Instance.
* Configure an Ubuntu server and install the necessary software (PostgresSQL, R, RStudio Server, Shiny Server, Docker)
  * Tony documented the entire process [here](https://exploringfinance.github.io/posts/2021-05-17-setting-up-an-aws-analytics-server-and-api-in-15-minutes/)
* Create Firewall rules to allow access over specific ports for security
* Download AWS Billing information through the Cost Explorer API
  * Save this data into the local Postgres database each day using a scheduled CRON job
  * Plot this data by category and overtime in a dashboard example
* Set up Shiny Server, and connect the dashboard to the local Postgres Database.
* It is understood that these are very simple data visualizations and examples. More complex dashboards and data wrangling examples/exercises can be found on Tony's [website](https://exploringfinance.github.io/).
* This exercise was completed to demonstrate Tony's understanding of the AWS platform and his experience with data analytics and dashboarding. 
* The second tab contains financial index data that was webscraped and loaded into a chart. This data is used to demonstrate a working API that also exists on this server. To see the API in action you can change the radio button or you can visit this address [http://ec2-54-158-91-129.compute-1.amazonaws.com:8000/data?sym=SP,Dow,NASDAQ,US,Gold](http://ec2-54-158-91-129.compute-1.amazonaws.com:8000/data?sym=SP,Dow,NASDAQ,US,Gold)
