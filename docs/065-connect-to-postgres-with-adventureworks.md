# Connect to the adventureworks database in PostgreSQL{#chapter_connect-to-adventureworks-db}

> This chapter demonstrates how to:
>
>  * Create and connect to the PostgreSQL `adventureworks` database in Docker
>  * Keep necessary credentials secret while being available to R when it executes.
>  * Connect to and disconnect R from the `adventureworks` database
>  * Set up the environment for subsequent chapters

## Overview

Docker commands can be run from a terminal (e.g., the Rstudio Terminal pane) or with a `system2()` command.  The necessary functions to start, stop Docker containers and do other busy work are provided in the `sqlpetr` package.  

> Note: The functions in the package are designed to help you focus on interacting with a dbms from R.  You can ignore how they work until you are ready to delve into the details.  They are all named to begin with `sp_`.  The first time a function is called in the book, we provide a note explaining its use.


Please install the `sqlpetr` package if not already installed:

```r
library(devtools)
if (!require(sqlpetr)) {
    remotes::install_github(
      "smithjd/sqlpetr",
      force = TRUE, build = FALSE, quiet = TRUE)
}
```
Note that when you install this package the first time, it will ask you to update the packages it uses and that may take some time.

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

## Verify that Docker is up, running, and clean up if necessary

> The `sp_check_that_docker_is_up` function from the `sqlpetr` package checks whether Docker is up and running.  If it's not, then you need to install, launch or re-install Docker.


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```


```r
sp_docker_start("adventureworks")
```


## Connect to PostgreSQL with R

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
That's equivalent to excuting this code to download the table from the DBMS to a local data frame:

For the moment we by-pass some complexity that results from the fact that the `adventureworks` database has multiple *schemas* and that we are interested in only one of them, named `information_schema`.  

```r
tbl(con, in_schema("information_schema", "schemata")) %>%
  select(catalog_name, schema_name, schema_owner) %>%
  collect()
```

```
## # A tibble: 16 x 3
##    catalog_name   schema_name        schema_owner
##    <chr>          <chr>              <chr>       
##  1 adventureworks sales              postgres    
##  2 adventureworks sa                 postgres    
##  3 adventureworks purchasing         postgres    
##  4 adventureworks pu                 postgres    
##  5 adventureworks production         postgres    
##  6 adventureworks pr                 postgres    
##  7 adventureworks person             postgres    
##  8 adventureworks pe                 postgres    
##  9 adventureworks humanresources     postgres    
## 10 adventureworks hr                 postgres    
## 11 adventureworks information_schema postgres    
## 12 adventureworks public             postgres    
## 13 adventureworks pg_catalog         postgres    
## 14 adventureworks pg_toast_temp_1    postgres    
## 15 adventureworks pg_temp_1          postgres    
## 16 adventureworks pg_toast           postgres
```

Schemas will be discussed later on because multiple schemas are the norm in an enterprise database environment, but they are a side issue at this point.  So we switch the order in which PostgreSQL searches for objects with the following SQL code:

```r
dbExecute(con, "set search_path to sales, public;")
```

```
## [1] 0
```
With the custom `search_path`, the following command shows the tables in the `sales` schema.  In the `adventureworks` database, there are no tables in the `public` schema.

```r
dbListTables(con)
```

```
##  [1] "countryregioncurrency"             
##  [2] "customer"                          
##  [3] "currencyrate"                      
##  [4] "creditcard"                        
##  [5] "personcreditcard"                  
##  [6] "specialoffer"                      
##  [7] "specialofferproduct"               
##  [8] "salesorderheadersalesreason"       
##  [9] "salespersonquotahistory"           
## [10] "shoppingcartitem"                  
## [11] "salesperson"                       
## [12] "currency"                          
## [13] "store"                             
## [14] "salesorderheader"                  
## [15] "salesorderdetail"                  
## [16] "salesreason"                       
## [17] "salesterritoryhistory"             
## [18] "vindividualcustomer"               
## [19] "vpersondemographics"               
## [20] "vsalesperson"                      
## [21] "vsalespersonsalesbyfiscalyears"    
## [22] "vsalespersonsalesbyfiscalyearsdata"
## [23] "vstorewithaddresses"               
## [24] "vstorewithcontacts"                
## [25] "vstorewithdemographics"            
## [26] "salestaxrate"                      
## [27] "salesterritory"
```
Notice there are several tables that start with the letter *v*: they are actually *views* which will turn out to be important.  They are clearly distinguished in the connections tab, but the naming is a matter of convention.

Same for `dbListFields`:

```r
dbListFields(con, "salesorderheader")
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
## #   creditcardid <int>, creditcardapprovalcode <chr>,
## #   currencyrateid <int>, subtotal <dbl>, taxamt <dbl>, freight <dbl>,
## #   totaldue <dbl>, comment <chr>, rowguid <chr>, modifieddate <dttm>
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
## #   creditcardid <int>, creditcardapprovalcode <chr>,
## #   currencyrateid <int>, subtotal <dbl>, taxamt <dbl>, freight <dbl>,
## #   totaldue <dbl>, comment <chr>, rowguid <chr>, modifieddate <dttm>
```

## `dplyr` connection objects
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
## #   creditcardid <int>, creditcardapprovalcode <chr>,
## #   currencyrateid <int>, subtotal <dbl>, taxamt <dbl>, freight <dbl>,
## #   totaldue <dbl>, comment <chr>, salesorderheader_details_updated <dttm>
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
## [1] "tbl_PqConnection" "tbl_dbi"          "tbl_sql"         
## [4] "tbl_lazy"         "tbl"
```

It is not just a normal `tbl` of data. We can see that from the structure of `salesorderheader_table`:

```r
str(salesorderheader_table)
```

```
## List of 2
##  $ src:List of 2
##   ..$ con  :Formal class 'PqConnection' [package "RPostgres"] with 3 slots
##   .. .. ..@ ptr     :<externalptr> 
##   .. .. ..@ bigint  : chr "integer64"
##   .. .. ..@ typnames:'data.frame':	796 obs. of  2 variables:
##   .. .. .. ..$ oid    : int [1:796] 16 17 18 19 20 21 22 23 24 25 ...
##   .. .. .. ..$ typname: chr [1:796] "bool" "bytea" "char" "name" ...
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
##   .. .. ..$ salesorderid                    : symbol salesorderid
##   .. .. ..$ revisionnumber                  : symbol revisionnumber
##   .. .. ..$ orderdate                       : symbol orderdate
##   .. .. ..$ duedate                         : symbol duedate
##   .. .. ..$ shipdate                        : symbol shipdate
##   .. .. ..$ status                          : symbol status
##   .. .. ..$ onlineorderflag                 : symbol onlineorderflag
##   .. .. ..$ purchaseordernumber             : symbol purchaseordernumber
##   .. .. ..$ accountnumber                   : symbol accountnumber
##   .. .. ..$ customerid                      : symbol customerid
##   .. .. ..$ salespersonid                   : symbol salespersonid
##   .. .. ..$ territoryid                     : symbol territoryid
##   .. .. ..$ billtoaddressid                 : symbol billtoaddressid
##   .. .. ..$ shiptoaddressid                 : symbol shiptoaddressid
##   .. .. ..$ shipmethodid                    : symbol shipmethodid
##   .. .. ..$ creditcardid                    : symbol creditcardid
##   .. .. ..$ creditcardapprovalcode          : symbol creditcardapprovalcode
##   .. .. ..$ currencyrateid                  : symbol currencyrateid
##   .. .. ..$ subtotal                        : symbol subtotal
##   .. .. ..$ taxamt                          : symbol taxamt
##   .. .. ..$ freight                         : symbol freight
##   .. .. ..$ totaldue                        : symbol totaldue
##   .. .. ..$ comment                         : symbol comment
##   .. .. ..$ salesorderheader_details_updated: symbol modifieddate
##   ..- attr(*, "class")= chr [1:3] "op_select" "op_single" "op"
##  - attr(*, "class")= chr [1:5] "tbl_PqConnection" "tbl_dbi" "tbl_sql" "tbl_lazy" ...
```

It has only _two_ rows!  The first row contains all the information in the `con` object, which contains information about all the tables and objects in the database:

```r
salesorderheader_table$src$con@typnames$typname[380:437]
```

```
##  [1] "user_mappings"                   "tablefunc_crosstab_2"           
##  [3] "_tablefunc_crosstab_2"           "tablefunc_crosstab_3"           
##  [5] "_tablefunc_crosstab_3"           "tablefunc_crosstab_4"           
##  [7] "_tablefunc_crosstab_4"           "AccountNumber"                  
##  [9] "_AccountNumber"                  "Flag"                           
## [11] "_Flag"                           "Name"                           
## [13] "_Name"                           "NameStyle"                      
## [15] "_NameStyle"                      "OrderNumber"                    
## [17] "_OrderNumber"                    "Phone"                          
## [19] "_Phone"                          "department"                     
## [21] "_department"                     "pg_toast_16439"                 
## [23] "d"                               "_d"                             
## [25] "employee"                        "_employee"                      
## [27] "pg_toast_16450"                  "e"                              
## [29] "_e"                              "employeedepartmenthistory"      
## [31] "_employeedepartmenthistory"      "edh"                            
## [33] "_edh"                            "employeepayhistory"             
## [35] "_employeepayhistory"             "pg_toast_16482"                 
## [37] "eph"                             "_eph"                           
## [39] "jobcandidate"                    "_jobcandidate"                  
## [41] "pg_toast_16495"                  "jc"                             
## [43] "_jc"                             "shift"                          
## [45] "_shift"                          "pg_toast_16506"                 
## [47] "s"                               "_s"                             
## [49] "department_departmentid_seq"     "jobcandidate_jobcandidateid_seq"
## [51] "shift_shiftid_seq"               "address"                        
## [53] "_address"                        "businessentityaddress"          
## [55] "_businessentityaddress"          "countryregion"                  
## [57] "_countryregion"                  "pg_toast_16533"
```
The second row contains a list of the columns in the `salesorderheader` table, among other things:

```r
salesorderheader_table$ops$x$vars
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
`salesorderheader_table` holds information needed to get the data from the 'salesorderheader' table, but `salesorderheader_table` does not hold the data itself. In the following sections, we will examine more closely this relationship between the `salesorderheader_table` object and the data in the database's 'salesorderheader' table.

Disconnect from the database:

```r
dbDisconnect(con)
```
## Stop and start to demonstrate persistence

Stop the container:

```r
sp_docker_stop("adventureworks")
sp_docker_containers_tibble()
```

```
## # A tibble: 0 x 0
```

When we stopped `adventureworks`, it no longer appeared in the tibble. But the
container is still there. `sp_docker_containers_tibble` by default only lists
the *running* containers. But we can use the `list_all` option and see it:


```r
sp_docker_containers_tibble(list_all = TRUE)
```

```
<<<<<<< HEAD
## # A tibble: 3 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 21053106fc9a post… docker… 2019-08-1… About … <NA>  Exite… 63B … adve…
## 2 f15839235dc7 memg… /usr/l… 2019-03-3… 4 mont… <NA>  Exite… 0B (… eleg…
## 3 a722c21a4228 coli… /bin/s… 2019-03-1… 4 mont… 0.0.… Exite… 134M… neo4r
=======
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 0105899fe547 post… docker… 2019-08-2… 26 sec… <NA>  Exite… 0B (… adve…
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```


Restart the container and verify that the adventureworks tables are still there:

```r
sp_docker_start("adventureworks")
sp_docker_containers_tibble()
```

```
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
<<<<<<< HEAD
## 1 21053106fc9a post… docker… 2019-08-1… About … 0.0.… Up Le… 63B … adve…
=======
## 1 0105899fe547 post… docker… 2019-08-2… 28 sec… 0.0.… Up Le… 63B … adve…
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```
Connect to the `adventureworks` database in PostgreSQL:

```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "adventureworks",
  seconds_to_test = 30
)
```

Check that you can still see the first few rows of the `salesorderheader` table:

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
## #   creditcardid <int>, creditcardapprovalcode <chr>,
## #   currencyrateid <int>, subtotal <dbl>, taxamt <dbl>, freight <dbl>,
## #   totaldue <dbl>, comment <chr>, rowguid <chr>, modifieddate <dttm>
```

## Cleaning up

Always have R disconnect from the database when you're done.

```r
dbDisconnect(con)
```

Stop the `adventureworks` container:

```r
sp_docker_stop("adventureworks")
```
Show that the container still exists even though it's not running


```r
sp_show_all_docker_containers()
```

```
<<<<<<< HEAD
## CONTAINER ID        IMAGE                   COMMAND                  CREATED              STATUS                                PORTS                    NAMES
## 21053106fc9a        postgres:11             "docker-entrypoint.s…"   About a minute ago   Exited (137) Less than a second ago                            adventureworks
## f15839235dc7        memgraph                "/usr/lib/memgraph/m…"   4 months ago         Exited (0) 4 months ago                                        elegant_mcclintock
## a722c21a4228        colinfay/neo4r-docker   "/bin/sh -c 'cd /hom…"   4 months ago         Exited (255) 4 months ago             0.0.0.0:8787->8787/tcp   neo4r
=======
## CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                              PORTS               NAMES
## 0105899fe547        postgres:11         "docker-entrypoint.s…"   28 seconds ago      Exited (0) Less than a second ago                       adventureworks
>>>>>>> b6501daaa228eb07c28ed412fb8e30891823ef72
```

Next time, you can just use this command to start the container: 

> `sp_docker_start("adventureworks")`

And once stopped, the container can be removed with:

> `sp_check_that_docker_is_up("adventureworks")`

## Using the `adventureworks` container in the rest of the book

After this point in the book, we assume that Docker is up and that we can always start up our *adventureworks database* with:

> `sp_docker_start("adventureworks")`

