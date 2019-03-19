# Lazy Evaluation and Execution Environment {#chapter_lazy-evaluation-and-timing}

> This chapter:
> 
> * Builds on the lazy loading discussion in the previous chapter
> * Demonstrates how the use of the `dplyr::collect()` creates a boundary between code that is sent to a dbms and code that is executed locally

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
Define two tables to use in a simple query to use in the following discussion.

```r
rental_table <- dplyr::tbl(con, "rental")
customer_table <- dplyr::tbl(con, "customer")
```

Here is a simple string of `dplyr` verbs similar to the query used to illustrate issues in the last chapter:


```r
Q <- rental_table %>%
  dplyr::left_join(customer_table, by = c("customer_id" = "customer_id")) %>%
  dplyr::select(rental_date, email)

Q
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    rental_date         email                                
##    <dttm>              <chr>                                
##  1 2005-05-24 22:54:33 tommy.collazo@sakilacustomer.org     
##  2 2005-05-24 23:03:39 manuel.murrell@sakilacustomer.org    
##  3 2005-05-24 23:04:41 andrew.purdy@sakilacustomer.org      
##  4 2005-05-24 23:05:21 delores.hansen@sakilacustomer.org    
##  5 2005-05-24 23:08:07 nelson.christenson@sakilacustomer.org
##  6 2005-05-24 23:11:53 cassandra.walters@sakilacustomer.org 
##  7 2005-05-24 23:31:46 minnie.romero@sakilacustomer.org     
##  8 2005-05-25 00:00:40 ellen.simpson@sakilacustomer.org     
##  9 2005-05-25 00:02:21 danny.isom@sakilacustomer.org        
## 10 2005-05-25 00:09:02 april.burns@sakilacustomer.org       
## # … with more rows
```
Note that in the previous example we follow this book's convention of fully qualifying function names (e.g., specifying the package).  In practice, it's possible and convenient to use more abbreviated notation.

```r
Q <- tbl(con, "rental") %>%
  left_join(tbl(con, "customer"), by = c("customer_id" = "customer_id")) %>%
  select(rental_date, email)

Q
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    rental_date         email                                
##    <dttm>              <chr>                                
##  1 2005-05-24 22:54:33 tommy.collazo@sakilacustomer.org     
##  2 2005-05-24 23:03:39 manuel.murrell@sakilacustomer.org    
##  3 2005-05-24 23:04:41 andrew.purdy@sakilacustomer.org      
##  4 2005-05-24 23:05:21 delores.hansen@sakilacustomer.org    
##  5 2005-05-24 23:08:07 nelson.christenson@sakilacustomer.org
##  6 2005-05-24 23:11:53 cassandra.walters@sakilacustomer.org 
##  7 2005-05-24 23:31:46 minnie.romero@sakilacustomer.org     
##  8 2005-05-25 00:00:40 ellen.simpson@sakilacustomer.org     
##  9 2005-05-25 00:02:21 danny.isom@sakilacustomer.org        
## 10 2005-05-25 00:09:02 april.burns@sakilacustomer.org       
## # … with more rows
```

### Characteristics of local vs. server processing



| Dimension|Local                    | Remote 
|---|-----------------------------------|---------------------------------------
|Processor power |Desktops/laptops have less memory, speed, and storage than the database server. |Database server are high powered machines.
|Memory constraint |Query result must fit into memory. |Servers have a lot of memory
|Data access |Data must be pulled over the network.|Data moved locally over the server backbone.
|Security|Local control (good or bad) |Responsibility of database administrators
|Storage of intermediate results |Easy to save locally.   |May require extra privileges to save results in the database
|Analytical resources |Ecosystem of available R packages  |Extending SQL instruction set involves dbms-specific functions or R pseudo functions


### Experiment overview
Think of `Q` as a black box for the moment.  The following examples will show how `Q` is interpreted differently by different functions. It's important to remember in the following discussion that the "**and then**" operator (`%>%`) actually wraps the subsequent code inside the preceding code so that `Q %>% print()` is equivalent to `print(Q)`.

**Notation**

> |Symbol|Explanation
> |----|-------------
> | ![](screenshots/green-check.png)| A single green check indicates that some rows are returned. <br>
> | ![](screenshots/green-check.png) ![](screenshots/green-check.png)| Two green checks indicate that all the rows are returned.
> | ![](screenshots/red-x.png) |The red X indicates that no rows are returned.
>


> R code | Result 
> -------| --------------
> **Time-based, execution environment issues** | 
> [`Qc <- Q %>% count(email, sort = TRUE)`](#lazy_q_build) | ![](screenshots/red-x.png) **Extends** the lazy query object
> 
> 

The next chapter will discuss how to build queries and how to explore intermediate steps. But first, the following subsections provide a more detailed discussion of each row in the preceding table.


### Time-based, execution environment issues

Remember that if the expression is assigned to an object, it is not executed.  If not, a `print()` function is implied. This behavior is the basis for a useful debugging and development process where queries are built up incrementally.

> *These two are different:*
> Q %>% count(email) 
> Q_query <- Q %>% count(email) 
>

### Q %>% `more dplyr` {#lazy_q_build}

![](screenshots/green-check.png) Because the following statement implies a `print()` function at the end, we can run it repeatedly, adding dplyr expressions, and only get 10 rows back.  Every time we add a dplyr expression to a chain, R will rewrite the SQL code.  For example:

```r
Q %>% count(email) 
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    email                             n              
##    <chr>                             <S3: integer64>
##  1 harold.martino@sakilacustomer.org 32             
##  2 sean.douglass@sakilacustomer.org  23             
##  3 bob.pfeiffer@sakilacustomer.org   24             
##  4 jo.fowler@sakilacustomer.org      20             
##  5 raul.fortier@sakilacustomer.org   20             
##  6 annette.olson@sakilacustomer.org  24             
##  7 jeanne.lawson@sakilacustomer.org  27             
##  8 diane.collins@sakilacustomer.org  35             
##  9 cindy.fisher@sakilacustomer.org   29             
## 10 shelly.watts@sakilacustomer.org   26             
## # … with more rows
```
As we understand more about the data, we simply add dplyr expressions to pinpoint what we are looking for:

```r
Q %>% count(email) %>% 
  filter(n > 40) %>% 
  arrange(email)
```

```
## # Source:     lazy query [?? x 2]
## # Database:   postgres [postgres@localhost:5432/dvdrental]
## # Ordered by: email
##   email                            n              
##   <chr>                            <S3: integer64>
## 1 clara.shaw@sakilacustomer.org    42             
## 2 eleanor.hunt@sakilacustomer.org  46             
## 3 karl.seal@sakilacustomer.org     45             
## 4 marcia.dean@sakilacustomer.org   42             
## 5 tammy.sanders@sakilacustomer.org 41
```

![](screenshots/green-check.png) When all the accumulated `dplyr` verbs are executed, they are submitted to the dbms and the number of rows that are returned follow the same rules as discussed above.

### Many handy R functions can't be translated to SQL

![](screenshots/green-check.png) It just so happens that PostgreSQL has a `date` function that does the same thing as the `date` function in the `lubridate` package.  In the following code the `date` function is executed by PostreSQL.

```r
rental_table %>% mutate(rental_date = date(rental_date))
```

```
## # Source:   lazy query [?? x 7]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    rental_id rental_date inventory_id customer_id return_date        
##        <int> <date>             <int>       <int> <dttm>             
##  1         2 2005-05-24          1525         459 2005-05-28 19:40:33
##  2         3 2005-05-24          1711         408 2005-06-01 22:12:39
##  3         4 2005-05-24          2452         333 2005-06-03 01:43:41
##  4         5 2005-05-24          2079         222 2005-06-02 04:33:21
##  5         6 2005-05-24          2792         549 2005-05-27 01:32:07
##  6         7 2005-05-24          3995         269 2005-05-29 20:34:53
##  7         8 2005-05-24          2346         239 2005-05-27 23:33:46
##  8         9 2005-05-25          2580         126 2005-05-28 00:22:40
##  9        10 2005-05-25          1824         399 2005-05-31 22:44:21
## 10        11 2005-05-25          4443         142 2005-06-02 20:56:02
## # … with more rows, and 2 more variables: staff_id <int>,
## #   last_update <dttm>
```
![](screenshots/green-check.png) ![](screenshots/green-check.png) If we specify that we want to use the `lubridate` version (or any number of other R functions) they are passed to the dbms unless we explicitly tell `dplyr` to stop translating and bring the results back to the R environment for local processing.

```r
try(rental_table %>% collect() %>% 
  mutate(rental_date = lubridate::date(rental_date)))
```

```
## # A tibble: 16,044 x 7
##    rental_id rental_date inventory_id customer_id return_date        
##        <int> <date>             <int>       <int> <dttm>             
##  1         2 2005-05-24          1525         459 2005-05-28 19:40:33
##  2         3 2005-05-24          1711         408 2005-06-01 22:12:39
##  3         4 2005-05-24          2452         333 2005-06-03 01:43:41
##  4         5 2005-05-24          2079         222 2005-06-02 04:33:21
##  5         6 2005-05-24          2792         549 2005-05-27 01:32:07
##  6         7 2005-05-24          3995         269 2005-05-29 20:34:53
##  7         8 2005-05-24          2346         239 2005-05-27 23:33:46
##  8         9 2005-05-25          2580         126 2005-05-28 00:22:40
##  9        10 2005-05-25          1824         399 2005-05-31 22:44:21
## 10        11 2005-05-25          4443         142 2005-06-02 20:56:02
## # … with 16,034 more rows, and 2 more variables: staff_id <int>,
## #   last_update <dttm>
```


### More lazy execution examples

See more examples of lazy execution [here](https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html).


```r
DBI::dbDisconnect(con)
sqlpetr::sp_docker_stop("sql-pet")
```


## Other resources

* Benjamin S. Baumer. 2017. A Grammar for Reproducible and Painless Extract-Transform-Load Operations on Medium Data. [https://arxiv.org/abs/1708.07073](https://arxiv.org/abs/1708.07073) 
* dplyr Reference documentation: Remote tables. [https://dplyr.tidyverse.org/reference/index.html#section-remote-tables](https://dplyr.tidyverse.org/reference/index.html#section-remote-tables)
* Data Carpentry. SQL Databases and R. [https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html](https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html)

## Parking lot

> Although the material in the following table looks like it's *good to know* it's not clear why a run-of-the-mill R user would be concerned with it.  It looks like a draft; not completley clear...

|Operation    |dplyr<br>Local-Only|dplyr<br>Local-Lazy|SQL
|-------------|-------------------|-------------------|----------------
|connection|DBI::dbConnect|DBI::dbConnect|DBI::dbConnect
|Single Read joining one or more tables<br>and fits into memory|DBI::dbReadTable, (returns a df)<br>R package calls always available|tbl() + collect()<br>tbl:Returns two lists<br> collect(): returns tbl_df<br>R package calls available only after collect() call.  Ideally push everything to DB.<br>May require R placeholder functions to mimick DB functions.|dbGetQuery
|Multiple Reads|Not Applicable|Not Applicable|dbSendQuery + dbFetch + dbClearResult
|Fetch Data locally|DBI::dbReadTable fetches data|collect()|dbGetQuery or dbSendQuery+dbFetch+dbClearResult|dbGetQuery or dbSendQuery + dbFetch
|Write Results Local|write family of functions|write family of functions|write family of functions
|Write Results to DB|compute() or copy_to|compute() or copy_to|compute() or copy_to

