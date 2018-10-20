# Getting metadata about and from the database (21)


Note that `tidyverse`, `DBI`, `RPostgres`, `glue`, and `knitr` are loaded.  Also, we've sourced the [`db-login-batch-code.R`]('book-src/db-login-batch-code.R') file which is used to log in to PostgreSQL.

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go. 

```r
sp_docker_start("sql-pet")
```
Connect to the database:

```r
con <-  sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10
)
```
## Always *look* at the data

### Connect with people who own, generate, or are the subjects of the data

A good chat with people who own the data, generate it, or are the subjects can generate insights and set the context for your investigation of the database. The purpose for collecting the data or circumsances where it was collected may be burried far afield in an organization, but *usually someone knows*.  The metadata discussed in this chapter is essential but will only take you so far.

### Browse a few rows of a table

Simple tools like `head` or `glimpse` are your friend.

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
## Database contents and structure

### Database structure

For large or complex databases, however, you need to use both the available documentation for your database (e.g.,  [the dvdrental](http://www.postgresqltutorial.com/postgresql-sample-database/) database) and the other empirical tools that are available.  For example it's worth learning to interpret the symbols in an [Entity Relationship Diagram](https://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model):

![](./screenshots/ER-diagram-symbols.png)

The `information_schema` is a trove of information *about* the database.  Its format is more or less consistent across the different SQL implementations that are available.   Here we explore some of what's available using several different methods.  Postgres stores [a lot of metadata](https://www.postgresql.org/docs/current/static/infoschema-columns.html).

### Contents of the `information_schema` 
For this chapter R needs the `dbplyr` package to access alternate schemas.  A [schema](http://www.postgresqltutorial.com/postgresql-server-and-database-objects/) is an object that contains one or more tables.  Most often there will be a default schema, but to access the metadata, you need to explicitly specify which schema contains the data you want.

### What tables are in the database?
The simplest way to get a list of tables is with 

```r
table_list  <- DBI::dbListTables(con)

kable(table_list)
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
### Digging into the `information_schema`

We usually need more detail than just a list of tables. Most SQL databases have an `information_schema` that has a standard structure to describe and control the database.

The `information_schema` is in a different schema from the default, so to connect to the `tables` table in the  `information_schema` we connect to the database in a different way:

```r
table_info_schema_table <- tbl(con, dbplyr::in_schema("information_schema", "tables"))
```
The `information_schema` is large and complex and contains 210 tables.  So it's easy to get lost in it.

This query retrieves a list of the tables in the database that includes additional detail, not just the name of the table.

```r
table_info <- table_info_schema_table %>%
  filter(table_schema == "public") %>%
  select(table_catalog, table_schema, table_name, table_type) %>%
  arrange(table_type, table_name) %>% 
  collect() 

kable(table_info)
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
In this context `table_catalog` is synonymous with `database`.

Notice that *VIEWS* are composites made up of one or more *BASE TABLES*.

The SQL world has its own terminology.  For example `rs` is shorthand for `result set`.  That's equivalent to using `df` for a `data frame`.  The following SQL query returns the same information as the previous one.

```r
rs <- dbGetQuery(
  con,
  "select table_catalog, table_schema, table_name, table_type 
  from information_schema.tables 
  where table_schema not in ('pg_catalog','information_schema')
  order by table_type, table_name 
  ;"
)
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

## What columns do those tables contain?

Of course, the `DBI` package has a `dbListFields` function that provides the simplest way to get the minimum, a list of column names:

```r
DBI::dbListFields(con, "rental")
```

```
## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
## [5] "return_date"  "staff_id"     "last_update"
```

But the `information_schema` has a lot more useful information that we can use.  

```r
columns_info_schema_table <- tbl(con, dbplyr::in_schema("information_schema", "columns"))
```

Since the `information_schema` contains 1855 columns, we are narrowing our focus to just one table.  This query retrieves more information about the `rental` table:

```r
columns_info_schema_info <- columns_info_schema_table %>%
  filter(table_schema == "public") %>% 
  select(
    table_catalog, table_schema, table_name, column_name, data_type, ordinal_position,
    character_maximum_length, column_default, numeric_precision, numeric_precision_radix
  ) %>%
  collect(n = Inf) %>% 
  mutate(data_type = case_when(
           data_type == "character varying" ~ paste0(data_type, ' (', character_maximum_length, ')'),
           data_type == "real" ~ paste0(data_type, ' (', numeric_precision, ',', numeric_precision_radix,')'),
           TRUE ~ data_type)
         ) %>% 
  filter(table_name == "rental") %>%
  select(-table_schema, -numeric_precision, -numeric_precision_radix)

glimpse(columns_info_schema_info)
```

```
## Observations: 7
## Variables: 7
## $ table_catalog            <chr> "dvdrental", "dvdrental", "dvdrental"...
## $ table_name               <chr> "rental", "rental", "rental", "rental...
## $ column_name              <chr> "rental_id", "rental_date", "inventor...
## $ data_type                <chr> "integer", "timestamp without time zo...
## $ ordinal_position         <int> 1, 2, 3, 4, 5, 6, 7
## $ character_maximum_length <int> NA, NA, NA, NA, NA, NA, NA
## $ column_default           <chr> "nextval('rental_rental_id_seq'::regc...
```

```r
kable(columns_info_schema_info)
```


\begin{tabular}{l|l|l|l|r|r|l}
\hline
table\_catalog & table\_name & column\_name & data\_type & ordinal\_position & character\_maximum\_length & column\_default\\
\hline
dvdrental & rental & rental\_id & integer & 1 & NA & nextval('rental\_rental\_id\_seq'::regclass)\\
\hline
dvdrental & rental & rental\_date & timestamp without time zone & 2 & NA & NA\\
\hline
dvdrental & rental & inventory\_id & integer & 3 & NA & NA\\
\hline
dvdrental & rental & customer\_id & smallint & 4 & NA & NA\\
\hline
dvdrental & rental & return\_date & timestamp without time zone & 5 & NA & NA\\
\hline
dvdrental & rental & staff\_id & smallint & 6 & NA & NA\\
\hline
dvdrental & rental & last\_update & timestamp without time zone & 7 & NA & now()\\
\hline
\end{tabular}

### What is the difference between a `VIEW` and a `BASE TABLE`?

The `BASE TABLE` has the underlying data in the database

```r
table_info_schema_table %>%
  filter(table_schema == "public" & table_type == "BASE TABLE") %>% 
  select(table_name, table_type) %>% 
  left_join(columns_info_schema_table, by = c("table_name" = "table_name")) %>% 
  select(
    table_type, table_name, column_name, data_type, ordinal_position,
    column_default
  ) %>%
  collect(n = Inf) %>% 
  filter(str_detect(table_name, "cust")) %>% 
  kable()
```


\begin{tabular}{l|l|l|l|r|l}
\hline
table\_type & table\_name & column\_name & data\_type & ordinal\_position & column\_default\\
\hline
BASE TABLE & customer & store\_id & smallint & 2 & NA\\
\hline
BASE TABLE & customer & first\_name & character varying & 3 & NA\\
\hline
BASE TABLE & customer & last\_name & character varying & 4 & NA\\
\hline
BASE TABLE & customer & email & character varying & 5 & NA\\
\hline
BASE TABLE & customer & address\_id & smallint & 6 & NA\\
\hline
BASE TABLE & customer & active & integer & 10 & NA\\
\hline
BASE TABLE & customer & customer\_id & integer & 1 & nextval('customer\_customer\_id\_seq'::regclass)\\
\hline
BASE TABLE & customer & activebool & boolean & 7 & true\\
\hline
BASE TABLE & customer & create\_date & date & 8 & ('now'::text)::date\\
\hline
BASE TABLE & customer & last\_update & timestamp without time zone & 9 & now()\\
\hline
\end{tabular}

Probably should explore how the `VIEW` is made up of data from BASE TABLEs.

```r
table_info_schema_table %>%
  filter(table_schema == "public" & table_type == "VIEW") %>%  
  select(table_name, table_type) %>% 
  left_join(columns_info_schema_table, by = c("table_name" = "table_name")) %>% 
  select(
    table_type, table_name, column_name, data_type, ordinal_position,
    column_default
  ) %>%
  collect(n = Inf) %>% 
  filter(str_detect(table_name, "cust")) %>% 
  kable()
```


\begin{tabular}{l|l|l|l|r|l}
\hline
table\_type & table\_name & column\_name & data\_type & ordinal\_position & column\_default\\
\hline
VIEW & customer\_list & id & integer & 1 & NA\\
\hline
VIEW & customer\_list & name & text & 2 & NA\\
\hline
VIEW & customer\_list & address & character varying & 3 & NA\\
\hline
VIEW & customer\_list & zip code & character varying & 4 & NA\\
\hline
VIEW & customer\_list & phone & character varying & 5 & NA\\
\hline
VIEW & customer\_list & city & character varying & 6 & NA\\
\hline
VIEW & customer\_list & country & character varying & 7 & NA\\
\hline
VIEW & customer\_list & notes & text & 8 & NA\\
\hline
VIEW & customer\_list & sid & smallint & 9 & NA\\
\hline
\end{tabular}

### What data types are found in the database?

```r
columns_info_schema_info %>% count(data_type)
```

```
## # A tibble: 3 x 2
##   data_type                       n
##   <chr>                       <int>
## 1 integer                         2
## 2 smallint                        2
## 3 timestamp without time zone     3
```

## Characterizing how things are named

Names are the handle for accessing the data.  Tables and columns may or may not be named consistently or in a way that makes sense to you.  You should look at these names *as data*.

### Counting columns and name reuse
Pull out some rough-and-ready but useful statistics about your database.  Since we are in SQL-land we talk about variables as `columns`.


```r
public_tables <- columns_info_schema_table %>%
  filter(table_schema == "public") %>% 
  collect()

public_tables %>% count(table_name, sort = TRUE) %>% 
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
address & 8\\
\hline
film\_list & 8\\
\hline
nicer\_but\_slower\_film\_list & 8\\
\hline
staff\_list & 8\\
\hline
rental & 7\\
\hline
payment & 6\\
\hline
actor & 4\\
\hline
actor\_info & 4\\
\hline
city & 4\\
\hline
inventory & 4\\
\hline
store & 4\\
\hline
category & 3\\
\hline
country & 3\\
\hline
film\_actor & 3\\
\hline
film\_category & 3\\
\hline
language & 3\\
\hline
sales\_by\_store & 3\\
\hline
sales\_by\_film\_category & 2\\
\hline
\end{tabular}

How many *column names* are shared across tables (or duplicated)?

```r
public_tables %>% count(column_name, sort = TRUE) %>% filter(n > 1)
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
public_tables %>% count(column_name) %>% filter(n == 1) %>% count()
```

```
## # A tibble: 1 x 1
##      nn
##   <int>
## 1    24
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
## Observations: 61,215
## Variables: 3
## $ table_name <chr> "dvdrental.information_schema.administrable_role_au...
## $ conname    <chr> "actor_pkey", "actor_pkey", "actor_pkey", "country_...
## $ condef     <chr> "PRIMARY KEY (actor_id)", "PRIMARY KEY (actor_id)",...
```

```r
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
## Observations: 33
## Variables: 3
## $ table_from           <chr> "actor", "address", "address", "category"...
## $ conname              <chr> "actor_pkey", "address_pkey", "fk_address...
## $ pg_get_constraintdef <chr> "PRIMARY KEY (actor_id)", "PRIMARY KEY (a...
```

```r
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
    "table_schema" =  "table_schema",
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
              )) %>%
  # left_join(constraint_column_usage) %>% # does this table add anything useful?
  select(table_name, table_type, constraint_name, constraint_type, column_name, ordinal_position) %>%
  arrange(table_name) %>% 
collect()
glimpse(keys)
```

```
## Observations: 35
## Variables: 6
## $ table_name       <chr> "actor", "address", "address", "category", "c...
## $ table_type       <chr> "BASE TABLE", "BASE TABLE", "BASE TABLE", "BA...
## $ constraint_name  <chr> "actor_pkey", "address_pkey", "fk_address_cit...
## $ constraint_type  <chr> "PRIMARY KEY", "PRIMARY KEY", "FOREIGN KEY", ...
## $ column_name      <chr> "actor_id", "address_id", "city_id", "categor...
## $ ordinal_position <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, ...
```

```r
kable(keys)
```


\begin{tabular}{l|l|l|l|l|r}
\hline
table\_name & table\_type & constraint\_name & constraint\_type & column\_name & ordinal\_position\\
\hline
actor & BASE TABLE & actor\_pkey & PRIMARY KEY & actor\_id & 1\\
\hline
address & BASE TABLE & address\_pkey & PRIMARY KEY & address\_id & 1\\
\hline
address & BASE TABLE & fk\_address\_city & FOREIGN KEY & city\_id & 1\\
\hline
category & BASE TABLE & category\_pkey & PRIMARY KEY & category\_id & 1\\
\hline
city & BASE TABLE & city\_pkey & PRIMARY KEY & city\_id & 1\\
\hline
city & BASE TABLE & fk\_city & FOREIGN KEY & country\_id & 1\\
\hline
country & BASE TABLE & country\_pkey & PRIMARY KEY & country\_id & 1\\
\hline
customer & BASE TABLE & customer\_address\_id\_fkey & FOREIGN KEY & address\_id & 1\\
\hline
customer & BASE TABLE & customer\_pkey & PRIMARY KEY & customer\_id & 1\\
\hline
film & BASE TABLE & film\_language\_id\_fkey & FOREIGN KEY & language\_id & 1\\
\hline
film & BASE TABLE & film\_pkey & PRIMARY KEY & film\_id & 1\\
\hline
film\_actor & BASE TABLE & film\_actor\_actor\_id\_fkey & FOREIGN KEY & actor\_id & 1\\
\hline
film\_actor & BASE TABLE & film\_actor\_film\_id\_fkey & FOREIGN KEY & film\_id & 1\\
\hline
film\_actor & BASE TABLE & film\_actor\_pkey & PRIMARY KEY & actor\_id & 1\\
\hline
film\_actor & BASE TABLE & film\_actor\_pkey & PRIMARY KEY & film\_id & 2\\
\hline
film\_category & BASE TABLE & film\_category\_category\_id\_fkey & FOREIGN KEY & category\_id & 1\\
\hline
film\_category & BASE TABLE & film\_category\_film\_id\_fkey & FOREIGN KEY & film\_id & 1\\
\hline
film\_category & BASE TABLE & film\_category\_pkey & PRIMARY KEY & film\_id & 1\\
\hline
film\_category & BASE TABLE & film\_category\_pkey & PRIMARY KEY & category\_id & 2\\
\hline
inventory & BASE TABLE & inventory\_film\_id\_fkey & FOREIGN KEY & film\_id & 1\\
\hline
inventory & BASE TABLE & inventory\_pkey & PRIMARY KEY & inventory\_id & 1\\
\hline
language & BASE TABLE & language\_pkey & PRIMARY KEY & language\_id & 1\\
\hline
payment & BASE TABLE & payment\_customer\_id\_fkey & FOREIGN KEY & customer\_id & 1\\
\hline
payment & BASE TABLE & payment\_pkey & PRIMARY KEY & payment\_id & 1\\
\hline
payment & BASE TABLE & payment\_rental\_id\_fkey & FOREIGN KEY & rental\_id & 1\\
\hline
payment & BASE TABLE & payment\_staff\_id\_fkey & FOREIGN KEY & staff\_id & 1\\
\hline
rental & BASE TABLE & rental\_customer\_id\_fkey & FOREIGN KEY & customer\_id & 1\\
\hline
rental & BASE TABLE & rental\_inventory\_id\_fkey & FOREIGN KEY & inventory\_id & 1\\
\hline
rental & BASE TABLE & rental\_pkey & PRIMARY KEY & rental\_id & 1\\
\hline
rental & BASE TABLE & rental\_staff\_id\_key & FOREIGN KEY & staff\_id & 1\\
\hline
staff & BASE TABLE & staff\_address\_id\_fkey & FOREIGN KEY & address\_id & 1\\
\hline
staff & BASE TABLE & staff\_pkey & PRIMARY KEY & staff\_id & 1\\
\hline
store & BASE TABLE & store\_address\_id\_fkey & FOREIGN KEY & address\_id & 1\\
\hline
store & BASE TABLE & store\_manager\_staff\_id\_fkey & FOREIGN KEY & manager\_staff\_id & 1\\
\hline
store & BASE TABLE & store\_pkey & PRIMARY KEY & store\_id & 1\\
\hline
\end{tabular}

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

## Creating your own data dictionary

If you are going to work with a database for an extended period it can be useful to create your own data dictionary.  Here is an illustration of the idea

```r
some_tables <- c("rental", "city", "store")

all_meta <- map_df(some_tables, sp_get_dbms_data_dictionary, con = con)

all_meta
```

```
## # A tibble: 15 x 11
##    table_name var_name var_type num_rows num_blank num_unique min   q_25 
##    <chr>      <chr>    <chr>       <int>     <int>      <int> <chr> <chr>
##  1 rental     rental_~ integer     16044         0      16044 1     4013 
##  2 rental     rental_~ double      16044         0      15815 2005~ 2005~
##  3 rental     invento~ integer     16044         0       4580 1     1154 
##  4 rental     custome~ integer     16044         0        599 1     148  
##  5 rental     return_~ double      16044       183      15836 2005~ 2005~
##  6 rental     staff_id integer     16044         0          2 1     1    
##  7 rental     last_up~ double      16044         0          3 2006~ 2006~
##  8 city       city_id  integer       600         0        600 1     150  
##  9 city       city     charact~      600         0        599 A Co~ Dzer~
## 10 city       country~ integer       600         0        109 1     28   
## 11 city       last_up~ double        600         0          1 2006~ 2006~
## 12 store      store_id integer         2         0          2 1     1    
## 13 store      manager~ integer         2         0          2 1     1    
## 14 store      address~ integer         2         0          2 1     1    
## 15 store      last_up~ double          2         0          1 2006~ 2006~
## # ... with 3 more variables: q_50 <chr>, q_75 <chr>, max <chr>
```

```r
glimpse(all_meta)
```

```
## Observations: 15
## Variables: 11
## $ table_name <chr> "rental", "rental", "rental", "rental", "rental", "...
## $ var_name   <chr> "rental_id", "rental_date", "inventory_id", "custom...
## $ var_type   <chr> "integer", "double", "integer", "integer", "double"...
## $ num_rows   <int> 16044, 16044, 16044, 16044, 16044, 16044, 16044, 60...
## $ num_blank  <int> 0, 0, 0, 0, 183, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
## $ num_unique <int> 16044, 15815, 4580, 599, 15836, 2, 3, 600, 599, 109...
## $ min        <chr> "1", "2005-05-24 22:53:30", "1", "1", "2005-05-25 2...
## $ q_25       <chr> "4013", "2005-07-07 00:58:00", "1154", "148", "2005...
## $ q_50       <chr> "8025", "2005-07-28 16:03:27", "2291", "296", "2005...
## $ q_75       <chr> "12037", "2005-08-17 21:13:35", "3433", "446", "200...
## $ max        <chr> "16049", "2006-02-14 15:16:03", "4581", "599", "200...
```

```r
kable(head(all_meta))
```


\begin{tabular}{l|l|l|r|r|r|l|l|l|l|l}
\hline
table\_name & var\_name & var\_type & num\_rows & num\_blank & num\_unique & min & q\_25 & q\_50 & q\_75 & max\\
\hline
rental & rental\_id & integer & 16044 & 0 & 16044 & 1 & 4013 & 8025 & 12037 & 16049\\
\hline
rental & rental\_date & double & 16044 & 0 & 15815 & 2005-05-24 22:53:30 & 2005-07-07 00:58:00 & 2005-07-28 16:03:27 & 2005-08-17 21:13:35 & 2006-02-14 15:16:03\\
\hline
rental & inventory\_id & integer & 16044 & 0 & 4580 & 1 & 1154 & 2291 & 3433 & 4581\\
\hline
rental & customer\_id & integer & 16044 & 0 & 599 & 1 & 148 & 296 & 446 & 599\\
\hline
rental & return\_date & double & 16044 & 183 & 15836 & 2005-05-25 23:55:21 & 2005-07-10 15:48:58 & 2005-08-01 19:31:15 & 2005-08-20 23:32:29 & 2005-09-02 02:35:22\\
\hline
rental & staff\_id & integer & 16044 & 0 & 2 & 1 & 1 & 1 & 2 & 2\\
\hline
\end{tabular}
## Save your work!

The work you do to understand the structure and contents of a database can be useful for others (including future-you).  So at the end of a session, you might look at all the data frames you want to save.  Consider saving them in a form where you can add notes at the appropriate level (as in a Google Doc representing table or columns that you annotate over time).

```r
ls()
```

```
##  [1] "all_meta"                  "columns_info_schema_info" 
##  [3] "columns_info_schema_table" "con"                      
##  [5] "constraint_column_usage"   "cranex"                   
##  [7] "key_column_usage"          "keys"                     
##  [9] "public_tables"             "referential_constraints"  
## [11] "rental"                    "rs"                       
## [13] "some_tables"               "table_constraints"        
## [15] "table_info"                "table_info_schema_table"  
## [17] "table_list"                "tables"
```

