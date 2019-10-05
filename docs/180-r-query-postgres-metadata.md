# Getting metadata about and from PostgreSQL {#chapter_postgresql-metadata}

> This chapter demonstrates:
> 
> * What kind of data about the database is contained in a dbms
> * Several methods for obtaining metadata from the dbms

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)
library(here)
require(knitr)
library(dbplyr)
library(sqlpetr)
```

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go. 

```r
sp_docker_start("adventureworks")
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
## Views trick parked here for the time being

### Explore the vsalelsperson and vsalespersonsalesbyfiscalyearsdata views

The following trick goes later in the book, where it's used to prove the finding that to make sense of othe data you need to 

```r
cat(unlist(dbGetQuery(con, "select pg_get_viewdef('sales.vsalesperson', true)")))
```

```
##  SELECT s.businessentityid,
##     p.title,
##     p.firstname,
##     p.middlename,
##     p.lastname,
##     p.suffix,
##     e.jobtitle,
##     pp.phonenumber,
##     pnt.name AS phonenumbertype,
##     ea.emailaddress,
##     p.emailpromotion,
##     a.addressline1,
##     a.addressline2,
##     a.city,
##     sp.name AS stateprovincename,
##     a.postalcode,
##     cr.name AS countryregionname,
##     st.name AS territoryname,
##     st."group" AS territorygroup,
##     s.salesquota,
##     s.salesytd,
##     s.saleslastyear
##    FROM sales.salesperson s
##      JOIN humanresources.employee e ON e.businessentityid = s.businessentityid
##      JOIN person.person p ON p.businessentityid = s.businessentityid
##      JOIN person.businessentityaddress bea ON bea.businessentityid = s.businessentityid
##      JOIN person.address a ON a.addressid = bea.addressid
##      JOIN person.stateprovince sp ON sp.stateprovinceid = a.stateprovinceid
##      JOIN person.countryregion cr ON cr.countryregioncode::text = sp.countryregioncode::text
##      LEFT JOIN sales.salesterritory st ON st.territoryid = s.territoryid
##      LEFT JOIN person.emailaddress ea ON ea.businessentityid = p.businessentityid
##      LEFT JOIN person.personphone pp ON pp.businessentityid = p.businessentityid
##      LEFT JOIN person.phonenumbertype pnt ON pnt.phonenumbertypeid = pp.phonenumbertypeid;
```



```
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           pg_get_viewdef
## 1  SELECT granular.salespersonid,\n    granular.fullname,\n    granular.jobtitle,\n    granular.salesterritory,\n    sum(granular.subtotal) AS salestotal,\n    granular.fiscalyear\n   FROM ( SELECT soh.salespersonid,\n            ((p.firstname::text || ' '::text) || COALESCE(p.middlename::text || ' '::text, ''::text)) || p.lastname::text AS fullname,\n            e.jobtitle,\n            st.name AS salesterritory,\n            soh.subtotal,\n            date_part('year'::text, soh.orderdate + '6 mons'::interval) AS fiscalyear\n           FROM sales.salesperson sp\n             JOIN sales.salesorderheader soh ON sp.businessentityid = soh.salespersonid\n             JOIN sales.salesterritory st ON sp.territoryid = st.territoryid\n             JOIN humanresources.employee e ON soh.salespersonid = e.businessentityid\n             JOIN person.person p ON p.businessentityid = sp.businessentityid) granular\n  GROUP BY granular.salespersonid, granular.fullname, granular.jobtitle, granular.salesterritory, granular.fiscalyear;
```



## Database contents and structure

After just looking at the data you seek, it might be worthwhile stepping back and looking at the big picture.

### Database structure

For large or complex databases you need to use both the available documentation for your database (e.g.,  [the dvdrental](http://www.postgresqltutorial.com/postgresql-sample-database/) database) and the other empirical tools that are available.  For example it's worth learning to interpret the symbols in an [Entity Relationship Diagram](https://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model):

![](./screenshots/ER-diagram-symbols.png)

The `information_schema` is a trove of information *about* the database.  Its format is more or less consistent across the different SQL implementations that are available.   Here we explore some of what's available using several different methods.  PostgreSQL stores [a lot of metadata](https://www.postgresql.org/docs/current/static/infoschema-columns.html).

### Contents of the `information_schema` 
For this chapter R needs the `dbplyr` package to access alternate schemas.  A [schema](http://www.postgresqltutorial.com/postgresql-server-and-database-objects/) is an object that contains one or more tables.  Most often there will be a default schema, but to access the metadata, you need to explicitly specify which schema contains the data you want.

### What tables are in the database?
The simplest way to get a list of tables is with ... *NO LONGER WORKS*:

```r
schema_list <- tbl(con, in_schema("information_schema", "schemata")) %>%
  select(catalog_name, schema_name, schema_owner) %>%
  collect()

sp_print_df(head(schema_list))
```

<!--html_preserve--><div id="htmlwidget-37146cf6ecae2786c03e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-37146cf6ecae2786c03e">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["adventureworks","adventureworks","adventureworks","adventureworks","adventureworks","adventureworks"],["sales","sa","purchasing","pu","production","pr"],["postgres","postgres","postgres","postgres","postgres","postgres"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>catalog_name<\/th>\n      <th>schema_name<\/th>\n      <th>schema_owner<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
### Digging into the `information_schema`

We usually need more detail than just a list of tables. Most SQL databases have an `information_schema` that has a standard structure to describe and control the database.

The `information_schema` is in a different schema from the default, so to connect to the `tables` table in the  `information_schema` we connect to the database in a different way:

```r
table_info_schema_table <- tbl(con, dbplyr::in_schema("information_schema", "tables"))
```
The `information_schema` is large and complex and contains 343 tables.  So it's easy to get lost in it.

This query retrieves a list of the tables in the database that includes additional detail, not just the name of the table.

```r
table_info <- table_info_schema_table %>%
  # filter(table_schema == "public") %>%
  select(table_catalog, table_schema, table_name, table_type) %>%
  arrange(table_type, table_name) %>%
  collect()

sp_print_df(head(table_info))
```

<!--html_preserve--><div id="htmlwidget-2b78b0c355ded83f71d2" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-2b78b0c355ded83f71d2">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["adventureworks","adventureworks","adventureworks","adventureworks","adventureworks","adventureworks"],["person","person","production","person","person","person"],["address","addresstype","billofmaterials","businessentity","businessentityaddress","businessentitycontact"],["BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_catalog<\/th>\n      <th>table_schema<\/th>\n      <th>table_name<\/th>\n      <th>table_type<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
In this context `table_catalog` is synonymous with `database`.

Notice that *VIEWS* are composites made up of one or more *BASE TABLES*.

The SQL world has its own terminology.  For example `rs` is shorthand for `result set`.  That's equivalent to using `df` for a `data frame`.  The following SQL query returns the same information as the previous dplyr code.

```r
rs <- dbGetQuery(
  con,
  "select table_catalog, table_schema, table_name, table_type 
  from information_schema.tables 
  where table_schema not in ('pg_catalog','information_schema')
  order by table_type, table_name 
  ;"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-e983c6ab438af11d5328" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-e983c6ab438af11d5328">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["adventureworks","adventureworks","adventureworks","adventureworks","adventureworks","adventureworks"],["person","person","production","person","person","person"],["address","addresstype","billofmaterials","businessentity","businessentityaddress","businessentitycontact"],["BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_catalog<\/th>\n      <th>table_schema<\/th>\n      <th>table_name<\/th>\n      <th>table_type<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## What columns do those tables contain?

Of course, the `DBI` package has a `dbListFields` function that provides the simplest way to get the minimum, a list of column names:

```r
# DBI::dbListFields(con, "rental")
```

But the `information_schema` has a lot more useful information that we can use.  

```r
columns_info_schema_table <- tbl(con, dbplyr::in_schema("information_schema", "columns"))
```

Since the `information_schema` contains 2961 columns, we are narrowing our focus to just one table.  This query retrieves more information about the `rental` table:

```r
columns_info_schema_info <- columns_info_schema_table %>%
  # filter(table_schema == "public") %>%
  select(
    table_catalog, table_schema, table_name, column_name, data_type, ordinal_position,
    character_maximum_length, column_default, numeric_precision, numeric_precision_radix
  ) %>%
  collect(n = Inf) %>%
  mutate(data_type = case_when(
    data_type == "character varying" ~ paste0(data_type, " (", character_maximum_length, ")"),
    data_type == "real" ~ paste0(data_type, " (", numeric_precision, ",", numeric_precision_radix, ")"),
    TRUE ~ data_type
  )) %>%
  # filter(table_name == "rental") %>%
  select(-table_schema, -numeric_precision, -numeric_precision_radix)

glimpse(columns_info_schema_info)
```

```
## Observations: 2,961
## Variables: 7
## $ table_catalog            <chr> "adventureworks", "adventureworks", "ad…
## $ table_name               <chr> "pg_proc", "pg_proc", "pg_proc", "pg_pr…
## $ column_name              <chr> "proname", "pronamespace", "proowner", …
## $ data_type                <chr> "name", "oid", "oid", "oid", "real (24,…
## $ ordinal_position         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, …
## $ character_maximum_length <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
## $ column_default           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
```

```r
sp_print_df(head(columns_info_schema_info))
```

<!--html_preserve--><div id="htmlwidget-ed744d0b48691d57f982" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-ed744d0b48691d57f982">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["adventureworks","adventureworks","adventureworks","adventureworks","adventureworks","adventureworks"],["pg_proc","pg_proc","pg_proc","pg_proc","pg_proc","pg_proc"],["proname","pronamespace","proowner","prolang","procost","prorows"],["name","oid","oid","oid","real (24,2)","real (24,2)"],[1,2,3,4,5,6],[null,null,null,null,null,null],[null,null,null,null,null,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_catalog<\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>data_type<\/th>\n      <th>ordinal_position<\/th>\n      <th>character_maximum_length<\/th>\n      <th>column_default<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### What is the difference between a `VIEW` and a `BASE TABLE`?

The `BASE TABLE` has the underlying data in the database

```r
table_info_schema_table %>%
  filter( table_type == "BASE TABLE") %>%
  # filter(table_schema == "public" & table_type == "BASE TABLE") %>%
  select(table_name, table_type) %>%
  left_join(columns_info_schema_table, by = c("table_name" = "table_name")) %>%
  select(
    table_type, table_name, column_name, data_type, ordinal_position,
    column_default
  ) %>%
  collect(n = Inf) %>%
  filter(str_detect(table_name, "cust")) %>%
  head() %>% 
  sp_print_df()
```

<!--html_preserve--><div id="htmlwidget-5f6bcf6eae04ab45035c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5f6bcf6eae04ab45035c">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE"],["customer","customer","customer","customer","customer","customer"],["personid","storeid","territoryid","rowguid","modifieddate","customerid"],["integer","integer","integer","uuid","timestamp without time zone","integer"],[2,3,4,5,6,1],[null,null,null,"uuid_generate_v1()","now()","nextval('sales.customer_customerid_seq'::regclass)"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_type<\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>data_type<\/th>\n      <th>ordinal_position<\/th>\n      <th>column_default<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":5},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Probably should explore how the `VIEW` is made up of data from BASE TABLEs.

```r
table_info_schema_table %>%
  filter( table_type == "VIEW") %>%
  # filter(table_schema == "public" & table_type == "VIEW") %>%
  select(table_name, table_type) %>%
  left_join(columns_info_schema_table, by = c("table_name" = "table_name")) %>%
  select(
    table_type, table_name, column_name, data_type, ordinal_position,
    column_default
  ) %>%
  collect(n = Inf) %>%
  filter(str_detect(table_name, "cust")) %>%
  head() %>% 
  sp_print_df()
```

<!--html_preserve--><div id="htmlwidget-03a707ce5d414ed499c1" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-03a707ce5d414ed499c1">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["VIEW","VIEW","VIEW","VIEW","VIEW","VIEW"],["vindividualcustomer","vindividualcustomer","vindividualcustomer","vindividualcustomer","vindividualcustomer","vindividualcustomer"],["businessentityid","title","firstname","middlename","lastname","suffix"],["integer","character varying","character varying","character varying","character varying","character varying"],[1,2,3,4,5,6],[null,null,null,null,null,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_type<\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>data_type<\/th>\n      <th>ordinal_position<\/th>\n      <th>column_default<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":5},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### What data types are found in the database?

```r
columns_info_schema_info %>% 
  count(data_type) %>% 
  head() %>% 
  sp_print_df()
```

<!--html_preserve--><div id="htmlwidget-5961b524ec6e5d8f457a" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5961b524ec6e5d8f457a">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["\"char\"","abstime","anyarray","ARRAY","bigint","boolean"],[38,2,9,75,161,136]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>data_type<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Characterizing how things are named

Names are the handle for accessing the data.  Tables and columns may or may not be named consistently or in a way that makes sense to you.  You should look at these names *as data*.

### Counting columns and name reuse
Pull out some rough-and-ready but useful statistics about your database.  Since we are in SQL-land we talk about variables as `columns`.

*this is wrong!*


```r
public_tables <- columns_info_schema_table %>%
  # filter(str_detect(table_name, "pg_") == FALSE) %>%
  # filter(table_schema == "public") %>%
  collect()

public_tables %>%
  count(table_name, sort = TRUE) %>% 
  head(n = 15) %>% 
  sp_print_df()
```

<!--html_preserve--><div id="htmlwidget-30c61db7c56a22288922" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-30c61db7c56a22288922">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"],["routines","columns","p","pg_class","parameters","attributes","pg_type","element_types","user_defined_types","pg_proc","domains","pg_statistic","soh","pg_constraint","product"],[82,44,40,33,32,31,30,29,29,28,27,26,26,25,25]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

How many *column names* are shared across tables (or duplicated)?

```r
public_tables %>% count(column_name, sort = TRUE) %>% 
  filter(n > 1) %>% 
  head()
```

```
## # A tibble: 6 x 2
##   column_name          n
##   <chr>            <int>
## 1 modifieddate       140
## 2 rowguid             61
## 3 id                  60
## 4 name                59
## 5 businessentityid    49
## 6 productid           32
```

How many column names are unique?

```r
public_tables %>% 
  count(column_name) %>% 
  filter(n == 1) %>% 
  count() %>% 
  head()
```

```
## # A tibble: 1 x 1
##       n
##   <int>
## 1   882
```

## Database keys

### Direct SQL

How do we use this output?  Could it be generated by dplyr?

```r
rs <- dbGetQuery(
  con,
  "
--SELECT conrelid::regclass as table_from
select table_catalog||'.'||table_schema||'.'||table_name table_name
, conname, pg_catalog.pg_get_constraintdef(r.oid, true) as condef
FROM information_schema.columns c,pg_catalog.pg_constraint r
WHERE 1 = 1 --r.conrelid = '16485' 
  AND r.contype  in ('f','p') ORDER BY 1
;"
)
glimpse(rs)
```

```
## Observations: 467,838
## Variables: 3
## $ table_name <chr> "adventureworks.hr.d", "adventureworks.hr.d", "advent…
## $ conname    <chr> "FK_SalesOrderDetail_SpecialOfferProduct_SpecialOffer…
## $ condef     <chr> "FOREIGN KEY (specialofferid, productid) REFERENCES s…
```

```r
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-35c72f52c6841456fbea" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-35c72f52c6841456fbea">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["adventureworks.hr.d","adventureworks.hr.d","adventureworks.hr.d","adventureworks.hr.d","adventureworks.hr.d","adventureworks.hr.d"],["FK_SalesOrderDetail_SpecialOfferProduct_SpecialOfferIDProductID","FK_SalesOrderDetail_SpecialOfferProduct_SpecialOfferIDProductID","FK_SalesOrderHeader_Address_BillToAddressID","FK_SalesOrderHeader_Address_BillToAddressID","FK_SalesOrderHeader_Address_BillToAddressID","FK_SalesOrderHeader_Address_BillToAddressID"],["FOREIGN KEY (specialofferid, productid) REFERENCES sales.specialofferproduct(specialofferid, productid)","FOREIGN KEY (specialofferid, productid) REFERENCES sales.specialofferproduct(specialofferid, productid)","FOREIGN KEY (billtoaddressid) REFERENCES person.address(addressid)","FOREIGN KEY (billtoaddressid) REFERENCES person.address(addressid)","FOREIGN KEY (billtoaddressid) REFERENCES person.address(addressid)","FOREIGN KEY (billtoaddressid) REFERENCES person.address(addressid)"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>conname<\/th>\n      <th>condef<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
The following is more compact and looks more useful.  What is the difference between the two?

```r
rs <- dbGetQuery(
  con,
  "select conrelid::regclass as table_from
      ,c.conname
      ,pg_get_constraintdef(c.oid)
  from pg_constraint c
  join pg_namespace n on n.oid = c.connamespace
 where c.contype in ('f','p')
   and n.nspname = 'public'
order by conrelid::regclass::text, contype DESC;
"
)
glimpse(rs)
```

```
## Observations: 0
## Variables: 3
## $ table_from           <chr> 
## $ conname              <chr> 
## $ pg_get_constraintdef <chr>
```

```r
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-a16acba4f07eaec47c17" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a16acba4f07eaec47c17">{"x":{"filter":"none","data":[[],[],[],[]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_from<\/th>\n      <th>conname<\/th>\n      <th>pg_get_constraintdef<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
dim(rs)[1]
```

```
## [1] 0
```

### Database keys with dplyr

This query shows the primary and foreign keys in the database.

```r
tables <- tbl(con, dbplyr::in_schema("information_schema", "tables"))
table_constraints <- tbl(con, dbplyr::in_schema("information_schema", "table_constraints"))
key_column_usage <- tbl(con, dbplyr::in_schema("information_schema", "key_column_usage"))
referential_constraints <- tbl(con, dbplyr::in_schema("information_schema", "referential_constraints"))
constraint_column_usage <- tbl(con, dbplyr::in_schema("information_schema", "constraint_column_usage"))

keys <- tables %>%
  left_join(table_constraints, by = c(
    "table_catalog" = "table_catalog",
    "table_schema" = "table_schema",
    "table_name" = "table_name"
  )) %>%
  # table_constraints %>%
  filter(constraint_type %in% c("FOREIGN KEY", "PRIMARY KEY")) %>%
  left_join(key_column_usage,
    by = c(
      "table_catalog" = "table_catalog",
      "constraint_catalog" = "constraint_catalog",
      "constraint_schema" = "constraint_schema",
      "table_name" = "table_name",
      "table_schema" = "table_schema",
      "constraint_name" = "constraint_name"
    )
  ) %>%
  # left_join(constraint_column_usage) %>% # does this table add anything useful?
  select(table_name, table_type, constraint_name, constraint_type, column_name, ordinal_position) %>%
  arrange(table_name) %>%
  collect()
glimpse(keys)
```

```
## Observations: 190
## Variables: 6
## $ table_name       <chr> "address", "address", "addresstype", "billofmat…
## $ table_type       <chr> "BASE TABLE", "BASE TABLE", "BASE TABLE", "BASE…
## $ constraint_name  <chr> "FK_Address_StateProvince_StateProvinceID", "PK…
## $ constraint_type  <chr> "FOREIGN KEY", "PRIMARY KEY", "PRIMARY KEY", "F…
## $ column_name      <chr> "stateprovinceid", "addressid", "addresstypeid"…
## $ ordinal_position <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 2, 1, 1,…
```

```r
sp_print_df(head(keys))
```

<!--html_preserve--><div id="htmlwidget-f1e0d329b385b65f967e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f1e0d329b385b65f967e">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["address","address","addresstype","billofmaterials","billofmaterials","billofmaterials"],["BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE","BASE TABLE"],["FK_Address_StateProvince_StateProvinceID","PK_Address_AddressID","PK_AddressType_AddressTypeID","FK_BillOfMaterials_Product_ComponentID","FK_BillOfMaterials_Product_ProductAssemblyID","FK_BillOfMaterials_UnitMeasure_UnitMeasureCode"],["FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY"],["stateprovinceid","addressid","addresstypeid","componentid","productassemblyid","unitmeasurecode"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>table_type<\/th>\n      <th>constraint_name<\/th>\n      <th>constraint_type<\/th>\n      <th>column_name<\/th>\n      <th>ordinal_position<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":6},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

What do we learn from the following query?  How is it useful? 

```r
rs <- dbGetQuery(
  con,
  "SELECT r.*,
  pg_catalog.pg_get_constraintdef(r.oid, true) as condef
  FROM pg_catalog.pg_constraint r
  WHERE 1=1 --r.conrelid = '16485' AND r.contype = 'f' ORDER BY 1;
  "
)

head(rs)
```

```
##                        conname connamespace contype condeferrable
## 1 cardinal_number_domain_check        12771       c         FALSE
## 2              yes_or_no_check        12771       c         FALSE
## 3        CK_Employee_BirthDate        16386       c         FALSE
## 4           CK_Employee_Gender        16386       c         FALSE
## 5         CK_Employee_HireDate        16386       c         FALSE
## 6    CK_Employee_MaritalStatus        16386       c         FALSE
##   condeferred convalidated conrelid contypid conindid conparentid
## 1       FALSE         TRUE        0    12785        0           0
## 2       FALSE         TRUE        0    12797        0           0
## 3       FALSE         TRUE    16450        0        0           0
## 4       FALSE         TRUE    16450        0        0           0
## 5       FALSE         TRUE    16450        0        0           0
## 6       FALSE         TRUE    16450        0        0           0
##   confrelid confupdtype confdeltype confmatchtype conislocal coninhcount
## 1         0                                             TRUE           0
## 2         0                                             TRUE           0
## 3         0                                             TRUE           0
## 4         0                                             TRUE           0
## 5         0                                             TRUE           0
## 6         0                                             TRUE           0
##   connoinherit conkey confkey conpfeqop conppeqop conffeqop conexclop
## 1        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 2        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 3        FALSE    {5}    <NA>      <NA>      <NA>      <NA>      <NA>
## 4        FALSE    {7}    <NA>      <NA>      <NA>      <NA>      <NA>
## 5        FALSE    {8}    <NA>      <NA>      <NA>      <NA>      <NA>
## 6        FALSE    {6}    <NA>      <NA>      <NA>      <NA>      <NA>
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    conbin
## 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         {OPEXPR :opno 525 :opfuncid 150 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({COERCETODOMAINVALUE :typeId 23 :typeMod -1 :collation 0 :location 195} {CONST :consttype 23 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 204 :constvalue 4 [ 0 0 0 0 0 0 0 0 ]}) :location 201}
## 2                                                                                                                                                                                 {SCALARARRAYOPEXPR :opno 98 :opfuncid 67 :useOr true :inputcollid 100 :args ({RELABELTYPE :arg {COERCETODOMAINVALUE :typeId 1043 :typeMod 7 :collation 100 :location 121} :resulttype 25 :resulttypmod -1 :resultcollid 100 :relabelformat 2 :location -1} {ARRAYCOERCEEXPR :arg {ARRAY :array_typeid 1015 :array_collid 100 :element_typeid 1043 :elements ({CONST :consttype 1043 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 131 :constvalue 7 [ 28 0 0 0 89 69 83 ]} {CONST :consttype 1043 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 138 :constvalue 6 [ 24 0 0 0 78 79 ]}) :multidims false :location -1} :elemexpr {RELABELTYPE :arg {CASETESTEXPR :typeId 1043 :typeMod -1 :collation 0} :resulttype 25 :resulttypmod -1 :resultcollid 100 :relabelformat 2 :location -1} :resulttype 1009 :resulttypmod -1 :resultcollid 100 :coerceformat 2 :location -1}) :location 127}
## 3     {BOOLEXPR :boolop and :args ({OPEXPR :opno 1098 :opfuncid 1090 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({VAR :varno 1 :varattno 5 :vartype 1082 :vartypmod -1 :varcollid 0 :varlevelsup 0 :varnoold 1 :varoattno 5 :location 804} {CONST :consttype 1082 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 817 :constvalue 4 [ 33 -100 -1 -1 -1 -1 -1 -1 ]}) :location 814} {OPEXPR :opno 2359 :opfuncid 2352 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({VAR :varno 1 :varattno 5 :vartype 1082 :vartypmod -1 :varcollid 0 :varlevelsup 0 :varnoold 1 :varoattno 5 :location 842} {OPEXPR :opno 1329 :opfuncid 1190 :opresulttype 1184 :opretset false :opcollid 0 :inputcollid 0 :args ({FUNCEXPR :funcid 1299 :funcresulttype 1184 :funcretset false :funcvariadic false :funcformat 0 :funccollid 0 :inputcollid 0 :args <> :location 856} {CONST :consttype 1186 :consttypmod -1 :constcollid 0 :constlen 16 :constbyval false :constisnull false :location 864 :constvalue 16 [ 0 0 0 0 0 0 0 0 0 0 0 0 -40 0 0 0 ]}) :location 862}) :location 852}) :location 837}
## 4                                                                                                                                                                                                                  {SCALARARRAYOPEXPR :opno 98 :opfuncid 67 :useOr true :inputcollid 100 :args ({FUNCEXPR :funcid 871 :funcresulttype 25 :funcretset false :funcvariadic false :funcformat 0 :funccollid 100 :inputcollid 100 :args ({FUNCEXPR :funcid 401 :funcresulttype 25 :funcretset false :funcvariadic false :funcformat 1 :funccollid 100 :inputcollid 100 :args ({VAR :varno 1 :varattno 7 :vartype 1042 :vartypmod 5 :varcollid 100 :varlevelsup 0 :varnoold 1 :varoattno 7 :location 941}) :location 948}) :location 934} {ARRAY :array_typeid 1009 :array_collid 100 :element_typeid 25 :elements ({CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 969 :constvalue 5 [ 20 0 0 0 77 ]} {CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 980 :constvalue 5 [ 20 0 0 0 70 ]}) :multidims false :location 963}) :location 956}
## 5 {BOOLEXPR :boolop and :args ({OPEXPR :opno 1098 :opfuncid 1090 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({VAR :varno 1 :varattno 8 :vartype 1082 :vartypmod -1 :varcollid 0 :varlevelsup 0 :varnoold 1 :varoattno 8 :location 1042} {CONST :consttype 1082 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 1054 :constvalue 4 [ 1 -5 -1 -1 -1 -1 -1 -1 ]}) :location 1051} {OPEXPR :opno 2359 :opfuncid 2352 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({VAR :varno 1 :varattno 8 :vartype 1082 :vartypmod -1 :varcollid 0 :varlevelsup 0 :varnoold 1 :varoattno 8 :location 1079} {OPEXPR :opno 1327 :opfuncid 1189 :opresulttype 1184 :opretset false :opcollid 0 :inputcollid 0 :args ({FUNCEXPR :funcid 1299 :funcresulttype 1184 :funcretset false :funcvariadic false :funcformat 0 :funccollid 0 :inputcollid 0 :args <> :location 1092} {CONST :consttype 1186 :consttypmod -1 :constcollid 0 :constlen 16 :constbyval false :constisnull false :location 1100 :constvalue 16 [ 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 ]}) :location 1098}) :location 1088}) :location 1074}
## 6                                                                                                                                                                                                           {SCALARARRAYOPEXPR :opno 98 :opfuncid 67 :useOr true :inputcollid 100 :args ({FUNCEXPR :funcid 871 :funcresulttype 25 :funcretset false :funcvariadic false :funcformat 0 :funccollid 100 :inputcollid 100 :args ({FUNCEXPR :funcid 401 :funcresulttype 25 :funcretset false :funcvariadic false :funcformat 1 :funccollid 100 :inputcollid 100 :args ({VAR :varno 1 :varattno 6 :vartype 1042 :vartypmod 5 :varcollid 100 :varlevelsup 0 :varnoold 1 :varoattno 6 :location 1181}) :location 1195}) :location 1174} {ARRAY :array_typeid 1009 :array_collid 100 :element_typeid 25 :elements ({CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 1216 :constvalue 5 [ 20 0 0 0 77 ]} {CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 1227 :constvalue 5 [ 20 0 0 0 83 ]}) :multidims false :location 1210}) :location 1203}
##                                                                                       consrc
## 1                                                                               (VALUE >= 0)
## 2 ((VALUE)::text = ANY ((ARRAY['YES'::character varying, 'NO'::character varying])::text[]))
## 3      ((birthdate >= '1930-01-01'::date) AND (birthdate <= (now() - '18 years'::interval)))
## 4                                (upper((gender)::text) = ANY (ARRAY['M'::text, 'F'::text]))
## 5           ((hiredate >= '1996-07-01'::date) AND (hiredate <= (now() + '1 day'::interval)))
## 6                         (upper((maritalstatus)::text) = ANY (ARRAY['M'::text, 'S'::text]))
##                                                                                         condef
## 1                                                                           CHECK (VALUE >= 0)
## 2 CHECK (VALUE::text = ANY (ARRAY['YES'::character varying, 'NO'::character varying]::text[]))
## 3      CHECK (birthdate >= '1930-01-01'::date AND birthdate <= (now() - '18 years'::interval))
## 4                              CHECK (upper(gender::text) = ANY (ARRAY['M'::text, 'F'::text]))
## 5           CHECK (hiredate >= '1996-07-01'::date AND hiredate <= (now() + '1 day'::interval))
## 6                       CHECK (upper(maritalstatus::text) = ANY (ARRAY['M'::text, 'S'::text]))
```

## Creating your own data dictionary

If you are going to work with a database for an extended period it can be useful to create your own data dictionary. This can take the form of [keeping detaild notes](https://caitlinhudon.com/2018/10/30/data-dictionaries/) as well as extracting metadata from the dbms. Here is an illustration of the idea.

*This probably doens't work anymore*

```r
# some_tables <- c("rental", "city", "store")
# 
# all_meta <- map_df(some_tables, sp_get_dbms_data_dictionary, con = con)
# 
# all_meta
# 
# glimpse(all_meta)
# 
# sp_print_df(head(all_meta))
```
## Save your work!

The work you do to understand the structure and contents of a database can be useful for others (including future-you).  So at the end of a session, you might look at all the data frames you want to save.  Consider saving them in a form where you can add notes at the appropriate level (as in a Google Doc representing table or columns that you annotate over time).

```r
ls()
```

```
##  [1] "columns_info_schema_info"  "columns_info_schema_table"
##  [3] "con"                       "constraint_column_usage"  
##  [5] "key_column_usage"          "keys"                     
##  [7] "public_tables"             "referential_constraints"  
##  [9] "rs"                        "schema_list"              
## [11] "table_constraints"         "table_info"               
## [13] "table_info_schema_table"   "tables"
```


