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
dbExecute(con, "set search_path to humanresources, public;") # watch for duplicates!
```

```
## [1] 0
```

```r
employee_tibble <- DBI::dbReadTable(con, "employee")
# employee_tibble <- DBI::dbReadTable(con, in_schema("humanresources", "employee"))
str(employee_tibble)
```

```
## 'data.frame':	290 obs. of  15 variables:
##  $ businessentityid: int  1 2 3 4 5 6 7 8 9 10 ...
##  $ nationalidnumber: chr  "295847284" "245797967" "509647174" "112457891" ...
##  $ loginid         : chr  "adventure-works\\ken0" "adventure-works\\terri0" "adventure-works\\roberto0" "adventure-works\\rob0" ...
##  $ jobtitle        : chr  "Chief Executive Officer" "Vice President of Engineering" "Engineering Manager" "Senior Tool Designer" ...
##  $ birthdate       : Date, format: "1969-01-29" "1971-08-01" ...
##  $ maritalstatus   : chr  "S" "S" "M" "S" ...
##  $ gender          : chr  "M" "F" "M" "M" ...
##  $ hiredate        : Date, format: "2009-01-14" "2008-01-31" ...
##  $ salariedflag    : logi  TRUE TRUE TRUE FALSE TRUE TRUE ...
##  $ vacationhours   : int  99 1 2 48 5 6 61 62 63 16 ...
##  $ sickleavehours  : int  69 20 21 80 22 23 50 51 51 64 ...
##  $ currentflag     : logi  TRUE TRUE TRUE TRUE TRUE TRUE ...
##  $ rowguid         : chr  "f01251e5-96a3-448d-981e-0f99d789110d" "45e8f437-670d-4409-93cb-f9424a40d6ee" "9bbbfb2c-efbb-4217-9ab7-f97689328841" "59747955-87b8-443f-8ed4-f8ad3afdf3a9" ...
##  $ modifieddate    : POSIXct, format: "2014-06-30 00:00:00" "2014-06-30 00:00:00" ...
##  $ organizationnode: chr  "/" "/1/" "/1/1/" "/1/1/1/" ...
```
That's very simple, but if the table is large it may not be a good idea, since R is designed to keep the entire table in memory.  Note that the first line of the str() output reports the total number of observations.  

### A table *object* that can be reused

The `dplyr::tbl` function gives us more control over access to a table by enabling  control over which columns and rows to download.  It creates  an object that might **look** like a data frame, but it's actually a list object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  


```r
employee_table <- dplyr::tbl(con, "employee")
class(employee_table)
```

```
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"         
## [4] "tbl_lazy"         "tbl"
```


### Controlling the number of rows returned

The `collect` function triggers the creation of a tibble and controls the number of rows that the DBMS sends to R.  For more complex queries, the `dplyr::collect()` function provides a mechanism to indicate what's processed on on the dbms server and what's processed by R on the local machine. The chapter on [Lazy Evaluation and Execution Environment](#chapter_lazy-evaluation-and-timing) discusses this issue in detail.

```r
employee_table %>% dplyr::collect(n = 3) %>% dim
```

```
## [1]  3 15
```

```r
employee_table %>% dplyr::collect(n = 500) %>% dim
```

```
## [1] 290  15
```

### Random rows from the dbms

When the dbms contains many rows, a sample of the data may be plenty for your purposes.  Although `dplyr` has nice functions to sample a data frame that's already in R (e.g., the `sample_n` and `sample_frac` functions), to get a sample from the dbms we have to use `dbGetQuery` to send native SQL to the database. To peek ahead, here is one example of a query that retrieves 20 rows from a 1% sample:


```r
one_percent_sample <- DBI::dbGetQuery(
  con,
  "SELECT businessentityid, jobtitle, birthdate
  FROM employee TABLESAMPLE BERNOULLI(3) LIMIT 20;
  "
)

one_percent_sample
```

```
<<<<<<< HEAD
##    businessentityid                                 jobtitle  birthdate
## 1                93             Production Supervisor - WC50 1980-04-28
## 2                96             Production Technician - WC50 1990-01-25
## 3               119             Production Technician - WC50 1989-06-15
## 4               159             Production Technician - WC20 1984-12-08
## 5               177             Production Technician - WC30 1982-02-11
## 6               182             Production Technician - WC20 1986-12-01
## 7               206             Production Technician - WC45 1962-09-13
## 8               218                       Control Specialist 1990-04-28
## 9               222                         Master Scheduler 1968-09-17
## 10              237 Human Resources Administrative Assistant 1977-04-17
## 11              266                    Network Administrator 1980-05-28
## 12              271                   Database Administrator 1976-01-06
## 13              287                   European Sales Manager 1957-09-20
=======
##    businessentityid                     jobtitle  birthdate
## 1                22         Marketing Specialist 1987-05-21
## 2                33 Production Technician - WC60 1976-12-26
## 3                44 Production Technician - WC60 1990-05-17
## 4                78 Production Supervisor - WC40 1987-08-27
## 5                88 Production Technician - WC10 1966-12-17
## 6                89 Production Technician - WC10 1986-09-10
## 7               109 Production Technician - WC50 1978-01-26
## 8               134 Production Supervisor - WC20 1985-01-19
## 9               135 Production Technician - WC20 1982-01-03
## 10              164 Production Technician - WC45 1988-09-24
## 11              205 Production Supervisor - WC45 1980-07-18
## 12              259                        Buyer 1973-06-03
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
```
**Exact sample of 100 records**

This technique depends on knowing the range of a record index, such as the `businessentityid` in the `employee` table of our `adventureworks` database.

Start by finding the min and max values.

```r
DBI::dbListFields(con, "employee")
```

```
##  [1] "businessentityid" "nationalidnumber" "loginid"         
##  [4] "jobtitle"         "birthdate"        "maritalstatus"   
##  [7] "gender"           "hiredate"         "salariedflag"    
## [10] "vacationhours"    "sickleavehours"   "currentflag"     
## [13] "rowguid"          "modifieddate"     "organizationnode"
```

```r
employee_df <- DBI::dbReadTable(con, "employee")

max(employee_df$businessentityid)
```

```
## [1] 290
```

```r
min(employee_df$businessentityid)
```

```
## [1] 1
```

Set the random number seed and draw the sample.

```r
set.seed(123)
sample_rows <- sample(1:max(employee_df$businessentityid), 10)
employee_table <- dplyr::tbl(con, "employee")
```

Run query with the filter verb listing the randomly sampled rows to be retrieved:

```r
employee_sample <- employee_table %>% 
  dplyr::filter(businessentityid %in% sample_rows) %>% 
  dplyr::collect()

str(employee_sample)
```

```
## Classes 'tbl_df', 'tbl' and 'data.frame':	10 obs. of  15 variables:
##  $ businessentityid: int  14 90 91 118 153 179 195 229 244 289
##  $ nationalidnumber: chr  "42487730" "82638150" "390124815" "222400012" ...
##  $ loginid         : chr  "adventure-works\\michael8" "adventure-works\\danielle0" "adventure-works\\kimberly0" "adventure-works\\don0" ...
##  $ jobtitle        : chr  "Senior Design Engineer" "Production Technician - WC10" "Production Technician - WC10" "Production Technician - WC50" ...
##  $ birthdate       : Date, format: "1979-06-16" "1986-09-07" ...
##  $ maritalstatus   : chr  "S" "S" "S" "M" ...
##  $ gender          : chr  "M" "F" "F" "M" ...
##  $ hiredate        : Date, format: "2010-12-30" "2010-02-20" ...
##  $ salariedflag    : logi  TRUE FALSE FALSE FALSE FALSE FALSE ...
##  $ vacationhours   : int  3 97 95 88 15 30 58 90 62 37
##  $ sickleavehours  : int  21 68 67 64 27 35 49 65 51 38
##  $ currentflag     : logi  TRUE TRUE TRUE TRUE TRUE TRUE ...
##  $ rowguid         : chr  "46286ca4-46dd-4ddb-9128-85b67e98d1a9" "bb886159-1400-4264-b7c9-a3769beb1274" "ce256b6c-1eee-43ed-9969-7cac480ff4d7" "e720053d-922e-4c91-b81a-a1ca4ef8bb0e" ...
##  $ modifieddate    : POSIXct, format: "2014-06-30" "2014-06-30" ...
##  $ organizationnode: chr  "/1/1/6/" "/3/1/8/3/" "/3/1/8/4/" "/3/1/11/10/" ...
```


### Sub-setting variables

A table in the dbms may not only have many more rows than you want, but also many more columns.  The `select` command controls which columns are retrieved.

```r
employee_table %>% dplyr::select(businessentityid, jobtitle, birthdate) %>% head()
```

```
## # Source:   lazy query [?? x 3]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   businessentityid jobtitle                      birthdate 
##              <int> <chr>                         <date>    
## 1                1 Chief Executive Officer       1969-01-29
## 2                2 Vice President of Engineering 1971-08-01
## 3                3 Engineering Manager           1974-11-12
## 4                4 Senior Tool Designer          1974-12-23
## 5                5 Design Engineer               1952-09-27
## 6                6 Design Engineer               1959-03-11
```
That's exactly equivalent to submitting the following SQL commands dirctly:

```r
DBI::dbGetQuery(
  con,
  'SELECT "businessentityid", "jobtitle", "birthdate"
FROM "employee"
LIMIT 6') 
```

```
##   businessentityid                      jobtitle  birthdate
## 1                1       Chief Executive Officer 1969-01-29
## 2                2 Vice President of Engineering 1971-08-01
## 3                3           Engineering Manager 1974-11-12
## 4                4          Senior Tool Designer 1974-12-23
## 5                5               Design Engineer 1952-09-27
## 6                6               Design Engineer 1959-03-11
```


We won't discuss `dplyr` methods for sub-setting variables, deriving new ones, or sub-setting rows based on the values found in the table, because they are covered well in other places, including:

  * Comprehensive reference: [https://dplyr.tidyverse.org/](https://dplyr.tidyverse.org/)
  * Good tutorial: [https://suzan.rbind.io/tags/dplyr/](https://suzan.rbind.io/tags/dplyr/) 

In practice we find that, **renaming variables** is often quite important because the names in an SQL database might not meet your needs as an analyst.  In "the wild", you will find names that are ambiguous or overly specified, with spaces in them, and other problems that will make them difficult to use in R.  It is good practice to do whatever renaming you are going to do in a predictable place like at the top of your code.  The names in the `adventureworks` database are simple and clear, but if they were not, you might rename them for subsequent use in this way:


```r
tbl(con, "employee") %>%
  dplyr::rename(businessentity_id_number = businessentityid, 
                employee_job_title = jobtitle) %>% 
  dplyr::select(businessentity_id_number, employee_job_title, birthdate) %>%
  # head()
show_query()
```

```
## <SQL>
## SELECT "businessentityid" AS "businessentity_id_number", "jobtitle" AS "employee_job_title", "birthdate"
## FROM "employee"
```
That's equivalent to the following SQL code:

```r
DBI::dbGetQuery(
  con,
  'SELECT "businessentityid" AS "businessentity_id_number", "jobtitle" AS "employee_job_title", "birthdate"
FROM "employee" 
LIMIT 6' )
```

```
##   businessentity_id_number            employee_job_title  birthdate
## 1                        1       Chief Executive Officer 1969-01-29
## 2                        2 Vice President of Engineering 1971-08-01
## 3                        3           Engineering Manager 1974-11-12
## 4                        4          Senior Tool Designer 1974-12-23
## 5                        5               Design Engineer 1952-09-27
## 6                        6               Design Engineer 1959-03-11
```
The one difference is that the `SQL` code returns a regular data frame and the `dplyr` code returns a `tibble`.  Notice that the seconds are greyed out in the `tibble` display.

### Translating `dplyr` code to `SQL` queries

Where did the translations we've shown above come from?  The `show_query` function shows how `dplyr` is translating your query to the dialect of the target dbms:

```r
employee_table %>%
  dplyr::tally() %>%
  dplyr::show_query()
```

```
## <SQL>
## SELECT COUNT(*) AS "n"
## FROM "employee"
```
Here is an extensive discussion of how `dplyr` code is translated into SQL:

* [https://dbplyr.tidyverse.org/articles/sql-translation.html](https://dbplyr.tidyverse.org/articles/sql-translation.html) 

If you prefer to use SQL directly, rather than `dplyr`, you can submit SQL code to the DBMS through the `DBI::dbGetQuery` function:

```r
DBI::dbGetQuery(
  con,
  'SELECT COUNT(*) AS "n"
     FROM "employee"   '
)
```

```
##     n
## 1 290
```

When you create a report to run repeatedly, you might want to put that query into R markdown. That way you can also execute that SQL code in a chunk with the following header:

  {`sql, connection=con, output.var = "query_results"`}


```sql
SELECT COUNT(*) AS "n"
     FROM "employee";
```
Rmarkdown stores that query result in a tibble which can be printed by referring to it:

```r
query_results
```

```
##     n
## 1 290
```

## Mixing dplyr and SQL

When dplyr finds code that it does not know how to translate into SQL, it will simply pass it along to the dbms. Therefore you can interleave native commands that your dbms will understand in the middle of dplyr code.  Consider this example that's derived from [@Ruiz2019]:


```r
employee_table %>%
  dplyr::select_at(vars(jobtitle, contains("hours"))) %>% 
  dplyr::mutate(today = now()) %>%
  dplyr::show_query()
```

```
## <SQL>
## SELECT "jobtitle", "vacationhours", "sickleavehours", CURRENT_TIMESTAMP AS "today"
## FROM "employee"
```
That is native to PostgreSQL, not [ANSI standard](https://en.wikipedia.org/wiki/SQL#Interoperability_and_standardization) SQL.

Verify that it works:

```r
employee_table %>%
  dplyr::select_at(vars(jobtitle, contains("hours"))) %>% 
  head() %>% 
  dplyr::mutate(today = now()) %>%
  dplyr::collect()
```

```
## # A tibble: 6 x 4
##   jobtitle                 vacationhours sickleavehours today              
##   <chr>                            <int>          <int> <dttm>             
<<<<<<< HEAD
## 1 Chief Executive Officer             99             69 2019-08-10 09:15:53
## 2 Vice President of Engin…             1             20 2019-08-10 09:15:53
## 3 Engineering Manager                  2             21 2019-08-10 09:15:53
## 4 Senior Tool Designer                48             80 2019-08-10 09:15:53
## 5 Design Engineer                      5             22 2019-08-10 09:15:53
## 6 Design Engineer                      6             23 2019-08-10 09:15:53
=======
## 1 Chief Executive Officer             99             69 2019-08-23 15:42:01
## 2 Vice President of Engin…             1             20 2019-08-23 15:42:01
## 3 Engineering Manager                  2             21 2019-08-23 15:42:01
## 4 Senior Tool Designer                48             80 2019-08-23 15:42:01
## 5 Design Engineer                      5             22 2019-08-23 15:42:01
## 6 Design Engineer                      6             23 2019-08-23 15:42:01
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
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
str(employee_tibble)
```

```
## 'data.frame':	290 obs. of  15 variables:
##  $ businessentityid: int  1 2 3 4 5 6 7 8 9 10 ...
##  $ nationalidnumber: chr  "295847284" "245797967" "509647174" "112457891" ...
##  $ loginid         : chr  "adventure-works\\ken0" "adventure-works\\terri0" "adventure-works\\roberto0" "adventure-works\\rob0" ...
##  $ jobtitle        : chr  "Chief Executive Officer" "Vice President of Engineering" "Engineering Manager" "Senior Tool Designer" ...
##  $ birthdate       : Date, format: "1969-01-29" "1971-08-01" ...
##  $ maritalstatus   : chr  "S" "S" "M" "S" ...
##  $ gender          : chr  "M" "F" "M" "M" ...
##  $ hiredate        : Date, format: "2009-01-14" "2008-01-31" ...
##  $ salariedflag    : logi  TRUE TRUE TRUE FALSE TRUE TRUE ...
##  $ vacationhours   : int  99 1 2 48 5 6 61 62 63 16 ...
##  $ sickleavehours  : int  69 20 21 80 22 23 50 51 51 64 ...
##  $ currentflag     : logi  TRUE TRUE TRUE TRUE TRUE TRUE ...
##  $ rowguid         : chr  "f01251e5-96a3-448d-981e-0f99d789110d" "45e8f437-670d-4409-93cb-f9424a40d6ee" "9bbbfb2c-efbb-4217-9ab7-f97689328841" "59747955-87b8-443f-8ed4-f8ad3afdf3a9" ...
##  $ modifieddate    : POSIXct, format: "2014-06-30 00:00:00" "2014-06-30 00:00:00" ...
##  $ organizationnode: chr  "/" "/1/" "/1/1/" "/1/1/1/" ...
```

### Always **look** at your data with `head`, `View`, or `kable`

There is no substitute for looking at your data and R provides several ways to just browse it.  The `head` function controls the number of rows that are displayed.  Note that tail does not work against a database object.  In every-day practice you would look at more than the default 6 rows, but here we wrap `head` around the data frame: 

```r
sqlpetr::sp_print_df(head(employee_tibble))
```

<!--html_preserve--><div id="htmlwidget-ffc4f25ab85bf888dc62" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-ffc4f25ab85bf888dc62">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,2,3,4,5,6],["295847284","245797967","509647174","112457891","695256908","998320692"],["adventure-works\\ken0","adventure-works\\terri0","adventure-works\\roberto0","adventure-works\\rob0","adventure-works\\gail0","adventure-works\\jossef0"],["Chief Executive Officer","Vice President of Engineering","Engineering Manager","Senior Tool Designer","Design Engineer","Design Engineer"],["1969-01-29","1971-08-01","1974-11-12","1974-12-23","1952-09-27","1959-03-11"],["S","S","M","S","M","M"],["M","F","M","M","F","M"],["2009-01-14","2008-01-31","2007-11-11","2007-12-05","2008-01-06","2008-01-24"],[true,true,true,false,true,true],[99,1,2,48,5,6],[69,20,21,80,22,23],[true,true,true,true,true,true],["f01251e5-96a3-448d-981e-0f99d789110d","45e8f437-670d-4409-93cb-f9424a40d6ee","9bbbfb2c-efbb-4217-9ab7-f97689328841","59747955-87b8-443f-8ed4-f8ad3afdf3a9","ec84ae09-f9b8-4a15-b4a9-6ccbab919b08","e39056f1-9cd5-478d-8945-14aca7fbdcdd"],["2014-06-30T07:00:00Z","2014-06-30T07:00:00Z","2014-06-30T07:00:00Z","2014-06-30T07:00:00Z","2014-06-30T07:00:00Z","2014-06-30T07:00:00Z"],["/","/1/","/1/1/","/1/1/1/","/1/1/2/","/1/1/3/"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>businessentityid<\/th>\n      <th>nationalidnumber<\/th>\n      <th>loginid<\/th>\n      <th>jobtitle<\/th>\n      <th>birthdate<\/th>\n      <th>maritalstatus<\/th>\n      <th>gender<\/th>\n      <th>hiredate<\/th>\n      <th>salariedflag<\/th>\n      <th>vacationhours<\/th>\n      <th>sickleavehours<\/th>\n      <th>currentflag<\/th>\n      <th>rowguid<\/th>\n      <th>modifieddate<\/th>\n      <th>organizationnode<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,10,11]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### The `summary` function in `base`

The `base` package's `summary` function provides basic statistics that serve a unique diagnostic purpose in this context. For example, the following output shows that:

    * `businessentityid` is a number from 1 to 16,049. In a previous section, we ran the `str` function and saw that there are 16,044 observations in this table. Therefore, the `businessentityid` seems to be sequential from 1:16049, but there are 5 values missing from that sequence. _Exercise for the Reader_: Which 5 values from 1:16049 are missing from `businessentityid` values in the `employee` table? (_Hint_: In the chapter on SQL Joins, you will learn the functions needed to answer this question.)
    * The number of NA's in the `return_date` column is a good first guess as to the number of DVDs rented out or lost as of 2005-09-02 02:35:22.


```r
summary(employee_tibble)
```

```
##  businessentityid nationalidnumber     loginid            jobtitle        
##  Min.   :  1.00   Length:290         Length:290         Length:290        
##  1st Qu.: 73.25   Class :character   Class :character   Class :character  
##  Median :145.50   Mode  :character   Mode  :character   Mode  :character  
##  Mean   :145.50                                                           
##  3rd Qu.:217.75                                                           
##  Max.   :290.00                                                           
##    birthdate          maritalstatus         gender         
##  Min.   :1951-10-17   Length:290         Length:290        
##  1st Qu.:1973-09-21   Class :character   Class :character  
##  Median :1978-10-19   Mode  :character   Mode  :character  
##  Mean   :1978-07-04                                        
##  3rd Qu.:1986-05-27                                        
##  Max.   :1991-05-31                                        
##     hiredate          salariedflag    vacationhours   sickleavehours 
##  Min.   :2006-06-30   Mode :logical   Min.   : 0.00   Min.   :20.00  
##  1st Qu.:2008-12-26   FALSE:238       1st Qu.:26.25   1st Qu.:33.00  
##  Median :2009-02-02   TRUE :52        Median :51.00   Median :46.00  
##  Mean   :2009-05-19                   Mean   :50.61   Mean   :45.31  
##  3rd Qu.:2009-10-09                   3rd Qu.:75.00   3rd Qu.:58.00  
##  Max.   :2013-05-30                   Max.   :99.00   Max.   :80.00  
##  currentflag      rowguid           modifieddate                
##  Mode:logical   Length:290         Min.   :2014-06-30 00:00:00  
##  TRUE:290       Class :character   1st Qu.:2014-06-30 00:00:00  
##                 Mode  :character   Median :2014-06-30 00:00:00  
##                                    Mean   :2014-07-01 20:32:52  
##                                    3rd Qu.:2014-06-30 00:00:00  
##                                    Max.   :2014-12-26 09:17:08  
##  organizationnode  
##  Length:290        
##  Class :character  
##  Mode  :character  
##                    
##                    
## 
```

So the `summary` function is surprisingly useful as we first start to look at the table contents.

### The `glimpse` function in the `tibble` package

The `tibble` package's `glimpse` function is a more compact version of `str`:

```r
tibble::glimpse(employee_tibble)
```

```
## Observations: 290
## Variables: 15
## $ businessentityid <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, …
## $ nationalidnumber <chr> "295847284", "245797967", "509647174", "1124578…
## $ loginid          <chr> "adventure-works\\ken0", "adventure-works\\terr…
## $ jobtitle         <chr> "Chief Executive Officer", "Vice President of E…
## $ birthdate        <date> 1969-01-29, 1971-08-01, 1974-11-12, 1974-12-23…
## $ maritalstatus    <chr> "S", "S", "M", "S", "M", "M", "M", "S", "M", "M…
## $ gender           <chr> "M", "F", "M", "M", "F", "M", "M", "F", "F", "M…
## $ hiredate         <date> 2009-01-14, 2008-01-31, 2007-11-11, 2007-12-05…
## $ salariedflag     <lgl> TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE…
## $ vacationhours    <int> 99, 1, 2, 48, 5, 6, 61, 62, 63, 16, 7, 9, 8, 3,…
## $ sickleavehours   <int> 69, 20, 21, 80, 22, 23, 50, 51, 51, 64, 23, 24,…
## $ currentflag      <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,…
## $ rowguid          <chr> "f01251e5-96a3-448d-981e-0f99d789110d", "45e8f4…
## $ modifieddate     <dttm> 2014-06-30, 2014-06-30, 2014-06-30, 2014-06-30…
## $ organizationnode <chr> "/", "/1/", "/1/1/", "/1/1/1/", "/1/1/2/", "/1/…
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
skimr::skim(employee_tibble)
```

```
## Skim summary statistics
##  n obs: 290 
##  n variables: 15 
## 
<<<<<<< HEAD
## ── Variable type:character ────────────────────────────────────────────────
=======
## ── Variable type:character ───────────────────────────────────────────────
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
##          variable missing complete   n min max empty n_unique
##            gender       0      290 290   1   1     0        2
##          jobtitle       0      290 290   5  40     0       67
##           loginid       0      290 290  19  28     0      290
##     maritalstatus       0      290 290   1   1     0        2
##  nationalidnumber       0      290 290   5   9     0      290
##  organizationnode       0      290 290   1  11     0      290
##           rowguid       0      290 290  36  36     0      290
## 
<<<<<<< HEAD
## ── Variable type:Date ─────────────────────────────────────────────────────
=======
## ── Variable type:Date ────────────────────────────────────────────────────
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
##   variable missing complete   n        min        max     median n_unique
##  birthdate       0      290 290 1951-10-17 1991-05-31 1978-10-19      275
##   hiredate       0      290 290 2006-06-30 2013-05-30 2009-02-02      164
## 
<<<<<<< HEAD
## ── Variable type:integer ──────────────────────────────────────────────────
=======
## ── Variable type:integer ─────────────────────────────────────────────────
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
##          variable missing complete   n   mean    sd p0   p25   p50    p75
##  businessentityid       0      290 290 145.5  83.86  1 73.25 145.5 217.75
##    sickleavehours       0      290 290  45.31 14.54 20 33     46    58   
##     vacationhours       0      290 290  50.61 28.79  0 26.25  51    75   
##  p100     hist
##   290 ▇▇▇▇▇▇▇▇
##    80 ▇▇▇▇▇▇▃▁
##    99 ▇▆▇▇▇▇▇▇
## 
<<<<<<< HEAD
## ── Variable type:logical ──────────────────────────────────────────────────
=======
## ── Variable type:logical ─────────────────────────────────────────────────
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
##      variable missing complete   n mean                    count
##   currentflag       0      290 290 1             TRU: 290, NA: 0
##  salariedflag       0      290 290 0.18 FAL: 238, TRU: 52, NA: 0
## 
<<<<<<< HEAD
## ── Variable type:POSIXct ──────────────────────────────────────────────────
=======
## ── Variable type:POSIXct ─────────────────────────────────────────────────
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
##      variable missing complete   n        min        max     median
##  modifieddate       0      290 290 2014-06-30 2014-12-26 2014-06-30
##  n_unique
##         2
```

```r
skimr::skim_to_wide(employee_tibble) #skimr doesn't like certain kinds of columns
```

```
## # A tibble: 15 x 19
##    type  variable missing complete n     min   max   empty n_unique median
##    <chr> <chr>    <chr>   <chr>    <chr> <chr> <chr> <chr> <chr>    <chr> 
##  1 char… gender   0       290      290   1     1     0     2        <NA>  
##  2 char… jobtitle 0       290      290   5     40    0     67       <NA>  
##  3 char… loginid  0       290      290   19    28    0     290      <NA>  
##  4 char… marital… 0       290      290   1     1     0     2        <NA>  
##  5 char… nationa… 0       290      290   5     9     0     290      <NA>  
##  6 char… organiz… 0       290      290   1     11    0     290      <NA>  
##  7 char… rowguid  0       290      290   36    36    0     290      <NA>  
##  8 Date  birthda… 0       290      290   1951… 1991… <NA>  275      1978-…
##  9 Date  hiredate 0       290      290   2006… 2013… <NA>  164      2009-…
## 10 inte… busines… 0       290      290   <NA>  <NA>  <NA>  <NA>     <NA>  
## 11 inte… sicklea… 0       290      290   <NA>  <NA>  <NA>  <NA>     <NA>  
## 12 inte… vacatio… 0       290      290   <NA>  <NA>  <NA>  <NA>     <NA>  
## 13 logi… current… 0       290      290   <NA>  <NA>  <NA>  <NA>     <NA>  
## 14 logi… salarie… 0       290      290   <NA>  <NA>  <NA>  <NA>     <NA>  
## 15 POSI… modifie… 0       290      290   2014… 2014… <NA>  2        2014-…
## # … with 9 more variables: mean <chr>, sd <chr>, p0 <chr>, p25 <chr>,
## #   p50 <chr>, p75 <chr>, p100 <chr>, hist <chr>, count <chr>
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

