# Introduction to DBMS queries (11)

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

Use the

```r
table_columns <- lapply(tables, dbListFields, conn = con) 

#rename each list [[1]] ... [[22]] to meaningful table name
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

### Referencing a table for many different purposes

The `dplyr::tbl` function gives us more control over access to a table by enabling  control over which columns and rows to download.  It creates  an object that might **look** like a data frame, but it's actually a list object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  


```r
rental_table <- dplyr::tbl(con, "rental")
```

Consider the structure of the connection object:

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

Notice that the first list contains the source connection information.  Among other things it contains a list of variables/columns in the table:


```r
rental_table$ops$vars
```

```
## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
## [5] "return_date"  "staff_id"     "last_update"
```

### Paradigm Shift: Lazy Execution

R and `dplyr` is designed to be both lazy and smart. Lazy execution affects when a donwload happens and when processing occurs on the dbms server side.  R retrieves the full data set when explicityly told to do so via the `collect` verb, otherwise it returns only 10 rows. And `dplyr` tries to get as much work done on the server side as possible before downloading anything.  All of this is a key paradigm shift for those new to working with databases using R and `dplyr`, especially if they have been working in a straight SQL environment.

In the code blocks below, we demonstrate three ways to check if `dplyr` has performed lazy/delayed execution.

1.  Display the object.
2.  nrow(object)
3.  Check the pipe.


```r
rental_table <- dplyr::tbl(con, "rental")
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

```r
head(rental_table, n = 25)
```

```
## # Source:   lazy query [?? x 7]
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
At the top of the output look for the dimensions, [?? x columns] or at the bottom for '... with more rows'

Notice that `head` should return 25 rows, but only shows the 10 rows it has can retrieve. 


```r
nrow(rental_table)
```

```
## [1] NA
```

The the `rental_table` is smart enough to returns `NA` when passed to `nrow` so no execution is performed.


```r
rental_table %>% dplyr::summarise(n = n())
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   n              
##   <S3: integer64>
## 1 16044
```

```r
rental_table %>% dplyr::summarise(n = n()) %>% show_query()
```

```
## <SQL>
## SELECT COUNT(*) AS "n"
## FROM "rental"
```
The `dplyr::summarise` verb does not force R to download the whole table.  It **processes** the whole table by counting all the rows on the dbms side and then downloads one number.

Next we give an example where R gets busy and returns the full data set.


```r
rental_table <- dplyr::tbl(con, "rental") # Lazy

collect_rental_table <- rental_table %>% collect() # Busy
collect_rental_table
```

```
## # A tibble: 16,044 x 7
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
## # ... with 16,034 more rows, and 3 more variables: return_date <dttm>,
## #   staff_id <int>, last_update <dttm>
```

At the top of the output, `# A tibble: 16,044 x 7` and at the bottom of the output, `# ... with 16,034 more rows` we see that `dplyr::tbl` returned all the rows associated with `collect_rental_table`.  See [Controlling number of rows returned] for additional R examples showing R getting to work, and return some or all the rows.

See more example of lazy execution can be found [Here](https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html).


### Controlling number of rows returned

The `collect` function triggers the creation of a tibble and controls the number of rows that the DBMS sends to R.  Note that in the following examples, the object dimensions are known.

```r
rental_table %>% collect(n = 3) %>% head
```

```
## # A tibble: 3 x 7
##   rental_id rental_date         inventory_id customer_id
##       <int> <dttm>                     <int>       <int>
## 1         2 2005-05-24 22:54:33         1525         459
## 2         3 2005-05-24 23:03:39         1711         408
## 3         4 2005-05-24 23:04:41         2452         333
## # ... with 3 more variables: return_date <dttm>, staff_id <int>,
## #   last_update <dttm>
```
In this case the `collect` function triggers the execution of a query that counts the number of records in the table by `staff_id`:

```r
rental_table %>% 
  count(staff_id) %>% 
  collect()
```

```
## # A tibble: 2 x 2
##   staff_id n              
##      <int> <S3: integer64>
## 1        1 8040           
## 2        2 8004
```

The `collect` function affects how much is downloaded, not how many rows the DBMS needs to process the query. This query processes all of the rows in the table but only displays one row of output.

```r
rental_table %>% 
  count(staff_id) %>% 
  collect(n = 1)
```

```
## # A tibble: 1 x 2
##   staff_id n              
##      <int> <S3: integer64>
## 1        1 8040
```

### Random rows from the dbms

When the dbms contains many rows, a sample of the data may be plenty for your purposes.  Although `dplyr` has nice functions to sample a data frame that's already in R (e.g., the `sample_n` and `sample_frac` functions), to get a sample from the dbms we have to use `dbGetQuery` to send native SQL to the database. To peak ahead, here is one example of a query that retrieves 20 rows from a 1% sample:


```r
one_percent_sample <- DBI::dbGetQuery(con,
  "SELECT rental_id, rental_date, inventory_id, customer_id FROM rental TABLESAMPLE SYSTEM(1) LIMIT 20;
  ")

one_percent_sample
```

```
##    rental_id         rental_date inventory_id customer_id
## 1       5033 2005-07-09 02:42:01         2841         299
## 2       5034 2005-07-09 02:48:15          340         148
## 3       5035 2005-07-09 02:51:34         3699          99
## 4       5036 2005-07-09 02:58:41           75         573
## 5       5037 2005-07-09 02:59:10          435         524
## 6       5038 2005-07-09 03:12:52         3086          10
## 7       5039 2005-07-09 03:14:45         2020         268
## 8       5040 2005-07-09 03:16:34         2479         405
## 9       5041 2005-07-09 03:18:51         2711         305
## 10      5042 2005-07-09 03:20:30         3609         254
## 11      5043 2005-07-09 03:25:18         2979         369
## 12      5044 2005-07-09 03:30:25         1625         147
## 13      5045 2005-07-09 03:33:32         1041         230
## 14      5046 2005-07-09 03:34:57         1639         227
## 15      5047 2005-07-09 03:44:15          230         272
## 16      5048 2005-07-09 03:46:33         1271         466
## 17      5049 2005-07-09 03:54:12         3336         144
## 18      5050 2005-07-09 03:54:38         3876         337
## 19      5051 2005-07-09 03:57:53         4091          85
## 20      5052 2005-07-09 03:59:43         1884         305
```

### Sub-setting variables

A table in the dbms may not only have many more rows than you want and also many more columns.  The `select` command controls which columns are retrieved.

```r
rental_table %>% select(rental_date, return_date) %>% head
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

We won't discuss `dplyr` methods for sub-setting variables, deriving new ones, or sub-setting rows based on the values found in the table because they are covered well in other places, including:

  * Comprehensive reference: [https://dplyr.tidyverse.org/](https://dplyr.tidyverse.org/)
  * Good tutorial: [https://suzan.rbind.io/tags/dplyr/](https://suzan.rbind.io/tags/dplyr/) 

In practice we find that, **renaming variables** is often quite important because the names in an SQL database might not meet your needs as an analyst.  In "the wild" you will find names that are ambiguous or overly specified, with spaces in them, and other problems that will make them difficult to use in R.  It is good practice to do whatever renaming you are going to do in a predictable place like at the top of your code.  The names in the `dvdrental` database are simple and clear, but if they were not, you might rename them for subsequent use in this way:


```r
renamed_rental_table <- dplyr::tbl(con, "rental") %>% 
  rename(rental_id_number = rental_id, inventory_id_number = inventory_id)

renamed_rental_table %>% 
  select(rental_id_number, rental_date, inventory_id_number) %>% 
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

### Examining `dplyr`'s SQL query and re-using SQL code

The `show_query` function shows how `dplyr` is translating your query to the dialect of the target dbms:

```r
rental_table %>% 
  count(staff_id) %>% 
  show_query()
```

```
## <SQL>
## SELECT "staff_id", COUNT(*) AS "n"
## FROM "rental"
## GROUP BY "staff_id"
```
Here is an extensive discussion of how `dplyr` code is translated into SQL:

* [https://dbplyr.tidyverse.org/articles/sql-translation.html](https://dbplyr.tidyverse.org/articles/sql-translation.html) 

The SQL code can submit the same query directly to the DBMS with the `DBI::dbGetQuery` function:

```r
DBI::dbGetQuery(con,
  'SELECT "staff_id", COUNT(*) AS "n"
   FROM "rental"
   GROUP BY "staff_id";
  ')
```

```
##   staff_id    n
## 1        1 8040
## 2        2 8004
```
<<smy We haven't investigated this, but it looks like `dplyr` collect() function triggers a call simmilar to the dbGetQuery call above.  The default `dplyr` behavior looks like dbSendQuery() and dbFetch() model is used.>>

When you create a report to run repeatedly, you might want to put that query into R markdown.  That way you can also execute that SQL code in a chunk with the following header:

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
## 1        1 8040
## 2        2 8004
```

## Investigating a single table with R

Dealing with a large, complex database highlights the utility of specific tools in R.  We include brief examples that we find to be handy:

  + Base R structure: `str`
  + printing out some of the data: `datatable`, `kable`, and `View`
  + summary statistics: `summary`
  + `glimpse` oin the   `tibble` package, which is included in the `tidyverse`
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

### Always just **look** at your data with `head`, `View`, or `kable`

There is no substitute for looking at your data and R provides several ways to just browse it.  The `head` function controls the number of rows that are displayed.  Note that tail does not work against a database object.  In every-day practice you would look at more than the default 6 rows, but here we wrap `head` around the data frame: 

```r
sp_print_df(head(rental_tibble))
```

<!--html_preserve--><div id="htmlwidget-b18b48ec4ad649442f3b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b18b48ec4ad649442f3b">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[2,3,4,5,6,7],["2005-05-25T05:54:33Z","2005-05-25T06:03:39Z","2005-05-25T06:04:41Z","2005-05-25T06:05:21Z","2005-05-25T06:08:07Z","2005-05-25T06:11:53Z"],[1525,1711,2452,2079,2792,3995],[459,408,333,222,549,269],["2005-05-29T02:40:33Z","2005-06-02T05:12:39Z","2005-06-03T08:43:41Z","2005-06-02T11:33:21Z","2005-05-27T08:32:07Z","2005-05-30T03:34:53Z"],[1,1,2,1,1,2],["2006-02-16T10:30:53Z","2006-02-16T10:30:53Z","2006-02-16T10:30:53Z","2006-02-16T10:30:53Z","2006-02-16T10:30:53Z","2006-02-16T10:30:53Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>rental_id<\/th>\n      <th>rental_date<\/th>\n      <th>inventory_id<\/th>\n      <th>customer_id<\/th>\n      <th>return_date<\/th>\n      <th>staff_id<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### The `summary` function in base

The basic statistics that the base package `summary` provides can serve a unique diagnostic purpose in this context.  For example, the following output shows that `rental_id` is a sequential number from 1 to 16,049 with no gaps.  The same is true of `inventory_id`.  The number of NA's is a good first guess as to the number of dvd's rented out or lost on 2005-09-02 02:35:22.

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

### The `glimpse` function in the `tibble` package

The `tibble` package's `glimpse` function is a more compact version of `str`:

```r
tibble::glimpse(rental_tibble)
```

```
## Observations: 16,044
## Variables: 7
## $ rental_id    <int> 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1...
## $ rental_date  <dttm> 2005-05-24 22:54:33, 2005-05-24 23:03:39, 2005-0...
## $ inventory_id <int> 1525, 1711, 2452, 2079, 2792, 3995, 2346, 2580, 1...
## $ customer_id  <int> 459, 408, 333, 222, 549, 269, 239, 126, 399, 142,...
## $ return_date  <dttm> 2005-05-28 19:40:33, 2005-06-01 22:12:39, 2005-0...
## $ staff_id     <int> 1, 1, 2, 1, 1, 2, 2, 1, 2, 2, 2, 1, 1, 1, 2, 1, 2...
## $ last_update  <dttm> 2006-02-16 02:30:53, 2006-02-16 02:30:53, 2006-0...
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
skim(rental_tibble)
```

```
## Skim summary statistics
##  n obs: 16044 
##  n variables: 7 
## 
## ── Variable type:integer ────────────────────────────────────────────────────────────────────────────────────────────────────────────────
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
## ── Variable type:POSIXct ────────────────────────────────────────────────────────────────────────────────────────────────────────────────
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
wide_rental_skim <- skim_to_wide(rental_tibble)
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

### `dplyr` tools

Where you place the `collect` function matters.

```r
dbDisconnect(con)
sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```

## DBI Package

In this chapter we touched on a number of functions from the DBI Package.  The table below shows other functions in the package.  The Chapter column references a section in the book if we have used it.

|DBI| Chapter|Call Example/Notes
|---|--------|----------------------------------------
|DBIConnection-class||
|dbAppendTable||
|dbCreateTable||
|dbDisconnect|Every Chapter|
|dbExecute|10.4.2|Executes a statement and returns the number of rows affected. dbExecute() comes with a default implementation (which should work with most backends) that calls dbSendStatement(), then dbGetRowsAffected(), ensuring that the result is always free-d by dbClearResult().
|dbExistsTable||dbExistsTable(con,'actor')
|dbFetch|17.1|dbFecth(rs)
|dbGetException||
|dbGetInfo||dbGetInfo(con)
|dbGetQuery|10.4.1|dbGetQuery(con,'select * from store;')
|dbIsReadOnly||dbIsReadOnly(con)
|dbIsValid||dbIsValid(con)
|dbListFields|8.1.1|DBI::dbListFields(con, "rental")
|dbListObjects||dbListObjects(con)
|dbListResults||deprecated
|dbListTables|8.1.1|DBI::dbListTables(con, "rental")
|dbReadTable|8.1.2|DBI::dbReadTable(con, "rental")
|dbRemoveTable||
|dbSendQuery|17.1|rs <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
|dbSendStatement||The dbSendStatement() method only submits and synchronously executes the SQL data manipulation statement (e.g., UPDATE, DELETE, INSERT INTO, DROP TABLE, ...) to the database engine. 
|dbWriteTable|17.1|dbWriteTable(con, "mtcars", mtcars, overwrite = TRUE)


## Other resources

  * Benjamin S. Baumer, A Grammar for Reproducible and Painless Extract-Transform-Load Operations on Medium Data: [https://arxiv.org/pdf/1708.07073](https://arxiv.org/pdf/1708.07073) 

