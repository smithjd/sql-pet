# DBI package and SQL {#chapter_dbi-package-sql}

> This chapter:
> 
> * Introduces more DBI functions and demonstrates techniques for submitting SQL to the dbms
> * Illustrates some of the differences between writing `dplyr` commands and SQL
> * Suggests some strategies for dividing the work between your local R session and the dbms

## Setup

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(dbplyr)
require(knitr)
library(bookdown)
library(sqlpetr)
```
If you have not yet set up the Docker container with PostgreSQL and the dvdrental database, go back to [those instructions][Build the pet-sql Docker Image] to configure your environment. Otherwise, start your `sql-pet` container:

```r
sqlpetr::sp_docker_start("sql-pet")
```
Connect to the database:

```r
con <- sqlpetr::sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 30, connection_tab = TRUE
)
```

## SQL in R Markdown

When you create a report to run repeatedly, you might want to put that query into R markdown. See the discussion of [multiple language engines in R Markdown](https://bookdown.org/yihui/rmarkdown/language-engines.html#sql). That way you can also execute that SQL code in a chunk with the following header:

  {`sql, connection=con, output.var = "query_results"`}


```sql
SELECT "staff_id", COUNT(*) AS "n"
FROM "rental"
GROUP BY "staff_id";
```
Rmarkdown stored that query result in a tibble:

```r
query_results
```

```
##   staff_id    n
## 1        2 8004
## 2        1 8040
```
## DBI Package

In this chapter we touched on a number of functions from the DBI Package.  The table in file 96b shows other functions in the package.  The Chapter column references a section in the book if we have used it.


```r
film_table <- tbl(con, "film")
```

### Retrieve the whole table

SQL code that is submitted to a database is evaluated all at once^[From R's perspective. Actually there are 4 steps behind the scenes.].  To think through an SQL query, you can use `dplyr` to build it up step by step and then convert it to SQL code. Or you can use an IDE such as [pgAdmin](https://www.pgadmin.org/) to develop your SQL code. Once you have the SQL code, the following R code demonstrates how to use `dbSendQuery` to submit SQL from your R environment.


```r
result_set <- DBI::dbSendQuery(con, 'SELECT "title", "rental_duration", "length"
FROM "film"
WHERE ("rental_duration" > 5.0 AND "length" > 117.0)')

long_rental_films <- DBI::dbFetch(result_set)
str(long_rental_films)
```

```
## 'data.frame':	202 obs. of  3 variables:
##  $ title          : chr  "African Egg" "Alamo Videotape" "Alaska Phantom" "Alley Evolution" ...
##  $ rental_duration: int  6 6 6 6 6 7 6 7 6 6 ...
##  $ length         : int  130 126 136 180 181 179 119 127 170 162 ...
```

```r
DBI::dbClearResult(result_set)
```

The `dbFetch` function returns a `data.frame`, so you don't have `dplyr`'s guardrails that manage the amount of data returned to your workspace. You need to manage the amount of data yourself, using the `n = ` argument of `dbFetch` to specify the maximum number of records to retrieve per fetch. In the code above, we did not specify `n`, so `dbFetch` returned _all_ pending records as the default behavior.

When you are finished using the result set object, remember to free all of the associated resources with `dbClearResult`, as shown in the code above for the `result_set` variable.

### Or a chunk at a time

The following code demonstrates using the `n` argument to `dbFetch` to specify the maximum number of rows to return. Normally, you would pick some fixed number of records to return each time, but this code shows that you can vary the number of records returned by each call to `dbFetch`.

```r
result_set <- dbSendQuery(con, 'SELECT "title", "rental_duration", "length"
FROM "film"
WHERE ("rental_duration" > 5.0 AND "length" > 117.0)')

set.seed(5439)

chunk_num <- 0
while (!dbHasCompleted(result_set)) {
  chunk_num <- chunk_num + 1
  chunk <- dbFetch(result_set, n = sample(7:13,1))
  # print(nrow(chunk))
  chunk$chunk_num <- chunk_num
  if (!chunk_num %% 9) {print(chunk)}
}
```

```
##              title rental_duration length chunk_num
## 1    Graduate Lord               7    156         9
## 2     Grease Youth               7    135         9
## 3     Greedy Roots               7    166         9
## 4   Greek Everyone               7    176         9
## 5   Grinch Massage               7    150         9
## 6  Groundhog Uncut               6    139         9
## 7    Half Outfield               6    146         9
## 8    Hamlet Wisdom               7    146         9
## 9    Harold French               6    168         9
## 10    Hedwig Alter               7    169         9
## 11 Holes Brannigan               7    128         9
##                     title rental_duration length chunk_num
## 1          Speakeasy Date               6    165        18
## 2              Speed Suit               7    124        18
## 3            Spinal Rocky               7    138        18
## 4      Spirit Flintstones               7    149        18
## 5       Steers Armageddon               6    140        18
## 6             Stock Glass               7    160        18
## 7              Story Side               7    163        18
## 8        Streak Ridgemont               7    132        18
## 9          Sweden Shining               6    176        18
## 10           Tadpole Park               6    155        18
## 11      Talented Homicide               6    173        18
## 12 Telemark Heartbreakers               6    152        18
```

```r
dbClearResult(result_set)
```

## Dividing the work between R on your machine and the DBMS

They work together.

### Make the server do as much work as you can

* show_query as a first draft of SQL.  May or may not use SQL code submitted directly.

### Criteria for choosing between `dplyr` and native SQL

This probably belongs later in the book.

* performance considerations: first get the right data, then worry about performance
* Trade offs between leaving the data in PostgreSQL vs what's kept in R: 
  + browsing the data
  + larger samples and complete tables
  + using what you know to write efficient queries that do most of the work on the server

Where you place the `collect` function matters.
Here is a typical string of dplyr verbs strung together with the magrittr `%>%` pipe command that will be used to tease out the several different behaviors that a lazy query has when passed to different R functions.  This query joins three connection objects into a query we'll call `Q`:


```r
rental_table <- dplyr::tbl(con, "rental")
staff_table <- dplyr::tbl(con, "staff") 
# the 'staff' table has 2 rows
customer_table <- dplyr::tbl(con, "customer") 
# the 'customer' table has 599 rows

Q <- rental_table %>%
  dplyr::left_join(staff_table, by = c("staff_id" = "staff_id")) %>%
  dplyr::rename(staff_email = email) %>%
  dplyr::left_join(customer_table, by = c("customer_id" = "customer_id")) %>%
  dplyr::rename(customer_email = email) %>%
  dplyr::select(rental_date, staff_email, customer_email)
```


```r
Q %>% dplyr::show_query()
```

```
## <SQL>
## SELECT "rental_date", "staff_email", "email" AS "customer_email"
## FROM (SELECT "LHS"."rental_id" AS "rental_id", "LHS"."rental_date" AS "rental_date", "LHS"."inventory_id" AS "inventory_id", "LHS"."customer_id" AS "customer_id", "LHS"."return_date" AS "return_date", "LHS"."staff_id" AS "staff_id", "LHS"."last_update.x" AS "last_update.x", "LHS"."first_name" AS "first_name.x", "LHS"."last_name" AS "last_name.x", "LHS"."address_id" AS "address_id.x", "LHS"."staff_email" AS "staff_email", "LHS"."store_id" AS "store_id.x", "LHS"."active" AS "active.x", "LHS"."username" AS "username", "LHS"."password" AS "password", "LHS"."last_update.y" AS "last_update.y", "LHS"."picture" AS "picture", "RHS"."store_id" AS "store_id.y", "RHS"."first_name" AS "first_name.y", "RHS"."last_name" AS "last_name.y", "RHS"."email" AS "email", "RHS"."address_id" AS "address_id.y", "RHS"."activebool" AS "activebool", "RHS"."create_date" AS "create_date", "RHS"."last_update" AS "last_update", "RHS"."active" AS "active.y"
## FROM (SELECT "rental_id", "rental_date", "inventory_id", "customer_id", "return_date", "staff_id", "last_update.x", "first_name", "last_name", "address_id", "email" AS "staff_email", "store_id", "active", "username", "password", "last_update.y", "picture"
## FROM (SELECT "LHS"."rental_id" AS "rental_id", "LHS"."rental_date" AS "rental_date", "LHS"."inventory_id" AS "inventory_id", "LHS"."customer_id" AS "customer_id", "LHS"."return_date" AS "return_date", "LHS"."staff_id" AS "staff_id", "LHS"."last_update" AS "last_update.x", "RHS"."first_name" AS "first_name", "RHS"."last_name" AS "last_name", "RHS"."address_id" AS "address_id", "RHS"."email" AS "email", "RHS"."store_id" AS "store_id", "RHS"."active" AS "active", "RHS"."username" AS "username", "RHS"."password" AS "password", "RHS"."last_update" AS "last_update.y", "RHS"."picture" AS "picture"
## FROM "rental" AS "LHS"
## LEFT JOIN "staff" AS "RHS"
## ON ("LHS"."staff_id" = "RHS"."staff_id")
## ) "dbplyr_001") "LHS"
## LEFT JOIN "customer" AS "RHS"
## ON ("LHS"."customer_id" = "RHS"."customer_id")
## ) "dbplyr_002"
```

Here is the SQL query formatted for readability:
```
SELECT "rental_date", 
       "staff_email", 
       "customer_email" 
FROM   (SELECT "rental_id", 
               "rental_date", 
               "inventory_id", 
               "customer_id", 
               "return_date", 
               "staff_id", 
               "last_update.x", 
               "first_name.x", 
               "last_name.x", 
               "address_id.x", 
               "staff_email", 
               "store_id.x", 
               "active.x", 
               "username", 
               "password", 
               "last_update.y", 
               "picture", 
               "store_id.y", 
               "first_name.y", 
               "last_name.y", 
               "email" AS "customer_email", 
               "address_id.y", 
               "activebool", 
               "create_date", 
               "last_update", 
               "active.y" 
        FROM   (SELECT "TBL_LEFT"."rental_id"     AS "rental_id", 
                       "TBL_LEFT"."rental_date"   AS "rental_date", 
                       "TBL_LEFT"."inventory_id"  AS "inventory_id", 
                       "TBL_LEFT"."customer_id"   AS "customer_id", 
                       "TBL_LEFT"."return_date"   AS "return_date", 
                       "TBL_LEFT"."staff_id"      AS "staff_id", 
                       "TBL_LEFT"."last_update.x" AS "last_update.x", 
                       "TBL_LEFT"."first_name"    AS "first_name.x", 
                       "TBL_LEFT"."last_name"     AS "last_name.x", 
                       "TBL_LEFT"."address_id"    AS "address_id.x", 
                       "TBL_LEFT"."staff_email"   AS "staff_email", 
                       "TBL_LEFT"."store_id"      AS "store_id.x", 
                       "TBL_LEFT"."active"        AS "active.x", 
                       "TBL_LEFT"."username"      AS "username", 
                       "TBL_LEFT"."password"      AS "password", 
                       "TBL_LEFT"."last_update.y" AS "last_update.y", 
                       "TBL_LEFT"."picture"       AS "picture", 
                       "TBL_RIGHT"."store_id"     AS "store_id.y", 
                       "TBL_RIGHT"."first_name"   AS "first_name.y", 
                       "TBL_RIGHT"."last_name"    AS "last_name.y", 
                       "TBL_RIGHT"."email"        AS "email", 
                       "TBL_RIGHT"."address_id"   AS "address_id.y", 
                       "TBL_RIGHT"."activebool"   AS "activebool", 
                       "TBL_RIGHT"."create_date"  AS "create_date", 
                       "TBL_RIGHT"."last_update"  AS "last_update", 
                       "TBL_RIGHT"."active"       AS "active.y" 
                FROM   (SELECT "rental_id", 
                               "rental_date", 
                               "inventory_id", 
                               "customer_id", 
                               "return_date", 
                               "staff_id", 
                               "last_update.x", 
                               "first_name", 
                               "last_name", 
                               "address_id", 
                               "email" AS "staff_email", 
                               "store_id", 
                               "active", 
                               "username", 
                               "password", 
                               "last_update.y", 
                               "picture" 
                        FROM   (SELECT "TBL_LEFT"."rental_id"    AS "rental_id", 
                                       "TBL_LEFT"."rental_date"  AS 
                                       "rental_date", 
                                       "TBL_LEFT"."inventory_id" AS 
                                       "inventory_id", 
                                       "TBL_LEFT"."customer_id"  AS 
                                       "customer_id", 
                                       "TBL_LEFT"."return_date"  AS 
                                       "return_date", 
                                       "TBL_LEFT"."staff_id"     AS "staff_id", 
                                       "TBL_LEFT"."last_update"  AS 
                                       "last_update.x", 
                                       "TBL_RIGHT"."first_name"  AS "first_name" 
                                       , 
                       "TBL_RIGHT"."last_name"   AS "last_name", 
                       "TBL_RIGHT"."address_id"  AS "address_id", 
                       "TBL_RIGHT"."email"       AS "email", 
                       "TBL_RIGHT"."store_id"    AS "store_id", 
                       "TBL_RIGHT"."active"      AS "active", 
                       "TBL_RIGHT"."username"    AS "username", 
                       "TBL_RIGHT"."password"    AS "password", 
                       "TBL_RIGHT"."last_update" AS "last_update.y", 
                       "TBL_RIGHT"."picture"     AS "picture" 
                                FROM   "rental" AS "TBL_LEFT" 
                                       LEFT JOIN "staff" AS "TBL_RIGHT" 
                                              ON ( "TBL_LEFT"."staff_id" = 
                                                   "TBL_RIGHT"."staff_id" )) 
                               "ymdofxkiex") "TBL_LEFT" 
                       LEFT JOIN "customer" AS "TBL_RIGHT" 
                              ON ( "TBL_LEFT"."customer_id" = 
                                 "TBL_RIGHT"."customer_id" )) 
               "exddcnhait") "aohfdiedlb" 
```

Hand-written SQL code to do the same job will probably look a lot nicer and could be more efficient, but functionally `dplyr` does the job.


```r
GQ <- dbGetQuery(
  con,
  "select r.rental_date, s.email staff_email,c.email customer_email  
     from rental r
          left outer join staff s on r.staff_id = s.staff_id
          left outer join customer c on r.customer_id = c.customer_id
  "
)
```

But because `Q` hasn't been executed, we can add to it.  This behavior is the basis for a useful debugging and development process where queries are built up incrementally.

Where you place the `collect` function matters.

```r
DBI::dbDisconnect(con)
sqlpetr::sp_docker_stop("sql-pet")
```
