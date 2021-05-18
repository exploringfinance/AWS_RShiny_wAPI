# AWS_RShiny_wAPI
Simple steps to set up an AWS server that can host an analytics dashboard and an API

---
title: "Setting up an AWS analytics server and API in 15 minutes"
description: |
  The steps to stand up an AWS server that can be used to host an analytics dashboard
  and/or a data feed API for FREE
author:
  - name: Exploring Finance
    url: https://exploringfinance.github.io/
date: 05-17-2021
output:
  distill::distill_article:
    self_contained: false
---


```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE)
```

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

Once you [create an AWS account](https://portal.aws.amazon.com/billing/signup), you can quickly launch an EC2 server from the [dashboard](https://console.aws.amazon.com/ec2/v2/home). Rstudio does have an AMI that already has RStudio Server already installed, but this will start with a clean install of Ubuntu. From AWS eC2 dashbord:

* Click Launch Instance
* Select Ubuntu Server 20.04 LTS (about 6-10 options down)
  * Make sure to keep the default x86 because the ARM chips do not work with Rstudio Server
* Start by using t3a.small to handle all the installations
  * After the installs, you can switch back to the free tier (t2.micro)
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

# Install PostresSQL database and create super user
sudo apt install postgresql postgresql-contrib
sudo -u postgres createuser --interactive
  Enter name of role to add: rstudio
  Shall the new role be a superuser? (y/n) y


# Install Docker
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io

```

## Hosting a Shiny App

The next step will be to ensure that Shiny is working. The first step is to clone my Git repository to get a sample application. You will then need to move the sample application to the Shiny Server. Once this has been completed, you should be able to test and make sure the app is running.

```
# Clone Git Repo
cd
git clone https://github.com/exploringfinance/AWS_RShiny_wAPI.git

# Copy App Folder to Shiny Server



```


