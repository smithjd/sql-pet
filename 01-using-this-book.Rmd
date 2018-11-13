# How to use this book (01)

This book is full of examples that you can replicate on your computer. 

## Prerequisites
You will need:

* A computer running 
  + Windows (Windows 7 64-bit or late - Windows 10-Pro is recommended)
  + MacOS
  + Linux (any Linux distro that will run Docker Community Edition, R and RStudio will work)
* Current versions of [R and RStudio](https://www.datacamp.com/community/tutorials/installing-R-windows-mac-ubuntu) required.
* Docker (instructions below)
* Our companion package `sqlpetr` installs with: `devtools::install_github("smithjd/sqlpetr")`.  Note that when you install the package it will ask you to update the packages it uses and that can take some time.

The database we use is PostgreSQL 10, but you do not need to install it - it's installed via a Docker image. 

In addition to the current version of R and RStudio, you will need current versions of the following packages:

* `DBI`
* `DiagrammeR`
* `RPostgres`
* `dbplyr`
* `devtools`
* `downloader`
* `glue`
* `here`
* `knitr`
* `skimr`
* `tidyverse`

* `bookdown` (for compiling the book, if you want to)

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
