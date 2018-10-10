# Simple queries (11)


Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go. 

```r
sp_docker_start("sql-pet")
```
Connect to the database:

```r
con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```

## Some extra handy libraries

https://dbplyr.tidyverse.org/articles/sql-translation.html 

Here are some packages that we find handy in the preliminary investigation of a database (or a problem that involves data from a database).

```r
library(glue)
library(skimr)
```

```
## 
## Attaching package: 'skimr'
```

```
## The following object is masked from 'package:knitr':
## 
##     kable
```

## Basic investigation

* Need both familiarity with the data and a focus question
  + An interative process
  + Each informs the other

* R tools for data investigation
  + glimpse
  + str
  + View and kable

* overview investigation: do you understand your data
  + documentation and its limits
  + what's *missing* from the database: (columns, records, cells)

* find out how the data is used by those who enter it and others who've used it before
  + why is there missing data?

## Using `dplyr`

We already started, but that's OK.

### Finding out what's in the database

* DBI / RPostgres packages
* R tools like glimpse, skimr, kable.
* Tutorials like: https://suzan.rbind.io/tags/dplyr/ 
* Benjamin S. Baumer, A Grammar for Reproducible and Painless Extract-Transform-Load Operations on Medium Data: https://arxiv.org/pdf/1708.07073 

### Sample query

* rental 
* date subset

### Subset: only retrieve what you need

* Columns
* Rows
  + number of row
  + specific rows
* Counts & stats

### Make the server do as much work as you can

discuss this simple example? http://www.postgresqltutorial.com/postgresql-left-join/ 

* `dplyr` joins on the server side
* Where you put `(collect(n = Inf))` really matters

## What is `dplyr` sending to the server?

* show_query as a first draft

## Writing SQL queries directly to the DBMS

* dbquery
* Glue for constructing SQL statements
  + parameterizing SQL queries

## Choosing between `dplyr` and native SQL

* performance considerations: first get the right data, then worry about performance
* Trade offs between leaving the data in PostgreSQL vs what's kept in R: 
  + browsing the data
  + larger samples and complete tables
  + using what you know to write efficient queries that do most of the work on the server

----
* left join staff
* left join customer

* dplyr joins in the R

```r
sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```

