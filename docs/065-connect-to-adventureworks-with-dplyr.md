# Connecting to the database with R code{#chapter_connect-to-db-with-r-code}

> This chapter demonstrates how to:
>
>  * Connect to and disconnect R from the `adventureworks` database
>  * Use dplyr to get an overview of the database, replicating the facilities provided by RStudio

These packages are called in this Chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(bookdown)
library(here)
```

## Verify that Docker is up and running, and start the database

> The `sp_check_that_docker_is_up` function from the `sqlpetr` package checks whether Docker is up and running.  If it's not, then you need to install, launch or re-install Docker.


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up, running these containers:"                                                                                                           
## [2] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES"           
## [3] "f44ee620b29e        postgres:11         \"docker-entrypoint.s…\"   5 days ago          Up 4 days           0.0.0.0:5432->5432/tcp   adventureworks"
```


```r
sp_docker_start("adventureworks")
```


## Connect to PostgreSQL 

*CHECK for `sqlpetr` update!`  The `sp_make_simple_pg` function we called above created a container from the
`postgres:11` library image downloaded from Docker Hub. As part of the process, it set the password for the PostgreSQL database superuser `postgres` to the value 
"postgres".

For simplicity, we are using a weak password at this point and it's shown here 
and in the code in plain text. That is bad practice because user credentials 
should not be shared in open code like that.  A [subsequent chapter](#dbms-login)
demonstrates how to store and use credentials to access the DBMS so that they 
are kept private.

> The `sp_get_postgres_connection` function from the `sqlpetr` package gets a DBI connection string to a PostgreSQL database, waiting if it is not ready. This function connects to an instance of PostgreSQL and we assign it to a symbol, `con`, for subsequent use. The `connctions_tab = TRUE` parameter opens a connections tab that's useful for navigating a database.

> Note that we are using port *5439* for PostgreSQL inside the container and published to `localhost`. Why? If you have PostgreSQL already running on the host or another container, it probably claimed port 5432, since that's the default. So we need to use a different port for *our* PostgreSQL container.

Use the DBI package to connect to the `adventureworks` database in PostgreSQL.  Remember the settings discussion about [keeping passwords hidden][Pause for some security considerations]


```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,  # this version still using 5432!!!
  user = "postgres",
  password = "postgres",
  dbname = "adventureworks",
  seconds_to_test = 20, connection_tab = TRUE
)
```

## Set schema search path and list its contents

Schemas will be discussed later on because multiple schemas are the norm in an enterprise database environment, but they are a side issue at this point.  So we switch the order in which PostgreSQL searches for objects with the following SQL code:

```r
dbExecute(con, "set search_path to sales;")
```

```
## [1] 0
```
With the custom `search_path`, the following command shows the tables in the `sales` schema.  In the `adventureworks` database, there are no tables in the `public` schema.

```r
dbListTables(con)
```

```
##  [1] "countryregioncurrency"              "customer"                          
##  [3] "currencyrate"                       "creditcard"                        
##  [5] "personcreditcard"                   "specialoffer"                      
##  [7] "specialofferproduct"                "salesorderheadersalesreason"       
##  [9] "shoppingcartitem"                   "salespersonquotahistory"           
## [11] "salesperson"                        "currency"                          
## [13] "store"                              "salesorderheader"                  
## [15] "salesorderdetail"                   "salesreason"                       
## [17] "salesterritoryhistory"              "vindividualcustomer"               
## [19] "vpersondemographics"                "vsalesperson"                      
## [21] "vsalespersonsalesbyfiscalyears"     "vsalespersonsalesbyfiscalyearsdata"
## [23] "vstorewithaddresses"                "vstorewithcontacts"                
## [25] "vstorewithdemographics"             "salestaxrate"                      
## [27] "salesterritory"
```
Notice there are several tables that start with the letter *v*: they are actually *views* which will turn out to be important.  They are clearly distinguished in the connections tab, but the naming is a matter of convention.

Same for `dbListFields`:

```r
dbListFields(con, "salesorderheader")
```

```
##  [1] "salesorderid"           "revisionnumber"         "orderdate"             
##  [4] "duedate"                "shipdate"               "status"                
##  [7] "onlineorderflag"        "purchaseordernumber"    "accountnumber"         
## [10] "customerid"             "salespersonid"          "territoryid"           
## [13] "billtoaddressid"        "shiptoaddressid"        "shipmethodid"          
## [16] "creditcardid"           "creditcardapprovalcode" "currencyrateid"        
## [19] "subtotal"               "taxamt"                 "freight"               
## [22] "totaldue"               "comment"                "rowguid"               
## [25] "modifieddate"
```

Thus with this search order, the following two produce identical results:

```r
tbl(con, in_schema("sales", "salesorderheader")) %>%
  head()
```

```
## # Source:   lazy query [?? x 25]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   salesorderid revisionnumber orderdate           duedate            
##          <int>          <int> <dttm>              <dttm>             
## 1        43659              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 2        43660              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 3        43661              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 4        43662              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 5        43663              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 6        43664              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## # … with 21 more variables: shipdate <dttm>, status <int>,
## #   onlineorderflag <lgl>, purchaseordernumber <chr>, accountnumber <chr>,
## #   customerid <int>, salespersonid <int>, territoryid <int>,
## #   billtoaddressid <int>, shiptoaddressid <int>, shipmethodid <int>,
## #   creditcardid <int>, creditcardapprovalcode <chr>, currencyrateid <int>,
## #   subtotal <dbl>, taxamt <dbl>, freight <dbl>, totaldue <dbl>, comment <chr>,
## #   rowguid <chr>, modifieddate <dttm>
```

```r
tbl(con, "salesorderheader") %>%
  head()
```

```
## # Source:   lazy query [?? x 25]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   salesorderid revisionnumber orderdate           duedate            
##          <int>          <int> <dttm>              <dttm>             
## 1        43659              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 2        43660              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 3        43661              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 4        43662              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 5        43663              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 6        43664              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## # … with 21 more variables: shipdate <dttm>, status <int>,
## #   onlineorderflag <lgl>, purchaseordernumber <chr>, accountnumber <chr>,
## #   customerid <int>, salespersonid <int>, territoryid <int>,
## #   billtoaddressid <int>, shiptoaddressid <int>, shipmethodid <int>,
## #   creditcardid <int>, creditcardapprovalcode <chr>, currencyrateid <int>,
## #   subtotal <dbl>, taxamt <dbl>, freight <dbl>, totaldue <dbl>, comment <chr>,
## #   rowguid <chr>, modifieddate <dttm>
```

## Anatomy of a `dplyr` connection object

As introduced in the previous chapter, the `dplyr::tbl` function creates an object that might **look** like a data frame in that when you enter it on the command line, it prints a bunch of rows from the dbms table.  But it is actually a **list** object that `dplyr` uses for constructing queries and retrieving data from the DBMS.  

The following code illustrates these issues.  The `dplyr::tbl` function creates the connection object that we store in an object named `salesorderheader_table`:

```r
salesorderheader_table <- dplyr::tbl(con, in_schema("sales", "salesorderheader")) %>% 
  select(-rowguid) %>% 
  rename(salesorderheader_details_updated = modifieddate)
```

At first glance, it _acts_ like a data frame when you print it, although it only prints 10 of the table's 31,465 rows:

```r
salesorderheader_table
```

```
## # Source:   lazy query [?? x 24]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##    salesorderid revisionnumber orderdate           duedate            
##           <int>          <int> <dttm>              <dttm>             
##  1        43659              8 2011-05-31 00:00:00 2011-06-12 00:00:00
##  2        43660              8 2011-05-31 00:00:00 2011-06-12 00:00:00
##  3        43661              8 2011-05-31 00:00:00 2011-06-12 00:00:00
##  4        43662              8 2011-05-31 00:00:00 2011-06-12 00:00:00
##  5        43663              8 2011-05-31 00:00:00 2011-06-12 00:00:00
##  6        43664              8 2011-05-31 00:00:00 2011-06-12 00:00:00
##  7        43665              8 2011-05-31 00:00:00 2011-06-12 00:00:00
##  8        43666              8 2011-05-31 00:00:00 2011-06-12 00:00:00
##  9        43667              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## 10        43668              8 2011-05-31 00:00:00 2011-06-12 00:00:00
## # … with more rows, and 20 more variables: shipdate <dttm>, status <int>,
## #   onlineorderflag <lgl>, purchaseordernumber <chr>, accountnumber <chr>,
## #   customerid <int>, salespersonid <int>, territoryid <int>,
## #   billtoaddressid <int>, shiptoaddressid <int>, shipmethodid <int>,
## #   creditcardid <int>, creditcardapprovalcode <chr>, currencyrateid <int>,
## #   subtotal <dbl>, taxamt <dbl>, freight <dbl>, totaldue <dbl>, comment <chr>,
## #   salesorderheader_details_updated <dttm>
```

However, notice that the first output line shows `??`, rather than providing the number of rows in the table. Similarly, the next to last line shows:
```
    … with more rows, and 20 more variables:
```
whereas the output for a normal `tbl` of this salesorderheader data would say:
```
    … with 31,455 more rows, and 20 more variables:
```

So even though `salesorderheader_table` is a `tbl`, it's **also** a `tbl_PqConnection`:

```r
class(salesorderheader_table)
```

```
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"          "tbl_lazy"        
## [5] "tbl"
```

It is not just a normal `tbl` of data. We can see that from the structure of `salesorderheader_table`:

```r
str(salesorderheader_table, max.level = 3)
```

```
## List of 2
##  $ src:List of 2
##   ..$ con  :Formal class 'PqConnection' [package "RPostgres"] with 3 slots
##   ..$ disco: NULL
##   ..- attr(*, "class")= chr [1:4] "src_PqConnection" "src_dbi" "src_sql" "src"
##  $ ops:List of 4
##   ..$ name: chr "select"
##   ..$ x   :List of 2
##   .. ..$ x   : 'ident_q' chr "sales.salesorderheader"
##   .. ..$ vars: chr [1:25] "salesorderid" "revisionnumber" "orderdate" "duedate" ...
##   .. ..- attr(*, "class")= chr [1:3] "op_base_remote" "op_base" "op"
##   ..$ dots: list()
##   ..$ args:List of 1
##   .. ..$ vars:List of 24
##   ..- attr(*, "class")= chr [1:3] "op_select" "op_single" "op"
##  - attr(*, "class")= chr [1:5] "tbl_PqConnection" "tbl_dbi" "tbl_sql" "tbl_lazy" ...
```

It has only _two_ rows!  The first row contains all the information in the `con` object, which contains information about all the tables and objects in the database.  Here is a sample:

```r
salesorderheader_table$src$con@typnames$typname[387:418]
```

```
##  [1] "AccountNumber"              "_AccountNumber"            
##  [3] "Flag"                       "_Flag"                     
##  [5] "Name"                       "_Name"                     
##  [7] "NameStyle"                  "_NameStyle"                
##  [9] "OrderNumber"                "_OrderNumber"              
## [11] "Phone"                      "_Phone"                    
## [13] "department"                 "_department"               
## [15] "pg_toast_16439"             "d"                         
## [17] "_d"                         "employee"                  
## [19] "_employee"                  "pg_toast_16450"            
## [21] "e"                          "_e"                        
## [23] "employeedepartmenthistory"  "_employeedepartmenthistory"
## [25] "edh"                        "_edh"                      
## [27] "employeepayhistory"         "_employeepayhistory"       
## [29] "pg_toast_16482"             "eph"                       
## [31] "_eph"                       "jobcandidate"
```
The second row contains a list of the columns in the `salesorderheader` table, among other things:

```r
salesorderheader_table$ops$x$vars
```

```
##  [1] "salesorderid"           "revisionnumber"         "orderdate"             
##  [4] "duedate"                "shipdate"               "status"                
##  [7] "onlineorderflag"        "purchaseordernumber"    "accountnumber"         
## [10] "customerid"             "salespersonid"          "territoryid"           
## [13] "billtoaddressid"        "shiptoaddressid"        "shipmethodid"          
## [16] "creditcardid"           "creditcardapprovalcode" "currencyrateid"        
## [19] "subtotal"               "taxamt"                 "freight"               
## [22] "totaldue"               "comment"                "rowguid"               
## [25] "modifieddate"
```
`salesorderheader_table` holds information needed to get the data from the 'salesorderheader' table, but `salesorderheader_table` does not hold the data itself. In the following sections, we will examine more closely this relationship between the `salesorderheader_table` object and the data in the database's 'salesorderheader' table.

## Disconnect from the database and stop Docker


```r
dbDisconnect(con)
sp_docker_stop("adventureworks")
```
