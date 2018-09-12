# Interacting with Postgres from R

## Basics

* keeping passwords secure
* differences between production and data warehouse environments
* learning to keep your DBAs happy
  + You are your own DBA in this simulation, so you can wreak havoc and learn from it, but you can learn to be DBA-friendly here.
  + in the end it's the subject-matter experts that understand your data, but you have to work with your DBAs first
 
## Using Dplyr

### finding out what's in the database

* dplyr queries
* examining dplyr queries (show_query on the R side v EXPLAIN on the Postges side)
* R tools like glimpse, skimr, kable.
* Tutorials like: https://suzan.rbind.io/tags/dplyr/ 
* Benjamin S. Baumer, A Grammar for Reproducible and Painless Extract-Transform-Load Operations on Medium Data: https://arxiv.org/pdf/1708.07073 


### Subset: only retrieve what you need

* Columns
* Rows
  + number of row
  + specific rows
* dplyr joins in the R

### Make the server do as much work as you can

* dplyr joins on the server side
* Where you put `(collect(n = Inf))` really matters

## What is dplyr sending to the server?

* show_query as a first draft

## Writing your on SQL directly to the DBMS

* dbquery
* Glue for constructing SQL statements
  + parameterizing SQL queries

## Chosing between dplyr and native SQL

* performance considerations: first get the right data, then worory about performance
* Tradeoffs between leaving the data in Postgres vs what's kept in R: 
  + browsing the data
  + larger samples and complete tables
  + using what you know to write efficient queries that do most of the work on the server

## More topics
* Check this against [Aaron Makubuya's workshop](https://github.com/Cascadia-R/Using_R_With_Databases/blob/master/Intro_To_R_With_Databases.Rmd) at the Cascadia R Conf.

