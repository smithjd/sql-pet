---
title: "R, Databases and Docker"
author: "Dipti Muni, Ian Frantz, John David Smith, Mary Anne Thygesen, M. Edward (Ed) Borasky,  Scott Case, and Sophie Yang"
date: "2018-10-02"
site: bookdown::bookdown_site
documentclass: book
bibliography: [book.bib, packages.bib]
biblio-style: apalike
link-citations: yes
description: "A collection of tutorials for integrating R with databases using Docker"
---

# Introduction

## Using R to query a DBMS in your organization

* Large data stores in organizations are stored in databases that have specific access constraints and structural characteristics.  Data documentation may be incomplete, often emphasizes operational issues rather than analytic ones, and often needs to be confirmed on the fly.  Data volumes and query performance are important design constraints.
* R users frequently need to make sense of complex data structures and coding schemes to address incompletely formed questions so that exploratory data analysis has to be fast. Exploratory techniques for the purpose should not be reinvented (and so would benefit from more public instruction or discussion).
* Learning to navigate the interfaces (passwords, packages, etc.) between R and a database is difficult to simulate outside corporate walls.  Resources for interface problem diagnosis behind corporate walls may or may not address all the issues that R users face, so a simulated environment is needed.

## Docker as a tool for UseRs

Noam Ross's "[Docker for the UseR](https://nyhackr.blob.core.windows.net/presentations/Docker-for-the-UseR_Noam-Ross.pdf)" suggests that there are four distinct Docker use-cases for useRs.  

1. Make a fixed working environment for reproducible analysis
2. Access a service outside of R **(e.g., Postgres)**
3. Create an R based service (e.g., with `plumber`)
4. Send our compute jobs to the cloud with minimal reconfiguration or revision

This book explores #2 because it allows us to work on the database access issues [described above][Using R to query a DBMS in your organization] and to practice on an industrial-scale DBMS.  

* Docker is a relatively easy way to simulate the relationship between an R/RStudio session and a database -- all on on a single machine, provided you have Docker installed and running.
* You may want to run PostgreSQL on a Docker container, avoiding any OS or system dependencies that might come up. 

## Docker and R on your machine

Here is how R and Docker fit on your operating system in this tutorial:
    
![R and Docker](./screenshots/r-and-docker.png)
(This diagram needs to be updated as our directory structure evolves.)

## Who are we?

* M. Edward (Ed) Borasky - [\@znmeb](https://github.com/znmeb)
* John David Smith - [\@smithjd](https://github.com/smithjd)
* Scott Came - [\@scottcame](https://github.com/scottcame)
* Ian Franz - [\@ianfrantz](https://github.com/ianfrantz)
* Sophie Yang - [\@SophieMYang](https://github.com/SophieMYang)
* Jim Tyhurst - [\@jimtyhurst](https://github.com/jimtyhurst)

## Prerequisites
You will need:

* A computer running Windows, MacOS, or Linux (Any Linux distro that will run Docker Community Edition, R and RStudio will work),
* [R, and RStudio](https://www.datacamp.com/community/tutorials/installing-R-windows-mac-ubuntu) and
* Docker hosting.

The database we use is PostgreSQL 10, but you do not need to install that - it's installed via a Docker image. RStudio 1.2 is highly recommended but not required.

In addition to the current version of R and RStudio, you will need the following packages:

* tidyverse
* DBI
* RPostgres
* glue
* dbplyr

## Install Docker

Install Docker.  Installation depends on your operating system:

  + [On a Mac](https://docs.docker.com/docker-for-mac/install/)
  + [On UNIX flavors](https://docs.docker.com/install/#supported-platforms)
  + For Windows, [consider these issues and follow these instructions](https://smithjd.github.io/sql-pet/docker-hosting-for-windows.html).

## Download the repo

First step: download [this repo](https://github.com/smithjd/sql-pet).  It contains source code to build a Docker container that has the dvdrental database in PostgreSQL and shows how to interact with the database from R.


