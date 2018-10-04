# Getting metadata about and from the database (21)


Note that `tidyverse`, `DBI`, `RPostgres`, `glue`, and `knitr` are loaded.  Also, we've sourced the [`db-login-batch-code.R`]('r-database-docker/book-src/db-login-batch-code.R') file which is used to log in to PostgreSQL.


For this chapter R needs the `dbplyr` package to access `alternate schemas`.  A [schema](http://www.postgresqltutorial.com/postgresql-server-and-database-objects/) is an object that contains one or more tables.  Most often there will be a default schema, but to access the metadata, you need to explicitly specify which schema contains the data you want.


```r
library(dbplyr)
```

```
## 
## Attaching package: 'dbplyr'
```

```
## The following objects are masked from 'package:dplyr':
## 
##     ident, sql
```


## Always look at the data

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go.

```r
system2("docker", "start sql-pet", stdout = TRUE, stderr = TRUE)
```

```
## [1] "sql-pet"
```

```r
con <- wait_for_postgres(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10
)
```

### Look at the data itself

So far in this books we've most often looked at the data by listing a few observations or using a tool like `glimpse`.

```r
rental <- dplyr::tbl(con, "rental")

kable(head(rental))
```


\begin{tabular}{r|l|r|r|l|r|l}
\hline
rental\_id & rental\_date & inventory\_id & customer\_id & return\_date & staff\_id & last\_update\\
\hline
2 & 2005-05-24 22:54:33 & 1525 & 459 & 2005-05-28 19:40:33 & 1 & 2006-02-16 02:30:53\\
\hline
3 & 2005-05-24 23:03:39 & 1711 & 408 & 2005-06-01 22:12:39 & 1 & 2006-02-16 02:30:53\\
\hline
4 & 2005-05-24 23:04:41 & 2452 & 333 & 2005-06-03 01:43:41 & 2 & 2006-02-16 02:30:53\\
\hline
5 & 2005-05-24 23:05:21 & 2079 & 222 & 2005-06-02 04:33:21 & 1 & 2006-02-16 02:30:53\\
\hline
6 & 2005-05-24 23:08:07 & 2792 & 549 & 2005-05-27 01:32:07 & 1 & 2006-02-16 02:30:53\\
\hline
7 & 2005-05-24 23:11:53 & 3995 & 269 & 2005-05-29 20:34:53 & 2 & 2006-02-16 02:30:53\\
\hline
\end{tabular}

```r
glimpse(rental)
```

```
## Observations: ??
## Variables: 7
## $ rental_id    <int> 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1...
## $ rental_date  <dttm> 2005-05-24 22:54:33, 2005-05-24 23:03:39, 2005-0...
## $ inventory_id <int> 1525, 1711, 2452, 2079, 2792, 3995, 2346, 2580, 1...
## $ customer_id  <int> 459, 408, 333, 222, 549, 269, 239, 126, 399, 142,...
## $ return_date  <dttm> 2005-05-28 19:40:33, 2005-06-01 22:12:39, 2005-0...
## $ staff_id     <int> 1, 1, 2, 1, 1, 2, 2, 1, 2, 2, 2, 1, 1, 1, 2, 1, 2...
## $ last_update  <dttm> 2006-02-16 02:30:53, 2006-02-16 02:30:53, 2006-0...
```

### Look at what R sends to `postgreSQL`


```r
rental %>% dplyr::show_query()
```

```
## <SQL>
## SELECT *
## FROM "rental"
```

For large or complex databases, however, you need to use both the available documentation for your database (e.g.,  [the dvdrental](http://www.postgresqltutorial.com/postgresql-sample-database/) database) and the other empirical tools that are available.  For example it's worth learning to interpret the symbols in an [Entity Relationship Diagram](https://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model):

![](./screenshots/ER-diagram-symbols.png)

The `information_schema` is a trove of information *about* the database.  Its format is more or less consistent across the different SQL implementations that are available.   Here we explore some of what's available using several different methods.  Postgres stores [a lot of metadata](https://www.postgresql.org/docs/current/static/infoschema-columns.html).

### Look at what `information_schema` conains
For this chapter R needs the `dbplyr` package to access alternate schemas.  A [schema](http://www.postgresqltutorial.com/postgresql-server-and-database-objects/) is an object that contains one or more tables.  Most often there will be a default schema, but to access the metadata, you need to explicitly specify which schema contains the data you want.

### Look at the tables first
The simplest way to get a list of tables is with 

```r
kable(DBI::dbListTables(con))
```


\begin{tabular}{l}
\hline
x\\
\hline
actor\_info\\
\hline
customer\_list\\
\hline
film\_list\\
\hline
nicer\_but\_slower\_film\_list\\
\hline
sales\_by\_film\_category\\
\hline
staff\\
\hline
sales\_by\_store\\
\hline
staff\_list\\
\hline
category\\
\hline
film\_category\\
\hline
country\\
\hline
actor\\
\hline
language\\
\hline
inventory\\
\hline
payment\\
\hline
rental\\
\hline
city\\
\hline
store\\
\hline
film\\
\hline
address\\
\hline
film\_actor\\
\hline
customer\\
\hline
\end{tabular}
Often we want more detail than just a list of tables.

```r
# table_catalog is the same as `database`.

table_info_schema_table <- tbl(con, dbplyr::in_schema("information_schema", "tables"))
table_info_schema_table %>%
  filter(table_schema == "public") %>%
  select(table_catalog, table_schema, table_name, table_type) %>%
  arrange(table_type, table_name) %>%
  collect() %>%
  kable()
```


\begin{tabular}{l|l|l|l}
\hline
table\_catalog & table\_schema & table\_name & table\_type\\
\hline
dvdrental & public & actor & BASE TABLE\\
\hline
dvdrental & public & address & BASE TABLE\\
\hline
dvdrental & public & category & BASE TABLE\\
\hline
dvdrental & public & city & BASE TABLE\\
\hline
dvdrental & public & country & BASE TABLE\\
\hline
dvdrental & public & customer & BASE TABLE\\
\hline
dvdrental & public & film & BASE TABLE\\
\hline
dvdrental & public & film\_actor & BASE TABLE\\
\hline
dvdrental & public & film\_category & BASE TABLE\\
\hline
dvdrental & public & inventory & BASE TABLE\\
\hline
dvdrental & public & language & BASE TABLE\\
\hline
dvdrental & public & payment & BASE TABLE\\
\hline
dvdrental & public & rental & BASE TABLE\\
\hline
dvdrental & public & staff & BASE TABLE\\
\hline
dvdrental & public & store & BASE TABLE\\
\hline
dvdrental & public & actor\_info & VIEW\\
\hline
dvdrental & public & customer\_list & VIEW\\
\hline
dvdrental & public & film\_list & VIEW\\
\hline
dvdrental & public & nicer\_but\_slower\_film\_list & VIEW\\
\hline
dvdrental & public & sales\_by\_film\_category & VIEW\\
\hline
dvdrental & public & sales\_by\_store & VIEW\\
\hline
dvdrental & public & staff\_list & VIEW\\
\hline
\end{tabular}

```r
table_info_schema_table %>%
  filter(table_schema == "public") %>%  # See alternative below
  select(table_catalog, table_schema, table_name, table_type) %>%
  arrange(table_type, table_name) %>%
  show_query()
```

```
## <SQL>
## SELECT "table_catalog", "table_schema", "table_name", "table_type"
## FROM information_schema.tables
## WHERE ("table_schema" = 'public')
## ORDER BY "table_type", "table_name"
```

```r
# notice that VIEWS are composites made up of one or more BASE TABLES
```

Get list of database objects
@SophieYang: is `rs` your shorthand for `result`?

Also: 

  WHERE ("table_schema" = 'public') 

is the same as 

  where table_schema not in ('pg_catalog','information_schema')

```r
rs <- dbGetQuery(
  con,
  "select table_catalog,table_schema,table_name,table_type 
  from information_schema.tables 
  where table_schema not in ('pg_catalog','information_schema')
  order by table_type, table_name 
  ;"
)
# Get list of tables
kable(rs)
```


\begin{tabular}{l|l|l|l}
\hline
table\_catalog & table\_schema & table\_name & table\_type\\
\hline
dvdrental & public & actor & BASE TABLE\\
\hline
dvdrental & public & address & BASE TABLE\\
\hline
dvdrental & public & category & BASE TABLE\\
\hline
dvdrental & public & city & BASE TABLE\\
\hline
dvdrental & public & country & BASE TABLE\\
\hline
dvdrental & public & customer & BASE TABLE\\
\hline
dvdrental & public & film & BASE TABLE\\
\hline
dvdrental & public & film\_actor & BASE TABLE\\
\hline
dvdrental & public & film\_category & BASE TABLE\\
\hline
dvdrental & public & inventory & BASE TABLE\\
\hline
dvdrental & public & language & BASE TABLE\\
\hline
dvdrental & public & payment & BASE TABLE\\
\hline
dvdrental & public & rental & BASE TABLE\\
\hline
dvdrental & public & staff & BASE TABLE\\
\hline
dvdrental & public & store & BASE TABLE\\
\hline
dvdrental & public & actor\_info & VIEW\\
\hline
dvdrental & public & customer\_list & VIEW\\
\hline
dvdrental & public & film\_list & VIEW\\
\hline
dvdrental & public & nicer\_but\_slower\_film\_list & VIEW\\
\hline
dvdrental & public & sales\_by\_film\_category & VIEW\\
\hline
dvdrental & public & sales\_by\_store & VIEW\\
\hline
dvdrental & public & staff\_list & VIEW\\
\hline
\end{tabular}

### Drill down into the columns

Of course, the `DBI` package has the simplest way to get a little metadata.

```r
DBI::dbListFields(con, "rental")
```

```
## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
## [5] "return_date"  "staff_id"     "last_update"
```

```r
columns_info_schema_table <- tbl(con, dbplyr::in_schema("information_schema", "columns")) 

columns_info_schema_info <- columns_info_schema_table %>%
  filter(table_schema == "public") %>% 
  select(
    table_name, column_name, data_type, ordinal_position,
    character_maximum_length, column_default
  ) %>%
  collect(n = Inf)

glimpse(columns_info_schema_info)
```

```
## Observations: 128
## Variables: 6
## $ table_name               <chr> "actor_info", "actor_info", "actor_in...
## $ column_name              <chr> "actor_id", "first_name", "last_name"...
## $ data_type                <chr> "integer", "character varying", "char...
## $ ordinal_position         <int> 1, 2, 3, 4, 1, 2, 3, 4, 5, 6, 7, 8, 9...
## $ character_maximum_length <int> NA, 45, 45, NA, NA, NA, 50, 10, 20, 5...
## $ column_default           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, N...
```
With a data frame from the `columns` table in `information_schema`, we can answer a number of questions

```r
columns_info_schema_info %>%
  filter(table_name == "rental") %>% 
  kable()
```


\begin{tabular}{l|l|l|r|r|l}
\hline
table\_name & column\_name & data\_type & ordinal\_position & character\_maximum\_length & column\_default\\
\hline
rental & rental\_id & integer & 1 & NA & nextval('rental\_rental\_id\_seq'::regclass)\\
\hline
rental & rental\_date & timestamp without time zone & 2 & NA & NA\\
\hline
rental & inventory\_id & integer & 3 & NA & NA\\
\hline
rental & customer\_id & smallint & 4 & NA & NA\\
\hline
rental & return\_date & timestamp without time zone & 5 & NA & NA\\
\hline
rental & staff\_id & smallint & 6 & NA & NA\\
\hline
rental & last\_update & timestamp without time zone & 7 & NA & now()\\
\hline
\end{tabular}


Pull out some rough-and-ready but useful statistics about your database.  Since we are in SQL-land we talk about variables as `columns`.

Create a list of tables names and a count of the number of columns that each one contains.

```r
columns_info_schema_table %>%
  filter(table_schema == "public") %>%
  count(table_name, sort = TRUE) %>%
  kable()
```


\begin{tabular}{l|r}
\hline
table\_name & n\\
\hline
film & 13\\
\hline
staff & 11\\
\hline
customer & 10\\
\hline
customer\_list & 9\\
\hline
film\_list & 8\\
\hline
staff\_list & 8\\
\hline
address & 8\\
\hline
nicer\_but\_slower\_film\_list & 8\\
\hline
rental & 7\\
\hline
payment & 6\\
\hline
actor\_info & 4\\
\hline
actor & 4\\
\hline
store & 4\\
\hline
city & 4\\
\hline
inventory & 4\\
\hline
film\_category & 3\\
\hline
category & 3\\
\hline
film\_actor & 3\\
\hline
language & 3\\
\hline
sales\_by\_store & 3\\
\hline
country & 3\\
\hline
sales\_by\_film\_category & 2\\
\hline
\end{tabular}

```r
# For the same query, show the SQL code that dplyr sends to PostgreSQL

columns_info_schema_table %>%
  filter(table_schema == "public") %>%
  count(table_name, sort = TRUE) %>%
  show_query()
```

```
## <SQL>
## SELECT "table_name", COUNT(*) AS "n"
## FROM information_schema.columns
## WHERE ("table_schema" = 'public')
## GROUP BY "table_name"
## ORDER BY "n" DESC
```

How many column names are shared across tables (or duplicated)?

```r
columns_info_schema_info %>% count(column_name, sort = TRUE) %>% filter(n > 1)
```

```
## # A tibble: 34 x 2
##    column_name     n
##    <chr>       <int>
##  1 last_update    14
##  2 address_id      4
##  3 film_id         4
##  4 first_name      4
##  5 last_name       4
##  6 name            4
##  7 store_id        4
##  8 actor_id        3
##  9 address         3
## 10 category        3
## # ... with 24 more rows
```

How many column names are unique?

```r
columns_info_schema_info %>% count(column_name) %>% filter(n > 1)
```

```
## # A tibble: 34 x 2
##    column_name     n
##    <chr>       <int>
##  1 active          2
##  2 actor_id        3
##  3 actors          2
##  4 address         3
##  5 address_id      4
##  6 category        3
##  7 category_id     2
##  8 city            3
##  9 city_id         2
## 10 country         3
## # ... with 24 more rows
```

What data types are found in the database?

```r
columns_info_schema_info %>% count(data_type)
```

```
## # A tibble: 13 x 2
##    data_type                       n
##    <chr>                       <int>
##  1 ARRAY                           1
##  2 boolean                         2
##  3 bytea                           1
##  4 character                       1
##  5 character varying              36
##  6 date                            1
##  7 integer                        22
##  8 numeric                         7
##  9 smallint                       25
## 10 text                           11
## 11 timestamp without time zone    17
## 12 tsvector                        1
## 13 USER-DEFINED                    3
```

### Submitting SQL statements directly

```r
table_schema_query <- glue(
  "SELECT ",
  "table_name, column_name, data_type, ordinal_position, character_maximum_length, column_default",
  " FROM information_schema.columns ",
  "WHERE table_schema = 'public'"
)

rental_meta_data <- dbGetQuery(con, table_schema_query)

glimpse(rental_meta_data)
```

```
## Observations: 128
## Variables: 6
## $ table_name               <chr> "actor_info", "actor_info", "actor_in...
## $ column_name              <chr> "actor_id", "first_name", "last_name"...
## $ data_type                <chr> "integer", "character varying", "char...
## $ ordinal_position         <int> 1, 2, 3, 4, 1, 2, 3, 4, 5, 6, 7, 8, 9...
## $ character_maximum_length <int> NA, 45, 45, NA, NA, NA, 50, 10, 20, 5...
## $ column_default           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, N...
```


```r
rs <- dbGetQuery(
  con
  , "select table_catalog||'.'||table_schema||'.'||table_name table_name
                         ,column_name,ordinal_position seq --,data_type
                         ,case when data_type = 'character varying' 
                               then data_type || '('|| character_maximum_length||')'
                               when data_type = 'real'
                               then data_type || '(' || numeric_precision ||','||numeric_precision_radix||')'
                               else data_type
                          end data_type
--                         ,character_maximum_length,numeric_precision,numeric_precision_radix
                     from information_schema.columns
                    where table_name in (select table_name
                                           from information_schema.tables
                                         where table_schema not in ('pg_catalog','information_schema')
                                         )
                   order by table_name,ordinal_position;

                  ;"
)
kable(head(rs, n = 20))
```


\begin{tabular}{l|l|r|l}
\hline
table\_name & column\_name & seq & data\_type\\
\hline
dvdrental.public.actor & actor\_id & 1 & integer\\
\hline
dvdrental.public.actor & first\_name & 2 & character varying(45)\\
\hline
dvdrental.public.actor & last\_name & 3 & character varying(45)\\
\hline
dvdrental.public.actor & last\_update & 4 & timestamp without time zone\\
\hline
dvdrental.public.actor\_info & actor\_id & 1 & integer\\
\hline
dvdrental.public.actor\_info & first\_name & 2 & character varying(45)\\
\hline
dvdrental.public.actor\_info & last\_name & 3 & character varying(45)\\
\hline
dvdrental.public.actor\_info & film\_info & 4 & text\\
\hline
dvdrental.public.address & address\_id & 1 & integer\\
\hline
dvdrental.public.address & address & 2 & character varying(50)\\
\hline
dvdrental.public.address & address2 & 3 & character varying(50)\\
\hline
dvdrental.public.address & district & 4 & character varying(20)\\
\hline
dvdrental.public.address & city\_id & 5 & smallint\\
\hline
dvdrental.public.address & postal\_code & 6 & character varying(10)\\
\hline
dvdrental.public.address & phone & 7 & character varying(20)\\
\hline
dvdrental.public.address & last\_update & 8 & timestamp without time zone\\
\hline
dvdrental.public.category & category\_id & 1 & integer\\
\hline
dvdrental.public.category & name & 2 & character varying(25)\\
\hline
dvdrental.public.category & last\_update & 3 & timestamp without time zone\\
\hline
dvdrental.public.city & city\_id & 1 & integer\\
\hline
\end{tabular}
There are {r dim(rs)[1]} rows in the catalog.


```r
rs <- dbGetQuery(
  con,
  "
--SELECT conrelid::regclass as table_from
select table_catalog||'.'||table_schema||'.'||table_name table_name
,conname,pg_catalog.pg_get_constraintdef(r.oid, true) as condef
FROM information_schema.columns c,pg_catalog.pg_constraint r
WHERE 1 = 1 --r.conrelid = '16485' 
  AND r.contype  in ('f','p') ORDER BY 1
;"
)

kable(head(rs))
```


\begin{tabular}{l|l|l}
\hline
table\_name & conname & condef\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & actor\_pkey & PRIMARY KEY (actor\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & actor\_pkey & PRIMARY KEY (actor\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & actor\_pkey & PRIMARY KEY (actor\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & country\_pkey & PRIMARY KEY (country\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & country\_pkey & PRIMARY KEY (country\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & country\_pkey & PRIMARY KEY (country\_id)\\
\hline
\end{tabular}


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
kable(head(rs))
```


\begin{tabular}{l|l|l}
\hline
table\_from & conname & pg\_get\_constraintdef\\
\hline
actor & actor\_pkey & PRIMARY KEY (actor\_id)\\
\hline
address & address\_pkey & PRIMARY KEY (address\_id)\\
\hline
address & fk\_address\_city & FOREIGN KEY (city\_id) REFERENCES city(city\_id)\\
\hline
category & category\_pkey & PRIMARY KEY (category\_id)\\
\hline
city & city\_pkey & PRIMARY KEY (city\_id)\\
\hline
city & fk\_city & FOREIGN KEY (country\_id) REFERENCES country(country\_id)\\
\hline
\end{tabular}

```r
dim(rs)[1]
```

```
## [1] 33
```


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
## 1 cardinal_number_domain_check        12703       c         FALSE
## 2              yes_or_no_check        12703       c         FALSE
## 3                   year_check         2200       c         FALSE
## 4                   actor_pkey         2200       p         FALSE
## 5                 address_pkey         2200       p         FALSE
## 6                category_pkey         2200       p         FALSE
##   condeferred convalidated conrelid contypid conindid confrelid
## 1       FALSE         TRUE        0    12716        0         0
## 2       FALSE         TRUE        0    12724        0         0
## 3       FALSE         TRUE        0    16397        0         0
## 4       FALSE         TRUE    16420        0    16555         0
## 5       FALSE         TRUE    16461        0    16557         0
## 6       FALSE         TRUE    16427        0    16559         0
##   confupdtype confdeltype confmatchtype conislocal coninhcount
## 1                                             TRUE           0
## 2                                             TRUE           0
## 3                                             TRUE           0
## 4                                             TRUE           0
## 5                                             TRUE           0
## 6                                             TRUE           0
##   connoinherit conkey confkey conpfeqop conppeqop conffeqop conexclop
## 1        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 2        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 3        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 4         TRUE    {1}    <NA>      <NA>      <NA>      <NA>      <NA>
## 5         TRUE    {1}    <NA>      <NA>      <NA>      <NA>      <NA>
## 6         TRUE    {1}    <NA>      <NA>      <NA>      <NA>      <NA>
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  conbin
## 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       {OPEXPR :opno 525 :opfuncid 150 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({COERCETODOMAINVALUE :typeId 23 :typeMod -1 :collation 0 :location 195} {CONST :consttype 23 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 204 :constvalue 4 [ 0 0 0 0 0 0 0 0 ]}) :location 201}
## 2 {SCALARARRAYOPEXPR :opno 98 :opfuncid 67 :useOr true :inputcollid 100 :args ({RELABELTYPE :arg {COERCETODOMAINVALUE :typeId 1043 :typeMod 7 :collation 100 :location 121} :resulttype 25 :resulttypmod -1 :resultcollid 100 :relabelformat 2 :location -1} {ARRAYCOERCEEXPR :arg {ARRAY :array_typeid 1015 :array_collid 100 :element_typeid 1043 :elements ({CONST :consttype 1043 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 131 :constvalue 7 [ 28 0 0 0 89 69 83 ]} {CONST :consttype 1043 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 138 :constvalue 6 [ 24 0 0 0 78 79 ]}) :multidims false :location -1} :elemfuncid 0 :resulttype 1009 :resulttypmod -1 :resultcollid 100 :isExplicit false :coerceformat 2 :location -1}) :location 127}
## 3                                                                                                             {BOOLEXPR :boolop and :args ({OPEXPR :opno 525 :opfuncid 150 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({COERCETODOMAINVALUE :typeId 23 :typeMod -1 :collation 0 :location 62} {CONST :consttype 23 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 71 :constvalue 4 [ 109 7 0 0 0 0 0 0 ]}) :location 68} {OPEXPR :opno 523 :opfuncid 149 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({COERCETODOMAINVALUE :typeId 23 :typeMod -1 :collation 0 :location 82} {CONST :consttype 23 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 91 :constvalue 4 [ 107 8 0 0 0 0 0 0 ]}) :location 88}) :location 77}
## 4                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  <NA>
## 5                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  <NA>
## 6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  <NA>
##                                                                                       consrc
## 1                                                                               (VALUE >= 0)
## 2 ((VALUE)::text = ANY ((ARRAY['YES'::character varying, 'NO'::character varying])::text[]))
## 3                                                      ((VALUE >= 1901) AND (VALUE <= 2155))
## 4                                                                                       <NA>
## 5                                                                                       <NA>
## 6                                                                                       <NA>
##                                                                                         condef
## 1                                                                           CHECK (VALUE >= 0)
## 2 CHECK (VALUE::text = ANY (ARRAY['YES'::character varying, 'NO'::character varying]::text[]))
## 3                                                      CHECK (VALUE >= 1901 AND VALUE <= 2155)
## 4                                                                       PRIMARY KEY (actor_id)
## 5                                                                     PRIMARY KEY (address_id)
## 6                                                                    PRIMARY KEY (category_id)
```

What is the difference between `VIEW`s and `BASE TABLE`s?

```r
table_info_schema_table %>%
  filter(table_schema == "public" & table_type == "VIEW") %>%  # See alternative below
  select(table_name) %>% 
  left_join(columns_info_schema_table, by = c("table_name" = "table_name")) %>% 
  select(
    table_name, column_name, data_type, ordinal_position,
    character_maximum_length, column_default
  ) %>%
  collect(n = Inf) %>% 
  filter(str_detect(table_name, "cust")) %>% 
  kable()
```


\begin{tabular}{l|l|l|r|r|l}
\hline
table\_name & column\_name & data\_type & ordinal\_position & character\_maximum\_length & column\_default\\
\hline
customer\_list & id & integer & 1 & NA & NA\\
\hline
customer\_list & name & text & 2 & NA & NA\\
\hline
customer\_list & address & character varying & 3 & 50 & NA\\
\hline
customer\_list & zip code & character varying & 4 & 10 & NA\\
\hline
customer\_list & phone & character varying & 5 & 20 & NA\\
\hline
customer\_list & city & character varying & 6 & 50 & NA\\
\hline
customer\_list & country & character varying & 7 & 50 & NA\\
\hline
customer\_list & notes & text & 8 & NA & NA\\
\hline
customer\_list & sid & smallint & 9 & NA & NA\\
\hline
\end{tabular}

```r
table_info_schema_table %>%
  filter(table_schema == "public" & table_type == "BASE TABLE") %>%  # See alternative below
  select(table_name) %>% 
  left_join(columns_info_schema_table, by = c("table_name" = "table_name")) %>% 
  select(
    table_name, column_name, data_type, ordinal_position,
    character_maximum_length, column_default
  ) %>%
  collect(n = Inf) %>% 
  filter(str_detect(table_name, "cust")) %>% 
  kable()
```


\begin{tabular}{l|l|l|r|r|l}
\hline
table\_name & column\_name & data\_type & ordinal\_position & character\_maximum\_length & column\_default\\
\hline
customer & store\_id & smallint & 2 & NA & NA\\
\hline
customer & first\_name & character varying & 3 & 45 & NA\\
\hline
customer & last\_name & character varying & 4 & 45 & NA\\
\hline
customer & email & character varying & 5 & 50 & NA\\
\hline
customer & address\_id & smallint & 6 & NA & NA\\
\hline
customer & active & integer & 10 & NA & NA\\
\hline
customer & customer\_id & integer & 1 & NA & nextval('customer\_customer\_id\_seq'::regclass)\\
\hline
customer & activebool & boolean & 7 & NA & true\\
\hline
customer & create\_date & date & 8 & NA & ('now'::text)::date\\
\hline
customer & last\_update & timestamp without time zone & 9 & NA & now()\\
\hline
\end{tabular}

