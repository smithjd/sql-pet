# Learning Goals and Use Cases (03)

At the end of this chapter, you will be able to 

  * Understand the importance of integrating R with databases using Docker.
  * Understand the learning goals that you will have achieved by end of the tutorial.
  * Learn the structure of the database and understand many use cases that can apply to you.

## Context: Why integrate R with databases using Docker? (03)

* Large data stores in organizations are stored in databases that have specific access constraints and  structural characteristics.
* Learning to navigate the gap between R and the database is difficult to simulate outside corporate walls.
* R users frequently need to make sense of complex data structures using diagnostic techniques that should not be reinvented (and so would benefit from more public instruction and  commentary).
* Docker is a relatively easy way to simulate the relationship between an R/Rstudio session and database -- all on on a single machine.

## Learning Goals

After working through this tutorial, you can expect to be able to:

* Run queries against PostgreSQL in an environment that simulates what you will find in a corporate setting.
* Understand some of the trade-offs between:
    1. queries aimed at exploration or informal investigation using [dplyr](https://cran.r-project.org/package=dplyr); and 
    2. those where performance is important because of the size of the database or the frequency with which a query is run.
* Rewrite `dplyr` queries as SQL and submit them directly. 
* Gain some understanding of techniques for assessing query structure and performance.
* Set up a PostgreSQL database in a Docker environment.
* Understand enough about Docker to swap databases, e.g. [Sports DB](http://www.sportsdb.org/sd/samples) for the [DVD rental database](http://www.postgresqltutorial.com/postgresql-sample-database/) used in this tutorial. Or swap the database management system (DBMS), e.g. [MySQL](https://www.mysql.com/) for [PostgreSQL](https://www.postgresql.org/).

## Use cases 

Imagine that you have one of several roles at our fictional company **DVDs R Us** and that you need to:

* As a data scientist, I want to know the distribution of number of rentals per month per customer, so that the Marketing department can create incentives for customers in 3 segments: Frequent Renters, Average Renters, Infrequent Renters.
* As the Director of Sales, I want to see the total number of rentals per month for the past 6 months and I want to know how fast our customer base is growing/shrinking per month for the past 6 months.
* As the Director of Marketing, I want to know which categories of DVDs are the least popular, so that I can create a campaign to draw attention to rarely used inventory.
* As a shipping clerk, I want to add rental information when I fulfill a shipment order.
* As the Director of Analytics, I want to test as much of the production R code in my shop as possible against a new release of the DBMS that the IT department is implementing next month.
* etc.

## ERD Diagram

This tutorial uses [the Postgres version of "dvd rental" database](http://www.postgresqltutorial.com/postgresql-sample-database/), which can be  [downloaded here](http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip).  Here's a glimpse of it's structure:
    
![Entity Relationship diagram for the dvdrental database](./screenshots/dvdrental-er-diagram.png)
