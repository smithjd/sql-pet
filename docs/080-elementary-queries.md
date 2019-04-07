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
  seconds_to_test = 30, connection_tab = TRUE
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
DBI::dbListFields(con, "film")
```

```
##  [1] "film_id"          "title"            "description"     
##  [4] "release_year"     "language_id"      "rental_duration" 
##  [7] "rental_rate"      "length"           "replacement_cost"
## [10] "rating"           "last_update"      "special_features"
## [13] "fulltext"
```

### Listing all the fields for all the tables

The first example, `DBI::dbListTables(con)` returned 22 tables and the second example, `DBI::dbListFields(con, "film")` returns 7 fields.  Here we combine the two calls to return a list of tables which has a list of all the fields in the table.  The code block just shows the first two tables.


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
film_tibble <- DBI::dbReadTable(con, "film")
str(film_tibble)
```

```
## 'data.frame':	1000 obs. of  13 variables:
##  $ film_id         : int  133 384 8 98 1 2 3 4 5 6 ...
##  $ title           : chr  "Chamber Italian" "Grosse Wonderful" "Airport Pollock" "Bright Encounters" ...
##  $ description     : chr  "A Fateful Reflection of a Moose And a Husband who must Overcome a Monkey in Nigeria" "A Epic Drama of a Cat And a Explorer who must Redeem a Moose in Australia" "A Epic Tale of a Moose And a Girl who must Confront a Monkey in Ancient India" "A Fateful Yarn of a Lumberjack And a Feminist who must Conquer a Student in A Jet Boat" ...
##  $ release_year    : int  2006 2006 2006 2006 2006 2006 2006 2006 2006 2006 ...
##  $ language_id     : int  1 1 1 1 1 1 1 1 1 1 ...
##  $ rental_duration : int  7 5 6 4 6 3 7 5 6 3 ...
##  $ rental_rate     : num  4.99 4.99 4.99 4.99 0.99 4.99 2.99 2.99 2.99 2.99 ...
##  $ length          : int  117 49 54 73 86 48 50 117 130 169 ...
##  $ replacement_cost: num  15 20 16 13 21 ...
##  $ rating          : 'pq_mpaa_rating' chr  "NC-17" "R" "R" "PG-13" ...
##  $ last_update     : POSIXct, format: "2013-05-26 14:50:58" "2013-05-26 14:50:58" ...
##  $ special_features: 'pq__text' chr  "{Trailers}" "{\"Behind the Scenes\"}" "{Trailers}" "{Trailers}" ...
##  $ fulltext        : 'pq_tsvector' chr  "'chamber':1 'fate':4 'husband':11 'italian':2 'monkey':16 'moos':8 'must':13 'nigeria':18 'overcom':14 'reflect':5" "'australia':18 'cat':8 'drama':5 'epic':4 'explor':11 'gross':1 'moos':16 'must':13 'redeem':14 'wonder':2" "'airport':1 'ancient':18 'confront':14 'epic':4 'girl':11 'india':19 'monkey':16 'moos':8 'must':13 'pollock':2 'tale':5" "'boat':20 'bright':1 'conquer':14 'encount':2 'fate':4 'feminist':11 'jet':19 'lumberjack':8 'must':13 'student':16 'yarn':5" ...
```
That's very simple, but if the table is large it may not be a good idea, since R is designed to keep the entire table in memory.  Note that the first line of the str() output reports the total number of observations.  

### A table object that can be reused

The `dplyr::tbl` function gives us more control over access to a table by enabling  control over which columns and rows to download.  It creates  an object that might **look** like a data frame, but it's actually a list object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  


```r
film_table <- dplyr::tbl(con, "film")
class(film_table)
```

```
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"         
## [4] "tbl_lazy"         "tbl"
```


### Controlling the number of rows returned

The `collect` function triggers the creation of a tibble and controls the number of rows that the DBMS sends to R.  For more complex queries, the `dplyr::collect()` function provides a mechanism to indicate what's processed on on the dbms server and what's processed by R on the local machine. The chapter on [Lazy Evaluation and Execution Environment](#chapter_lazy-evaluation-and-timing) discusses this issue in detail.

```r
film_table %>% dplyr::collect(n = 3) %>% dim
```

```
## [1]  3 13
```

```r
film_table %>% dplyr::collect(n = 500) %>% dim
```

```
## [1] 500  13
```

### Random rows from the dbms

When the dbms contains many rows, a sample of the data may be plenty for your purposes.  Although `dplyr` has nice functions to sample a data frame that's already in R (e.g., the `sample_n` and `sample_frac` functions), to get a sample from the dbms we have to use `dbGetQuery` to send native SQL to the database. To peek ahead, here is one example of a query that retrieves 20 rows from a 1% sample:


```r
one_percent_sample <- DBI::dbGetQuery(
  con,
  "SELECT film_id, title, rating
  FROM film TABLESAMPLE BERNOULLI(1) LIMIT 20;
  "
)

one_percent_sample
```

```
##    film_id               title rating
## 1      213          Date Speed      R
## 2       33         Apollo Teen  PG-13
## 3       76     Birdcage Casper  NC-17
## 4      127       Cat Coneheads      G
## 5      236 Divine Resurrection      R
## 6      251 Dragonfly Strangers  NC-17
## 7      296      Express Lonely      R
## 8      375  Grail Frankenstein  NC-17
## 9      766       Savannah Town  PG-13
## 10     888      Thin Sagebrush  PG-13
## 11     999   Zoolander Fiction      R
```
**Exact sample of 100 records**

This technique depends on knowing the range of a record index, such as the `film_id` in the `film` table of our `dvdrental` database.

Start by finding the min and max values.

```r
DBI::dbListFields(con, "film")
```

```
##  [1] "film_id"          "title"            "description"     
##  [4] "release_year"     "language_id"      "rental_duration" 
##  [7] "rental_rate"      "length"           "replacement_cost"
## [10] "rating"           "last_update"      "special_features"
## [13] "fulltext"
```

```r
film_df <- DBI::dbReadTable(con, "film")

max(film_df$film_id)
```

```
## [1] 1000
```

```r
min(film_df$film_id)
```

```
## [1] 1
```

Set the random number seed and draw the sample.

```r
set.seed(123)
sample_rows <- sample(1:1000, 100)
film_table <- dplyr::tbl(con, "film")
```

Run query with the filter verb listing the randomly sampled rows to be retrieved:

```r
film_sample <- film_table %>% 
  dplyr::filter(film_id %in% sample_rows) %>% 
  dplyr::collect()

str(film_sample)
```

```
## Classes 'tbl_df', 'tbl' and 'data.frame':	100 obs. of  13 variables:
##  $ film_id         : int  133 384 1 24 42 44 46 85 90 95 ...
##  $ title           : chr  "Chamber Italian" "Grosse Wonderful" "Academy Dinosaur" "Analyze Hoosiers" ...
##  $ description     : chr  "A Fateful Reflection of a Moose And a Husband who must Overcome a Monkey in Nigeria" "A Epic Drama of a Cat And a Explorer who must Redeem a Moose in Australia" "A Epic Drama of a Feminist And a Mad Scientist who must Battle a Teacher in The Canadian Rockies" "A Thoughtful Display of a Explorer And a Pastry Chef who must Overcome a Feminist in The Sahara Desert" ...
##  $ release_year    : int  2006 2006 2006 2006 2006 2006 2006 2006 2006 2006 ...
##  $ language_id     : int  1 1 1 1 1 1 1 1 1 1 ...
##  $ rental_duration : int  7 5 6 6 5 5 3 4 3 5 ...
##  $ rental_rate     : num  4.99 4.99 0.99 2.99 2.99 4.99 4.99 0.99 0.99 4.99 ...
##  $ length          : int  117 49 86 181 170 113 108 63 63 123 ...
##  $ replacement_cost: num  15 20 21 20 11 ...
##  $ rating          : 'pq_mpaa_rating' chr  "NC-17" "R" "PG" "R" ...
##  $ last_update     : POSIXct, format: "2013-05-26 14:50:58" "2013-05-26 14:50:58" ...
##  $ special_features: 'pq__text' chr  "{Trailers}" "{\"Behind the Scenes\"}" "{\"Deleted Scenes\",\"Behind the Scenes\"}" "{Trailers,\"Behind the Scenes\"}" ...
##  $ fulltext        : 'pq_tsvector' chr  "'chamber':1 'fate':4 'husband':11 'italian':2 'monkey':16 'moos':8 'must':13 'nigeria':18 'overcom':14 'reflect':5" "'australia':18 'cat':8 'drama':5 'epic':4 'explor':11 'gross':1 'moos':16 'must':13 'redeem':14 'wonder':2" "'academi':1 'battl':15 'canadian':20 'dinosaur':2 'drama':5 'epic':4 'feminist':8 'mad':11 'must':14 'rocki':21"| __truncated__ "'analyz':1 'chef':12 'desert':21 'display':5 'explor':8 'feminist':17 'hoosier':2 'must':14 'overcom':15 'pastr"| __truncated__ ...
```


### Sub-setting variables

A table in the dbms may not only have many more rows than you want, but also many more columns.  The `select` command controls which columns are retrieved.

```r
film_table %>% dplyr::select(title, rating) %>% head()
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5439/dvdrental]
##   title             rating              
##   <chr>             <S3: pq_mpaa_rating>
## 1 Chamber Italian   NC-17               
## 2 Grosse Wonderful  R                   
## 3 Airport Pollock   R                   
## 4 Bright Encounters PG-13               
## 5 Academy Dinosaur  PG                  
## 6 Ace Goldfinger    G
```
That's exactly equivalent to submitting the following SQL commands dirctly:

```r
DBI::dbGetQuery(
  con,
  'SELECT "title", "rating"
FROM "film"
LIMIT 6') 
```

```
##               title rating
## 1   Chamber Italian  NC-17
## 2  Grosse Wonderful      R
## 3   Airport Pollock      R
## 4 Bright Encounters  PG-13
## 5  Academy Dinosaur     PG
## 6    Ace Goldfinger      G
```


We won't discuss `dplyr` methods for sub-setting variables, deriving new ones, or sub-setting rows based on the values found in the table, because they are covered well in other places, including:

  * Comprehensive reference: [https://dplyr.tidyverse.org/](https://dplyr.tidyverse.org/)
  * Good tutorial: [https://suzan.rbind.io/tags/dplyr/](https://suzan.rbind.io/tags/dplyr/) 

In practice we find that, **renaming variables** is often quite important because the names in an SQL database might not meet your needs as an analyst.  In "the wild", you will find names that are ambiguous or overly specified, with spaces in them, and other problems that will make them difficult to use in R.  It is good practice to do whatever renaming you are going to do in a predictable place like at the top of your code.  The names in the `dvdrental` database are simple and clear, but if they were not, you might rename them for subsequent use in this way:


```r
tbl(con, "film") %>%
  ## CHANGE STUFF
  dplyr::rename(film_id_number = film_id, 
                language_id_number = language_id) %>% 
  dplyr::select(film_id_number, title, 
                language_id_number) %>%
  # head()
show_query()
```

```
## <SQL>
## SELECT "film_id_number", "title", "language_id_number"
## FROM (SELECT "film_id" AS "film_id_number", "title", "description", "release_year", "language_id" AS "language_id_number", "rental_duration", "rental_rate", "length", "replacement_cost", "rating", "last_update", "special_features", "fulltext"
## FROM "film") "pimymxxpkd"
```
That's equivalent to the following SQL code:

```r
DBI::dbGetQuery(
  con,
  'SELECT "film_id_number", "title", "language_id_number"
FROM (SELECT "film_id" AS "film_id_number", "title", "description",
  "release_year", "language_id" AS "language_id_number", 
  "rental_duration", "rental_rate", "length", "replacement_cost", 
  "rating", "last_update", "special_features", "fulltext"
FROM "film") "yhbysdoypk"
LIMIT 6' )
```

```
##   film_id_number             title language_id_number
## 1            133   Chamber Italian                  1
## 2            384  Grosse Wonderful                  1
## 3              8   Airport Pollock                  1
## 4             98 Bright Encounters                  1
## 5              1  Academy Dinosaur                  1
## 6              2    Ace Goldfinger                  1
```
The one difference is that the `SQL` code returns a regular data frame and the `dplyr` code returns a `tibble`.  Notice that the seconds are greyed out in the `tibble` display.

### Translating `dplyr` code to `SQL` queries

Where did the translations we've shown above come from?  The `show_query` function shows how `dplyr` is translating your query to the dialect of the target dbms:

```r
film_table %>%
  dplyr::tally() %>%
  dplyr::show_query()
```

```
## <SQL>
## SELECT COUNT(*) AS "n"
## FROM "film"
```
Here is an extensive discussion of how `dplyr` code is translated into SQL:

* [https://dbplyr.tidyverse.org/articles/sql-translation.html](https://dbplyr.tidyverse.org/articles/sql-translation.html) 

If you prefer to use SQL directly, rather than `dplyr`, you can submit SQL code to the DBMS through the `DBI::dbGetQuery` function:

```r
DBI::dbGetQuery(
  con,
  'SELECT COUNT(*) AS "n"
     FROM "film"   '
)
```

```
##      n
## 1 1000
```

When you create a report to run repeatedly, you might want to put that query into R markdown. That way you can also execute that SQL code in a chunk with the following header:

  {`sql, connection=con, output.var = "query_results"`}


```sql
SELECT COUNT(*) AS "n"
     FROM "film";
```
Rmarkdown stores that query result in a tibble which can be printed by referring to it:

```r
query_results
```

```
##      n
## 1 1000
```

## Mixing dplyr and SQL

When dplyr finds code that it does not know how to translate into SQL, it will simply pass it along to the dbms. Therefore you can interleave native commands that your dbms will understand in the middle of dplyr code.  Consider this example that's derived from [@Ruiz2019]:


```r
film_table %>%
  dplyr::select_at(vars( -contains("_id"))) %>% 
  dplyr::mutate(today = now()) %>%
  dplyr::show_query()
```

```
## <SQL>
## SELECT "title", "description", "release_year", "rental_duration", "rental_rate", "length", "replacement_cost", "rating", "last_update", "special_features", "fulltext", NOW() AS "today"
## FROM (SELECT "title", "description", "release_year", "rental_duration", "rental_rate", "length", "replacement_cost", "rating", "last_update", "special_features", "fulltext"
## FROM "film") "yhbysdoypk"
```
That is native to PostgreSQL, not [ANSI standard](https://en.wikipedia.org/wiki/SQL#Interoperability_and_standardization) SQL.

Verify that it works:

```r
film_table %>%
  dplyr::select_at(vars( -contains("_id"))) %>% 
  head() %>% 
  dplyr::mutate(today = now()) %>%
  dplyr::collect()
```

```
## # A tibble: 6 x 12
##   title description release_year rental_duration rental_rate length
##   <chr> <chr>              <int>           <int>       <dbl>  <int>
## 1 Cham… A Fateful …         2006               7        4.99    117
## 2 Gros… A Epic Dra…         2006               5        4.99     49
## 3 Airp… A Epic Tal…         2006               6        4.99     54
## 4 Brig… A Fateful …         2006               4        4.99     73
## 5 Acad… A Epic Dra…         2006               6        0.99     86
## 6 Ace … A Astoundi…         2006               3        4.99     48
## # … with 6 more variables: replacement_cost <dbl>, rating <chr>,
## #   last_update <dttm>, special_features <chr>, fulltext <chr>,
## #   today <dttm>
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
str(film_tibble)
```

```
## 'data.frame':	1000 obs. of  13 variables:
##  $ film_id         : int  133 384 8 98 1 2 3 4 5 6 ...
##  $ title           : chr  "Chamber Italian" "Grosse Wonderful" "Airport Pollock" "Bright Encounters" ...
##  $ description     : chr  "A Fateful Reflection of a Moose And a Husband who must Overcome a Monkey in Nigeria" "A Epic Drama of a Cat And a Explorer who must Redeem a Moose in Australia" "A Epic Tale of a Moose And a Girl who must Confront a Monkey in Ancient India" "A Fateful Yarn of a Lumberjack And a Feminist who must Conquer a Student in A Jet Boat" ...
##  $ release_year    : int  2006 2006 2006 2006 2006 2006 2006 2006 2006 2006 ...
##  $ language_id     : int  1 1 1 1 1 1 1 1 1 1 ...
##  $ rental_duration : int  7 5 6 4 6 3 7 5 6 3 ...
##  $ rental_rate     : num  4.99 4.99 4.99 4.99 0.99 4.99 2.99 2.99 2.99 2.99 ...
##  $ length          : int  117 49 54 73 86 48 50 117 130 169 ...
##  $ replacement_cost: num  15 20 16 13 21 ...
##  $ rating          : 'pq_mpaa_rating' chr  "NC-17" "R" "R" "PG-13" ...
##  $ last_update     : POSIXct, format: "2013-05-26 14:50:58" "2013-05-26 14:50:58" ...
##  $ special_features: 'pq__text' chr  "{Trailers}" "{\"Behind the Scenes\"}" "{Trailers}" "{Trailers}" ...
##  $ fulltext        : 'pq_tsvector' chr  "'chamber':1 'fate':4 'husband':11 'italian':2 'monkey':16 'moos':8 'must':13 'nigeria':18 'overcom':14 'reflect':5" "'australia':18 'cat':8 'drama':5 'epic':4 'explor':11 'gross':1 'moos':16 'must':13 'redeem':14 'wonder':2" "'airport':1 'ancient':18 'confront':14 'epic':4 'girl':11 'india':19 'monkey':16 'moos':8 'must':13 'pollock':2 'tale':5" "'boat':20 'bright':1 'conquer':14 'encount':2 'fate':4 'feminist':11 'jet':19 'lumberjack':8 'must':13 'student':16 'yarn':5" ...
```

### Always **look** at your data with `head`, `View`, or `kable`

There is no substitute for looking at your data and R provides several ways to just browse it.  The `head` function controls the number of rows that are displayed.  Note that tail does not work against a database object.  In every-day practice you would look at more than the default 6 rows, but here we wrap `head` around the data frame: 

```r
sqlpetr::sp_print_df(head(film_tibble))
```

<!--html_preserve--><div id="htmlwidget-4f68022fd73b3d133ebb" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-4f68022fd73b3d133ebb">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[133,384,8,98,1,2],["Chamber Italian","Grosse Wonderful","Airport Pollock","Bright Encounters","Academy Dinosaur","Ace Goldfinger"],["A Fateful Reflection of a Moose And a Husband who must Overcome a Monkey in Nigeria","A Epic Drama of a Cat And a Explorer who must Redeem a Moose in Australia","A Epic Tale of a Moose And a Girl who must Confront a Monkey in Ancient India","A Fateful Yarn of a Lumberjack And a Feminist who must Conquer a Student in A Jet Boat","A Epic Drama of a Feminist And a Mad Scientist who must Battle a Teacher in The Canadian Rockies","A Astounding Epistle of a Database Administrator And a Explorer who must Find a Car in Ancient China"],[2006,2006,2006,2006,2006,2006],[1,1,1,1,1,1],[7,5,6,4,6,3],[4.99,4.99,4.99,4.99,0.99,4.99],[117,49,54,73,86,48],[14.99,19.99,15.99,12.99,20.99,12.99],["NC-17","R","R","PG-13","PG","G"],["2013-05-26T21:50:58Z","2013-05-26T21:50:58Z","2013-05-26T21:50:58Z","2013-05-26T21:50:58Z","2013-05-26T21:50:58Z","2013-05-26T21:50:58Z"],["{Trailers}","{\"Behind the Scenes\"}","{Trailers}","{Trailers}","{\"Deleted Scenes\",\"Behind the Scenes\"}","{Trailers,\"Deleted Scenes\"}"],["'chamber':1 'fate':4 'husband':11 'italian':2 'monkey':16 'moos':8 'must':13 'nigeria':18 'overcom':14 'reflect':5","'australia':18 'cat':8 'drama':5 'epic':4 'explor':11 'gross':1 'moos':16 'must':13 'redeem':14 'wonder':2","'airport':1 'ancient':18 'confront':14 'epic':4 'girl':11 'india':19 'monkey':16 'moos':8 'must':13 'pollock':2 'tale':5","'boat':20 'bright':1 'conquer':14 'encount':2 'fate':4 'feminist':11 'jet':19 'lumberjack':8 'must':13 'student':16 'yarn':5","'academi':1 'battl':15 'canadian':20 'dinosaur':2 'drama':5 'epic':4 'feminist':8 'mad':11 'must':14 'rocki':21 'scientist':12 'teacher':17","'ace':1 'administr':9 'ancient':19 'astound':4 'car':17 'china':20 'databas':8 'epistl':5 'explor':12 'find':15 'goldfing':2 'must':14"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>description<\/th>\n      <th>release_year<\/th>\n      <th>language_id<\/th>\n      <th>rental_duration<\/th>\n      <th>rental_rate<\/th>\n      <th>length<\/th>\n      <th>replacement_cost<\/th>\n      <th>rating<\/th>\n      <th>last_update<\/th>\n      <th>special_features<\/th>\n      <th>fulltext<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5,6,7,8,9]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### The `summary` function in `base`

The `base` package's `summary` function provides basic statistics that serve a unique diagnostic purpose in this context. For example, the following output shows that:

    * `film_id` is a number from 1 to 16,049. In a previous section, we ran the `str` function and saw that there are 16,044 observations in this table. Therefore, the `film_id` seems to be sequential from 1:16049, but there are 5 values missing from that sequence. _Exercise for the Reader_: Which 5 values from 1:16049 are missing from `film_id` values in the `film` table? (_Hint_: In the chapter on SQL Joins, you will learn the functions needed to answer this question.)
    * The number of NA's in the `return_date` column is a good first guess as to the number of DVDs rented out or lost as of 2005-09-02 02:35:22.


```r
summary(film_tibble)
```

```
##     film_id          title           description         release_year 
##  Min.   :   1.0   Length:1000        Length:1000        Min.   :2006  
##  1st Qu.: 250.8   Class :character   Class :character   1st Qu.:2006  
##  Median : 500.5   Mode  :character   Mode  :character   Median :2006  
##  Mean   : 500.5                                         Mean   :2006  
##  3rd Qu.: 750.2                                         3rd Qu.:2006  
##  Max.   :1000.0                                         Max.   :2006  
##   language_id rental_duration  rental_rate       length     
##  Min.   :1    Min.   :3.000   Min.   :0.99   Min.   : 46.0  
##  1st Qu.:1    1st Qu.:4.000   1st Qu.:0.99   1st Qu.: 80.0  
##  Median :1    Median :5.000   Median :2.99   Median :114.0  
##  Mean   :1    Mean   :4.985   Mean   :2.98   Mean   :115.3  
##  3rd Qu.:1    3rd Qu.:6.000   3rd Qu.:4.99   3rd Qu.:149.2  
##  Max.   :1    Max.   :7.000   Max.   :4.99   Max.   :185.0  
##  replacement_cost    rating                last_update                 
##  Min.   : 9.99    Length:1000             Min.   :2013-05-26 14:50:58  
##  1st Qu.:14.99    Class :pq_mpaa_rating   1st Qu.:2013-05-26 14:50:58  
##  Median :19.99    Mode  :character        Median :2013-05-26 14:50:58  
##  Mean   :19.98                            Mean   :2013-05-26 14:50:58  
##  3rd Qu.:24.99                            3rd Qu.:2013-05-26 14:50:58  
##  Max.   :29.99                            Max.   :2013-05-26 14:50:58  
##  special_features     fulltext          
##  Length:1000        Length:1000         
##  Class :pq__text    Class :pq_tsvector  
##  Mode  :character   Mode  :character    
##                                         
##                                         
## 
```

So the `summary` function is surprisingly useful as we first start to look at the table contents.

### The `glimpse` function in the `tibble` package

The `tibble` package's `glimpse` function is a more compact version of `str`:

```r
tibble::glimpse(film_tibble)
```

```
## Observations: 1,000
## Variables: 13
## $ film_id          <int> 133, 384, 8, 98, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11…
## $ title            <chr> "Chamber Italian", "Grosse Wonderful", "Airport…
## $ description      <chr> "A Fateful Reflection of a Moose And a Husband …
## $ release_year     <int> 2006, 2006, 2006, 2006, 2006, 2006, 2006, 2006,…
## $ language_id      <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
## $ rental_duration  <int> 7, 5, 6, 4, 6, 3, 7, 5, 6, 3, 6, 3, 6, 6, 6, 4,…
## $ rental_rate      <dbl> 4.99, 4.99, 4.99, 4.99, 0.99, 4.99, 2.99, 2.99,…
## $ length           <int> 117, 49, 54, 73, 86, 48, 50, 117, 130, 169, 62,…
## $ replacement_cost <dbl> 14.99, 19.99, 15.99, 12.99, 20.99, 12.99, 18.99…
## $ rating           <chr> "NC-17", "R", "R", "PG-13", "PG", "G", "NC-17",…
## $ last_update      <dttm> 2013-05-26 14:50:58, 2013-05-26 14:50:58, 2013…
## $ special_features <chr> "{Trailers}", "{\"Behind the Scenes\"}", "{Trai…
## $ fulltext         <chr> "'chamber':1 'fate':4 'husband':11 'italian':2 …
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
skimr::skim(film_tibble)
```

```
## Warning: No summary functions for vectors of class: pq_mpaa_rating.
## Coercing to character
```

```
## Warning: No summary functions for vectors of class: pq__text.
## Coercing to character
```

```
## Warning: No summary functions for vectors of class: pq_tsvector.
## Coercing to character
```

```
## Skim summary statistics
##  n obs: 1000 
##  n variables: 13 
## 
## ── Variable type:character ─────────────────────────────────────────────────────────
##          variable missing complete    n min max empty n_unique
##       description       0     1000 1000  70 130     0     1000
##          fulltext       0     1000 1000  98 205     0     1000
##            rating       0     1000 1000   1   5     0        5
##  special_features       0     1000 1000  10  60     0       15
##             title       0     1000 1000   8  27     0     1000
## 
## ── Variable type:integer ───────────────────────────────────────────────────────────
##         variable missing complete    n    mean     sd   p0     p25    p50
##          film_id       0     1000 1000  500.5  288.82    1  250.75  500.5
##      language_id       0     1000 1000    1      0       1    1       1  
##           length       0     1000 1000  115.27  40.43   46   80     114  
##     release_year       0     1000 1000 2006      0    2006 2006    2006  
##  rental_duration       0     1000 1000    4.99   1.41    3    4       5  
##      p75 p100     hist
##   750.25 1000 ▇▇▇▇▇▇▇▇
##     1       1 ▁▁▁▇▁▁▁▁
##   149.25  185 ▇▇▆▇▆▇▆▇
##  2006    2006 ▁▁▁▇▁▁▁▁
##     6       7 ▇▇▁▇▁▇▁▇
## 
## ── Variable type:numeric ───────────────────────────────────────────────────────────
##          variable missing complete    n  mean   sd    p0   p25   p50   p75
##       rental_rate       0     1000 1000  2.98 1.65  0.99  0.99  2.99  4.99
##  replacement_cost       0     1000 1000 19.98 6.05  9.99 14.99 19.99 24.99
##   p100     hist
##   4.99 ▇▁▁▇▁▁▁▇
##  29.99 ▇▇▃▇▆▇▅▇
## 
## ── Variable type:POSIXct ───────────────────────────────────────────────────────────
##     variable missing complete    n        min        max     median
##  last_update       0     1000 1000 2013-05-26 2013-05-26 2013-05-26
##  n_unique
##         1
```

```r
skimr::skim_to_wide(film_tibble[,1:7]) #skimr doesn't like certain kinds of columns
```

```
## # A tibble: 7 x 17
##   type  variable missing complete n     min   max   empty n_unique mean 
##   <chr> <chr>    <chr>   <chr>    <chr> <chr> <chr> <chr> <chr>    <chr>
## 1 char… descrip… 0       1000     1000  70    130   0     1000     <NA> 
## 2 char… title    0       1000     1000  8     27    0     1000     <NA> 
## 3 inte… film_id  0       1000     1000  <NA>  <NA>  <NA>  <NA>     " 50…
## 4 inte… languag… 0       1000     1000  <NA>  <NA>  <NA>  <NA>     "   …
## 5 inte… release… 0       1000     1000  <NA>  <NA>  <NA>  <NA>     "200…
## 6 inte… rental_… 0       1000     1000  <NA>  <NA>  <NA>  <NA>     "   …
## 7 nume… rental_… 0       1000     1000  <NA>  <NA>  <NA>  <NA>     2.98 
## # … with 7 more variables: sd <chr>, p0 <chr>, p25 <chr>, p50 <chr>,
## #   p75 <chr>, p100 <chr>, hist <chr>
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

