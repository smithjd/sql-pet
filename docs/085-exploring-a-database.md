# Exploring a database {#chapter_database-exploration}

> This chapter demonstrates how to:
> 
> * Investigate what tables are in the database and what fields a table contains
> * Build up queries

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

## Getting data from the database

As we show later on, the database serves as a store of data and as an engine for sub-setting, joining, and computation on the data.  We begin with getting data from the dbms, or "downloading" data.

### Finding out what's there

We've already seen how the connections tab is the easiest way to explore a database.  

![Adventureworks connections tab](screenshots/adventureworks-connections-tab.png)

It's a little more complex than the `cattle` example because we have additional structure: the `adventureworks` [database contains schemas](https://en.wikipedia.org/wiki/Database_schema), which contain tables.  The `hr` schema is the same as the `humanresources` schema, but with nicknames (the `d` table in `hr` is the same as the `department` table in the `humanresources` schema).  Schemas are used to control access and to set up shortcuts.  Clicking on the the right opens up the table view of the `d` table:

![Adventureworks connections tab](screenshots/adventureworks-hr-dept-table.png)

Exploring a databse using R code is a little more complicated.  The following command does not give you a list of tables as it did in the simpler case when there were no schemas other than the `public` schema:

```r
tables <- DBI::dbListTables(con)
tables
```

```
## character(0)
```

We need to to tell the database which schemas to search

```r
dbExecute(con, "set search_path to hr, humanresources;")
```

```
## [1] 0
```

```r
DBI::dbListTables(con)
```

```
##  [1] "employee"                   "d"                         
##  [3] "shift"                      "e"                         
##  [5] "employeepayhistory"         "edh"                       
##  [7] "eph"                        "jc"                        
##  [9] "jobcandidate"               "s"                         
## [11] "department"                 "vemployee"                 
## [13] "vemployeedepartment"        "vemployeedepartmenthistory"
## [15] "vjobcandidate"              "vjobcandidateeducation"    
## [17] "vjobcandidateemployment"    "employeedepartmenthistory"
```
Notice the way the database designers have abbreviated table names for your convenience.

```r
DBI::dbListFields(con, "d")
```

```
## [1] "id"           "departmentid" "name"         "groupname"   
## [5] "modifieddate"
```

### Listing all the fields for all the tables

The first example, `DBI::dbListTables(con)` returned 22 tables and the second example, `DBI::dbListFields(con, "employee")` returns 7 fields.  Here we combine the two calls to return a list of tables which has a list of all the fields in the table.  The code block just shows the first two tables.


```r
table_columns <- purrr::map(tables, ~ dbListFields(.,conn = con) )
```
Rename each list [[1]] ... [[43]] to meaningful table name

```r
names(table_columns) <- tables

head(table_columns)
```

```
## named list()
```

Later on we'll discuss how to get more extensive data about each table and column from the database's own store of metadata using a similar technique.  As we go further the issue of scale will come up again and again: you need to be careful about how much data a call to the dbms will return, whether it's a list of tables or a table that could have millions of rows.

It's important to connect with people who own, generate, or are the subjects of the data.  A good chat with people who own the data, generate it, or are the subjects can generate insights and set the context for your investigation of the database. The purpose for collecting the data or circumstances where it was collected may be buried far afield in an organization, but *usually someone knows*.  The metadata discussed in a later chapter is essential but will only take you so far.

There are different ways of just **looking at the data**, which we explore below.


### A table object that can be reused

The `dplyr::tbl` function gives us more control over access to a table by enabling  control over which columns and rows to download.  It creates  an object that might **look** like a data frame, but it's actually a list object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  


```r
employee_table <- dplyr::tbl(con, "employee")
class(employee_table)
```

```
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"         
## [4] "tbl_lazy"         "tbl"
```
### Table links for queries

To illustrate the different issues involved in data retrieval, we create more connection objects to link to two other tables.  

```r
employee_table <- tbl(con, in_schema("humanresources", "employee")) %>% 
  select(-modifieddate, -rowguid)
```
The 'employee' table has 290 rows and 13 columns because we dropped `modifieddate` which is a column name that appears in more than one table.  To get the data we want we will usually want to drop or rename duplicates as we connect to each table.


```r
sales_person_table <- tbl(con, in_schema("sales", "salesperson")) %>% 
  select(-rowguid) %>% 
  rename(sale_info_updated = modifieddate)
```
The 'salesperson' table has 17 rows.

Discuss the *person* table here:

```r
person_table <- tbl(con, in_schema("person", "person")) %>% 
  select(-modifieddate, -rowguid)
```
### merge this into the above:
Define two tables to use in a simple query to use in the following discussion.

```r
sales_person_table <- tbl(con, in_schema("sales", "salesperson")) %>% 
  select(-rowguid) %>% 
  rename(sale_info_updated = modifieddate)

employee_table <- tbl(con, in_schema("humanresources", "employee")) %>% 
  select(-modifieddate, -rowguid)
```

Here is a simple string of `dplyr` verbs similar to the query used to illustrate issues in the last chapter:


```r
Q <- tbl(con, in_schema("sales", "salesperson")) %>%
  left_join(tbl(con, in_schema("humanresources", "employee")), 
            by = c("businessentityid" = "businessentityid")) %>%
  dplyr::select(birthdate, saleslastyear)

Q
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##    birthdate  saleslastyear
##    <date>             <dbl>
##  1 1951-10-17            0 
##  2 1968-12-25      1750406.
##  3 1980-02-27      1439156.
##  4 1962-08-29      1997186.
##  5 1975-02-04      1620277.
##  6 1974-01-18      1849641.
##  7 1974-12-06      1927059.
##  8 1968-03-09      2073506.
##  9 1963-12-11      2038235.
## 10 1974-02-11      1371635.
## # … with more rows
```
Note that in the previous example we follow this book's convention of creating a connection object to each table and fully qualifying function names (e.g., specifying the package).  In practice, it's possible and convenient to use more abbreviated notation.

```r
Q <- tbl(con, in_schema("sales", "salesperson")) %>%
  left_join(tbl(con, in_schema("humanresources", "employee")),  by = c("businessentityid" = "businessentityid")) %>%
  select(birthdate, saleslastyear)

Q
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##    birthdate  saleslastyear
##    <date>             <dbl>
##  1 1951-10-17            0 
##  2 1968-12-25      1750406.
##  3 1980-02-27      1439156.
##  4 1962-08-29      1997186.
##  5 1975-02-04      1620277.
##  6 1974-01-18      1849641.
##  7 1974-12-06      1927059.
##  8 1968-03-09      2073506.
##  9 1963-12-11      2038235.
## 10 1974-02-11      1371635.
## # … with more rows
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

