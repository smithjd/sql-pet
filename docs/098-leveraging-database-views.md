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
library(gt)

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

## Existing views as a resource

### Define a database `view`

??

Three reasons for views:
  * Performance: aggregation calculations done on the server.
  * Conceptual abstraction/simplification, e.g. looking at monthly subtotals, rather than having to do the aggregation in each of your   * queries.
  * Reuse: putting commonly used code in one place.
    * If you find any problems, it only needs to be fixed in one place.
    * Simplifies downstream code, which will be simpler.
  * Managing data provenance 

  * They are boring, but very important

### Unpack and inspect a view

```r
dbGetQuery(con, "select pg_get_viewdef('sales.vsalespersonsalesbyfiscalyearsdata', true)")
```

```
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           pg_get_viewdef
## 1  SELECT granular.salespersonid,\n    granular.fullname,\n    granular.jobtitle,\n    granular.salesterritory,\n    sum(granular.subtotal) AS salestotal,\n    granular.fiscalyear\n   FROM ( SELECT soh.salespersonid,\n            ((p.firstname::text || ' '::text) || COALESCE(p.middlename::text || ' '::text, ''::text)) || p.lastname::text AS fullname,\n            e.jobtitle,\n            st.name AS salesterritory,\n            soh.subtotal,\n            date_part('year'::text, soh.orderdate + '6 mons'::interval) AS fiscalyear\n           FROM sales.salesperson sp\n             JOIN sales.salesorderheader soh ON sp.businessentityid = soh.salespersonid\n             JOIN sales.salesterritory st ON sp.territoryid = st.territoryid\n             JOIN humanresources.employee e ON soh.salespersonid = e.businessentityid\n             JOIN person.person p ON p.businessentityid = sp.businessentityid) granular\n  GROUP BY granular.salespersonid, granular.fullname, granular.jobtitle, granular.salesterritory, granular.fiscalyear;
```

```r
x <- tbl(con, in_schema("sales","vsalespersonsalesbyfiscalyearsdata")) %>% collect()
```

### We recommend leverageing them

## Modifying a view

  * What about by month? This could be motivation for creating a new view that does aggregation in the database, rather than in R.
  * See SQL code for 'vsalespersonsalesbyfiscalyearsdata'. Consider:
  * Modifying that to include quantity of sales.
  * Modifying that to include monthly totals, in addition to the yearly totals that it already has.
  * Why are 3 of the sales people from 'vsalesperson' missing in 'vsalespersonsalesbyfiscalyearsdata'?
     * Amy Alberts
     * Stephen Jiang
     * Syed Abbas

### First draft with dplyr

Save the SQL

Why 3 sales folks in vsalesperson don’t show up in 2014 vsalespersonsalesbyfiscalyearsdata

Different environments / SQL dialects
