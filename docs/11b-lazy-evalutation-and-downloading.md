# Lazy Evaluation and Lazy Queries (11b)


## This chapter:
> 
> * Reviews lazy evaluation and discusses its interaction with remote query execution on a dbms 
> * Illustrates some of the differences between writing `dplyr` commands and SQL
> * Suggests some strategies for dividing the work between your local R session and the dbms

### Setup

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
Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go. If not go back to [the previous Chapter][Build the pet-sql Docker Image]

```r
sp_docker_start("sql-pet")
```
Connect to the database:

```r
con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10
)
```

## R is lazy and comes with guardrails

By design, R is both a language and an interactive development environment (IDE).  As a language, R tries to be as efficient as possible.  As an IDE, R creates some guardrails to make it easy and safe to work with your data. For example `getOption("max.print")` prevents R from printing more rows of data than you can handle, with a nice default of 99999, which may or may not suit you.

On the other hand SQL a *"Structured Query Language (SQL) is a standard computer language for relational database management and data manipulation."* ^[https://www.techopedia.com/definition/1245/structured-query-language-sql]. SQL has database-specific Interactive Development Environments (IDEs): for postgreSQL it's [pgAdmin](https://www.pgadmin.org/).  Roger Peng explains in [R Programming for Data Science](https://bookdown.org/rdpeng/rprogdatascience/history-and-overview-of-r.html#basic-features-of-r) that:

> R has maintained the original S philosophy, which is that it provides a language that is both useful for interactive work, but contains a powerful programming language for developing new tools. 

This is complicated when R interacts with SQL.  In [the vignette for dbplyr](https://cran.r-project.org/web/packages/dbplyr/vignettes/dbplyr.html) Hadley Wikham explains:

> The most important difference between ordinary data frames and remote database queries is that your R code is translated into SQL and executed in the database on the remote server, not in R on your local machine. When working with databases, dplyr tries to be as lazy as possible:
> 
> * It never pulls data into R unless you explicitly ask for it.
> 
> * It delays doing any work until the last possible moment: it collects together everything you want to do and then sends it to > the database in one step.
> 

Eventually, if you are interacting with a dbms from R you will need to understand the differences between lazy loading, lazy evaluation, and lazy queries.

### Lazy loading

"*Lazy loading is always used for code in packages but is optional (selected by the package maintainer) for datasets in packages.*"^[https://cran.r-project.org/doc/manuals/r-release/R-ints.html#Lazy-loading]  Lazy loading means that the code for a particular function doesn't actually get loaded into memory until the last minute -- when it's actually being used.

### Lazy evaluation 

Essentially "Lazy evaluation is a programming strategy that allows a symbol to be evaluated only when needed." ^[https://colinfay.me/lazyeval/]  That means that lazy evaluation is about **symbols** such as function arguments ^[http://adv-r.had.co.nz/Functions.html#function-arguments] when they are evaluated. Tidy evaluation complicates lazy evaluation. ^[https://colinfay.me/tidyeval-1/]

### Lazy Queries

"*When you create a "lazy" query, you're creating a pointer to a set of conditions on the database, but the query isn't actually run and the data isn't actually loaded until you call "next" or some similar method to actually fetch the data and load it into an object.*" ^[https://www.quora.com/What-is-a-lazy-query]  The `collect()` function retrieves data into a local tibble.^[https://dplyr.tidyverse.org/reference/compute.html]

## Lazy evaluation and lazy queries

### Dplyr connection objects
As introduced in the previous chapter, the `dplyr::tbl` function creates  an object that might **look** like a data frame in that when you enter it on the command line, it prints a bunch of rows from the dbms table.  But is actually a **list** object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  

The following code illustrates these issues.  The `dplyr::tbl` function creates the connection object that we store in an object named `rental_table`:

```r
rental_table <- dplyr::tbl(con, "rental")
```
At first glance, it kind of **looks** like a data frame although it only prints 10 of the table's 16,044 rows:

```r
rental_table
```

```
## # Source:   table<rental> [?? x 7]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    rental_id rental_date         inventory_id customer_id
##        <int> <dttm>                     <int>       <int>
##  1         2 2005-05-24 22:54:33         1525         459
##  2         3 2005-05-24 23:03:39         1711         408
##  3         4 2005-05-24 23:04:41         2452         333
##  4         5 2005-05-24 23:05:21         2079         222
##  5         6 2005-05-24 23:08:07         2792         549
##  6         7 2005-05-24 23:11:53         3995         269
##  7         8 2005-05-24 23:31:46         2346         239
##  8         9 2005-05-25 00:00:40         2580         126
##  9        10 2005-05-25 00:02:21         1824         399
## 10        11 2005-05-25 00:09:02         4443         142
## # ... with more rows, and 3 more variables: return_date <dttm>,
## #   staff_id <int>, last_update <dttm>
```
But consider the structure of  `rental_table`:

```r
str(rental_table)
```

```
## List of 2
##  $ src:List of 2
##   ..$ con  :Formal class 'PqConnection' [package "RPostgres"] with 3 slots
##   .. .. ..@ ptr     :<externalptr> 
##   .. .. ..@ bigint  : chr "integer64"
##   .. .. ..@ typnames:'data.frame':	437 obs. of  2 variables:
##   .. .. .. ..$ oid    : int [1:437] 16 17 18 19 20 21 22 23 24 25 ...
##   .. .. .. ..$ typname: chr [1:437] "bool" "bytea" "char" "name" ...
##   ..$ disco: NULL
##   ..- attr(*, "class")= chr [1:3] "src_dbi" "src_sql" "src"
##  $ ops:List of 2
##   ..$ x   : 'ident' chr "rental"
##   ..$ vars: chr [1:7] "rental_id" "rental_date" "inventory_id" "customer_id" ...
##   ..- attr(*, "class")= chr [1:3] "op_base_remote" "op_base" "op"
##  - attr(*, "class")= chr [1:4] "tbl_dbi" "tbl_sql" "tbl_lazy" "tbl"
```

It has two rows.  The first row contains all the information in the `con` object, which contains information about all the tables and objects in the database:

```r
rental_table$src$con@typnames$typname[380:437]
```

```
##  [1] "customer"                    "_customer"                  
##  [3] "actor_actor_id_seq"          "actor"                      
##  [5] "_actor"                      "category_category_id_seq"   
##  [7] "category"                    "_category"                  
##  [9] "film_film_id_seq"            "film"                       
## [11] "_film"                       "pg_toast_16434"             
## [13] "film_actor"                  "_film_actor"                
## [15] "film_category"               "_film_category"             
## [17] "actor_info"                  "_actor_info"                
## [19] "address_address_id_seq"      "address"                    
## [21] "_address"                    "city_city_id_seq"           
## [23] "city"                        "_city"                      
## [25] "country_country_id_seq"      "country"                    
## [27] "_country"                    "customer_list"              
## [29] "_customer_list"              "film_list"                  
## [31] "_film_list"                  "inventory_inventory_id_seq" 
## [33] "inventory"                   "_inventory"                 
## [35] "language_language_id_seq"    "language"                   
## [37] "_language"                   "nicer_but_slower_film_list" 
## [39] "_nicer_but_slower_film_list" "payment_payment_id_seq"     
## [41] "payment"                     "_payment"                   
## [43] "rental_rental_id_seq"        "rental"                     
## [45] "_rental"                     "sales_by_film_category"     
## [47] "_sales_by_film_category"     "staff_staff_id_seq"         
## [49] "staff"                       "_staff"                     
## [51] "pg_toast_16529"              "store_store_id_seq"         
## [53] "store"                       "_store"                     
## [55] "sales_by_store"              "_sales_by_store"            
## [57] "staff_list"                  "_staff_list"
```
The second row contains a list of the columns in the `rental` table, among other things:


```r
rental_table$ops$vars
```

```
## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
## [5] "return_date"  "staff_id"     "last_update"
```

To illustrate the different issues involved in data retrieval, we create equivalent connection objects to link to two other tables.  

```r
staff_table <- dplyr::tbl(con, "staff") 
# the 'staff' table has 2 rows

customer_table <- dplyr::tbl(con, "customer") 
# the 'customer' table has 599 rows
```

### Using a lazy query

Here is a typical string of dplyr verbs strung together with the magrittr `%>%` command that will be used to tease out the several different behaviors that a lazy query has when passed to different R functions.  This query joins three connection objects into a query we'll call `Q`:


```r
Q <- rental_table %>%
  select(staff_id, customer_id, rental_date) %>%
  left_join(staff_table, by = c("staff_id" = "staff_id")) %>%
  rename(staff_email = email) %>%
  select(staff_id, customer_id, rental_date, staff_email) %>%
  left_join(customer_table, by = c("customer_id" = "customer_id")) %>%
  rename(customer_email = email) %>%
  select(rental_date, staff_email, customer_email)
```

Think of `Q` as a black box for the moment.  The following examples will show how `Q` is interpreted differently by different functions. 

> R code | Result 
> -------| --------------
> `Q %>% print()` | Prints x rows; same as just entering `Q`  
> `Q %>% as.tibble()` | Forces `Q` to be a tibble
> `Q %>% head()` |  Prints the first 6 rows 
> `Q %>% length()` |  Counts the rows in `Q`
> `Q %>% str(max.level = 3)` | Shows the top 3 levels of the **object** `Q` 
> `Q %>% nrow()` | **Attempts** to determine the number of rows 
> `Q %>% tally()` | Counts all the rows -- on the dbms side
> `Q %>% collect (n = 20)` | Prints 20 rows  
> `Q %>% collect (n = 20) %>% head()` | Prints 6 rows  
> `Q %>% show_query()` | **Translates** the lazy query object into SQL  
> `Qc <- Q %>%` <br /> `count(customer_email, sort = TRUE)` <br /> `Qc` | **Extends** the lazy query object
>
> 

(The next chapter will discuss how to build queries and how to explore intermediate steps.)

Remember that `Q %>% print()` is equivalent to `print(Q)` and the same as just entering `Q` on the command line.  We use the magrittr pipe operator here because chaining functions highlights how the same object behaves differently in each use.

```r
Q %>% print()
```

```
## # Source:   lazy query [?? x 3]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    rental_date         staff_email            customer_email              
##    <dttm>              <chr>                  <chr>                       
##  1 2005-05-24 22:54:33 Mike.Hillyer@sakilast… tommy.collazo@sakilacustome…
##  2 2005-05-24 23:03:39 Mike.Hillyer@sakilast… manuel.murrell@sakilacustom…
##  3 2005-05-24 23:04:41 Jon.Stephens@sakilast… andrew.purdy@sakilacustomer…
##  4 2005-05-24 23:05:21 Mike.Hillyer@sakilast… delores.hansen@sakilacustom…
##  5 2005-05-24 23:08:07 Mike.Hillyer@sakilast… nelson.christenson@sakilacu…
##  6 2005-05-24 23:11:53 Jon.Stephens@sakilast… cassandra.walters@sakilacus…
##  7 2005-05-24 23:31:46 Jon.Stephens@sakilast… minnie.romero@sakilacustome…
##  8 2005-05-25 00:00:40 Mike.Hillyer@sakilast… ellen.simpson@sakilacustome…
##  9 2005-05-25 00:02:21 Jon.Stephens@sakilast… danny.isom@sakilacustomer.o…
## 10 2005-05-25 00:09:02 Jon.Stephens@sakilast… april.burns@sakilacustomer.…
## # ... with more rows
```
In its role as IDE, R has provided nicely formatted output that is similar to what it prints for a tibble, with descriptive information about the dataset and each column:

>
> \# Source:   lazy query [?? x 3] </br >
> \# Database: postgres [postgres@localhost:5432/dvdrental] </br >
>   rental_date         staff_email                  customer_email 
>   \<dttm\>              \<chr\>                        \<chr\>
>

It has only retrieved 10 rows but doesn't know how many rows are left to retrieve as it notes `... with more rows`. 
In contrast to `print()`, the `as.tibble()` function causes R to download the whole table, using tibble's default of displaying only the first 10 rows.

```r
Q %>% as.tibble()
```

```
## # A tibble: 16,044 x 3
##    rental_date         staff_email            customer_email              
##    <dttm>              <chr>                  <chr>                       
##  1 2005-05-24 22:54:33 Mike.Hillyer@sakilast… tommy.collazo@sakilacustome…
##  2 2005-05-24 23:03:39 Mike.Hillyer@sakilast… manuel.murrell@sakilacustom…
##  3 2005-05-24 23:04:41 Jon.Stephens@sakilast… andrew.purdy@sakilacustomer…
##  4 2005-05-24 23:05:21 Mike.Hillyer@sakilast… delores.hansen@sakilacustom…
##  5 2005-05-24 23:08:07 Mike.Hillyer@sakilast… nelson.christenson@sakilacu…
##  6 2005-05-24 23:11:53 Jon.Stephens@sakilast… cassandra.walters@sakilacus…
##  7 2005-05-24 23:31:46 Jon.Stephens@sakilast… minnie.romero@sakilacustome…
##  8 2005-05-25 00:00:40 Mike.Hillyer@sakilast… ellen.simpson@sakilacustome…
##  9 2005-05-25 00:02:21 Jon.Stephens@sakilast… danny.isom@sakilacustomer.o…
## 10 2005-05-25 00:09:02 Jon.Stephens@sakilast… april.burns@sakilacustomer.…
## # ... with 16,034 more rows
```

The `head()` function is very similar to print but has a different "`max.print`" value.

```r
Q %>% head()
```

```
## # Source:   lazy query [?? x 3]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   rental_date         staff_email             customer_email              
##   <dttm>              <chr>                   <chr>                       
## 1 2005-05-24 22:54:33 Mike.Hillyer@sakilasta… tommy.collazo@sakilacustome…
## 2 2005-05-24 23:03:39 Mike.Hillyer@sakilasta… manuel.murrell@sakilacustom…
## 3 2005-05-24 23:04:41 Jon.Stephens@sakilasta… andrew.purdy@sakilacustomer…
## 4 2005-05-24 23:05:21 Mike.Hillyer@sakilasta… delores.hansen@sakilacustom…
## 5 2005-05-24 23:08:07 Mike.Hillyer@sakilasta… nelson.christenson@sakilacu…
## 6 2005-05-24 23:11:53 Jon.Stephens@sakilasta… cassandra.walters@sakilacus…
```
Because the `Q` object is relatively complex, using `str()` on it prints many lines.  You can glimpse what's going on with `length()`:

```r
Q %>% length()
```

```
## [1] 2
```
Looking inside shows some of what's going on:

```r
Q %>% str(max.level = 3) 
```

```
## List of 2
##  $ src:List of 2
##   ..$ con  :Formal class 'PqConnection' [package "RPostgres"] with 3 slots
##   ..$ disco: NULL
##   ..- attr(*, "class")= chr [1:3] "src_dbi" "src_sql" "src"
##  $ ops:List of 4
##   ..$ name: chr "select"
##   ..$ x   :List of 4
##   .. ..$ name: chr "rename"
##   .. ..$ x   :List of 4
##   .. .. ..- attr(*, "class")= chr [1:3] "op_join" "op_double" "op"
##   .. ..$ dots:List of 1
##   .. ..$ args: list()
##   .. ..- attr(*, "class")= chr [1:3] "op_rename" "op_single" "op"
##   ..$ dots:List of 3
##   .. ..$ : language ~rental_date
##   .. .. ..- attr(*, ".Environment")=<environment: 0x7fcb13a6c078> 
##   .. ..$ : language ~staff_email
##   .. .. ..- attr(*, ".Environment")=<environment: 0x7fcb13a6c078> 
##   .. ..$ : language ~customer_email
##   .. .. ..- attr(*, ".Environment")=<environment: 0x7fcb13a6c078> 
##   .. ..- attr(*, "class")= chr "quosures"
##   ..$ args: list()
##   ..- attr(*, "class")= chr [1:3] "op_select" "op_single" "op"
##  - attr(*, "class")= chr [1:4] "tbl_dbi" "tbl_sql" "tbl_lazy" "tbl"
```
Notice the difference between `nrow()` and `tally()`:

```r
Q %>% nrow()
```

```
## [1] NA
```

```r
Q %>% tally()
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   n              
##   <S3: integer64>
## 1 16044
```
The `nrow()` function knows that `Q` is a list.  On the other hand, the `tally()` function tells SQL to go count all the rows. Notice that `Q` results in 16,044 rows -- the same number of rows as `rental`.

The `dplyr::collect()` function triggers a dbFetch() function behind the scenes, which forces R to download a specified number of rows:

```r
Q %>% collect(n = 20)
```

```
## # A tibble: 20 x 3
##    rental_date         staff_email            customer_email              
##    <dttm>              <chr>                  <chr>                       
##  1 2005-05-24 22:54:33 Mike.Hillyer@sakilast… tommy.collazo@sakilacustome…
##  2 2005-05-24 23:03:39 Mike.Hillyer@sakilast… manuel.murrell@sakilacustom…
##  3 2005-05-24 23:04:41 Jon.Stephens@sakilast… andrew.purdy@sakilacustomer…
##  4 2005-05-24 23:05:21 Mike.Hillyer@sakilast… delores.hansen@sakilacustom…
##  5 2005-05-24 23:08:07 Mike.Hillyer@sakilast… nelson.christenson@sakilacu…
##  6 2005-05-24 23:11:53 Jon.Stephens@sakilast… cassandra.walters@sakilacus…
##  7 2005-05-24 23:31:46 Jon.Stephens@sakilast… minnie.romero@sakilacustome…
##  8 2005-05-25 00:00:40 Mike.Hillyer@sakilast… ellen.simpson@sakilacustome…
##  9 2005-05-25 00:02:21 Jon.Stephens@sakilast… danny.isom@sakilacustomer.o…
## 10 2005-05-25 00:09:02 Jon.Stephens@sakilast… april.burns@sakilacustomer.…
## 11 2005-05-25 00:19:27 Jon.Stephens@sakilast… deanna.byrd@sakilacustomer.…
## 12 2005-05-25 00:22:55 Mike.Hillyer@sakilast… raymond.mcwhorter@sakilacus…
## 13 2005-05-25 00:31:15 Mike.Hillyer@sakilast… theodore.culp@sakilacustome…
## 14 2005-05-25 00:39:22 Mike.Hillyer@sakilast… ronald.weiner@sakilacustome…
## 15 2005-05-25 00:43:11 Jon.Stephens@sakilast… steven.curley@sakilacustome…
## 16 2005-05-25 01:06:36 Mike.Hillyer@sakilast… isaac.oglesby@sakilacustome…
## 17 2005-05-25 01:10:47 Jon.Stephens@sakilast… ruth.martinez@sakilacustome…
## 18 2005-05-25 01:17:24 Mike.Hillyer@sakilast… ronnie.ricketts@sakilacusto…
## 19 2005-05-25 01:48:41 Jon.Stephens@sakilast… roberta.harper@sakilacustom…
## 20 2005-05-25 01:59:46 Jon.Stephens@sakilast… craig.morrell@sakilacustome…
```

```r
Q %>% collect(n = 20) %>% head()
```

```
## # A tibble: 6 x 3
##   rental_date         staff_email             customer_email              
##   <dttm>              <chr>                   <chr>                       
## 1 2005-05-24 22:54:33 Mike.Hillyer@sakilasta… tommy.collazo@sakilacustome…
## 2 2005-05-24 23:03:39 Mike.Hillyer@sakilasta… manuel.murrell@sakilacustom…
## 3 2005-05-24 23:04:41 Jon.Stephens@sakilasta… andrew.purdy@sakilacustomer…
## 4 2005-05-24 23:05:21 Mike.Hillyer@sakilasta… delores.hansen@sakilacustom…
## 5 2005-05-24 23:08:07 Mike.Hillyer@sakilasta… nelson.christenson@sakilacu…
## 6 2005-05-24 23:11:53 Jon.Stephens@sakilasta… cassandra.walters@sakilacus…
```
The `collect` function triggers the creation of a tibble and controls the number of rows that the DBMS sends to R.  Notice that `head` only prints 6 of the 25 rows that R has retrieved.  


```r
Q %>% show_query()
```

```
## <SQL>
## SELECT "rental_date", "staff_email", "customer_email"
## FROM (SELECT "staff_id", "customer_id", "rental_date", "staff_email", "store_id", "first_name", "last_name", "email" AS "customer_email", "address_id", "activebool", "create_date", "last_update", "active"
## FROM (SELECT "TBL_LEFT"."staff_id" AS "staff_id", "TBL_LEFT"."customer_id" AS "customer_id", "TBL_LEFT"."rental_date" AS "rental_date", "TBL_LEFT"."staff_email" AS "staff_email", "TBL_RIGHT"."store_id" AS "store_id", "TBL_RIGHT"."first_name" AS "first_name", "TBL_RIGHT"."last_name" AS "last_name", "TBL_RIGHT"."email" AS "email", "TBL_RIGHT"."address_id" AS "address_id", "TBL_RIGHT"."activebool" AS "activebool", "TBL_RIGHT"."create_date" AS "create_date", "TBL_RIGHT"."last_update" AS "last_update", "TBL_RIGHT"."active" AS "active"
##   FROM (SELECT "staff_id", "customer_id", "rental_date", "staff_email"
## FROM (SELECT "staff_id", "customer_id", "rental_date", "first_name", "last_name", "address_id", "email" AS "staff_email", "store_id", "active", "username", "password", "last_update", "picture"
## FROM (SELECT "TBL_LEFT"."staff_id" AS "staff_id", "TBL_LEFT"."customer_id" AS "customer_id", "TBL_LEFT"."rental_date" AS "rental_date", "TBL_RIGHT"."first_name" AS "first_name", "TBL_RIGHT"."last_name" AS "last_name", "TBL_RIGHT"."address_id" AS "address_id", "TBL_RIGHT"."email" AS "email", "TBL_RIGHT"."store_id" AS "store_id", "TBL_RIGHT"."active" AS "active", "TBL_RIGHT"."username" AS "username", "TBL_RIGHT"."password" AS "password", "TBL_RIGHT"."last_update" AS "last_update", "TBL_RIGHT"."picture" AS "picture"
##   FROM (SELECT "staff_id", "customer_id", "rental_date"
## FROM "rental") "TBL_LEFT"
##   LEFT JOIN "staff" AS "TBL_RIGHT"
##   ON ("TBL_LEFT"."staff_id" = "TBL_RIGHT"."staff_id")
## ) "npghbogapn") "vapgdctabt") "TBL_LEFT"
##   LEFT JOIN "customer" AS "TBL_RIGHT"
##   ON ("TBL_LEFT"."customer_id" = "TBL_RIGHT"."customer_id")
## ) "jtjuanvogi") "jlxuthlhsv"
```
Hand-written SQL code to do the same job will probably look a lot nicer and could be more efficient, but functionally dplyr does the job.

But because `Q` hasn't been executed, we can add to it.  This behavior is the basis for a useful debugging and development process where queries are built up incrementally.

```r
Qc <- Q %>% count(customer_email, sort = TRUE) 
Qc
```

```
## # Source:     lazy query [?? x 2]
## # Database:   postgres [postgres@localhost:5432/dvdrental]
## # Ordered by: desc(n)
##    customer_email                    n              
##    <chr>                             <S3: integer64>
##  1 eleanor.hunt@sakilacustomer.org   46             
##  2 karl.seal@sakilacustomer.org      45             
##  3 clara.shaw@sakilacustomer.org     42             
##  4 marcia.dean@sakilacustomer.org    42             
##  5 tammy.sanders@sakilacustomer.org  41             
##  6 wesley.bull@sakilacustomer.org    40             
##  7 sue.peters@sakilacustomer.org     40             
##  8 tim.cary@sakilacustomer.org       39             
##  9 rhonda.kennedy@sakilacustomer.org 39             
## 10 marion.snyder@sakilacustomer.org  39             
## # ... with more rows
```

See more example of lazy execution can be found [Here](https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html).

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

SQL code that is submitted to a database is evaluated all at once^[From R's perspective. Actually there are 4 steps behind the scenes.].  To think through an SQL query, either use dplyr to build it up step by step and then convert it to SQL code or an IDE such as [pgAdmin](https://www.pgadmin.org/). DBI returns a data.frame, so you don't have dplyr's guardrails.

```r
res <- dbSendQuery(con, 'SELECT "title", "rental_duration", "length"
FROM "film"
WHERE ("rental_duration" > 5.0 AND "length" > 117.0)')

res_output <- dbFetch(res)
str(res_output)
```

```
## 'data.frame':	202 obs. of  3 variables:
##  $ title          : chr  "African Egg" "Alamo Videotape" "Alaska Phantom" "Alley Evolution" ...
##  $ rental_duration: int  6 6 6 6 6 7 6 7 6 6 ...
##  $ length         : int  130 126 136 180 181 179 119 127 170 162 ...
```

```r
dbClearResult(res)
```

### Or a chunk at a time


```r
res <- dbSendQuery(con, 'SELECT "title", "rental_duration", "length"
FROM "film"
WHERE ("rental_duration" > 5.0 AND "length" > 117.0)')

chunk_num <- 0
while(!dbHasCompleted(res)){
  chunk_num <- chunk_num + 1
  chunk <- dbFetch(res, n = 5)
  print(nrow(chunk))
  if (!chunk_num %% 7) {print(chunk)}
}
```

```
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
##                 title rental_duration length
## 1 Christmas Moonshine               7    150
## 2       Citizen Shrek               7    165
## 3     Cleopatra Devil               6    150
## 4  Clockwork Paradise               7    143
## 5    Clones Pinocchio               6    124
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
##                     title rental_duration length
## 1 Extraordinary Conquerer               6    122
## 2             Flight Lies               7    179
## 3           Floats Garden               6    145
## 4       Forever Candidate               7    131
## 5   Frankenstein Stranger               7    159
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
##              title rental_duration length
## 1    Jungle Closer               6    134
## 2  Killer Innocent               7    161
## 3 Lambs Cincinatti               6    144
## 4   Lawless Vision               6    181
## 5    Lawrence Love               7    175
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
##               title rental_duration length
## 1   Outbreak Divine               6    169
## 2      Outlaw Hanky               7    148
## 3     Paris Weekend               7    121
## 4 Philadelphia Wife               7    137
## 5  Pianist Outfield               6    136
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
##                title rental_duration length
## 1       Spinal Rocky               7    138
## 2 Spirit Flintstones               7    149
## 3  Steers Armageddon               6    140
## 4        Stock Glass               7    160
## 5         Story Side               7    163
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 5
## [1] 2
```

```r
dbClearResult(res)
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

```r
dbDisconnect(con)
sp_docker_stop("sql-pet")
```


## Other resources

  * Benjamin S. Baumer, A Grammar for Reproducible and Painless Extract-Transform-Load Operations on Medium Data: [https://arxiv.org/pdf/1708.07073](https://arxiv.org/pdf/1708.07073) 

