# Exploratory Data Analysis {#chapter_exploratory-data-analysis}

> The previous chapter enabled us to get started with the AdventureWorks database. We saw how to list tables and fields to get an overview of the type of data contained in the database. This chapter proceeds through a hypothetical scenario where we dig deeper to answer specific business questions.

## Setup

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(dplyr)
library(dbplyr)
library(lubridate)
library(forcats)
library(ggplot2)
library(sqlpetr)
library(glue)
require(knitr)
library(bookdown)
```

We assume that the Docker container with PostgreSQL and the `adventureworks` database have already been prepared, but make sure the container has been started:

```r
sqlpetr::sp_docker_start("adventureworks")
```
If that `sp_docker_start` command leads to errors, you may need to revisit [Chapter 4](#chapter_setup-adventureworks-db).

## Number of Orders
Suppose we are developers who use the corporate database. We often receive requests from executives who have some burning question as they try to understand and improve the company's processes. Today is no exception. AdventureWorks has just hired a new Vice President of Sales, Sally Seashells. She sends us an email, asking for a report of sales volumes for the past 4 years.

Let's find the quantity of sales orders, which we can count from the `SalesOrderHeader` table. First, we connect to the database:

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

We can list the fields in the `SalesOrderHeader` table in the `Sales` schema, using `DBI` functions:

```r
DBI::dbExecute(con, "set search_path to sales;")
```

```
## [1] 0
```

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

The `SalesOrderHeader` table has a row for each sales order, so we create a table in our R environment for that data source, ignoring the fields {`rowguid`, `modifieddate`}, which we will not be using:

```r
sales_order_header_table <- 
  dplyr::tbl(con, dbplyr::in_schema("sales", "salesorderheader")) %>% 
  dplyr::select(-rowguid, -modifieddate)
names(dplyr::collect(sales_order_header_table))
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
## [23] "comment"
```

Sally asked us for the sales volume, so let's assume she wants us to count the orders by the `shipdate`, rather than the `orderdate`, since `shipdate` is when the revenue is counted. Which dates are covered by our database?

```r
ship_dates <- sales_order_header_table %>% 
  dplyr::select(shipdate) %>% 
  dplyr::arrange(shipdate) %>% 
  dplyr::collect()
glue(
  "shipdate range = ({first}, {last})",
  first = head(ship_dates, 1)[[1]],
  last = tail(ship_dates, 1)[[1]]
)
```

```
## shipdate range = (2011-06-07, 2014-07-07)
```

Let's count the number of orders by year:

```r
# Workaround as of 2019-08-09: Must convert integer64 `shipyear` to a factor,
# due to ggplot2 defect (https://github.com/tidyverse/ggplot2/issues/2377)
sales_order_header_table %>% 
  dplyr::select(shipdate) %>% 
  dplyr::collect() %>%   # collect before using tidyverse functions
  dplyr::mutate(shipyear = lubridate::year(shipdate)) %>% 
  dplyr::mutate(shipyear = forcats::as_factor(shipyear)) %>%  # workaround
  dplyr::count(shipyear) %>%  # places count in column `n`
  dplyr::arrange(shipyear) %>%
  ggplot(aes(shipyear, n)) + 
  geom_col() + 
  geom_text(aes(label = n), vjust = -0.5) + 
  ggtitle("Orders by Year") + 
  xlab("Year") + 
  ylab("Number of Orders")
```

<img src="087-exploratory-data-analysis_files/figure-html/count orders by year-1.png" width="672" />

This looks like a good start, but maybe years are too broad. Let's drill down for more detail. We could count the number of orders by week, but that seems too detailed. Let's count by month:

```r
sales_order_header_table %>% 
  dplyr::select(shipdate) %>% 
  dplyr::collect() %>%   # collect before using tidyverse functions
  dplyr::mutate(shipmonth = format(shipdate, "%m")) %>% 
  dplyr::mutate(shipyear = format(shipdate, "%Y")) %>% 
  dplyr::mutate(ship_year_month = as.Date(paste(shipyear, shipmonth, "01", sep = "-"), "%Y-%m-%d")) %>% 
  dplyr::count(ship_year_month) %>%  # places count in column `n`
  dplyr::arrange(ship_year_month) %>%
  ggplot(aes(ship_year_month, n)) + 
  geom_col() + 
  scale_x_date(labels = scales::date_format("%Y-%m")) +
  ggtitle("Orders by Month") + 
  xlab("Month") + 
  ylab("Number of Orders")
```

<img src="087-exploratory-data-analysis_files/figure-html/count orders by month-1.png" width="672" />

These two plots provide a good overview of sales volume, but that huge increase in number of orders starting in July 2013 requires more investigation. Why did the number of orders increase so significantly starting that month? And why did the number decrease so drastically in June 2014?

## Sources of Orders

&#x1F53B;&nbsp;_To Do_: 

* Why the big jump in numbers of orders? 
* Are there new customers? 
* Is there a corresponding jump in revenue?

&nbsp;&#x1F53A;

## Characteristics of Orders

&#x1F53B;&nbsp;_To Do_: Has the nature of orders changed over time? For example, 

* revenue per order
* number of items per order
* frequency of orders by customer
* ...

&nbsp;&#x1F53A;
