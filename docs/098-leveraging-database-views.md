# Leveraging Database Views {#chapter_leveraging-database-views}

> This chapter demonstrates how to:
>
>   * Understand database views and their uses
>   * Unpack a database view to see what it's doing
>   * Reproduce a database view with dplyr code 
>   * Write an alternative to a view that provides more details
>   * Create a database view either for personal use or for submittal to your enterprise DBA


## Setup our standard working environment



Use these libraries:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(connections)
library(glue)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(bookdown)
library(here)
library(lubridate)
library(skimr)
# library(DiagrammeR)

library(scales) # ggplot xy scales
theme_set(theme_light())
```

Connect to `adventureworks`:

```r
sp_docker_start("adventureworks")
Sys.sleep(sleep_default)
con <- connection_open(  # use in an interactive session
# con <- dbConnect(          # use in other settings
  RPostgres::Postgres(),
  # without the following (and preceding) lines, 
  # bigint become int64 which is a problem for ggplot
  bigint = "integer",  
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "adventureworks"
)
dbExecute(con, "set search_path to sales;")
```

```
## [1] 0
```


## The role of database `views`

A database `view` is an SQL query that is stored in the database.  Most `views` are used for data retrieval, since they usually denormalize the tables involved.  Because they are standardized and well-understood, they can save you a lot of work.

### Why database `views` are useful

Database `views` are useful for many reasons.

  * **Authoritative**: database `views` are typically written by the business application vendor or DBA, so they contain authoritative knowledge about the structure and intended use of the database.
  * **Performance**: `views` are designed to gather data in an efficient way, using all the indexes in an efficient sequence and doing as much work on the database server as possible.
  * **Abstraction**: `views` are abstractions or simplifications of complex queries that provide customary (useful) aggregations.  Common examples would be monthly totals or aggregation of activity tied to one individual.
  * **Reuse**: a `view` puts commonly used code in one place where it can be used for many purposes by many people. If there is a change or a problem found in a `view`, it only needs to be fixed in one place, rather than having to change many places downstream.
  * **Security**: a view can give selective access to someone who does not have access to underlying tables or columns.
  * **Provenance**: `views` standardize data provenance.  For example, the `AdventureWorks` database all of them are named in a consistent way that suggests the underlying tables that they query.  And they all start with a **v**.

### Rely on **and** be critical of `views`

Because they represent a conventional view of the database, a `view` may seem quite boring; remember why they are very important. Just because they are conventional and authorized, they may still need verification or auditing when used for a purpose other than the original intent. They can guide you toward what you need from the database but they could also mislead because they are easy to use and available.  People may forget why a specific view exists and who is using it. Therefore any given view might be a forgotten vestige or part of a production data pipeline or a priceless nugget of insight. How can you tell? Consider the owner and schema, whether it's a materialized index view or not, if it has a trigger and try to deduce the intentionality behind the view.

## Unpacking the elements of a `view` Tidyverse

Since a view is just like an ordinary table, many of the tools we've become familiar with work the same.  The simplest way of getting a list of columns in a view is the same as it is for a regular table:


```r
dbListFields(con, "vsalespersonsalesbyfiscalyearsdata")
```

```
## [1] "salespersonid"  "fullname"       "jobtitle"       "salesterritory"
## [5] "salestotal"     "fiscalyear"
```

### Use a `view` just like any other table

From a retrieval perspective a database `view` is just like any other table.  Using a view to retrieve data from the database will be completely standard across all flavors of SQL.  (To find out what a view does behind the scenes requires that you use functions that are **not** standard.)


```r
v_salesperson_sales_by_fiscal_years_data <- 
  tbl(con, in_schema("sales","vsalespersonsalesbyfiscalyearsdata")) %>% 
  collect()

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
tbl(con, in_schema("sales","vsalespersonsalesbyfiscalyearsdata")) %>% 
  filter(salespersonid == 275) %>% 
  collect()
```

```
## # A tibble: 4 x 6
##   salespersonid fullname     jobtitle       salesterritory salestotal fiscalyear
##           <int> <chr>        <chr>          <chr>               <dbl>      <dbl>
## 1           275 Michael G B… Sales Represe… Northeast          63763.       2011
## 2           275 Michael G B… Sales Represe… Northeast        2399593.       2012
## 3           275 Michael G B… Sales Represe… Northeast        3765459.       2013
## 4           275 Michael G B… Sales Represe… Northeast        3065088.       2014
```

view replication is a big PITA. do it to understand the view mechanics and do that to extend or modify the view.  at the end: share with others via the DBA.

Start with what you need, then "look up" with other tables.  Within the constraints of foreign keys.  Index considerations.

### SQL source code

Database-specific idioms for looking at a view itself will vary.  Here is the code to retrieve a PostgreSQL view (using the `pg_get_viewdef` function):


```r
view_definition <- dbGetQuery(con, "select 
                   pg_get_viewdef('sales.vsalespersonsalesbyfiscalyearsdata', 
                   true)")
```
The PostgreSQL `pg_get_viewdef` function returns a data frame with one column named `pg_get_viewdef` and one row.  To properly view its contents, the `\n` character strings need to be turned into new-lines.


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
##            FROM salesperson sp
##              JOIN salesorderheader soh ON sp.businessentityid = soh.salespersonid
##              JOIN salesterritory st ON sp.territoryid = st.territoryid
##              JOIN humanresources.employee e ON soh.salespersonid = e.businessentityid
##              JOIN person.person p ON p.businessentityid = sp.businessentityid) granular
##   GROUP BY granular.salespersonid, granular.fullname, granular.jobtitle, granular.salesterritory, granular.fiscalyear;
```

Even if you don't intend to become completely fluent in SQL, it's useful to study as much of it as possible.  Studying the SQL in a view is particularly useful to:

  * Test your understanding of the database structure, elements, and usage
  * Extend what's already been done to extract useful data from the database

### The ERD as context for SQL code

A database Entity Relationship Diagram (ERD) is very helpful in making sense of the SQL in a `view`.  The ERD for `AdventureWorks` is [here](https://i.stack.imgur.com/LMu4W.gif). 
Save and study the SQL.

### Tables and columns

use tools like PostgreSQL pg_modeler to get an ERD.


It can be helpful to actually mark up the ERD to identify the specific tables that are involved in the view you are going to reproduce.
![](screenshots/AW-2008-OLTP-ERD.gif)

The `sales.vsalespersonsalesbyfiscalyearsdata` view joins data from five different tables

Define each table that is involved and identify the columns that will be needed from that table.  The tables that are involved are:

  1. sales_order_header
  2. sales_territory
  3. sales_person
  4. employee
  5. person

Select the columns and do any necessary changes or renaming.  Avoid `dbplyr` default joins by **not** including `rowguid` and `ModifiedDate` columns, which appear in almost all `AdventureWorks` tables.  Also, we follow the convention that any column that we change or create on the fly uses a snake case naming convention.

```r
sales_order_header <- tbl(con, in_schema("sales", "salesorderheader")) %>% 
  select(orderdate, salespersonid, subtotal)

sales_territory <- tbl(con, in_schema("sales", "salesterritory")) %>% 
    select(territoryid, territory_name = name) 
  
sales_person <- tbl(con, in_schema("sales", "salesperson")) %>% 
  select(businessentityid, territoryid) 

employee <- tbl(con, in_schema("humanresources", "employee")) %>% 
  select(businessentityid, jobtitle)

person <- tbl(con, in_schema("person", "person")) %>% 
  mutate(full_name = paste(firstname, middlename, lastname)) %>% 
  select(businessentityid, full_name)
```

Double check on the names that are defined in each `tbl` object.  First define a function to show the names of columns you will retrieve.


```r
getnames <- function(table) {
  {table} %>% collect(n = 5) %>% names()
}
```

Verify the names selected:

```r
getnames(sales_order_header)
```

```
## [1] "orderdate"     "salespersonid" "subtotal"
```

```r
getnames(sales_territory)
```

```
## [1] "territoryid"    "territory_name"
```

```r
getnames(sales_person)
```

```
## [1] "businessentityid" "territoryid"
```

```r
getnames(employee)
```

```
## [1] "businessentityid" "jobtitle"
```

```r
getnames(person)
```

```
## [1] "businessentityid" "full_name"
```

### Join the tables together

Join all of the data pertaining to a person.  Notice that since all of these 4 tables contain `businessentityid`, dplyr will join them all on that common column automatically.


```r
salesperson_info <- sales_person %>% 
  left_join(employee) %>% 
  left_join(person) %>% 
  left_join(sales_territory) %>%
  collect()
```

```
## Joining, by = "businessentityid"Joining, by = "businessentityid"Joining, by =
## "territoryid"
```

```r
str(salesperson_info)
```

```
## Classes 'tbl_df', 'tbl' and 'data.frame':	17 obs. of  5 variables:
##  $ businessentityid: int  274 275 276 277 278 279 280 281 282 283 ...
##  $ territoryid     : int  NA 2 4 3 6 5 1 4 6 1 ...
##  $ jobtitle        : chr  "North American Sales Manager" "Sales Representative" "Sales Representative" "Sales Representative" ...
##  $ full_name       : chr  "Stephen Y Jiang" "Michael G Blythe" "Linda C Mitchell" "Jillian Carson" ...
##  $ territory_name  : chr  NA "Northeast" "Southwest" "Central" ...
```

Discuss:
  `date_part('year'::text, soh.orderdate + '6 mons'::interval) AS fiscalyear`

Do a crude version with `orderdate`.  All of the work can be done on the database server.


```r
sales_data_year <- sales_person %>% 
  left_join(sales_order_header, by = c("businessentityid" = "salespersonid")) %>% 
  group_by(businessentityid, orderdate) %>% 
  summarize(sales_total = sum(subtotal, na.rm = TRUE))  %>%
  collect()
```

Lubridate makes it very easy to convert `orderdate` to `fiscal_year`.  Doing that conversion interleaving dplyr and **ANSI-STANDARD** SQL is harder.  Too lazy!  Therefore we just pull the data from the server after the `left_join` and do the rest of the job on the R side.

** notice that the merge is happening on the R side. there would be a modification to make it all (or as much as possible) happen on the server side.**


Using this function as a model:

```r
dbExecute(
  con,
  "CREATE OR REPLACE FUNCTION so_adj_date(so_date timestamp, ONLINE_ORDER boolean) RETURNS timestamp AS $$
     BEGIN
        IF (ONLINE_ORDER) THEN
            RETURN (SELECT so_date);
        ELSE
            RETURN(SELECT CASE WHEN EXTRACT(DAY FROM so_date) = 1
                               THEN  so_date - '1 day'::interval
                               ELSE  so_date
                          END
                  );
        END IF;
 END; $$
LANGUAGE PLPGSQL;
"
)
```

Trying to create a function that returns fiscal year on the server side.


```r
dbExecute(
  con,
  "CREATE OR REPLACE FUNCTION so_calc_fy(orderdate timestamp) RETURNS orderdate AS $$
        RETURN(date_part('year'::text, orderdate + '6 mons'::interval))
$$
LANGUAGE PLPGSQL;
"
)
```



```r
sales_data_fiscal_year <- sales_person %>% 
  left_join(sales_order_header, by = c("businessentityid" = "salespersonid")) %>% 
  # mutate(fiscal_year = year(orderdate %m+% months(6))) %>% 
  group_by(businessentityid, orderdate) %>%
  summarize(sales_total = sum(subtotal, na.rm = TRUE)) %>% 
  mutate(
    orderdate = as.Date(orderdate),
    day = day(orderdate)
  ) %>%
  collect() %>% 
  ungroup() %>% 
  mutate(
    adjusted_orderdate = case_when(
      day == 1L ~ orderdate -1,
      TRUE ~ orderdate
    ),
    year_month = floor_date(adjusted_orderdate, "month")
  )

str(sales_data_fiscal_year)
```

```
## Classes 'tbl_df', 'tbl' and 'data.frame':	468 obs. of  6 variables:
##  $ businessentityid  : int  276 280 277 287 286 274 290 275 276 275 ...
##  $ orderdate         : Date, format: "2013-12-31" "2011-07-01" ...
##  $ sales_total       : num  497156 153059 333179 42042 185822 ...
##  $ day               : num  31 1 30 31 30 1 31 30 31 29 ...
##  $ adjusted_orderdate: Date, format: "2013-12-31" "2011-06-30" ...
##  $ year_month        : Date, format: "2013-12-01" "2011-06-01" ...
```

```r
# View(sales_data_fiscal_year)
```

Put the two parts together: `sales_data_fiscal_year` and `person_info` to yield the final query.


```r
salesperson_sales_by_fiscal_years_dplyr <- sales_data_fiscal_year %>% 
  left_join(salesperson_info) %>% 
  filter(!is.na(territoryid))
```

```
## Joining, by = "businessentityid"
```
 Notice that we're dropping the Sales Managers -- who don't have a `territoryid`.

## Compare the official from a view and the dplyr output

Use `pivot_wider` to make it easier to compare the native view to our dplyr version.


```r
salesperson_sales_by_fiscal_years_dplyr %>% 
  mutate(calendar_year = year(adjusted_orderdate)) %>% #names()
  group_by(full_name, territory_name, calendar_year) %>% 
  summarize(sales_total = sum(sales_total)) %>% 
  # select(full_name, territory_name, calendar_year, sales_total) %>% 
  ungroup() %>% 
  pivot_wider(names_from = calendar_year, values_from = sales_total, values_fill = 0) %>% 
  arrange(territory_name, full_name)
```

```
## # A tibble: 14 x 6
##    full_name                  territory_name   `2011`   `2012`   `2013`   `2014`
##    <chr>                      <chr>             <dbl>    <dbl>    <dbl>    <dbl>
##  1 Lynn N Tsoflias            Australia            0        0   836055.  585756.
##  2 Garrett R Vargas           Canada          613330. 1170331. 1389837.  435949.
##  3 José Edvaldo Saraiva       Canada         1338400. 1672323. 1870884. 1044811.
##  4 Jillian Carson             Central        1631265. 3997669. 3396776. 1040093.
##  5 Ranjit R Varkey Chudukatil France               0   996292. 2646078.  867519.
##  6 Rachel B Valdez            Germany              0        0  1245459.  581608.
##  7 Michael G Blythe           Northeast      1031655. 3219626. 3985375. 1057247.
##  8 David R Campbell           Northwest       726049. 1162008. 1351422.  490466.
##  9 Pamela O Ansman-Wolfe      Northwest       838589. 1018161.  963421.  504932.
## 10 Tete A Mensa-Annan         Northwest            0   441640. 1269909.  600997.
## 11 Tsvi Michael Reiter        Southeast      1833198. 2362528. 2188083.  787204.
## 12 Linda C Mitchell           Southwest      1530233. 3454391. 4111295. 1271089.
## 13 Shu K Ito                  Southwest      1046490. 2215318. 2387256.  777942.
## 14 Jae B Pak                  United Kingdom       0  3014278. 4106064. 1382997.
```

```r
  # pivot_wider(names_from = fiscal_year, values_from = sales_total)

v_salesperson_sales_by_fiscal_years_data %>% # names()
  select(-jobtitle, -salespersonid) %>%
  pivot_wider(names_from = fiscalyear, values_from = salestotal, values_fill = 0) %>% 
  arrange(salesterritory, fullname)
```

```
## # A tibble: 14 x 6
##    fullname                   salesterritory  `2011`   `2012`   `2013`   `2014`
##    <chr>                      <chr>            <dbl>    <dbl>    <dbl>    <dbl>
##  1 Lynn N Tsoflias            Australia           0        0   184106. 1237705.
##  2 Garrett R Vargas           Canada           9109. 1254087. 1179531. 1166720.
##  3 José Edvaldo Saraiva       Canada         106252. 2171995. 1388793. 2259378.
##  4 Jillian Carson             Central         46696. 3496244. 3940665. 2582199.
##  5 Ranjit R Varkey Chudukatil France              0   360246. 1770367. 2379277.
##  6 Rachel B Valdez            Germany             0        0   371973. 1455094.
##  7 Michael G Blythe           Northeast       63763. 2399593. 3765459. 3065088.
##  8 David R Campbell           Northwest       69473. 1291905. 1151081. 1217487.
##  9 Pamela O Ansman-Wolfe      Northwest       24433. 1533076.  587779. 1179815.
## 10 Tete A Mensa-Annan         Northwest           0        0   959000. 1353546.
## 11 Tsvi Michael Reiter        Southeast      104419. 3037175. 2159685. 1869733.
## 12 Linda C Mitchell           Southwest        5476. 3013884. 4064078. 3283569.
## 13 Shu K Ito                  Southwest       59708. 1953001. 2439216. 1975080.
## 14 Jae B Pak                  United Kingdom      0   963345. 4188307. 3351687.
```

The column names don't match up, partly because we are using snake case convention for derived elements.


```r
names(salesperson_sales_by_fiscal_years_dplyr) %>% sort()
```

```
##  [1] "adjusted_orderdate" "businessentityid"   "day"               
##  [4] "full_name"          "jobtitle"           "orderdate"         
##  [7] "sales_total"        "territory_name"     "territoryid"       
## [10] "year_month"
```

```r
names(v_salesperson_sales_by_fiscal_years_data) %>% sort()
```

```
## [1] "fiscalyear"     "fullname"       "jobtitle"       "salespersonid" 
## [5] "salesterritory" "salestotal"
```



```r
sales_order_header_fy <- tbl(con, in_schema("sales", "salesorderheader")) %>% 
  mutate(sales_order_year = year(orderdate),
         sales_order_month = month(orderdate)) %>% 
 select(sales_order_year, sales_order_month, salespersonid, subtotal, orderdate)
```

Why 3 sales folks in vsalesperson don’t show up in 2014 vsalespersonsalesbyfiscalyearsdata

Different environments / SQL dialects

## Revise the view

repeat the function creation strategy from 083 --

  * correct the date
  * extract the fiscal year


  * What about by month? This could be motivation for creating a new view that does aggregation in the database, rather than in R.
  * See SQL code for 'vsalespersonsalesbyfiscalyearsdata'. Consider:
  * Modifying that to include quantity of sales.
  * Modifying that to include monthly totals, in addition to the yearly totals that it already has.
  * Why are 3 of the sales people from 'vsalesperson' missing in 'vsalespersonsalesbyfiscalyearsdata'?
     * Amy Alberts
     * Stephen Jiang
     * Syed Abbas
  * Making the change may not be your prerogative, but it's your responsibility to propose any reasonable changes to those who have the authority to make the make the change.


## Save a `view` in the database


```r
connection_close(con) # Use in an interactive setting
# dbDisconnect(con)     # Use in non-interactive setting
```

