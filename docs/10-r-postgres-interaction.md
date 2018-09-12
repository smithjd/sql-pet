# Interacting with Postgres from R


## Basics

* keeping passwords secure
* Coverage in this book.  There are many SQL tutorials that are available.  For example, we are drawing some materials from  [a tutorial we recommend](http://www.postgresqltutorial.com/postgresql-sample-database/).  In particular, we will not replicate the lessons there, which you might want to complete.  Instead, we are showing strategies that are recommended for R users.  That will include some translations of queries that are discussed there.

## Ask yourself about what you are aiming for?

* differences between production and data warehouse environments
* learning to keep your DBAs happy
  + You are your own DBA in this simulation, so you can wreak havoc and learn from it, but you can learn to be DBA-friendly here.
  + in the end it's the subject-matter experts that understand your data, but you have to work with your DBAs first

## Get some basic information about your database

Assume that the Docker container with Postgres and the dvdrental database are ready to go.

```r
system2("docker",  "start pet", stdout = TRUE, stderr = TRUE)
```

```
## [1] "pet"
```

```r
Sys.sleep(2) # need to wait for Docker & Postgres to come up before connecting.
con <- DBI::dbConnect(RPostgres::Postgres(), host = "localhost",
                      port = "5432", user = "postgres",
                      password = "postgres", dbname = "dvdrental" ) # note that the dbname is specified
```

You usually need to use both the available documentation for your [database](http://www.postgresqltutorial.com/postgresql-sample-database/) and to be somewhat skeptical (e.g., empirical).  It's worth learning to interpret the symbols in an [Entity Relationship Diagram](https://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model):

![](./screenshots/ER-diagram-symbols.png)

Depending on how skeptical you are about the documenttion, you might want to get an overview of a database by pulling data from the database `information_schema`.  Here's a selection of useful information although you may want more (or less).  There is a lot to choose from [a vast list of metadata](https://www.postgresql.org/docs/current/static/infoschema-columns.html).  Note that information schemas are somewhat consistent across different DBMS' that you may encounter.


```r
table_schema_query  <- paste0("SELECT ", 
  "table_name, column_name, data_type, ordinal_position, column_default, character_maximum_length, is_nullable", 
  " FROM information_schema.columns ", 
  "WHERE table_schema = 'public'")
 
  rental_meta_data  <- dbGetQuery(con, table_schema_query) 

glimpse(rental_meta_data)
```

```
## Observations: 128
## Variables: 7
## $ table_name               <chr> "actor_info", "actor_info", "actor_in...
## $ column_name              <chr> "actor_id", "first_name", "last_name"...
## $ data_type                <chr> "integer", "character varying", "char...
## $ ordinal_position         <int> 1, 2, 3, 4, 1, 2, 3, 4, 5, 6, 7, 8, 9...
## $ column_default           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, N...
## $ character_maximum_length <int> NA, 45, 45, NA, NA, NA, 50, 10, 20, 5...
## $ is_nullable              <chr> "YES", "YES", "YES", "YES", "YES", "Y...
```
Pull out some rough-and-ready but useful statistics about your database.  Since we are in SQL-land we talk about variables as `columns`.

Start with a list of tables names and a count of the number of columns that each one contains.

```r
rental_meta_data %>% count(table_name) %>% rename(number_of_columns = n) %>% as.data.frame()
```

```
##                    table_name number_of_columns
## 1                       actor                 4
## 2                  actor_info                 4
## 3                     address                 8
## 4                    category                 3
## 5                        city                 4
## 6                     country                 3
## 7                    customer                10
## 8               customer_list                 9
## 9                        film                13
## 10                 film_actor                 3
## 11              film_category                 3
## 12                  film_list                 8
## 13                  inventory                 4
## 14                   language                 3
## 15 nicer_but_slower_film_list                 8
## 16                    payment                 6
## 17                     rental                 7
## 18     sales_by_film_category                 2
## 19             sales_by_store                 3
## 20                      staff                11
## 21                 staff_list                 8
## 22                      store                 4
```

How many column names are shared across tables (or duplicated)?

```r
rental_meta_data %>% count(column_name, sort = TRUE) %>% filter(n > 1)
```

```
## # A tibble: 34 x 2
##    column_name     n
##    <chr>       <int>
##  1 last_update    14
##  2 address_id      4
##  3 film_id         4
##  4 first_name      4
##  5 last_name       4
##  6 name            4
##  7 store_id        4
##  8 actor_id        3
##  9 address         3
## 10 category        3
## # ... with 24 more rows
```

How many column names are unique?

```r
rental_meta_data %>% count(column_name) %>% filter(n > 1)
```

```
## # A tibble: 34 x 2
##    column_name     n
##    <chr>       <int>
##  1 active          2
##  2 actor_id        3
##  3 actors          2
##  4 address         3
##  5 address_id      4
##  6 category        3
##  7 category_id     2
##  8 city            3
##  9 city_id         2
## 10 country         3
## # ... with 24 more rows
```

What data types are found in the database?

```r
rental_meta_data %>% count(data_type)
```

```
## # A tibble: 13 x 2
##    data_type                       n
##    <chr>                       <int>
##  1 ARRAY                           1
##  2 boolean                         2
##  3 bytea                           1
##  4 character                       1
##  5 character varying              36
##  6 date                            1
##  7 integer                        22
##  8 numeric                         7
##  9 smallint                       25
## 10 text                           11
## 11 timestamp without time zone    17
## 12 tsvector                        1
## 13 USER-DEFINED                    3
```

## Using Dplyr

We already started, but that's OK.

### finding out what's in the database

* DBI / RPostgres packaages
* R tools like glimpse, skimr, kable.
* examining dplyr queries (show_query on the R side v EXPLAIN on the Postges side)
* Tutorials like: https://suzan.rbind.io/tags/dplyr/ 
* Benjamin S. Baumer, A Grammar for Reproducible and Painless Extract-Transform-Load Operations on Medium Data: https://arxiv.org/pdf/1708.07073 

### sample query

* rental 
* date subset
* left join staff
* left join customer

### Subset: only retrieve what you need

* Columns
* Rows
  + number of row
  + specific rows
* dplyr joins in the R

### Make the server do as much work as you can

discuss this simple example? http://www.postgresqltutorial.com/postgresql-left-join/ 

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

