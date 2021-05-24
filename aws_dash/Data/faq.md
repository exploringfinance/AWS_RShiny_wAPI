This dashboard was built by Tony Trevisan to demonstrate some of the capabilities of the AWS services. The dashboard itself is hosted on an AWS EC2 Instance. The dashboard includes visualizations and tables on Billing data and a second tab to plot data scraped from [www.inesting.com](www.investing.com). The final tab plots data that is pulled directly from a Redshift cluster. The data is made available to the dashboard through a local database, through an API hosted on this server, or a Redshift Cluster. The following steps were taken to build this site:
* Launch an EC2 Instance.
* Configure an Ubuntu server and install the necessary software (PostgresSQL, R, RStudio Server, Shiny Server, Docker)
  * Tony documented the entire process [here](https://exploringfinance.github.io/posts/2021-05-17-setting-up-an-aws-analytics-server-and-api-in-15-minutes/)
* Create Firewall rules to allow access over specific ports for security
* Download AWS Billing information through the Cost Explorer API
  * Save this data into the local Postgres database each day using a scheduled CRON job
  * Plot this data by category and overtime in a dashboard example
  * This data is from Tonys personal AWS account that he has been using for over a year for day trading and development work. He also used it to set up a COVID vaccine appointment web scraping tool to help individuals find vaccine appointments during March/April when it was challenging to find an appointment. 
* Set up Shiny Server, and connect the dashboard to the local Postgres Database.
* Create a Redshift cluster and connect Amazon Quicksight to generate charts
  * Recreate the charts in R shiny because the Quicksight Dashboard could not be easily shared without specific permissioning
* It is understood that these are very simple data visualizations and examples. More complex dashboards and data wrangling examples/exercises can be found on Tony's [website](https://exploringfinance.github.io/).
* This exercise was completed to demonstrate Tony's understanding of the AWS platform and his experience with data analytics and dashboarding. 
* The second tab contains financial index data that was webscraped and loaded into a chart. This data is used to demonstrate a working API that also exists on this server. To see the API in action you can change the radio button or you can visit this address [http://ec2-54-158-91-129.compute-1.amazonaws.com:8000/data?sym=SP,Dow,NASDAQ,US,Gold](http://ec2-54-158-91-129.compute-1.amazonaws.com:8000/data?sym=SP,Dow,NASDAQ,US,Gold)
* The Third tab has data sourced from Amazon using the [Redshift example](https://docs.aws.amazon.com/redshift/latest/gsg/rs-gsg-create-sample-db.html). The data was loaded into a private S3 bucket and uploaded to Redshift. The data is pulled from Redshift on demand when the button is pressed by the user.
