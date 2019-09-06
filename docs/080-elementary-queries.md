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
Assume that the Docker container with PostgreSQL and the adventureworks database are ready to go. If not go back to [Chapter 6][#chapter_setup-adventureworks-db]

```r
sqlpetr::sp_docker_start("adventureworks")
```
Connect to the database:

```r
con <- sqlpetr::sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "adventureworks",
  port = 5432, 
  seconds_to_test = 20, 
  connection_tab = TRUE
)
```

## Downloading a single table

For the moment, assume you know something about the database and specifically what table you need to retrieve.

### Downloading the entire table

There are many different methods of getting data from a DBMS, and we'll explore the different ways of controlling each one of them.

`DBI::dbReadTable` will download an entire table into an R [tibble](https://tibble.tidyverse.org/).  

```r
dbExecute(con, "set search_path to sales, humanresources;") # watch for duplicates!
```

```
## [1] 0
```

```r
salesorderheader_tibble <- DBI::dbReadTable(con, "salesorderheader")
str(salesorderheader_tibble)
```

```
## 'data.frame':	31465 obs. of  25 variables:
##  $ salesorderid          : int  43659 43660 43661 43662 43663 43664 43665 43666 43667 43668 ...
##  $ revisionnumber        : int  8 8 8 8 8 8 8 8 8 8 ...
##  $ orderdate             : POSIXct, format: "2011-05-31" "2011-05-31" ...
##  $ duedate               : POSIXct, format: "2011-06-12" "2011-06-12" ...
##  $ shipdate              : POSIXct, format: "2011-06-07" "2011-06-07" ...
##  $ status                : int  5 5 5 5 5 5 5 5 5 5 ...
##  $ onlineorderflag       : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
##  $ purchaseordernumber   : chr  "PO522145787" "PO18850127500" "PO18473189620" "PO18444174044" ...
##  $ accountnumber         : chr  "10-4020-000676" "10-4020-000117" "10-4020-000442" "10-4020-000227" ...
##  $ customerid            : int  29825 29672 29734 29994 29565 29898 29580 30052 29974 29614 ...
##  $ salespersonid         : int  279 279 282 282 276 280 283 276 277 282 ...
##  $ territoryid           : int  5 5 6 6 4 1 1 4 3 6 ...
##  $ billtoaddressid       : int  985 921 517 482 1073 876 849 1074 629 529 ...
##  $ shiptoaddressid       : int  985 921 517 482 1073 876 849 1074 629 529 ...
##  $ shipmethodid          : int  5 5 5 5 5 5 5 5 5 5 ...
##  $ creditcardid          : int  16281 5618 1346 10456 4322 806 15232 13349 10370 1566 ...
##  $ creditcardapprovalcode: chr  "105041Vi84182" "115213Vi29411" "85274Vi6854" "125295Vi53935" ...
##  $ currencyrateid        : int  NA NA 4 4 NA NA NA NA NA 4 ...
##  $ subtotal              : num  20566 1294 32726 28833 419 ...
##  $ taxamt                : num  1971.5 124.2 3153.8 2775.2 40.3 ...
##  $ freight               : num  616.1 38.8 985.6 867.2 12.6 ...
##  $ totaldue              : num  23153 1457 36866 32475 472 ...
##  $ comment               : chr  NA NA NA NA ...
##  $ rowguid               : chr  "79b65321-39ca-4115-9cba-8fe0903e12e6" "738dc42d-d03b-48a1-9822-f95a67ea7389" "d91b9131-18a4-4a11-bc3a-90b6f53e9d74" "4a1ecfc0-cc3a-4740-b028-1c50bb48711c" ...
##  $ modifieddate          : POSIXct, format: "2011-06-07" "2011-06-07" ...
```
That's very simple, but if the table is large it may not be a good idea, since R is designed to keep the entire table in memory.  Note that the first line of the str() output reports the total number of observations.  

### A table *object* that can be reused

The `dplyr::tbl` function gives us more control over access to a table by enabling  control over which columns and rows to download.  It creates  an object that might **look** like a data frame, but it's actually a list object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  


```r
salesorderheader_table <- dplyr::tbl(con, "salesorderheader")
class(salesorderheader_table)
```

```
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"         
## [4] "tbl_lazy"         "tbl"
```


### Controlling the number of rows returned

The `collect` function triggers the creation of a tibble and controls the number of rows that the DBMS sends to R.  For more complex queries, the `dplyr::collect()` function provides a mechanism to indicate what's processed on on the dbms server and what's processed by R on the local machine. The chapter on [Lazy Evaluation and Execution Environment](#chapter_lazy-evaluation-and-timing) discusses this issue in detail.

```r
salesorderheader_table %>% dplyr::collect(n = 3) %>% dim
```

```
## [1]  3 25
```

```r
salesorderheader_table %>% dplyr::collect(n = 500) %>% dim
```

```
## [1] 500  25
```

### Random rows from the dbms

When the dbms contains many rows, a sample of the data may be plenty for your purposes.  Although `dplyr` has nice functions to sample a data frame that's already in R (e.g., the `sample_n` and `sample_frac` functions), to get a sample from the dbms we have to use `dbGetQuery` to send native SQL to the database. To peek ahead, here is one example of a query that retrieves 20 rows from a 1% sample:


```r
one_percent_sample <- DBI::dbGetQuery(
  con,
  "SELECT orderdate, subtotal, taxamt, freight, totaldue
  FROM salesorderheader TABLESAMPLE BERNOULLI(3) LIMIT 20;
  "
)


one_percent_sample
```

```
##     orderdate   subtotal    taxamt  freight   totaldue
## 1  2011-05-31 20565.6206 1971.5149 616.0984 23153.2339
## 2  2011-05-31  6107.0820  586.1203 183.1626  6876.3649
## 3  2011-06-05  3578.2700  286.2616  89.4568  3953.9884
## 4  2011-06-20  3578.2700  286.2616  89.4568  3953.9884
## 5  2011-06-22  3578.2700  286.2616  89.4568  3953.9884
## 6  2011-06-24   699.0982   55.9279  17.4775   772.5036
## 7  2011-07-01  2561.5408  246.3213  76.9754  2884.8375
## 8  2011-07-13   699.0982   55.9279  17.4775   772.5036
## 9  2011-07-26  3578.2700  286.2616  89.4568  3953.9884
## 10 2011-08-13   699.0982   55.9279  17.4775   772.5036
## 11 2011-08-22  3578.2700  286.2616  89.4568  3953.9884
## 12 2011-08-30  3578.2700  286.2616  89.4568  3953.9884
## 13 2011-08-31 29479.3877 2832.6003 885.1876 33197.1756
## 14 2011-08-31  3785.5031  363.3115 113.5348  4262.3494
## 15 2011-09-03  3578.2700  286.2616  89.4568  3953.9884
## 16 2011-09-14  3578.2700  286.2616  89.4568  3953.9884
## 17 2011-09-16  3578.2700  286.2616  89.4568  3953.9884
## 18 2011-09-30  3374.9900  269.9992  84.3748  3729.3640
## 19 2011-10-01  6127.7820  588.0543 183.7670  6899.6033
## 20 2011-10-08  3578.2700  286.2616  89.4568  3953.9884
```
**Exact sample of 100 records**

This technique depends on knowing the range of a record index, such as the `businessentityid` in the `salesorderheader` table of our `adventureworks` database.

Start by finding the min and max values.

```r
DBI::dbListFields(con, "salesorderheader")
```

```
##  [1] "salesorderid"           "revisionnumber"        
##  [3] "orderdate"              "duedate"               
##  [5] "shipdate"               "status"                
##  [7] "onlineorderflag"        "purchaseordernumber"   
##  [9] "accountnumber"          "customerid"            
## [11] "salespersonid"          "territoryid"           
## [13] "billtoaddressid"        "shiptoaddressid"       
## [15] "shipmethodid"           "creditcardid"          
## [17] "creditcardapprovalcode" "currencyrateid"        
## [19] "subtotal"               "taxamt"                
## [21] "freight"                "totaldue"              
## [23] "comment"                "rowguid"               
## [25] "modifieddate"
```

```r
salesorderheader_df <- DBI::dbReadTable(con, "salesorderheader")

(max_id <- max(salesorderheader_df$salesorderid))
```

```
## [1] 75123
```

```r
(min_id <- min(salesorderheader_df$salesorderid))
```

```
## [1] 43659
```

Set the random number seed and draw the sample.

```r
set.seed(123)
sample_rows <- sample(1:max(salesorderheader_df$salesorderid), 10)
salesorderheader_table <- dplyr::tbl(con, "salesorderheader")
```

Run query with the filter verb listing the randomly sampled rows to be retrieved:

```r
salesorderheader_sample <- salesorderheader_table %>% 
  dplyr::filter(salesorderid %in% sample_rows) %>% 
  dplyr::collect()

str(salesorderheader_sample)
```

```
## Classes 'tbl_df', 'tbl' and 'data.frame':	7 obs. of  25 variables:
##  $ salesorderid          : int  45404 46435 51663 57870 62555 65161 68293
##  $ revisionnumber        : int  8 8 8 8 8 8 8
##  $ orderdate             : POSIXct, format: "2012-01-10" "2012-05-06" ...
##  $ duedate               : POSIXct, format: "2012-01-22" "2012-05-18" ...
##  $ shipdate              : POSIXct, format: "2012-01-17" "2012-05-13" ...
##  $ status                : int  5 5 5 5 5 5 5
##  $ onlineorderflag       : logi  TRUE TRUE TRUE TRUE TRUE FALSE ...
##  $ purchaseordernumber   : chr  NA NA NA NA ...
##  $ accountnumber         : chr  "10-4030-011217" "10-4030-012251" "10-4030-016327" "10-4030-018572" ...
##  $ customerid            : int  11217 12251 16327 18572 13483 29799 13239
##  $ salespersonid         : int  NA NA NA NA NA 281 NA
##  $ territoryid           : int  1 9 8 4 1 4 6
##  $ billtoaddressid       : int  19321 24859 19265 16902 15267 997 27923
##  $ shiptoaddressid       : int  19321 24859 19265 16902 15267 997 27923
##  $ shipmethodid          : int  1 1 1 1 1 5 1
##  $ creditcardid          : int  8241 13188 16357 1884 4409 12582 1529
##  $ creditcardapprovalcode: chr  "332581Vi42712" "635144Vi68383" "420152Vi84562" "1224478Vi9772" ...
##  $ currencyrateid        : int  NA 4121 NA NA NA NA 11581
##  $ subtotal              : num  3578 3375 2466 14 57 ...
##  $ taxamt                : num  286.26 270 197.31 1.12 4.56 ...
##  $ freight               : num  89.457 84.375 61.658 0.349 1.424 ...
##  $ totaldue              : num  3954 3729.4 2725.3 15.4 63 ...
##  $ comment               : chr  NA NA NA NA ...
##  $ rowguid               : chr  "358f91b2-dadd-4014-8d4f-7f9736cb664e" "eb312409-fcd5-4bac-bd3b-16d4bd7889db" "ddc60552-af98-4166-9249-d09d424d8430" "fe46e631-47b9-4e14-9da5-1e4a4a135364" ...
##  $ modifieddate          : POSIXct, format: "2012-01-17" "2012-05-13" ...
```


### Sub-setting variables

A table in the dbms may not only have many more rows than you want, but also many more columns.  The `select` command controls which columns are retrieved.

```r
salesorderheader_table %>% dplyr::select(orderdate, subtotal, taxamt, freight, totaldue) %>% 
  head() 
```

```
## # Source:   lazy query [?? x 5]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   orderdate           subtotal taxamt freight totaldue
##   <dttm>                 <dbl>  <dbl>   <dbl>    <dbl>
## 1 2011-05-31 00:00:00   20566. 1972.    616.    23153.
## 2 2011-05-31 00:00:00    1294.  124.     38.8    1457.
## 3 2011-05-31 00:00:00   32726. 3154.    986.    36866.
## 4 2011-05-31 00:00:00   28833. 2775.    867.    32475.
## 5 2011-05-31 00:00:00     419.   40.3    12.6     472.
## 6 2011-05-31 00:00:00   24433. 2345.    733.    27510.
```
That's exactly equivalent to submitting the following SQL commands dirctly:

```r
DBI::dbGetQuery(
  con,
  'SELECT "orderdate", "subtotal", "taxamt", "freight", "totaldue"
    FROM "salesorderheader"
    LIMIT 6') 
```

```
##    orderdate   subtotal    taxamt  freight   totaldue
## 1 2011-05-31 20565.6206 1971.5149 616.0984 23153.2339
## 2 2011-05-31  1294.2529  124.2483  38.8276  1457.3288
## 3 2011-05-31 32726.4786 3153.7696 985.5530 36865.8012
## 4 2011-05-31 28832.5289 2775.1646 867.2389 32474.9324
## 5 2011-05-31   419.4589   40.2681  12.5838   472.3108
## 6 2011-05-31 24432.6088 2344.9921 732.8100 27510.4109
```


We won't discuss `dplyr` methods for sub-setting variables, deriving new ones, or sub-setting rows based on the values found in the table, because they are covered well in other places, including:

  * Comprehensive reference: [https://dplyr.tidyverse.org/](https://dplyr.tidyverse.org/)
  * Good tutorial: [https://suzan.rbind.io/tags/dplyr/](https://suzan.rbind.io/tags/dplyr/) 

In practice we find that, **renaming variables** is often quite important because the names in an SQL database might not meet your needs as an analyst.  In "the wild", you will find names that are ambiguous or overly specified, with spaces in them, and other problems that will make them difficult to use in R.  It is good practice to do whatever renaming you are going to do in a predictable place like at the top of your code.  The names in the `adventureworks` database are simple and clear, but if they were not, you might rename them for subsequent use in this way:


```r
tbl(con, "salesorderheader") %>%
  dplyr::rename(order_date = orderdate, sub_total_amount = subtotal,
              tax_amount = taxamt, freight_amount = freight, total_due_amount = totaldue) %>% 
  dplyr::select(order_date, sub_total_amount, tax_amount, freight_amount, total_due_amount ) %>%
  # head()
show_query()
```

```
## <SQL>
## SELECT "orderdate" AS "order_date", "subtotal" AS "sub_total_amount", "taxamt" AS "tax_amount", "freight" AS "freight_amount", "totaldue" AS "total_due_amount"
## FROM "salesorderheader"
```
That's equivalent to the following SQL code:

```r
DBI::dbGetQuery(
  con,
    'SELECT "orderdate" AS "order_date", 
    "subtotal" AS "sub_total_amount", 
    "taxamt" AS "tax_amount", 
    "freight" AS "freight_amount", 
    "totaldue" AS "total_due_amount"
    FROM "salesorderheader"' ) %>% head()
```

```
##   order_date sub_total_amount tax_amount freight_amount total_due_amount
## 1 2011-05-31       20565.6206  1971.5149       616.0984       23153.2339
## 2 2011-05-31        1294.2529   124.2483        38.8276        1457.3288
## 3 2011-05-31       32726.4786  3153.7696       985.5530       36865.8012
## 4 2011-05-31       28832.5289  2775.1646       867.2389       32474.9324
## 5 2011-05-31         419.4589    40.2681        12.5838         472.3108
## 6 2011-05-31       24432.6088  2344.9921       732.8100       27510.4109
```
The one difference is that the `SQL` code returns a regular data frame and the `dplyr` code returns a `tibble`.  Notice that the seconds are greyed out in the `tibble` display.

### Translating `dplyr` code to `SQL` queries

Where did the translations we've shown above come from?  The `show_query` function shows how `dplyr` is translating your query to the dialect of the target dbms:

```r
salesorderheader_table %>%
  dplyr::tally() %>%
  dplyr::show_query()
```

```
## <SQL>
## SELECT COUNT(*) AS "n"
## FROM "salesorderheader"
```
Here is an extensive discussion of how `dplyr` code is translated into SQL:

* [https://dbplyr.tidyverse.org/articles/sql-translation.html](https://dbplyr.tidyverse.org/articles/sql-translation.html) 

If you prefer to use SQL directly, rather than `dplyr`, you can submit SQL code to the DBMS through the `DBI::dbGetQuery` function:

```r
DBI::dbGetQuery(
  con,
  'SELECT COUNT(*) AS "n"
     FROM "salesorderheader"   '
)
```

```
##       n
## 1 31465
```

When you create a report to run repeatedly, you might want to put that query into R markdown. That way you can also execute that SQL code in a chunk with the following header:

  {`sql, connection=con, output.var = "query_results"`}


```sql
SELECT COUNT(*) AS "n"
     FROM "salesorderheader";
```
Rmarkdown stores that query result in a tibble which can be printed by referring to it:

```r
query_results
```

```
##       n
## 1 31465
```

## Mixing dplyr and SQL

When dplyr finds code that it does not know how to translate into SQL, it will simply pass it along to the dbms. Therefore you can interleave native commands that your dbms will understand in the middle of dplyr code.  Consider this example that's derived from [@Ruiz2019]:


```r
salesorderheader_table %>%
  dplyr::select_at(vars(subtotal, contains("date"))) %>% 
  dplyr::mutate(today = now()) %>%
  dplyr::show_query()
```

```
## <SQL>
## SELECT "subtotal", "orderdate", "duedate", "shipdate", "modifieddate", CURRENT_TIMESTAMP AS "today"
## FROM "salesorderheader"
```
That is native to PostgreSQL, not [ANSI standard](https://en.wikipedia.org/wiki/SQL#Interoperability_and_standardization) SQL.

Verify that it works:

```r
salesorderheader_table %>%
  dplyr::select_at(vars(subtotal, contains("date"))) %>% 
  head() %>% 
  dplyr::mutate(today = now()) %>%
  dplyr::collect()
```

```
## # A tibble: 6 x 6
##   subtotal orderdate           duedate             shipdate           
##      <dbl> <dttm>              <dttm>              <dttm>             
## 1   20566. 2011-05-31 00:00:00 2011-06-12 00:00:00 2011-06-07 00:00:00
## 2    1294. 2011-05-31 00:00:00 2011-06-12 00:00:00 2011-06-07 00:00:00
## 3   32726. 2011-05-31 00:00:00 2011-06-12 00:00:00 2011-06-07 00:00:00
## 4   28833. 2011-05-31 00:00:00 2011-06-12 00:00:00 2011-06-07 00:00:00
## 5     419. 2011-05-31 00:00:00 2011-06-12 00:00:00 2011-06-07 00:00:00
## 6   24433. 2011-05-31 00:00:00 2011-06-12 00:00:00 2011-06-07 00:00:00
## # … with 2 more variables: modifieddate <dttm>, today <dttm>
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
str(salesorderheader_tibble)
```

```
## 'data.frame':	31465 obs. of  25 variables:
##  $ salesorderid          : int  43659 43660 43661 43662 43663 43664 43665 43666 43667 43668 ...
##  $ revisionnumber        : int  8 8 8 8 8 8 8 8 8 8 ...
##  $ orderdate             : POSIXct, format: "2011-05-31" "2011-05-31" ...
##  $ duedate               : POSIXct, format: "2011-06-12" "2011-06-12" ...
##  $ shipdate              : POSIXct, format: "2011-06-07" "2011-06-07" ...
##  $ status                : int  5 5 5 5 5 5 5 5 5 5 ...
##  $ onlineorderflag       : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
##  $ purchaseordernumber   : chr  "PO522145787" "PO18850127500" "PO18473189620" "PO18444174044" ...
##  $ accountnumber         : chr  "10-4020-000676" "10-4020-000117" "10-4020-000442" "10-4020-000227" ...
##  $ customerid            : int  29825 29672 29734 29994 29565 29898 29580 30052 29974 29614 ...
##  $ salespersonid         : int  279 279 282 282 276 280 283 276 277 282 ...
##  $ territoryid           : int  5 5 6 6 4 1 1 4 3 6 ...
##  $ billtoaddressid       : int  985 921 517 482 1073 876 849 1074 629 529 ...
##  $ shiptoaddressid       : int  985 921 517 482 1073 876 849 1074 629 529 ...
##  $ shipmethodid          : int  5 5 5 5 5 5 5 5 5 5 ...
##  $ creditcardid          : int  16281 5618 1346 10456 4322 806 15232 13349 10370 1566 ...
##  $ creditcardapprovalcode: chr  "105041Vi84182" "115213Vi29411" "85274Vi6854" "125295Vi53935" ...
##  $ currencyrateid        : int  NA NA 4 4 NA NA NA NA NA 4 ...
##  $ subtotal              : num  20566 1294 32726 28833 419 ...
##  $ taxamt                : num  1971.5 124.2 3153.8 2775.2 40.3 ...
##  $ freight               : num  616.1 38.8 985.6 867.2 12.6 ...
##  $ totaldue              : num  23153 1457 36866 32475 472 ...
##  $ comment               : chr  NA NA NA NA ...
##  $ rowguid               : chr  "79b65321-39ca-4115-9cba-8fe0903e12e6" "738dc42d-d03b-48a1-9822-f95a67ea7389" "d91b9131-18a4-4a11-bc3a-90b6f53e9d74" "4a1ecfc0-cc3a-4740-b028-1c50bb48711c" ...
##  $ modifieddate          : POSIXct, format: "2011-06-07" "2011-06-07" ...
```

### Always **look** at your data with `head`, `View`, or `kable`

There is no substitute for looking at your data and R provides several ways to just browse it.  The `head` function controls the number of rows that are displayed.  Note that tail does not work against a database object.  In every-day practice you would look at more than the default 6 rows, but here we wrap `head` around the data frame: 

```r
sqlpetr::sp_print_df(head(salesorderheader_tibble))
```

<!--html_preserve--><div id="htmlwidget-88fdd2a34d502a66744b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-88fdd2a34d502a66744b">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[43659,43660,43661,43662,43663,43664],[8,8,8,8,8,8],["2011-05-31T07:00:00Z","2011-05-31T07:00:00Z","2011-05-31T07:00:00Z","2011-05-31T07:00:00Z","2011-05-31T07:00:00Z","2011-05-31T07:00:00Z"],["2011-06-12T07:00:00Z","2011-06-12T07:00:00Z","2011-06-12T07:00:00Z","2011-06-12T07:00:00Z","2011-06-12T07:00:00Z","2011-06-12T07:00:00Z"],["2011-06-07T07:00:00Z","2011-06-07T07:00:00Z","2011-06-07T07:00:00Z","2011-06-07T07:00:00Z","2011-06-07T07:00:00Z","2011-06-07T07:00:00Z"],[5,5,5,5,5,5],[false,false,false,false,false,false],["PO522145787","PO18850127500","PO18473189620","PO18444174044","PO18009186470","PO16617121983"],["10-4020-000676","10-4020-000117","10-4020-000442","10-4020-000227","10-4020-000510","10-4020-000397"],[29825,29672,29734,29994,29565,29898],[279,279,282,282,276,280],[5,5,6,6,4,1],[985,921,517,482,1073,876],[985,921,517,482,1073,876],[5,5,5,5,5,5],[16281,5618,1346,10456,4322,806],["105041Vi84182","115213Vi29411","85274Vi6854","125295Vi53935","45303Vi22691","95555Vi4081"],[null,null,4,4,null,null],[20565.6206,1294.2529,32726.4786,28832.5289,419.4589,24432.6088],[1971.5149,124.2483,3153.7696,2775.1646,40.2681,2344.9921],[616.0984,38.8276,985.553,867.2389,12.5838,732.81],[23153.2339,1457.3288,36865.8012,32474.9324,472.3108,27510.4109],[null,null,null,null,null,null],["79b65321-39ca-4115-9cba-8fe0903e12e6","738dc42d-d03b-48a1-9822-f95a67ea7389","d91b9131-18a4-4a11-bc3a-90b6f53e9d74","4a1ecfc0-cc3a-4740-b028-1c50bb48711c","9b1e7a40-6ae0-4ad3-811c-a64951857c4b","22a8a5da-8c22-42ad-9241-839489b6ef0d"],["2011-06-07T07:00:00Z","2011-06-07T07:00:00Z","2011-06-07T07:00:00Z","2011-06-07T07:00:00Z","2011-06-07T07:00:00Z","2011-06-07T07:00:00Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>salesorderid<\/th>\n      <th>revisionnumber<\/th>\n      <th>orderdate<\/th>\n      <th>duedate<\/th>\n      <th>shipdate<\/th>\n      <th>status<\/th>\n      <th>onlineorderflag<\/th>\n      <th>purchaseordernumber<\/th>\n      <th>accountnumber<\/th>\n      <th>customerid<\/th>\n      <th>salespersonid<\/th>\n      <th>territoryid<\/th>\n      <th>billtoaddressid<\/th>\n      <th>shiptoaddressid<\/th>\n      <th>shipmethodid<\/th>\n      <th>creditcardid<\/th>\n      <th>creditcardapprovalcode<\/th>\n      <th>currencyrateid<\/th>\n      <th>subtotal<\/th>\n      <th>taxamt<\/th>\n      <th>freight<\/th>\n      <th>totaldue<\/th>\n      <th>comment<\/th>\n      <th>rowguid<\/th>\n      <th>modifieddate<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10,11,12,13,14,15,16,18,19,20,21,22]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### The `summary` function in `base`

The `base` package's `summary` function provides basic statistics that serve a unique diagnostic purpose in this context. For example, the following output shows that:

    * `businessentityid` is a number from 1 to 16,049. In a previous section, we ran the `str` function and saw that there are 16,044 observations in this table. Therefore, the `businessentityid` seems to be sequential from 1:16049, but there are 5 values missing from that sequence. _Exercise for the Reader_: Which 5 values from 1:16049 are missing from `businessentityid` values in the `salesorderheader` table? (_Hint_: In the chapter on SQL Joins, you will learn the functions needed to answer this question.)
    * The number of NA's in the `return_date` column is a good first guess as to the number of DVDs rented out or lost as of 2005-09-02 02:35:22.


```r
summary(salesorderheader_tibble)
```

```
##   salesorderid   revisionnumber    orderdate                  
##  Min.   :43659   Min.   :8.000   Min.   :2011-05-31 00:00:00  
##  1st Qu.:51525   1st Qu.:8.000   1st Qu.:2013-06-20 00:00:00  
##  Median :59391   Median :8.000   Median :2013-11-03 00:00:00  
##  Mean   :59391   Mean   :8.001   Mean   :2013-08-21 12:05:04  
##  3rd Qu.:67257   3rd Qu.:8.000   3rd Qu.:2014-02-28 00:00:00  
##  Max.   :75123   Max.   :9.000   Max.   :2014-06-30 00:00:00  
##                                                               
##     duedate                       shipdate                       status 
##  Min.   :2011-06-12 00:00:00   Min.   :2011-06-07 00:00:00   Min.   :5  
##  1st Qu.:2013-07-02 00:00:00   1st Qu.:2013-06-27 00:00:00   1st Qu.:5  
##  Median :2013-11-15 00:00:00   Median :2013-11-10 00:00:00   Median :5  
##  Mean   :2013-09-02 12:05:41   Mean   :2013-08-28 12:06:06   Mean   :5  
##  3rd Qu.:2014-03-13 00:00:00   3rd Qu.:2014-03-08 00:00:00   3rd Qu.:5  
##  Max.   :2014-07-12 00:00:00   Max.   :2014-07-07 00:00:00   Max.   :5  
##                                                                         
##  onlineorderflag purchaseordernumber accountnumber        customerid   
##  Mode :logical   Length:31465        Length:31465       Min.   :11000  
##  FALSE:3806      Class :character    Class :character   1st Qu.:14432  
##  TRUE :27659     Mode  :character    Mode  :character   Median :19452  
##                                                         Mean   :20170  
##                                                         3rd Qu.:25994  
##                                                         Max.   :30118  
##                                                                        
##  salespersonid    territoryid     billtoaddressid shiptoaddressid
##  Min.   :274.0   Min.   : 1.000   Min.   :  405   Min.   :    9  
##  1st Qu.:277.0   1st Qu.: 4.000   1st Qu.:14080   1st Qu.:14063  
##  Median :279.0   Median : 6.000   Median :19449   Median :19438  
##  Mean   :280.6   Mean   : 6.091   Mean   :18263   Mean   :18249  
##  3rd Qu.:284.0   3rd Qu.: 9.000   3rd Qu.:24678   3rd Qu.:24672  
##  Max.   :290.0   Max.   :10.000   Max.   :29883   Max.   :29883  
##  NA's   :27659                                                   
##   shipmethodid    creditcardid   creditcardapprovalcode currencyrateid 
##  Min.   :1.000   Min.   :    1   Length:31465           Min.   :    2  
##  1st Qu.:1.000   1st Qu.: 4894   Class :character       1st Qu.: 8510  
##  Median :1.000   Median : 9720   Mode  :character       Median :10074  
##  Mean   :1.484   Mean   : 9684                          Mean   : 9192  
##  3rd Qu.:1.000   3rd Qu.:14511                          3rd Qu.:11282  
##  Max.   :5.000   Max.   :19237                          Max.   :12431  
##                  NA's   :1131                           NA's   :17489  
##     subtotal             taxamt             freight        
##  Min.   :     1.37   Min.   :    0.110   Min.   :   0.034  
##  1st Qu.:    56.97   1st Qu.:    4.558   1st Qu.:   1.424  
##  Median :   782.99   Median :   62.639   Median :  19.575  
##  Mean   :  3491.07   Mean   :  323.756   Mean   : 101.174  
##  3rd Qu.:  2366.96   3rd Qu.:  189.598   3rd Qu.:  59.249  
##  Max.   :163930.39   Max.   :17948.519   Max.   :5608.912  
##                                                            
##     totaldue           comment            rowguid         
##  Min.   :     1.52   Length:31465       Length:31465      
##  1st Qu.:    62.95   Class :character   Class :character  
##  Median :   865.20   Mode  :character   Mode  :character  
##  Mean   :  3916.00                                        
##  3rd Qu.:  2615.49                                        
##  Max.   :187487.83                                        
##                                                           
##   modifieddate                
##  Min.   :2011-06-07 00:00:00  
##  1st Qu.:2013-06-27 00:00:00  
##  Median :2013-11-10 00:00:00  
##  Mean   :2013-08-28 12:06:06  
##  3rd Qu.:2014-03-08 00:00:00  
##  Max.   :2014-07-07 00:00:00  
## 
```

So the `summary` function is surprisingly useful as we first start to look at the table contents.

### The `glimpse` function in the `tibble` package

The `tibble` package's `glimpse` function is a more compact version of `str`:

```r
tibble::glimpse(salesorderheader_tibble)
```

```
## Observations: 31,465
## Variables: 25
## $ salesorderid           <int> 43659, 43660, 43661, 43662, 43663, 43664,…
## $ revisionnumber         <int> 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,…
## $ orderdate              <dttm> 2011-05-31, 2011-05-31, 2011-05-31, 2011…
## $ duedate                <dttm> 2011-06-12, 2011-06-12, 2011-06-12, 2011…
## $ shipdate               <dttm> 2011-06-07, 2011-06-07, 2011-06-07, 2011…
## $ status                 <int> 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,…
## $ onlineorderflag        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
## $ purchaseordernumber    <chr> "PO522145787", "PO18850127500", "PO184731…
## $ accountnumber          <chr> "10-4020-000676", "10-4020-000117", "10-4…
## $ customerid             <int> 29825, 29672, 29734, 29994, 29565, 29898,…
## $ salespersonid          <int> 279, 279, 282, 282, 276, 280, 283, 276, 2…
## $ territoryid            <int> 5, 5, 6, 6, 4, 1, 1, 4, 3, 6, 1, 3, 1, 6,…
## $ billtoaddressid        <int> 985, 921, 517, 482, 1073, 876, 849, 1074,…
## $ shiptoaddressid        <int> 985, 921, 517, 482, 1073, 876, 849, 1074,…
## $ shipmethodid           <int> 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,…
## $ creditcardid           <int> 16281, 5618, 1346, 10456, 4322, 806, 1523…
## $ creditcardapprovalcode <chr> "105041Vi84182", "115213Vi29411", "85274V…
## $ currencyrateid         <int> NA, NA, 4, 4, NA, NA, NA, NA, NA, 4, NA, …
## $ subtotal               <dbl> 20565.6206, 1294.2529, 32726.4786, 28832.…
## $ taxamt                 <dbl> 1971.5149, 124.2483, 3153.7696, 2775.1646…
## $ freight                <dbl> 616.0984, 38.8276, 985.5530, 867.2389, 12…
## $ totaldue               <dbl> 23153.2339, 1457.3288, 36865.8012, 32474.…
## $ comment                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ rowguid                <chr> "79b65321-39ca-4115-9cba-8fe0903e12e6", "…
## $ modifieddate           <dttm> 2011-06-07, 2011-06-07, 2011-06-07, 2011…
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

```
## The following object is masked from 'package:stats':
## 
##     filter
```

```r
skimr::skim(salesorderheader_tibble)
```

```
## Skim summary statistics
##  n obs: 31465 
##  n variables: 25 
## 
## ── Variable type:character ───────────────────────────────────────────────────────────────────────
##                variable missing complete     n min max empty n_unique
##           accountnumber       0    31465 31465  14  14     0    19119
##                 comment   31465        0 31465  NA  NA     0        0
##  creditcardapprovalcode    1131    30334 31465   9  15     0    30334
##     purchaseordernumber   27659     3806 31465  10  13     0     3806
##                 rowguid       0    31465 31465  36  36     0    31465
## 
## ── Variable type:integer ─────────────────────────────────────────────────────────────────────────
##         variable missing complete     n     mean       sd    p0      p25
##  billtoaddressid       0    31465 31465 18263.15 8210.07    405 14080   
##     creditcardid    1131    30334 31465  9684.1  5566.3       1  4894.25
##   currencyrateid   17489    13976 31465  9191.5  2945.17      2  8510   
##       customerid       0    31465 31465 20170.18 6261.73  11000 14432   
##   revisionnumber       0    31465 31465     8       0.031     8     8   
##     salesorderid       0    31465 31465 59391    9083.31  43659 51525   
##    salespersonid   27659     3806 31465   280.61    4.85    274   277   
##     shipmethodid       0    31465 31465     1.48    1.3       1     1   
##  shiptoaddressid       0    31465 31465 18249.19 8218.43      9 14063   
##           status       0    31465 31465     5       0         5     5   
##      territoryid       0    31465 31465     6.09    2.96      1     4   
##      p50      p75  p100     hist
##  19449   24678    29883 ▆▁▁▇▇▇▇▇
##   9719.5 14510.75 19237 ▇▇▇▇▇▇▇▇
##  10074   11282    12431 ▁▁▁▁▂▃▇▇
##  19452   25994    30118 ▇▆▅▅▃▃▅▇
##      8       8        9 ▇▁▁▁▁▁▁▁
##  59391   67257    75123 ▇▇▇▇▇▇▇▇
##    279     284      290 ▇▆▅▅▃▁▂▅
##      1       1        5 ▇▁▁▁▁▁▁▁
##  19438   24672    29883 ▆▁▁▇▇▇▇▇
##      5       5        5 ▁▁▁▇▁▁▁▁
##      6       9       10 ▃▁▅▁▃▂▂▇
## 
## ── Variable type:logical ─────────────────────────────────────────────────────────────────────────
##         variable missing complete     n mean                        count
##  onlineorderflag       0    31465 31465 0.88 TRU: 27659, FAL: 3806, NA: 0
## 
## ── Variable type:numeric ─────────────────────────────────────────────────────────────────────────
##  variable missing complete     n    mean       sd    p0   p25    p50
##   freight       0    31465 31465  101.17   339.08 0.034  1.42  19.57
##  subtotal       0    31465 31465 3491.07 11093.45 1.37  56.97 782.99
##    taxamt       0    31465 31465  323.76  1085.05 0.11   4.56  62.64
##  totaldue       0    31465 31465 3916    12515.46 1.52  62.95 865.2 
##      p75      p100     hist
##    59.25   5608.91 ▇▁▁▁▁▁▁▁
##  2366.96 163930.39 ▇▁▁▁▁▁▁▁
##   189.6   17948.52 ▇▁▁▁▁▁▁▁
##  2615.49 187487.83 ▇▁▁▁▁▁▁▁
## 
## ── Variable type:POSIXct ─────────────────────────────────────────────────────────────────────────
##      variable missing complete     n        min        max     median
##       duedate       0    31465 31465 2011-06-12 2014-07-12 2013-11-15
##  modifieddate       0    31465 31465 2011-06-07 2014-07-07 2013-11-10
##     orderdate       0    31465 31465 2011-05-31 2014-06-30 2013-11-03
##      shipdate       0    31465 31465 2011-06-07 2014-07-07 2013-11-10
##  n_unique
##      1124
##      1124
##      1124
##      1124
```

```r
skimr::skim_to_wide(salesorderheader_tibble) #skimr doesn't like certain kinds of columns
```

```
## # A tibble: 25 x 19
##    type  variable missing complete n     min   max   empty n_unique mean 
##    <chr> <chr>    <chr>   <chr>    <chr> <chr> <chr> <chr> <chr>    <chr>
##  1 char… account… 0       31465    31465 14    14    0     19119    <NA> 
##  2 char… comment  31465   0        31465 NA    NA    0     0        <NA> 
##  3 char… creditc… 1131    30334    31465 9     15    0     30334    <NA> 
##  4 char… purchas… 27659   3806     31465 10    13    0     3806     <NA> 
##  5 char… rowguid  0       31465    31465 36    36    0     31465    <NA> 
##  6 inte… billtoa… 0       31465    31465 <NA>  <NA>  <NA>  <NA>     1826…
##  7 inte… creditc… 1131    30334    31465 <NA>  <NA>  <NA>  <NA>     " 96…
##  8 inte… currenc… 17489   13976    31465 <NA>  <NA>  <NA>  <NA>     " 91…
##  9 inte… custome… 0       31465    31465 <NA>  <NA>  <NA>  <NA>     2017…
## 10 inte… revisio… 0       31465    31465 <NA>  <NA>  <NA>  <NA>     "   …
## # … with 15 more rows, and 9 more variables: sd <chr>, p0 <chr>,
## #   p25 <chr>, p50 <chr>, p75 <chr>, p100 <chr>, hist <chr>, count <chr>,
## #   median <chr>
```

### Close the connection and shut down adventureworks

Where you place the `collect` function matters.

```r
DBI::dbDisconnect(con)
sqlpetr::sp_docker_stop("adventureworks")
```

## Additional reading

* [@Wickham2018]
* [@Baumer2018]

