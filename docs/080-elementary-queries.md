# Introduction to DBMS queries {#chapter_dbms-queries-intro}

> This chapter demonstrates how to:
> 
> * Get a glimpse of what tables are in the database and what fields a table contains
> * Download all or part of a table from the dbms
> * See how `dplyr` code is translated into `SQL` commands
> * Get acquainted with some useful tools for investigating a single table
> * Begin thinking about how to divide the work between your local R session and the dbms

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
Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go. If not go back to [Chapter 7][Build the pet-sql Docker Image]

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

## Getting data from the database

As we show later on, the database serves as a store of data and as an engine for sub-setting, joining, and computation on the data.  We begin with getting data from the dbms, or "downloading" data.

### Finding out what's there

We've already seen the simplest way of getting a list of tables in a database with `DBI` functions that list tables and fields.  Generate a vector listing the (public) tables in the database:

```r
tables <- DBI::dbListTables(con)
tables
```

```
##  [1] "actor_info"                 "customer_list"             
##  [3] "film_list"                  "nicer_but_slower_film_list"
##  [5] "sales_by_film_category"     "staff"                     
##  [7] "sales_by_store"             "staff_list"                
##  [9] "category"                   "film_category"             
## [11] "country"                    "actor"                     
## [13] "language"                   "inventory"                 
## [15] "payment"                    "rental"                    
## [17] "city"                       "store"                     
## [19] "film"                       "address"                   
## [21] "film_actor"                 "customer"
```
Print a vector with all the fields (or columns or variables) in one specific table:

```r
DBI::dbListFields(con, "rental")
```

```
## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
## [5] "return_date"  "staff_id"     "last_update"
```

### Listing all the fields for all the tables

The first example, `DBI::dbListTables(con)` returned 22 tables and the second example, `DBI::dbListFields(con, "rental")` returns 7 fields.  Here we combine the two calls to return a list of tables which has a list of all the fields in the table.  The code block just shows the first two tables.


```r
table_columns <- lapply(tables, dbListFields, conn = con)
```

Or, using purr:

```r
table_columns <- purrr::map(tables, ~ dbListFields(.,conn = con) )
```
Rename each list [[1]] ... [[22]] to meaningful table name

```r
names(table_columns) <- tables

head(table_columns)
```

```
## $actor_info
## [1] "actor_id"   "first_name" "last_name"  "film_info" 
## 
## $customer_list
## [1] "id"       "name"     "address"  "zip code" "phone"    "city"    
## [7] "country"  "notes"    "sid"     
## 
## $film_list
## [1] "fid"         "title"       "description" "category"    "price"      
## [6] "length"      "rating"      "actors"     
## 
## $nicer_but_slower_film_list
## [1] "fid"         "title"       "description" "category"    "price"      
## [6] "length"      "rating"      "actors"     
## 
## $sales_by_film_category
## [1] "category"    "total_sales"
## 
## $staff
##  [1] "staff_id"    "first_name"  "last_name"   "address_id"  "email"      
##  [6] "store_id"    "active"      "username"    "password"    "last_update"
## [11] "picture"
```

Later on we'll discuss how to get more extensive data about each table and column from the database's own store of metadata using a similar technique.  As we go further the issue of scale will come up again and again: you need to be careful about how much data a call to the dbms will return, whether it's a list of tables or a table that could have millions of rows.

It's important to connect with people who own, generate, or are the subjects of the data.  A good chat with people who own the data, generate it, or are the subjects can generate insights and set the context for your investigation of the database. The purpose for collecting the data or circumstances where it was collected may be buried far afield in an organization, but *usually someone knows*.  The metadata discussed in a later chapter is essential but will only take you so far.

There are different ways of just **looking at the data**, which we explore below.

### Downloading an entire table

There are many different methods of getting data from a DBMS, and we'll explore the different ways of controlling each one of them.

`DBI::dbReadTable` will download an entire table into an R [tibble](https://tibble.tidyverse.org/).  

```r
rental_tibble <- DBI::dbReadTable(con, "rental")
str(rental_tibble)
```

```
## 'data.frame':	16044 obs. of  7 variables:
##  $ rental_id   : int  2 3 4 5 6 7 8 9 10 11 ...
##  $ rental_date : POSIXct, format: "2005-05-24 22:54:33" "2005-05-24 23:03:39" ...
##  $ inventory_id: int  1525 1711 2452 2079 2792 3995 2346 2580 1824 4443 ...
##  $ customer_id : int  459 408 333 222 549 269 239 126 399 142 ...
##  $ return_date : POSIXct, format: "2005-05-28 19:40:33" "2005-06-01 22:12:39" ...
##  $ staff_id    : int  1 1 2 1 1 2 2 1 2 2 ...
##  $ last_update : POSIXct, format: "2006-02-16 02:30:53" "2006-02-16 02:30:53" ...
```
That's very simple, but if the table is large it may not be a good idea, since R is designed to keep the entire table in memory.  Note that the first line of the str() output reports the total number of observations.  

### A table object that can be reused

The `dplyr::tbl` function gives us more control over access to a table by enabling  control over which columns and rows to download.  It creates  an object that might **look** like a data frame, but it's actually a list object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  


```r
rental_table <- dplyr::tbl(con, "rental")
class(rental_table)
```

```
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"         
## [4] "tbl_lazy"         "tbl"
```


### Controlling the number of rows returned

The `collect` function triggers the creation of a tibble and controls the number of rows that the DBMS sends to R.  

```r
rental_table %>% dplyr::collect(n = 3) %>% dim
```

```
## [1] 3 7
```

```r
rental_table %>% dplyr::collect(n = 500) %>% dim
```

```
## [1] 500   7
```

### Random rows from the dbms

When the dbms contains many rows, a sample of the data may be plenty for your purposes.  Although `dplyr` has nice functions to sample a data frame that's already in R (e.g., the `sample_n` and `sample_frac` functions), to get a sample from the dbms we have to use `dbGetQuery` to send native SQL to the database. To peek ahead, here is one example of a query that retrieves 20 rows from a 1% sample:


```r
one_percent_sample <- DBI::dbGetQuery(
  con,
  "SELECT rental_id, rental_date, inventory_id, customer_id FROM rental TABLESAMPLE BERNOULLI(1) LIMIT 20;
  "
)

one_percent_sample
```

```
##    rental_id         rental_date inventory_id customer_id
## 1          9 2005-05-25 00:00:40         2580         126
## 2         43 2005-05-25 05:39:25         2578         532
## 3        138 2005-05-25 22:48:22         4134         586
## 4        157 2005-05-26 01:25:21          887         344
## 5        168 2005-05-26 03:07:43         2714         469
## 6        207 2005-05-26 08:04:38          102          47
## 7        222 2005-05-26 10:14:38         2745          83
## 8        292 2005-05-26 20:22:12         4264         515
## 9        544 2005-05-28 07:03:00         2964         311
## 10       614 2005-05-28 15:33:28          280         307
## 11       737 2005-05-29 08:11:31          769         589
## 12       779 2005-05-29 14:17:17          533         105
## 13       808 2005-05-29 19:08:20         1928         104
## 14      1085 2005-05-31 11:15:43          301           5
## 15      1150 2005-05-31 21:20:09         1632         136
## 16      1348 2005-06-15 12:45:30         2078         196
## 17      1382 2005-06-15 15:18:08         3133         455
## 18      1448 2005-06-15 19:17:16         2781         246
## 19      1509 2005-06-15 22:35:53          655         167
## 20      1636 2005-06-16 08:28:54         2052         574
```
**Exact sample of 100 records**

This technique depends on knowing the range of a record index, such as the `rental_id` in the `rental` table of our `dvdrental` database.

Start by finding the min and max values.

```r
DBI::dbListFields(con, "rental")
```

```
## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
## [5] "return_date"  "staff_id"     "last_update"
```

```r
rental_df <- DBI::dbReadTable(con, "rental")

max(rental_df$rental_id)
```

```
## [1] 16049
```

```r
min(rental_df$rental_id)
```

```
## [1] 1
```

Set the random number seed and draw the sample.

```r
set.seed(123)
sample_rows <- sample(1:16049, 100)
rental_table <- dplyr::tbl(con, "rental")
```

Run query with the filter verb listing the randomly sampled rows to be retrieved:

```r
rental_sample <- rental_table %>% 
  dplyr::filter(rental_id %in% sample_rows) %>% 
  dplyr::collect()

str(rental_sample)
```

```
## Classes 'tbl_df', 'tbl' and 'data.frame':	100 obs. of  7 variables:
##  $ rental_id   : int  10 395 675 731 734 1494 1517 1643 1651 1775 ...
##  $ rental_date : POSIXct, format: "2005-05-25 00:02:21" "2005-05-27 11:45:49" ...
##  $ inventory_id: int  1824 752 1273 4124 3084 244 3728 1352 4444 1922 ...
##  $ customer_id : int  399 575 338 5 538 575 148 484 524 123 ...
##  $ return_date : POSIXct, format: "2005-05-31 22:44:21" "2005-05-31 13:42:49" ...
##  $ staff_id    : int  2 1 2 1 2 1 1 2 2 2 ...
##  $ last_update : POSIXct, format: "2006-02-16 02:30:53" "2006-02-16 02:30:53" ...
```


### Sub-setting variables

A table in the dbms may not only have many more rows than you want, but also many more columns.  The `select` command controls which columns are retrieved.

```r
rental_table %>% dplyr::select(rental_date, return_date) %>% head()
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   rental_date         return_date        
##   <dttm>              <dttm>             
## 1 2005-05-24 22:54:33 2005-05-28 19:40:33
## 2 2005-05-24 23:03:39 2005-06-01 22:12:39
## 3 2005-05-24 23:04:41 2005-06-03 01:43:41
## 4 2005-05-24 23:05:21 2005-06-02 04:33:21
## 5 2005-05-24 23:08:07 2005-05-27 01:32:07
## 6 2005-05-24 23:11:53 2005-05-29 20:34:53
```
That's exactly equivalent to submitting the following SQL commands dirctly:

```r
DBI::dbGetQuery(
  con,
  'SELECT "rental_date", "return_date"
FROM "rental"
LIMIT 6') 
```

```
##           rental_date         return_date
## 1 2005-05-24 22:54:33 2005-05-28 19:40:33
## 2 2005-05-24 23:03:39 2005-06-01 22:12:39
## 3 2005-05-24 23:04:41 2005-06-03 01:43:41
## 4 2005-05-24 23:05:21 2005-06-02 04:33:21
## 5 2005-05-24 23:08:07 2005-05-27 01:32:07
## 6 2005-05-24 23:11:53 2005-05-29 20:34:53
```


We won't discuss `dplyr` methods for sub-setting variables, deriving new ones, or sub-setting rows based on the values found in the table, because they are covered well in other places, including:

  * Comprehensive reference: [https://dplyr.tidyverse.org/](https://dplyr.tidyverse.org/)
  * Good tutorial: [https://suzan.rbind.io/tags/dplyr/](https://suzan.rbind.io/tags/dplyr/) 

In practice we find that, **renaming variables** is often quite important because the names in an SQL database might not meet your needs as an analyst.  In "the wild", you will find names that are ambiguous or overly specified, with spaces in them, and other problems that will make them difficult to use in R.  It is good practice to do whatever renaming you are going to do in a predictable place like at the top of your code.  The names in the `dvdrental` database are simple and clear, but if they were not, you might rename them for subsequent use in this way:


```r
tbl(con, "rental") %>%
  dplyr::rename(rental_id_number = rental_id, inventory_id_number = inventory_id) %>% 
  dplyr::select(rental_id_number, rental_date, inventory_id_number) %>%
  head()
```

```
## # Source:   lazy query [?? x 3]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   rental_id_number rental_date         inventory_id_number
##              <int> <dttm>                            <int>
## 1                2 2005-05-24 22:54:33                1525
## 2                3 2005-05-24 23:03:39                1711
## 3                4 2005-05-24 23:04:41                2452
## 4                5 2005-05-24 23:05:21                2079
## 5                6 2005-05-24 23:08:07                2792
## 6                7 2005-05-24 23:11:53                3995
```
That's equivalent to the following SQL code:

```r
DBI::dbGetQuery(
  con,
  'SELECT "rental_id_number", "rental_date", "inventory_id_number"
FROM (SELECT "rental_id" AS "rental_id_number", "rental_date", "inventory_id" AS "inventory_id_number", "customer_id", "return_date", "staff_id", "last_update"
FROM "rental") "ihebfvnxvb"
LIMIT 6' )
```

```
##   rental_id_number         rental_date inventory_id_number
## 1                2 2005-05-24 22:54:33                1525
## 2                3 2005-05-24 23:03:39                1711
## 3                4 2005-05-24 23:04:41                2452
## 4                5 2005-05-24 23:05:21                2079
## 5                6 2005-05-24 23:08:07                2792
## 6                7 2005-05-24 23:11:53                3995
```
The one difference is that the `SQL` code returns a regular data frame and the `dplyr` code returns a `tibble`.  Notice that the seconds are greyed out in the `tibble` display.

### Translating `dplyr` code to `SQL` queries

Where did the translations we've shown above come from?  The `show_query` function shows how `dplyr` is translating your query to the dialect of the target dbms:

```r
rental_table %>%
  dplyr::count(staff_id) %>%
  dplyr::show_query()
```

```
## <SQL>
## SELECT "staff_id", COUNT(*) AS "n"
## FROM "rental"
## GROUP BY "staff_id"
```
Here is an extensive discussion of how `dplyr` code is translated into SQL:

* [https://dbplyr.tidyverse.org/articles/sql-translation.html](https://dbplyr.tidyverse.org/articles/sql-translation.html) 

If you prefer to use SQL directly, rather than `dplyr`, you can submit SQL code to the DBMS through the `DBI::dbGetQuery` function:

```r
DBI::dbGetQuery(
  con,
  'SELECT "staff_id", COUNT(*) AS "n"
   FROM "rental"
   GROUP BY "staff_id";
  '
)
```

```
##   staff_id    n
## 1        2 8004
## 2        1 8040
```

When you create a report to run repeatedly, you might want to put that query into R markdown. That way you can also execute that SQL code in a chunk with the following header:

  {`sql, connection=con, output.var = "query_results"`}


```sql
SELECT "staff_id", COUNT(*) AS "n"
FROM "rental"
GROUP BY "staff_id";
```
Rmarkdown stores that query result in a tibble which can be printed by referring to it:

```r
query_results
```

```
##   staff_id    n
## 1        2 8004
## 2        1 8040
```

## Mixing dplyr and SQL

When dplyr finds code that it does not know how to translate into SQL, it will simply pass it along to the dbms. Therefore you can interleave native commands that your dbms will understand in the middle of dplyr code.  Consider this example that's derived from [@Ruiz2019]:


```r
rental_table %>%
  dplyr::select_at(vars( -contains("_id"))) %>% 
  dplyr::mutate(today = now()) %>%
  dplyr::show_query()
```

```
## <SQL>
## SELECT "rental_date", "return_date", "last_update", NOW() AS "today"
## FROM (SELECT "rental_date", "return_date", "last_update"
## FROM "rental") "yhbysdoypk"
```
That is native to PostgreSQL, not [ANSI standard](https://en.wikipedia.org/wiki/SQL#Interoperability_and_standardization) SQL.

Verify that it works:

```r
rental_table %>%
  dplyr::select_at(vars( -contains("_id"))) %>% 
  head() %>% 
  dplyr::mutate(today = now()) %>%
  dplyr::collect()
```

```
## # A tibble: 6 x 4
##   rental_date         return_date         last_update        
##   <dttm>              <dttm>              <dttm>             
## 1 2005-05-24 22:54:33 2005-05-28 19:40:33 2006-02-16 02:30:53
## 2 2005-05-24 23:03:39 2005-06-01 22:12:39 2006-02-16 02:30:53
## 3 2005-05-24 23:04:41 2005-06-03 01:43:41 2006-02-16 02:30:53
## 4 2005-05-24 23:05:21 2005-06-02 04:33:21 2006-02-16 02:30:53
## 5 2005-05-24 23:08:07 2005-05-27 01:32:07 2006-02-16 02:30:53
## 6 2005-05-24 23:11:53 2005-05-29 20:34:53 2006-02-16 02:30:53
## # … with 1 more variable: today <dttm>
```


## Examining a single table with R

Dealing with a large, complex database highlights the utility of specific tools in R.  We include brief examples that we find to be handy:

  + Base R structure: `str`
  + Printing out some of the data: `datatable`, `kable`, and `View`
  + Summary statistics: `summary`
  + `glimpse` in the `tibble` package, which is included in the `tidyverse`
  + `skim` in the `skimr` package

### `str` - a base package workhorse

`str` is a workhorse function that lists variables, their type and a sample of the first few variable values.

```r
str(rental_tibble)
```

```
## 'data.frame':	16044 obs. of  7 variables:
##  $ rental_id   : int  2 3 4 5 6 7 8 9 10 11 ...
##  $ rental_date : POSIXct, format: "2005-05-24 22:54:33" "2005-05-24 23:03:39" ...
##  $ inventory_id: int  1525 1711 2452 2079 2792 3995 2346 2580 1824 4443 ...
##  $ customer_id : int  459 408 333 222 549 269 239 126 399 142 ...
##  $ return_date : POSIXct, format: "2005-05-28 19:40:33" "2005-06-01 22:12:39" ...
##  $ staff_id    : int  1 1 2 1 1 2 2 1 2 2 ...
##  $ last_update : POSIXct, format: "2006-02-16 02:30:53" "2006-02-16 02:30:53" ...
```

### Always **look** at your data with `head`, `View`, or `kable`

There is no substitute for looking at your data and R provides several ways to just browse it.  The `head` function controls the number of rows that are displayed.  Note that tail does not work against a database object.  In every-day practice you would look at more than the default 6 rows, but here we wrap `head` around the data frame: 

```r
sqlpetr::sp_print_df(head(rental_tibble))
```

<!--html_preserve--><div id="htmlwidget-4f68022fd73b3d133ebb" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-4f68022fd73b3d133ebb">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[2,3,4,5,6,7],["2005-05-25T05:54:33Z","2005-05-25T06:03:39Z","2005-05-25T06:04:41Z","2005-05-25T06:05:21Z","2005-05-25T06:08:07Z","2005-05-25T06:11:53Z"],[1525,1711,2452,2079,2792,3995],[459,408,333,222,549,269],["2005-05-29T02:40:33Z","2005-06-02T05:12:39Z","2005-06-03T08:43:41Z","2005-06-02T11:33:21Z","2005-05-27T08:32:07Z","2005-05-30T03:34:53Z"],[1,1,2,1,1,2],["2006-02-16T10:30:53Z","2006-02-16T10:30:53Z","2006-02-16T10:30:53Z","2006-02-16T10:30:53Z","2006-02-16T10:30:53Z","2006-02-16T10:30:53Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>rental_id<\/th>\n      <th>rental_date<\/th>\n      <th>inventory_id<\/th>\n      <th>customer_id<\/th>\n      <th>return_date<\/th>\n      <th>staff_id<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### The `summary` function in `base`

The `base` package's `summary` function provides basic statistics that serve a unique diagnostic purpose in this context. For example, the following output shows that:

    * `rental_id` is a number from 1 to 16,049. In a previous section, we ran the `str` function and saw that there are 16,044 observations in this table. Therefore, the `rental_id` seems to be sequential from 1:16049, but there are 5 values missing from that sequence. _Exercise for the Reader_: Which 5 values from 1:16049 are missing from `rental_id` values in the `rental` table? (_Hint_: In the chapter on SQL Joins, you will learn the functions needed to answer this question.)
    * The number of NA's in the `return_date` column is a good first guess as to the number of DVDs rented out or lost as of 2005-09-02 02:35:22.


```r
summary(rental_tibble)
```

```
##    rental_id      rental_date                   inventory_id 
##  Min.   :    1   Min.   :2005-05-24 22:53:30   Min.   :   1  
##  1st Qu.: 4014   1st Qu.:2005-07-07 00:58:40   1st Qu.:1154  
##  Median : 8026   Median :2005-07-28 16:04:32   Median :2291  
##  Mean   : 8025   Mean   :2005-07-23 08:13:34   Mean   :2292  
##  3rd Qu.:12037   3rd Qu.:2005-08-17 21:16:23   3rd Qu.:3433  
##  Max.   :16049   Max.   :2006-02-14 15:16:03   Max.   :4581  
##                                                              
##   customer_id     return_date                     staff_id    
##  Min.   :  1.0   Min.   :2005-05-25 23:55:21   Min.   :1.000  
##  1st Qu.:148.0   1st Qu.:2005-07-10 15:49:36   1st Qu.:1.000  
##  Median :296.0   Median :2005-08-01 19:45:29   Median :1.000  
##  Mean   :297.1   Mean   :2005-07-25 23:58:03   Mean   :1.499  
##  3rd Qu.:446.0   3rd Qu.:2005-08-20 23:35:55   3rd Qu.:2.000  
##  Max.   :599.0   Max.   :2005-09-02 02:35:22   Max.   :2.000  
##                  NA's   :183                                  
##   last_update                 
##  Min.   :2006-02-15 21:30:53  
##  1st Qu.:2006-02-16 02:30:53  
##  Median :2006-02-16 02:30:53  
##  Mean   :2006-02-16 02:31:31  
##  3rd Qu.:2006-02-16 02:30:53  
##  Max.   :2006-02-23 09:12:08  
## 
```

So the `summary` function is surprisingly useful as we first start to look at the table contents.

### The `glimpse` function in the `tibble` package

The `tibble` package's `glimpse` function is a more compact version of `str`:

```r
tibble::glimpse(rental_tibble)
```

```
## Observations: 16,044
## Variables: 7
## $ rental_id    <int> 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,…
## $ rental_date  <dttm> 2005-05-24 22:54:33, 2005-05-24 23:03:39, 2005-05-…
## $ inventory_id <int> 1525, 1711, 2452, 2079, 2792, 3995, 2346, 2580, 182…
## $ customer_id  <int> 459, 408, 333, 222, 549, 269, 239, 126, 399, 142, 2…
## $ return_date  <dttm> 2005-05-28 19:40:33, 2005-06-01 22:12:39, 2005-06-…
## $ staff_id     <int> 1, 1, 2, 1, 1, 2, 2, 1, 2, 2, 2, 1, 1, 1, 2, 1, 2, …
## $ last_update  <dttm> 2006-02-16 02:30:53, 2006-02-16 02:30:53, 2006-02-…
```
### The `skim` function in the `skimr` package

The `skimr` package has several functions that make it easy to examine an unknown data frame and assess what it contains. It is also extensible.

```r
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

```r
skimr::skim(rental_tibble)
```

```
## Skim summary statistics
##  n obs: 16044 
##  n variables: 7 
## 
## ── Variable type:integer ─────────────────────────────────────────────────────────────────────────────────────────────
##      variable missing complete     n    mean      sd p0     p25    p50
##   customer_id       0    16044 16044  297.14  172.45  1  148     296  
##  inventory_id       0    16044 16044 2291.84 1322.21  1 1154    2291  
##     rental_id       0    16044 16044 8025.37 4632.78  1 4013.75 8025.5
##      staff_id       0    16044 16044    1.5     0.5   1    1       1  
##       p75  p100     hist
##    446      599 ▇▇▇▇▇▇▇▇
##   3433     4581 ▇▇▇▇▇▇▇▇
##  12037.25 16049 ▇▇▇▇▇▇▇▇
##      2        2 ▇▁▁▁▁▁▁▇
## 
## ── Variable type:POSIXct ─────────────────────────────────────────────────────────────────────────────────────────────
##     variable missing complete     n        min        max     median
##  last_update       0    16044 16044 2006-02-15 2006-02-23 2006-02-16
##  rental_date       0    16044 16044 2005-05-24 2006-02-14 2005-07-28
##  return_date     183    15861 16044 2005-05-25 2005-09-02 2005-08-01
##  n_unique
##         3
##     15815
##     15836
```

```r
wide_rental_skim <- skimr::skim_to_wide(rental_tibble)
```

### Close the connection and shut down sql-pet

Where you place the `collect` function matters.

```r
DBI::dbDisconnect(con)
sqlpetr::sp_docker_stop("sql-pet")
```

## Additional reading

* [@Wickham2018]
* [@Baumer2018]

