---
title: "R, Databases, and Docker"
author: John David Smith, Sophie Yang, M. Edward (Ed) 
  Borasky, Jim Tyhurst, Scott Came, Mary Anne Thygesen, Ian Frantz, and Dipti Muni
date: "2019-03-04"
bibliography: [book.bib, packages.bib]
description: An introduction to Docker and PostgreSQL for R users to simulate use cases behind corporate walls.
documentclass: book
link-citations: yes
site: bookdown::bookdown_site
---

# Introduction {#chapter_introduction}

> This chapter introduces:
> 
> * The motivation for this book and the strategies we have adopted
> * How Docker can be used to set up a dbms to demonstrate access to a service like PostgreSQL from R
> * Our team and how this project came about

## Using R to query a DBMS in your organization

Many R users (or *useRs*) live a dual life: in the vibrant open-source R community where R is created, improved, discussed, and taught. And then they go to work in a secured, complex, closed organizational environment where they may be on their own.  Here is [a request on the Rstudio community site](https://community.rstudio.com/t/moving-from-rjdbc-to-odbc/22419) for help that has been lightly edited to emphasize the generality that we see:

> I'm trying to migrate some inherited scripts that [...] to connect to a [...] database to [...] instead. I've reviewed the https://db.rstudio.com docs and tried a number of configurations but haven't been able to connect. *I'm in uncharted territory within my org, so haven't been able to get much help internally.*

This book will help you create a hybrid environment on your machine that can mimic some of the uncharted territory in your organization.  It goes far beyond the basic connection issues and covers issues that you face when you are finding your way around or writing queries to your organization's databases, not just when maintaining inherited scripts.

* **Technology hurdles**.  The interfaces (passwords, packages, etc.) and gaps between R and a back end database are hidden from public view as a matter of security, so pinpointing exactly where a problem is can be difficult. A **simulated** environment such as we offer here can be an important learning resource.

* **Scale issues**. We see at least two types of scale issues.  Handling large volumes of data so that performance issues must be a consideration requires a basic understanding of what's happening in "the back end" (which is necessarily hidden from view). Therefore mastering techniques for drawing samples or small batches of data are essential. In addition to their size, your organization's databases will often have structural characteristics that are complex and obscure.  Data documentation is often incomplete and emphasizes operational characteristics, rather than analytic opportunities.  A careful useR often needs to confirm the documentation on the fly and de-normalize data carefully.

* **Use cases**. R users frequently need to make sense of an organization's complex data structures and coding schemes to address incompletely formed questions so that informal exploratory data analysis has to be intuitive and fast. The technology details should not get in the way. Sharing and discussing exploratory and diagnostic retrieval techniquesis best in public, but is constrained by organizational requirements.

We have found that PostgreSQL in a Docker container solves many of the foregoing problems.

## Docker as a tool for UseRs

Noam Ross's "[Docker for the UseR](https://nyhackr.blob.core.windows.net/presentations/Docker-for-the-UseR_Noam-Ross.pdf)" [@Ross2018a] suggests that there are four distinct Docker use-cases for useRs.  

1. Make a fixed working environment for reproducible analysis
2. Access a service outside of R **(e.g., PostgreSQL)**
3. Create an R based service (e.g., with `plumber`)
4. Send our compute jobs to the cloud with minimal reconfiguration or revision

This book explores #2 because it allows us to work on the database access issues described above and to practice on an industrial-scale DBMS.  

* Docker is a comparatively easy way to simulate the relationship between an R/RStudio session and a database -- all on on your machine (provided you have Docker installed and running). 
* Running PostgreSQL on a Docker container avoids OS or system dependencies or conflicts that cause confusion and limit reproducibility. 
* A Docker environment consumes relatively few resources.  Our sandbox does much less but only includes PostgreSQL and sample data, so it takes up about 5% of the space taken up by the Vagrant environment that inspired this project. [@Makubuya2018]
* A simple Docker container such as the one used in our sandbox is easy to use and could be extended for other uses.
* Docker is a widely used technology for deploying applications in the cloud, so for many useRs it's worth mastering.

## Who are we?

We have been collaborating on this book since the Summer of 2018, each of us chipping into the project as time permits:

* Dipti Muni - [\@deemuni](https://github.com/deemuni)
* Ian Franz - [\@ianfrantz](https://github.com/ianfrantz)
* Jim Tyhurst - [\@jimtyhurst](https://github.com/jimtyhurst)
* John David Smith - [\@smithjd](https://github.com/smithjd)
* M. Edward (Ed) Borasky - [\@znmeb](https://github.com/znmeb)
* Maryanne Thygesen [\@maryannet](https://github.com/maryannet)
* Scott Came - [\@scottcame](https://github.com/scottcame)
* Sophie Yang - [\@SophieMYang](https://github.com/SophieMYang)

## How did this project come about?

We trace this book back to the [June 2, 2018 Cascadia R Conf](https://cascadiarconf.com/) where Aaron Makubuya gave [a presentation using Vagrant hosting](https://github.com/Cascadia-R/Using_R_With_Databases) [@Makubuya2018].  After that [John Smith](https://github.com/smithjd), [Ian Franz](https://github.com/ianfrantz), and [Sophie Yang](https://github.com/SophieMYang) had discussions after the monthly [Data Discussion Meetups](https://www.meetup.com/Portland-Data-Science-Group/events/fxvhbnywmbgb/) about the difficulties around setting up [Vagrant](https://www.vagrantup.com/) (a virtual environment), connecting to a corporate database, and having realistic **public** environment to demo or practice the issues that come up behind corporate firewalls. [Scott Came's](https://github.com/scottcame) tutorial on [R and Docker](http://www.cascadia-analytics.com/2018/07/21/docker-r-p1.html) [@Came2018] (an alternative to Vagrant) at the 2018 UseR Conference in Melbourne was provocative and it turned out he lived nearby.  We re-connected with [M. Edward (Ed) Borasky](https://github.com/znmeb) who had done extensive development for a [Hack Oregon data science containerization project](https://github.com/hackoregon/data-science-pet-containers) [@Borasky2018].

## Navigation
If this is the first `bookdown` [@Xie2016] book you've read, here's how to navigate the website.

1. The controls on the upper left: there are four controls on the upper left.

    * A "hamburger" menu: this toggles the table of contents on the left side of the page on or off.
    * A magnifying glass: this toggles a search box on or off.
    * A letter "A": this lets you pick how you want the site to display. You have your choice of small or large text, a serif or sans-serif font, and a white, sepia or night theme.
    * A pencil: this is the "Edit" button. This will take you to a GitHub edit dialog for the chapter you're reading. If you're a committer to the repository, you'll be able to edit the source directly. 
    
        If not, GitHub will fork a copy of the repository to your own account and you'll be able to edit that version. Then you can make a pull request.
    
2. The share buttons in the upper right hand corner. There's one for Twitter, one for Facebook, and one that gives a menu of options, including LinkedIn.


