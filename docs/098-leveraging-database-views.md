# Leveraging Database Views {#chapter_leveraging-datbase-views}

> This chapter demonstrates how to:
>
>   * Investigate a database from a business perspective
>   * Dig into a single Adventureworks table containing sales data


## Setup our standard working environment



Use these libraries:

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
library(lubridate)
library(skimr)

library(scales) # ggplot xy scales
theme_set(theme_light())
```

Connect to `adventureworks`:

```r
sp_docker_start("adventureworks")
Sys.sleep(sleep_default)
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "adventureworks",
  seconds_to_test = sleep_default, connection_tab = TRUE
)
```


## Define a database `view`

  * A `view` is query that is stored in the database 
  * Can be used to read or write to the database in a standardized and well-understood way

### Why views are useful

Reasons for views:

  * Performance: aggregation calculations done on the server.
  * Conceptual abstraction/simplification, e.g. looking at monthly subtotals, rather than having to do the aggregation in each of your   * queries.
  * Reuse: putting commonly used code in one place.
    * If you find any problems, it only needs to be fixed in one place.
    * Simplifies downstream code, so easier to read and maintain.
  * Standardizes data provenance 

## Existing views as a resource

  * Authoritative
  * They are boring, but very important


### How to unpack and inspect a view

Using a view to retireve data from the database will be completely standard across all flavors of SQL.


```r
v_salesperson_sales_by_fiscal_years_data <- tbl(con, in_schema("sales","vsalespersonsalesbyfiscalyearsdata")) %>% collect()

str(v_salesperson_sales_by_fiscal_years_data)
```

```
## Classes 'tbl_df', 'tbl' and 'data.frame':	48 obs. of  6 variables:
##  $ salespersonid : int  275 275 275 275 276 276 276 276 277 277 ...
##  $ fullname      : chr  "Michael G Blythe" "Michael G Blythe" "Michael G Blythe" "Michael G Blythe" ...
##  $ jobtitle      : chr  "Sales Representative" "Sales Representative" "Sales Representative" "Sales Representative" ...
##  $ salesterritory: chr  "Northeast" "Northeast" "Northeast" "Northeast" ...
##  $ salestotal    : num  63763 2399593 3765459 3065088 5476 ...
##  $ fiscalyear    : num  2011 2012 2013 2014 2011 ...
```

```r
skim(v_salesperson_sales_by_fiscal_years_data)
```

```
## Skim summary statistics
##  n obs: 48 
##  n variables: 6 
## 
## ── Variable type:character ──────────────────────────────────
##        variable missing complete  n min max empty n_unique
##        fullname       0       48 48   9  26     0       14
##        jobtitle       0       48 48  20  20     0        1
##  salesterritory       0       48 48   6  14     0       10
## 
## ── Variable type:integer ────────────────────────────────────
##       variable missing complete  n   mean   sd  p0    p25   p50    p75
##  salespersonid       0       48 48 281.19 4.57 275 277.75 280.5 283.25
##  p100     hist
##   290 ▇▇▇▇▆▂▂▆
## 
## ── Variable type:numeric ────────────────────────────────────
##    variable missing complete  n       mean         sd      p0      p25
##  fiscalyear       0       48 48    2012.69       1.09 2011      2012  
##  salestotal       0       48 48 1635214.51 1243833.87 5475.95 533827.7
##         p50        p75    p100     hist
##     2013       2014       2014 ▅▁▆▁▁▇▁▇
##  1371169.72 2409498.88 4188307 ▇▂▇▂▅▂▂▂
```

```r
v_salesperson_sales_by_fiscal_years_data %>% filter(salespersonid == 275)
```

```
## # A tibble: 4 x 6
##   salespersonid fullname   jobtitle    salesterritory salestotal fiscalyear
##           <int> <chr>      <chr>       <chr>               <dbl>      <dbl>
## 1           275 Michael G… Sales Repr… Northeast          63763.       2011
## 2           275 Michael G… Sales Repr… Northeast        2399593.       2012
## 3           275 Michael G… Sales Repr… Northeast        3765459.       2013
## 4           275 Michael G… Sales Repr… Northeast        3065088.       2014
```
Local idioms for looking at a view itself will vary.  Here is the code that will work for PostgreSQL:


```r
view_definition <- dbGetQuery(con, "select pg_get_viewdef('sales.vsalespersonsalesbyfiscalyearsdata', true)")
str(view_definition)
```

```
## 'data.frame':	1 obs. of  1 variable:
##  $ pg_get_viewdef: chr " SELECT granular.salespersonid,\n    granular.fullname,\n    granular.jobtitle,\n    granular.salesterritory,\n"| __truncated__
```

```r
cat(str_replace_all(view_definition$pg_get_viewdef, "\\\\\\\\n", "\\\\n")) 
```

```
##  SELECT granular.salespersonid,
##     granular.fullname,
##     granular.jobtitle,
##     granular.salesterritory,
##     sum(granular.subtotal) AS salestotal,
##     granular.fiscalyear
##    FROM ( SELECT soh.salespersonid,
##             ((p.firstname::text || ' '::text) || COALESCE(p.middlename::text || ' '::text, ''::text)) || p.lastname::text AS fullname,
##             e.jobtitle,
##             st.name AS salesterritory,
##             soh.subtotal,
##             date_part('year'::text, soh.orderdate + '6 mons'::interval) AS fiscalyear
##            FROM sales.salesperson sp
##              JOIN sales.salesorderheader soh ON sp.businessentityid = soh.salespersonid
##              JOIN sales.salesterritory st ON sp.territoryid = st.territoryid
##              JOIN humanresources.employee e ON soh.salespersonid = e.businessentityid
##              JOIN person.person p ON p.businessentityid = sp.businessentityid) granular
##   GROUP BY granular.salespersonid, granular.fullname, granular.jobtitle, granular.salesterritory, granular.fiscalyear;
```

Even if you don't intend to become fluent in SQL, it's useful to read as much of it as possible.  

### We recommend leverageing them

## Writing your own or modifying a view

  * What about by month? This could be motivation for creating a new view that does aggregation in the database, rather than in R.
  * See SQL code for 'vsalespersonsalesbyfiscalyearsdata'. Consider:
  * Modifying that to include quantity of sales.
  * Modifying that to include monthly totals, in addition to the yearly totals that it already has.
  * Why are 3 of the sales people from 'vsalesperson' missing in 'vsalespersonsalesbyfiscalyearsdata'?
     * Amy Alberts
     * Stephen Jiang
     * Syed Abbas

### First draft with dplyr

Save and study the SQL

t_salesperson_sales_by_fiscal_years_data %>% 


```r
rm(t_salesperson_sales_by_fiscal_years_data)
```

```
## Warning in rm(t_salesperson_sales_by_fiscal_years_data): object
## 't_salesperson_sales_by_fiscal_years_data' not found
```

```r
t_salesperson_sales_by_fiscal_years_data <- 
  tbl(con, in_schema("sales", "salesperson")) %>% 
  select(-territoryid) %>% 
  left_join(tbl(con, in_schema("sales", "salesorderheader")), by = c("businessentityid" = "salespersonid")) %>%
  mutate(fiscalyear = year(orderdate)) %>% 
  # mutate(fiscalyear = substr(as.character(orderdate), 1,5)) %>% 
  left_join(tbl(con, in_schema("sales", "salesterritory")), by = c("territoryid" = "territoryid")) %>%
  
  rename(sales_territory = name) %>% 
  left_join(tbl(con, in_schema("humanresources", "employee")), by = c("businessentityid" = "businessentityid")) %>%
  left_join(tbl(con, in_schema("person", "person")), by = c("businessentityid" = "businessentityid")) %>%
  mutate(fullname = paste(firstname, middlename, lastname)) %>% 
  group_by(businessentityid, fullname, jobtitle, sales_territory, fiscalyear) %>% 
  summarize(subtotal = sum(subtotal) ) %>% 
collect() %>% ungroup()
```

```
## Warning: Missing values are always removed in SQL.
## Use `SUM(x, na.rm = TRUE)` to silence this warning
## This warning is displayed only once per session.
```

```r
t_salesperson_sales_by_fiscal_years_data
```

```
## # A tibble: 108 x 6
##    businessentityid fullname  jobtitle  sales_territory fiscalyear subtotal
##               <int> <chr>     <chr>     <chr>                <dbl>    <dbl>
##  1              274 Stephen … North Am… Canada                2011    2040.
##  2              274 Stephen … North Am… Canada                2012   62250.
##  3              274 Stephen … North Am… Canada                2013  100556.
##  4              274 Stephen … North Am… Canada                2014   11803.
##  5              274 Stephen … North Am… Central               2014   35332.
##  6              274 Stephen … North Am… Northeast             2012   83216.
##  7              274 Stephen … North Am… Northwest             2011   20545.
##  8              274 Stephen … North Am… Northwest             2012    5810.
##  9              274 Stephen … North Am… Northwest             2013  204390.
## 10              274 Stephen … North Am… Northwest             2014    2321.
## # … with 98 more rows
```

```r
skim(t_salesperson_sales_by_fiscal_years_data)
```

```
## Skim summary statistics
##  n obs: 108 
##  n variables: 6 
## 
## ── Variable type:character ──────────────────────────────────
##         variable missing complete   n min max empty n_unique
##         fullname       0      108 108   9  26     0       17
##         jobtitle       0      108 108  20  28     0        4
##  sales_territory       0      108 108   6  14     0       10
## 
## ── Variable type:integer ────────────────────────────────────
##          variable missing complete   n   mean   sd  p0 p25 p50 p75 p100
##  businessentityid       0      108 108 279.36 4.79 274 275 278 282  290
##      hist
##  ▇▃▂▃▂▁▂▁
## 
## ── Variable type:numeric ────────────────────────────────────
##    variable missing complete   n      mean        sd      p0       p25
##  fiscalyear       0      108 108   2012.62      1.07 2011      2012   
##    subtotal       0      108 108 745256.52 820632.09  672.29 116279.93
##        p50        p75       p100     hist
##    2013       2014       2014    ▅▁▇▁▁▇▁▇
##  541771.55 1008421.64 4106064.01 ▇▅▂▁▁▁▁▁
```

```r
t_salesperson_sales_by_fiscal_years_data %>% filter(businessentityid == 275)
```

```
## # A tibble: 11 x 6
##    businessentityid fullname  jobtitle  sales_territory fiscalyear subtotal
##               <int> <chr>     <chr>     <chr>                <dbl>    <dbl>
##  1              275 Michael … Sales Re… Central               2011  132244.
##  2              275 Michael … Sales Re… Central               2012  593815.
##  3              275 Michael … Sales Re… Central               2013 1371919.
##  4              275 Michael … Sales Re… Central               2014  472698.
##  5              275 Michael … Sales Re… Northeast             2011  626626.
##  6              275 Michael … Sales Re… Northeast             2012 2302605.
##  7              275 Michael … Sales Re… Southeast             2011  116954.
##  8              275 Michael … Sales Re… Southeast             2012  171773.
##  9              275 Michael … Sales Re… Southwest             2012  307263.
## 10              275 Michael … Sales Re… Southwest             2013 2613456.
## 11              275 Michael … Sales Re… Southwest             2014  584549.
```

Why 3 sales folks in vsalesperson don’t show up in 2014 vsalespersonsalesbyfiscalyearsdata

Different environments / SQL dialects
