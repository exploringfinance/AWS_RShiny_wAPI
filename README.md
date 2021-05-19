---
title: "Setting up an AWS analytics server and API in 15 minutes"
description: |
  The steps to stand up an AWS server that can be used to host an analytics dashboard
  and/or a data feed API
date: 05-17-2021
---

## Introduction

In a [previous post](https://exploringfinance.github.io/posts/2020-11-14-automated-trading-and-investing-using-aws/), I went over the steps to stand up an AWS server that can be used for automated trading using two trading packages I wrote: [rameritrade](https://exploringfinance.github.io/rameritrade/) and [etrader](https://exploringfinance.github.io/etrader/). This post will step through the process of setting up a server that can be used to host an analytics dashboard or a data feed API. This post will cover:

* Setting up an AWS server (3 minutes)
* Installing the necessary software (5 minutes)
  * R, RStudio, Shiny Server, Postgres DB, and Docker
  * Securing the server (1 minute)
  * Configuring the software (1 minute)
* Hosting a very basic Shiny App (2 minutes)
* Creating a data feed API (3 minutes)

I will link to detailed instructions for all of these steps, but will provide some basic steps that a technical user can follow.

## Setting up an AWS Server

AWS has incredible documentation across the website and includes how to [Launch an Amazon EC2 Instance](https://docs.aws.amazon.com/quickstarts/latest/vmlaunch/step-1-launch-instance.html). 

Once you [create an AWS account](https://portal.aws.amazon.com/billing/signup), you can quickly launch an EC2 server from the [dashboard](https://console.aws.amazon.com/ec2/v2/home). Rstudio does have an AMI that already has RStudio Server already installed, but this will start with a clean install of Ubuntu. From AWS eC2 dashboard:

* Click Launch Instance
* Select Ubuntu Server 20.04 LTS (about 6-10 options down)
  * Make sure to keep the default x86 because the ARM chips do not work with Rstudio Server
* Start by using at least t3a.micro to handle all the installations, but a t3a.small or t3a.medium will speed things up. You can then revert back to a micro.
  * The free tier (t2.micro) is unable to handle all the installations and server hosting
  * Do not use a t4 server. These are only offered in ARM which do not work with Rstudio
* Click Review and Launch
  * We will revisit the Security Groups later, so don't change anything here
  * I would increase the storage size up to 10 gbs to account for Docker
* Click Launch and Create a New Key Pair
  * Make sure to download the .pem file
  
Your instance is now running. You will now need to connect to your server to install the necessary software. 

## Installing the required software

*I would highly recommend following the order provided here.*

Once your instance is running, click into the details. In the top right corner, click the button that says "Connect". You should now be on the command line of your server as the ubuntu user. Using the following commands, we are going to create a new user 'rstudio' with sudo privileges and then install the software needed. 

```
# Create User with home directory
sudo useradd -m rstudio
 
# Change user password (this will be your rstudio login credentials)
sudo passwd rstudio

# Grant user sudo priveleges
sudo usermod -a -G sudo rstudio

# Swtich to new user to install software
sudo su rstudio

# Create folder to download software
cd
mkdir downloads
cd downloads

```

Before going to the next step for installation. We want to open some ports to make sure we can get to the software we install. Under Security, click the security group that is displayed. We are going to open port 3838 for all traffic and port 8787 for just your IP address. You can open port 8787, it will just be less secure. Click "Edit Inbound Rules" and add the following rules. At a later date, you can close port 22 to all traffic but you will need to reach the terminal through either RStudio or an SSH tool like Putty. 

* Custom TCP - Port Range 8787 and enter your IP address next to Custom (select the one below that has /32)
  * For RStudio Server
* Custom TCP - Port Range 3838 and enter 0.0.0.0/0 next to Custom
  * For Shiny Server
* Custom TCP - Port Range 8000 and enter 0.0.0.0/0 next to Custom
  * For Docker and Plumber (the API)

You are now ready to install the software. We are going to perform the following steps. The links to detailed instructions are provided. The actual installs may take a few minutes.

* [Install R](https://rtask.thinkr.fr/installation-of-r-4-0-on-ubuntu-20-04-lts-and-tips-for-spatial-packages/)
* [Install RStudio Server](https://www.rstudio.com/products/rstudio/download-server/debian-ubuntu/)
  * Once you install Rstudio verify the installation by visiting the site. Get the external IP address from the AWS Instance dashboard and add :8787. For example: http://ec1-2-34-567-890.compute-1.amazonaws.com:8787
  * This will not work unless you modified the security groups as explained above
* [Install Shiny Server](https://www.rstudio.com/products/shiny/download-server/ubuntu/)
  * Verify the installation by visiting a sample address: http://ec1-2-34-567-890.compute-1.amazonaws.com:3838/sample-apps/hello/
* [Install PostgresSQL](https://www.digitalocean.com/community/tutorials/how-to-install-postgresql-on-ubuntu-20-04-quickstart)
* [Install Docker](https://linuxize.com/post/how-to-install-and-use-docker-on-ubuntu-20-04/)


```
# Install R 4.0
sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
sudo apt update
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | sudo apt-key add -
sudo apt install r-base r-base-core r-recommended r-base-dev

# Install RStudio Server
# You may want to visit the install link above to make sure you are getting the latest version
# Make sure you download for Ubuntu 20
sudo apt-get install gdebi-core
wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1106-amd64.deb
sudo gdebi rstudio-server-1.4.1106-amd64.deb

# Install Shiny Server (the first command may take several minutes -especially  Rcpp)
sudo su - -c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.16.958-amd64.deb
sudo gdebi shiny-server-1.5.16.958-amd64.deb

# Install PostresSQL database and create super user with database
sudo apt install postgresql postgresql-contrib
sudo -u postgres createuser --interactive
  Enter name of role to add: rstudio
  Shall the new role be a superuser? (y/n) y
sudo -u postgres createdb rstudio
# we will need to change the password to work with the scripts
psql
ALTER ROLE rstudio WITH PASSWORD 'rstudio';
\q

# Now we will enter 

# Install Docker
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io

```

## Housting a data API

In order to host a data API, you will first need to collect some data to host. We are going to scrape some financial data from [https://www.investing.com/](https://www.investing.com/). I have already written a script to scrape down data for a few indexes and commodities. You will need to copy down my git repo. Make sure to be in your home directory and then clone the repo down. You will also need to install some more R libraries which could take a few minutes. Again, this will go faster with a t3a.small or t3a.medium. 


```

# Install Linux Libraries for dependencies on R packages
sudo apt-get update -y
sudo apt-get install -y libssl-dev
sudo apt-get install -y libcurl4-openssl-dev
sudo apt-get install -y libxml2-dev
sudo apt-get install -y libpq-dev

# Install necessary R packages
sudo su - -c "R -e \"install.packages(c('httr','tidyverse','RPostgres'))\""

# Clone Git Repo
cd
git clone https://github.com/exploringfinance/AWS_RShiny_wAPI.git

# Run R script to download data. This will also save data to a folder for loading data into the database.
/usr/bin/Rscript /home/rstudio/AWS_RShiny_wAPI/code/IndexPull.R

# Sweep data into database - will create tables if none exist
/usr/bin/Rscript /home/rstudio/AWS_RShiny_wAPI/code/postgres_upd.R

# Setup cron to scrape data automatically and sweep to database
crontab -e

# Press i and then copy these two lines at the bottom of the cron file. 
# They will run twice daily to scrape and sweep 
00 12,22 * * * /usr/bin/Rscript /home/rstudio/AWS_RShiny_wAPI/code/IndexPull.R
10 12,22 * * * /usr/bin/Rscript /home/rstudio/AWS_RShiny_wAPI/code/postgres_upd.R


```

Now that you have the data stored down. We can setup a docker container that can host the API which would feed your custom Shiny App. In theory, this is extra steps, the Shiny App can be configured to read from the database or read in local files, but if you wanted to host the API or Shiny App on different machines, this is one option. 

Below, we are going to pull a docker container and then start the container using a custom docker file. Detailed instructions can be found [here](https://www.rplumber.io/index.html).

```

# Pull Docker File
sudo systemctl start docker
sudo docker pull rstudio/plumber

# If you cloned my git repo, the command below should start a custom docker container
sudo docker build -t customdock /home/rstudio/AWS_RShiny_wAPI/plumber_api/
sudo docker run --rm -p 8000:8000 -v `pwd`/AWS_RShiny_wAPI/plumber_api/app:/app customdock /app/api.R

# Test that the API is now working. Enter the link below into a browser with your IP
http://ec1-23-456-789.compute-1.amazonaws.com:8000/data?sym=SP,Dow

# You will want to close the terminal in order to keep the API open (do not hit ctrl+c)
# Open a new terminal window and confirm API container is still up
sudo docker ps


```


## Hosting a Shiny App

Now that Shiny is working, the API is up, and the database is running with data populated, we will set up a Shiny app that pulls from the database but can be redirected to pull from the API. I have already built the Shiny app so if you run the commands below, everything should work. This is a very simple app with a single chart and some drop downs to choose from. 


```
# Install Plotly
sudo su - -c "R -e \"install.packages(c('plotly'))\""

# Copy the App to the Shiny Server
sudo cp -rf /home/rstudio/AWS_RShiny_wAPI/example/ /srv/shiny-server/

# Visit your app to make sure it is running
http://ec1-2-34-567-890.compute-1.amazonaws.com:3838/example

# If there are any issues, you can check the logs
cd /var/log/shiny-server
ls
sudo more ENTER LOG FILE

```

## Wrapping up

Congratulations! You have now stood up an AWS Server, created a database, web scraped some data, set up an API, and launched a dashboard. This is only scratching the surface of the amazing features that can be explored with any of these capabilities. Hopefully this gave you a foundation to get started!

