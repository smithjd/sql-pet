# Lazy Evaluation and Lazy Queries {#chapter_lazy-evaluation-queries}

> This chapter:
> 
> * Reviews lazy evaluation and discusses its interaction with remote query execution on a dbms 
> * Demonstrates how `dplyr` queries behave in connection with several different functions
> * Offers some further resources on lazy loading, evaluation, execution, etc.

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
  seconds_to_test = 30
)
```

## R is lazy and comes with guardrails

By design, R is both a language and an interactive development environment (IDE).  As a language, R tries to be as efficient as possible.  As an IDE, R creates some guardrails to make it easy and safe to work with your data. For example `getOption("max.print")` prevents R from printing more rows of data than you want to handle in an interactive session, with a default of 99999 lines, which may or may not suit you.

On the other hand SQL is a *"Structured Query Language (SQL): a standard computer language for relational database management and data manipulation."* ^[https://www.techopedia.com/definition/1245/structured-query-language-sql]. SQL has various database-specific Interactive Development Environments (IDEs), such as [pgAdmin](https://www.pgadmin.org/) for PostgreSQL.  Roger Peng explains in [R Programming for Data Science](https://bookdown.org/rdpeng/rprogdatascience/history-and-overview-of-r.html#basic-features-of-r) that:

> R has maintained the original S philosophy, which is that it provides a language that is both useful for interactive work, but contains a powerful programming language for developing new tools. 

This is complicated when R interacts with SQL.  In a [vignette for dbplyr](https://cran.r-project.org/web/packages/dbplyr/vignettes/dbplyr.html) Hadley Wickham explains:

> The most important difference between ordinary data frames and remote database queries is that your R code is translated into SQL and executed in the database on the remote server, not in R on your local machine. When working with databases, dplyr tries to be as lazy as possible:
> 
> * It never pulls data into R unless you explicitly ask for it.
> 
> * It delays doing any work until the last possible moment: it collects together everything you want to do and then sends it to the database in one step.
> 

Exactly when, which, and how much data is returned from the dbms is the topic of this chapter.  Exactly how the data is represented in the dbms and then translated to a data frame is discussed in the [DBI specification](https://cran.r-project.org/web/packages/DBI/vignettes/spec.html#_fetch_records_from_a_previously_executed_query_).

Eventually, if you are interacting with a dbms from R you will need to understand the differences between lazy loading, lazy evaluation, and lazy queries.

### Lazy loading

"*Lazy loading is always used for code in packages but is optional (selected by the package maintainer) for datasets in packages.*"^[https://cran.r-project.org/doc/manuals/r-release/R-ints.html#Lazy-loading]  Lazy loading means that the code for a particular function doesn't actually get loaded into memory until the last minute -- when it's actually being used.

### Lazy evaluation 

Essentially "Lazy evaluation is a programming strategy that allows a symbol to be evaluated only when needed." ^[https://colinfay.me/lazyeval/]  That means that lazy evaluation is about **symbols** such as function arguments ^[http://adv-r.had.co.nz/Functions.html#function-arguments] when they are evaluated. Tidy evaluation complicates lazy evaluation. ^[https://colinfay.me/tidyeval-1/]

### Lazy Queries

"*When you create a "lazy" query, you're creating a pointer to a set of conditions on the database, but the query isn't actually run and the data isn't actually loaded until you call "next" or some similar method to actually fetch the data and load it into an object.*" ^[https://www.quora.com/What-is-a-lazy-query]

## Lazy evaluation and lazy queries

### `dplyr` connection objects
As introduced in the previous chapter, the `dplyr::tbl` function creates an object that might **look** like a data frame in that when you enter it on the command line, it prints a bunch of rows from the dbms table.  But it is actually a **list** object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  

The following code illustrates these issues.  The `dplyr::tbl` function creates the connection object that we store in an object named `rental_table`:

```r
rental_table <- dplyr::tbl(con, "rental")
```

At first glance, it _acts_ like a data frame when you print it, although it only prints 10 of the table's 16,044 rows:

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
## # … with more rows, and 3 more variables: return_date <dttm>,
## #   staff_id <int>, last_update <dttm>
```

However, notice that the first output line shows `??`, rather than providing the number of rows in the table. Similarly, the next to last line shows:
```
    ... with more rows, and 3 more variables
```
whereas the output for a normal `tbl` of this rental data would say:
```
    ... with 16,034 more rows, and 3 more variables
```

So even though `rental_table` is a `tbl`:

```r
class(rental_table)
```

```
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"         
## [4] "tbl_lazy"         "tbl"
```

It is not just a normal `tbl` of data. We can see that from the structure of `rental_table`:

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
##   ..- attr(*, "class")= chr [1:4] "src_PqConnection" "src_dbi" "src_sql" "src"
##  $ ops:List of 2
##   ..$ x   : 'ident' chr "rental"
##   ..$ vars: chr [1:7] "rental_id" "rental_date" "inventory_id" "customer_id" ...
##   ..- attr(*, "class")= chr [1:3] "op_base_remote" "op_base" "op"
##  - attr(*, "class")= chr [1:5] "tbl_PqConnection" "tbl_dbi" "tbl_sql" "tbl_lazy" ...
```

It has only _two_ rows!  The first row contains all the information in the `con` object, which contains information about all the tables and objects in the database:

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
`rental_table` holds information needed to get the data from the 'rental' table, but `rental_table` does not hold the data itself. In the following sections, we will examine more closely this relationship between the `rental_table` object and the data in the database's 'rental' table.

## When does a lazy query trigger data retrieval?

### Create a black box query for experimentation

To illustrate the different issues involved in data retrieval, we create more connection objects to link to two other tables.  

```r
staff_table <- dplyr::tbl(con, "staff") 
```
The 'staff' table has 2 rows.


```r
customer_table <- dplyr::tbl(con, "customer") 
```
The 'customer' table has 599 rows.

Here is a typical string of `dplyr` verbs strung together with the magrittr `%>%` pipe command that will be used to tease out the several different behaviors that a lazy query has when passed to different R functions.  This query joins three connection objects into a query we'll call `Q`:


```r
Q <- rental_table %>%
  dplyr::left_join(staff_table, by = c("staff_id" = "staff_id")) %>%
  dplyr::rename(staff_email = email) %>%
  dplyr::left_join(customer_table, by = c("customer_id" = "customer_id")) %>%
  dplyr::rename(customer_email = email) %>%
  dplyr::select(rental_date, staff_email, customer_email)
```

### Experiment overview
Think of `Q` as a black box for the moment.  The following examples will show how `Q` is interpreted differently by different functions. 

**Notation**

* ![](screenshots/green-check.png): A single green check indicates that some rows are returned.
* ![](screenshots/green-check.png) ![](screenshots/green-check.png): Two green checks indicate that all the rows are returned.
* ![](screenshots/red-x.png): The red X indicates that no rows are returned.

> R code | Result 
> -------| --------------
> [`Q %>% print()`](#lazy_q_print) | ![](screenshots/green-check.png) Prints x rows; same as just entering `Q`  
> [`Q %>% dplyr::as_tibble()`](#Q-as-tibble) | ![](screenshots/green-check.png)![](screenshots/green-check.png) Forces `Q` to be a tibble
> [`Q %>% head()`](#lazy_q_head) | ![](screenshots/green-check.png) Prints the first 6 rows 
> [`Q %>% tail()`](#lazy_q_tail) | ![](screenshots/red-x.png) Error: tail() is not supported by sql sources 
> [`Q %>% length()`](#lazy_q_length) |  ![](screenshots/red-x.png) Counts the rows in `Q`
> [`Q %>% str()`](#lazy_q_str) |  ![](screenshots/red-x.png)Shows the top 3 levels of the **object** `Q` 
> [`Q %>% nrow()`](#lazy_q_nrow) | ![](screenshots/red-x.png) **Attempts** to determine the number of rows 
> [`Q %>% dplyr::tally()`](#lazy_q_tally) | ![](screenshots/green-check.png) ![](screenshots/green-check.png) Counts all the rows -- on the dbms side
> [`Q %>% dplyr::collect(n = 20)`](#lazy_q_collect) | ![](screenshots/green-check.png) Prints 20 rows  
> [`Q %>% dplyr::collect(n = 20) %>% head()`](#lazy_q_collect) | ![](screenshots/green-check.png) Prints 6 rows  
> [`Q %>% dplyr::show_query()`](#lazy-q-show-query) | ![](screenshots/red-x.png) **Translates** the lazy query object into SQL  
> [`Qc <- Q %>% dplyr::count(customer_email, sort = TRUE)` <br /> `Qc`](#lazy_q_build) | ![](screenshots/red-x.png) **Extends** the lazy query object
>
> 

The next chapter will discuss how to build queries and how to explore intermediate steps. But first, the following subsections provide a more detailed discussion of each row in the preceding table.

### Q %>% print(){#lazy_q_print}

Remember that `Q %>% print()` is equivalent to `print(Q)` and the same as just entering `Q` on the command line.  We use the magrittr pipe operator here, because chaining functions highlights how the same object behaves differently in each use.

```r
Q %>% print()
```

```
## # Source:   lazy query [?? x 3]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    rental_date         staff_email             customer_email              
##    <dttm>              <chr>                   <chr>                       
##  1 2005-05-24 22:54:33 Mike.Hillyer@sakilasta… tommy.collazo@sakilacustome…
##  2 2005-05-24 23:03:39 Mike.Hillyer@sakilasta… manuel.murrell@sakilacustom…
##  3 2005-05-24 23:04:41 Jon.Stephens@sakilasta… andrew.purdy@sakilacustomer…
##  4 2005-05-24 23:05:21 Mike.Hillyer@sakilasta… delores.hansen@sakilacustom…
##  5 2005-05-24 23:08:07 Mike.Hillyer@sakilasta… nelson.christenson@sakilacu…
##  6 2005-05-24 23:11:53 Jon.Stephens@sakilasta… cassandra.walters@sakilacus…
##  7 2005-05-24 23:31:46 Jon.Stephens@sakilasta… minnie.romero@sakilacustome…
##  8 2005-05-25 00:00:40 Mike.Hillyer@sakilasta… ellen.simpson@sakilacustome…
##  9 2005-05-25 00:02:21 Jon.Stephens@sakilasta… danny.isom@sakilacustomer.o…
## 10 2005-05-25 00:09:02 Jon.Stephens@sakilasta… april.burns@sakilacustomer.…
## # … with more rows
```
![](screenshots/green-check.png) R retrieves 10 observations and 3 columns.  In its role as IDE, R has provided nicely formatted output that is similar to what it prints for a tibble, with descriptive information about the dataset and each column:

>
> \# Source:   lazy query [?? x 3] </br >
> \# Database: postgres [postgres@localhost:5432/dvdrental] </br >
>   rental_date         staff_email                  customer_email 
>   \<dttm\>              \<chr\>                        \<chr\>
>

R has not determined how many rows are left to retrieve as it shows with `[?? x 3]` and `... with more rows` in the data summary. 

### Q %>% dplyr::as_tibble() {#lazy_q_as-tibble}

![](screenshots/green-check.png) ![](screenshots/green-check.png) In contrast to `print()`, the `as_tibble()` function causes R to download the whole table, using tibble's default of displaying only the first 10 rows.

```r
Q %>% dplyr::as_tibble()
```

```
## # A tibble: 16,044 x 3
##    rental_date         staff_email             customer_email              
##    <dttm>              <chr>                   <chr>                       
##  1 2005-05-24 22:54:33 Mike.Hillyer@sakilasta… tommy.collazo@sakilacustome…
##  2 2005-05-24 23:03:39 Mike.Hillyer@sakilasta… manuel.murrell@sakilacustom…
##  3 2005-05-24 23:04:41 Jon.Stephens@sakilasta… andrew.purdy@sakilacustomer…
##  4 2005-05-24 23:05:21 Mike.Hillyer@sakilasta… delores.hansen@sakilacustom…
##  5 2005-05-24 23:08:07 Mike.Hillyer@sakilasta… nelson.christenson@sakilacu…
##  6 2005-05-24 23:11:53 Jon.Stephens@sakilasta… cassandra.walters@sakilacus…
##  7 2005-05-24 23:31:46 Jon.Stephens@sakilasta… minnie.romero@sakilacustome…
##  8 2005-05-25 00:00:40 Mike.Hillyer@sakilasta… ellen.simpson@sakilacustome…
##  9 2005-05-25 00:02:21 Jon.Stephens@sakilasta… danny.isom@sakilacustomer.o…
## 10 2005-05-25 00:09:02 Jon.Stephens@sakilasta… april.burns@sakilacustomer.…
## # … with 16,034 more rows
```

### Q %>% head() {#lazy_q_head}

![](screenshots/green-check.png) The `head()` function is very similar to print but has a different "`max.print`" value.

```r
Q %>% head()
```

```
## # Source:   lazy query [?? x 3]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   rental_date         staff_email             customer_email               
##   <dttm>              <chr>                   <chr>                        
## 1 2005-05-24 22:54:33 Mike.Hillyer@sakilasta… tommy.collazo@sakilacustomer…
## 2 2005-05-24 23:03:39 Mike.Hillyer@sakilasta… manuel.murrell@sakilacustome…
## 3 2005-05-24 23:04:41 Jon.Stephens@sakilasta… andrew.purdy@sakilacustomer.…
## 4 2005-05-24 23:05:21 Mike.Hillyer@sakilasta… delores.hansen@sakilacustome…
## 5 2005-05-24 23:08:07 Mike.Hillyer@sakilasta… nelson.christenson@sakilacus…
## 6 2005-05-24 23:11:53 Jon.Stephens@sakilasta… cassandra.walters@sakilacust…
```

### Q %>% tail() {#lazy_q_tail}

![](screenshots/red-x.png) Produces an error, because `Q` does not hold all of the data, so it is not possible to list the last few items from the table:

```r
try(
  Q %>% tail(),
  silent = FALSE,
  outFile = stdout()
)
```

```
## Error : tail() is not supported by sql sources
```

### Q %>% length() {#lazy_q_length}

![](screenshots/red-x.png) Because the `Q` object is relatively complex, using `str()` on it prints many lines.  You can glimpse what's going on with `length()`:

```r
Q %>% length()
```

```
## [1] 2
```

### Q %>% str() {#lazy_q_str}

![](screenshots/red-x.png) Looking inside shows some of what's going on (three levels deep):

```r
Q %>% str(max.level = 3) 
```

```
## List of 2
##  $ src:List of 2
##   ..$ con  :Formal class 'PqConnection' [package "RPostgres"] with 3 slots
##   ..$ disco: NULL
##   ..- attr(*, "class")= chr [1:4] "src_PqConnection" "src_dbi" "src_sql" "src"
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
##   .. .. ..- attr(*, ".Environment")=<environment: 0x7f92a81b6328> 
##   .. ..$ : language ~staff_email
##   .. .. ..- attr(*, ".Environment")=<environment: 0x7f92a81b6328> 
##   .. ..$ : language ~customer_email
##   .. .. ..- attr(*, ".Environment")=<environment: 0x7f92a81b6328> 
##   .. ..- attr(*, "class")= chr "quosures"
##   ..$ args: list()
##   ..- attr(*, "class")= chr [1:3] "op_select" "op_single" "op"
##  - attr(*, "class")= chr [1:5] "tbl_PqConnection" "tbl_dbi" "tbl_sql" "tbl_lazy" ...
```

### Q %>% nrow() {#lazy_q_nrow}

![](screenshots/red-x.png) Notice the difference between `nrow()` and `tally()`. The `nrow` functions returns `NA` and does not execute a query:

```r
Q %>% nrow()
```

```
## [1] NA
```

### Q %>% dplyr::tally() {#lazy_q_tally}

![](screenshots/green-check.png) The `tally` function actually counts all the rows.

```r
Q %>% dplyr::tally()
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   n              
##   <S3: integer64>
## 1 16044
```
The `nrow()` function knows that `Q` is a list.  On the other hand, the `tally()` function tells SQL to go count all the rows. Notice that `Q` results in 16,044 rows -- the same number of rows as `rental`.

### Q %>% dplyr::collect(){#lazy_q_collect}

![](screenshots/green-check.png) The dplyr::[collect](https://dplyr.tidyverse.org/reference/compute.html) function triggers a call to the `DBI:dbFetch()` function behind the scenes, which forces R to download a specified number of rows:

```r
Q %>% dplyr::collect(n = 20)
```

```
## # A tibble: 20 x 3
##    rental_date         staff_email             customer_email              
##    <dttm>              <chr>                   <chr>                       
##  1 2005-05-24 22:54:33 Mike.Hillyer@sakilasta… tommy.collazo@sakilacustome…
##  2 2005-05-24 23:03:39 Mike.Hillyer@sakilasta… manuel.murrell@sakilacustom…
##  3 2005-05-24 23:04:41 Jon.Stephens@sakilasta… andrew.purdy@sakilacustomer…
##  4 2005-05-24 23:05:21 Mike.Hillyer@sakilasta… delores.hansen@sakilacustom…
##  5 2005-05-24 23:08:07 Mike.Hillyer@sakilasta… nelson.christenson@sakilacu…
##  6 2005-05-24 23:11:53 Jon.Stephens@sakilasta… cassandra.walters@sakilacus…
##  7 2005-05-24 23:31:46 Jon.Stephens@sakilasta… minnie.romero@sakilacustome…
##  8 2005-05-25 00:00:40 Mike.Hillyer@sakilasta… ellen.simpson@sakilacustome…
##  9 2005-05-25 00:02:21 Jon.Stephens@sakilasta… danny.isom@sakilacustomer.o…
## 10 2005-05-25 00:09:02 Jon.Stephens@sakilasta… april.burns@sakilacustomer.…
## 11 2005-05-25 00:19:27 Jon.Stephens@sakilasta… deanna.byrd@sakilacustomer.…
## 12 2005-05-25 00:22:55 Mike.Hillyer@sakilasta… raymond.mcwhorter@sakilacus…
## 13 2005-05-25 00:31:15 Mike.Hillyer@sakilasta… theodore.culp@sakilacustome…
## 14 2005-05-25 00:39:22 Mike.Hillyer@sakilasta… ronald.weiner@sakilacustome…
## 15 2005-05-25 00:43:11 Jon.Stephens@sakilasta… steven.curley@sakilacustome…
## 16 2005-05-25 01:06:36 Mike.Hillyer@sakilasta… isaac.oglesby@sakilacustome…
## 17 2005-05-25 01:10:47 Jon.Stephens@sakilasta… ruth.martinez@sakilacustome…
## 18 2005-05-25 01:17:24 Mike.Hillyer@sakilasta… ronnie.ricketts@sakilacusto…
## 19 2005-05-25 01:48:41 Jon.Stephens@sakilasta… roberta.harper@sakilacustom…
## 20 2005-05-25 01:59:46 Jon.Stephens@sakilasta… craig.morrell@sakilacustome…
```

```r
Q %>% dplyr::collect(n = 20) %>% head()
```

```
## # A tibble: 6 x 3
##   rental_date         staff_email             customer_email               
##   <dttm>              <chr>                   <chr>                        
## 1 2005-05-24 22:54:33 Mike.Hillyer@sakilasta… tommy.collazo@sakilacustomer…
## 2 2005-05-24 23:03:39 Mike.Hillyer@sakilasta… manuel.murrell@sakilacustome…
## 3 2005-05-24 23:04:41 Jon.Stephens@sakilasta… andrew.purdy@sakilacustomer.…
## 4 2005-05-24 23:05:21 Mike.Hillyer@sakilasta… delores.hansen@sakilacustome…
## 5 2005-05-24 23:08:07 Mike.Hillyer@sakilasta… nelson.christenson@sakilacus…
## 6 2005-05-24 23:11:53 Jon.Stephens@sakilasta… cassandra.walters@sakilacust…
```
The `dplyr::collect` function triggers the creation of a tibble and controls the number of rows that the DBMS sends to R.  Notice that `head` only prints 6 of the 20 rows that R has retrieved.

If you do not provide a value for the `n` argument, _all_ of the rows will be retrieved into your R workspace.

### Q %>% dplyr::show_query() {#lazy_q_show-query}


```r
Q %>% dplyr::show_query()
```

```
## <SQL>
## SELECT "rental_date", "staff_email", "customer_email"
## FROM (SELECT "rental_id", "rental_date", "inventory_id", "customer_id", "return_date", "staff_id", "last_update.x", "first_name.x", "last_name.x", "address_id.x", "staff_email", "store_id.x", "active.x", "username", "password", "last_update.y", "picture", "store_id.y", "first_name.y", "last_name.y", "email" AS "customer_email", "address_id.y", "activebool", "create_date", "last_update", "active.y"
## FROM (SELECT "TBL_LEFT"."rental_id" AS "rental_id", "TBL_LEFT"."rental_date" AS "rental_date", "TBL_LEFT"."inventory_id" AS "inventory_id", "TBL_LEFT"."customer_id" AS "customer_id", "TBL_LEFT"."return_date" AS "return_date", "TBL_LEFT"."staff_id" AS "staff_id", "TBL_LEFT"."last_update.x" AS "last_update.x", "TBL_LEFT"."first_name" AS "first_name.x", "TBL_LEFT"."last_name" AS "last_name.x", "TBL_LEFT"."address_id" AS "address_id.x", "TBL_LEFT"."staff_email" AS "staff_email", "TBL_LEFT"."store_id" AS "store_id.x", "TBL_LEFT"."active" AS "active.x", "TBL_LEFT"."username" AS "username", "TBL_LEFT"."password" AS "password", "TBL_LEFT"."last_update.y" AS "last_update.y", "TBL_LEFT"."picture" AS "picture", "TBL_RIGHT"."store_id" AS "store_id.y", "TBL_RIGHT"."first_name" AS "first_name.y", "TBL_RIGHT"."last_name" AS "last_name.y", "TBL_RIGHT"."email" AS "email", "TBL_RIGHT"."address_id" AS "address_id.y", "TBL_RIGHT"."activebool" AS "activebool", "TBL_RIGHT"."create_date" AS "create_date", "TBL_RIGHT"."last_update" AS "last_update", "TBL_RIGHT"."active" AS "active.y"
##   FROM (SELECT "rental_id", "rental_date", "inventory_id", "customer_id", "return_date", "staff_id", "last_update.x", "first_name", "last_name", "address_id", "email" AS "staff_email", "store_id", "active", "username", "password", "last_update.y", "picture"
## FROM (SELECT "TBL_LEFT"."rental_id" AS "rental_id", "TBL_LEFT"."rental_date" AS "rental_date", "TBL_LEFT"."inventory_id" AS "inventory_id", "TBL_LEFT"."customer_id" AS "customer_id", "TBL_LEFT"."return_date" AS "return_date", "TBL_LEFT"."staff_id" AS "staff_id", "TBL_LEFT"."last_update" AS "last_update.x", "TBL_RIGHT"."first_name" AS "first_name", "TBL_RIGHT"."last_name" AS "last_name", "TBL_RIGHT"."address_id" AS "address_id", "TBL_RIGHT"."email" AS "email", "TBL_RIGHT"."store_id" AS "store_id", "TBL_RIGHT"."active" AS "active", "TBL_RIGHT"."username" AS "username", "TBL_RIGHT"."password" AS "password", "TBL_RIGHT"."last_update" AS "last_update.y", "TBL_RIGHT"."picture" AS "picture"
##   FROM "rental" AS "TBL_LEFT"
##   LEFT JOIN "staff" AS "TBL_RIGHT"
##   ON ("TBL_LEFT"."staff_id" = "TBL_RIGHT"."staff_id")
## ) "hitrczxkos") "TBL_LEFT"
##   LEFT JOIN "customer" AS "TBL_RIGHT"
##   ON ("TBL_LEFT"."customer_id" = "TBL_RIGHT"."customer_id")
## ) "jefzfrcbts") "cnkarxlwbd"
```
Hand-written SQL code to do the same job will probably look a lot nicer and could be more efficient, but functionally `dplyr` does the job.

### Qc <- Q %>% dplyr::count(customer_email) {#lazy_q_build}

![](screenshots/red-x.png) Until `Q` is executed, we can add to it.  This behavior is the basis for a useful debugging and development process where queries are built up incrementally.

```r
Qc <- Q %>% dplyr::count(customer_email, sort = TRUE)
```

![](screenshots/green-check.png) When all the accumulated `dplyr` verbs are executed, they are submitted to the dbms and the number of rows that are returned follow the same rules as discussed above.

```r
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
##  8 marion.snyder@sakilacustomer.org  39             
##  9 rhonda.kennedy@sakilacustomer.org 39             
## 10 tim.cary@sakilacustomer.org       39             
## # … with more rows
```

See more examples of lazy execution [here](https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html).


```r
DBI::dbDisconnect(con)
sqlpetr::sp_docker_stop("sql-pet")
```


## Other resources

* Benjamin S. Baumer. 2017. A Grammar for Reproducible and Painless Extract-Transform-Load Operations on Medium Data. [https://arxiv.org/abs/1708.07073](https://arxiv.org/abs/1708.07073) 
* dplyr Reference documentation: Remote tables. [https://dplyr.tidyverse.org/reference/index.html#section-remote-tables](https://dplyr.tidyverse.org/reference/index.html#section-remote-tables)
* Data Carpentry. SQL Databases and R. [https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html](https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html)
