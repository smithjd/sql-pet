# Learning Goals and Use Cases {#chapter_learning-goals}

> This chapter sets the context for the book by:
> 
> * Describing our assumptions about your goals, context, and expectations
> * Describing what the book offers in terms of:
>   * Problems that are addressed 
>   * Learning objectives
>   * R packages used
> * Describing the sample database used in the book
> * Posing some imaginary but realistic use cases that frame the exercises and discussions

An R analyst....



## Challenge: goals, context and expectations

## The Challenge: Investigating a question using an organization's database

* Need both familiarity with the data and a focus question
  + An iterative process where 
    + the data resource can shape your understanding of the question
    + the question you need to answer will frame how you see the data resource
  + You need to go back and forth between the two, asking 
    + do I understand the question?
    + do I understand the data?

* How well do you understand the data resource (in the DBMS)?
  + Use all available documentation and understand its limits
  + Use your own tools and skills to examine the data resource
  + What is *missing* from the database: (columns, records, cells)
  + Why is the data missing?
  
* How well do you understand the question you seek to answer?
  + How general or specific is your question?
  + How aligned is it with the purpose for which the database was designed and is being operated?
  + How different are your assumptions and concerns from those of the people who enter and use the data on a day to day basis?


## Ask yourself, what are you aiming for?  

* Differences between production and data warehouse environments.
* Learning to keep your DBAs happy:
  + You are your own DBA in this simulation, so you can wreak havoc and learn from it, but you can learn to be DBA-friendly here.
  + In the end it's the subject-matter experts that understand your data, but you have to work with your DBAs first.

### Problems that are addressed

* Database exploration 
* Wisdom from Sophie

### Learning Objectives

After working through the code in this book, you can expect to be able to:

* R, SQL and PostgreSQL
  * Run queries against PostgreSQL in an environment that simulates what is found in a corporate setting.
  * Understand techniques and some of the trade-offs between:
      * queries aimed at exploration or informal investigation using [dplyr](https://cran.r-project.org/package=dplyr)    [@Wickham2018]; and 
      * queries that should be written in SQL, because performance is important due to the size of the database or the frequency  with which a query is to be run.
  * Understand the equivalence between `dplyr` and SQL queries, and how R translates one into the other.
  * Gain familiarity with techniques that help you explore a database and verify its documentation.
  * Gain familiarity with the standard metadata that a SQL database contains to describe its own contents.
  * Understand some advanced SQL techniques.
  * Gain some understanding of techniques for assessing query structure and performance.
* Docker related
  * Set up a PostgreSQL database in a Docker environment. 
  * Gain familiarity with the various ways of interacting with the Docker and PostgreSQL environments
  * Understand enough about Docker to swap databases, e.g. [Sports DB](http://www.sportsdb.org/sd/samples) for the [DVD rental database](http://www.postgresqltutorial.com/postgresql-sample-database/) used in this tutorial. Or swap the database management system (DBMS), e.g. [MySQL](https://www.mysql.com/) for [PostgreSQL](https://www.postgresql.org/).


### R Packages

These R packages are discussed or used in exercises:

* [DBI](https://cran.r-project.org/package=DBI)
* [dbplyr](https://cran.r-project.org/package=dbplyr)
* [devtools](https://cran.r-project.org/package=devtools)
* [downloader](https://cran.r-project.org/package=downloader)
* [glue](https://cran.r-project.org/package=glue)
* [gt](https://cran.r-project.org/package=gt)
* [here](https://cran.r-project.org/package=here)
* [knitr](https://cran.r-project.org/package=knitr)
* [RPostgres](https://cran.r-project.org/package=RPostgres)
* [skimr](https://cran.r-project.org/package=skimr)
* [sqlpetr](https://github.com/smithjd/sqlpetr) (installs with: `remotes::install_github("smithjd/sqlpetr", force = TRUE, quiet = TRUE, build = TRUE, build_opts = "")`)
* [tidyverse](https://cran.r-project.org/package=tidyverse)

In addition, these are used to render the book:
* [bookdown](https://cran.r-project.org/package=bookdown)
* [DiagrammeR](https://cran.r-project.org/package=DiagrammeR)

## AdventureWorks

In this book we have adopted the Microsoft AdventureWorks online transaction processing database for our examples.  It is 

https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008/ms124438(v=sql.100) 

See Sections 3 and 4

Journal of Information Systems Education, Vol. 26(3) Summer 2015. “_Teaching Tip Active Learning via a Sample Database: The Case of Microsoft’s Adventure Works_” by Michel Mitri

http://jise.org/Volume26/n3/JISEv26n3p177.pdf

See the [AdventureWorks Data Dictionary](https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008/ms124438%28v%3dsql.100%29) and a sample table ([employee](https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008/ms124432(v=sql.100))).

Here is a (link to an ERD diagram)[https://i.stack.imgur.com/LMu4W.gif]

