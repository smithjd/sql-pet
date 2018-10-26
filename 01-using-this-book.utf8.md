# How to use this book (01)

This book is full of examples that you can replicate on your computer. 

## Prerequisites
You will need:

* A computer running Windows, MacOS, or Linux (any Linux distro that will run Docker Community Edition, R and RStudio will work)
* [R, and RStudio](https://www.datacamp.com/community/tutorials/installing-R-windows-mac-ubuntu)
* Docker
* Our companion package `sqlpetr` installs with: `devtools::install_github("smithjd/sqlpetr")`.

The database we use is PostgreSQL 10, but you do not need to install that - it's installed via a Docker image. RStudio 1.2 is highly recommended but not required.

In addition to the current version of R and RStudio, you will need current versions of the following packages:

* tidyverse
* DBI
* RPostgres
* glue
* dbplyr
* knitr

## Installing Docker

Install Docker.  Installation depends on your operating system:

  + [On a Mac](https://docs.docker.com/docker-for-mac/install/)
  + [On UNIX flavors](https://docs.docker.com/install/#supported-platforms)
  + For Windows, [consider these issues and follow these instructions](https://smithjd.github.io/sql-pet/docker-hosting-for-windows.html).

## Download the repo

The code to generate the book and the exercises it contains can be downloaded from [this repo](https://github.com/smithjd/sql-pet). 

## Read along, experiment as you go

We have never been sure whether we're writing an expository book or a massive tutorial.  You may use it either way.

After the introductory chapters and the chapter that creates the persistent database ("The dvdrental database in Postgres in Docker (05)), you can jump around and each chapter stands on its own.
