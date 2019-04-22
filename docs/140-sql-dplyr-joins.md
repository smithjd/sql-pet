# SQL & `dplyr` joins {#chapter_sql-dplyr-joins}

> This chapter demonstrates how to:
> 
> * Use primary and foreign keys to retrieve specific rows of a table
> * Do different kinds of join queries
> * Exercises
> * Query the database to get basic information about each dvdrental story
> * How to interact with the database using different strategies



Verify Docker is up and running:

```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```

Verify pet DB is available, it may be stopped.


```r
sp_show_all_docker_containers()
```

```
## CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                     PORTS               NAMES
## 1918fe2a68e7        postgres-dvdrental   "docker-entrypoint.s…"   52 seconds ago      Exited (0) 2 seconds ago                       sql-pet
```

Start up the `docker-pet` container


```r
sp_docker_start("sql-pet")
```

Now connect to the database with R


```r
# need to wait for Docker & Postgres to come up before connecting.

con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 30, connection_tab = TRUE
)
```


```r
source(file = here::here('book-src/sql_pet_data.R'), echo = TRUE)
## 
## > dbExecute(con, "delete from film_category where film_id >= 1001;")
## [1] 4
## 
## > dbExecute(con, "delete from rental where rental_id >= 16050;")
## [1] 1
## 
## > dbExecute(con, "delete from inventory where film_id >= 1001;")
## [1] 2
## 
## > dbExecute(con, "delete from film where film_id >= 1001;")
## [1] 2
## 
## > dbExecute(con, "delete from customer where customer_id >= 600;")
## [1] 7
## 
## > dbExecute(con, "delete from store where store_id > 2;")
## [1] 1
## 
## > dbExecute(con, "insert into customer\n  (customer_id,store_id,first_name,last_name,email,address_id,activebool\n  ,create_date,last_update,active)\n ..." ... [TRUNCATED] 
## [1] 5
## 
## > dbExecute(con, "ALTER TABLE store DISABLE TRIGGER ALL;")
## [1] 0
## 
## > df <- data.frame(store_id = 10, manager_staff_id = 10, 
## +     address_id = 10, last_update = Sys.time())
## 
## > dbWriteTable(con, "store", value = df, append = TRUE, 
## +     row.names = FALSE)
## 
## > dbExecute(con, "ALTER TABLE store ENABLE TRIGGER ALL;")
## [1] 0
## 
## > dbExecute(con, "insert into film\n  (film_id,title,description,release_year,language_id\n  ,rental_duration,rental_rate,length,replacement_cost,rati ..." ... [TRUNCATED] 
## [1] 1
## 
## > dbExecute(con, "insert into film_category\n  (film_id,category_id,last_update)\n  values(1001,6,now()::date)\n  ,(1001,7,now()::date)\n  ;")
## [1] 2
## 
## > dbExecute(con, "insert into inventory\n  (inventory_id,film_id,store_id,last_update)\n  values(4582,1001,1,now()::date)\n  ,(4583,1001,2,now()::date ..." ... [TRUNCATED] 
## [1] 2
## 
## > dbExecute(con, "insert into rental\n  (rental_id,rental_date,inventory_id,customer_id,return_date,staff_id,last_update)\n  values(16050,now()::date  ..." ... [TRUNCATED] 
## [1] 1
```


## Joins

In section 'SQL Quick Start Simple Retrieval', there is a brief discussion of databases and third normal form (3NF).  One of the goals of normalization is to eliminate redundant data being kept in multiple tables and having each table contain a very granular level of detail.  If a record then needs to be updated, it is updated in one table instead of multiple tables improving overall system performance.  This also helps simplify and maintain referential integrity between tables.
 
Normalization breaks data down and JOINs denormalize the data and builds it back up.  The tables are typically related via a primary key - foreign key relationship. The PostgreSQL database enforces the primary and foreign key constraints in the DVD rental database.  

### Join Types

<!--html_preserve--><div id="htmlwidget-f0a342ae722c83f7a83f" style="width:672px;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-f0a342ae722c83f7a83f">{"x":{"diagram":"\ndigraph JOINS {\n\n  # a \"graph\" statement\n  graph [overlap = true, fontsize = 10]\n\n  node [shape = box,\n        fixedsize = false,\n        hegith = 1.5\n        width = 1.50]\n  0[label=\"0.  Mutable Joins\"]\n  1[label=\"1.  Inner Join\nL.col1 {<,=,>} R.col2\"]\n  2[label=\"2.  Outer Join\nL.col1=R.col2\"]\n  3[label=\"3.  Self Join\nL.col1=tbl1.col2\"]\n  4[label=\"4.  Cross (Cartesian) Join\nL.col1=R.col2\"]\n  5[label=\"5.  Equi Join\nL.col1=R.col2\"] \n  6[label=\"6.  Natural Join\nL.col1=R.col1\"]\n  7[label=\"7.  Left Join\nL.col1=R.col1\"]\n  8[label=\"8.  Right Join\nL.col1=R.col1\"]\n  9[label=\"9.  Full Join\nL.col1=tbl2.col1\"]\n 10[label=\"10.  NonMutable Joins\"]\n 11[label=\"11.  Semi Join\nL.col1=R.col2\ncondition true\"]\n 12[label=\"12.  Anti Join\nL.col1=R.col2\ncondition false\"]\n\n  # several \"edge\" statements\n  0 -> {1,2,3,4} [arrowhead=none]\n  1 -> 5 [arrowhead=none]\n  5 -> 6 [arrowhead=none]\n  2 -> {7,8,9} [arrowhead=none]\n  10 -> {11,12} [arrowhead=none]\n\n  #3 -> {7,8,9}\n}\n","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The diagram above shows the hierarchy of the different types of joins.  In the boxes above:

*  The joins are based on a single column from the two tables, the left and right tables.  Joins can be based on multiple columns from both tables.
*  The `L.` and `R.` are aliases for the left and right table names.  
*  Often the joining columns have the same name as in the Natural Join, L.col1 = R.col1 
*  However, the joining column names can be different L.col1 = R.col2.  
*  All dplyr joins are based on equality between the table columns, L.col1 = R.col2.  See the `fuzzyjoin` package for non-equality column conditions.  SQL supports non-equality column conditions.  Non-equality column conditions are rare.  
*  Equi Joins are a subset of the Inner Join.

For this tutorial, we can think of joins as either an Inner/Equi Join or an Outer Join.

For those interested though, the typical Venn diagrams can be found [here](http://www.sql-join.com/sql-join-types/).

### Graphic illustration of Join types

This book is focused on data retrieval from a dbms such as is found inside an organiztion, and the discussion and examples are built around the `dvdrental` database.  However, it's always helpful to remember the basic SQL concepts.  For this we refer to Jenny Bryan's [Join Cheat Sheet](http://stat545.com/bit001_dplyr-cheatsheet.html), which is part of a UBC STAT 545A and 547M course on [Data wrangling, exploration, and analysis with R](http://stat545.com/index.html).

### Join Syntax

The table below shows the two R join function call formats, standalone function call and pipe function call and the corresponding SQL join format.

|Join|dplyr                                                                            |sql
|-----|--------------------------------------------------------------------------------|------------------------------------------------------
|inner|inner_join(customer_tbl, rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|from customer c join rental r on c.customer_id = r.customer_id
|     |customer_tbl %>% inner_join(rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|
|left |left_join(customer_tbl, rental_tbl, by = 'customer_id', suffix = c(".c", ".r")) |from customer c left outer join rental r on c.customer_id = r.customer_id
|     |customer_tbl %>% left_join(rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|
|right|right_join(customer_tbl, rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|from customer c right outer join rental r on c.customer_id = r.customer_id
|     |customer_tbl %>% right_join(rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|
|full |full_join(customer_tbl, rental_tbl, by = 'customer_id', suffix = c(".c", ".r")) |from customer c full outer join rental r on c.customer_id = r.customer_id
|     |customer_tbl %>% full_join(rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|
|semi |semi_join(customer_tbl, rental_tbl, by = 'customer_id')    |
|     |customer_tbl %>% semi_join(rental_tbl, by = 'customer_id') |
|anti |anti_join(customer_tbl, rental_tbl, by = 'customer_id')    |     |     |customer_tbl %>% semi_join(rental_tbl, by = 'customer_id') |


### Join Tables

The `dplyr` join documentation describes two different types of joins, `mutating` and `filtering` joins.  For those coming to R with a SQL background, the mutating documentation is misleading in one respect.  Here is the inner_join documentation:

> inner_join()
>   
> return all rows from x where there are matching values in y, and all columns from x and y. If there are multiple matches between x and y, all combination of the matches are returned.

The misleading part is 'and all the columns from *x* and *y*.'  If the join column is `KEY`, SQL will return x.KEY and y.KEY.  `dplyr` returns just KEY, the KEY from the driving table.  This is important if you are translating SQL to R because SQL developers will reference both columns x.KEY and y.KEY.  One needs to mutate the y.KEY column.  This difference should become clear in the outer join examples.  

In the next couple of examples, we will use a small sample of the `customer` and `store` table data from the database to illustrate the diffent joins.  In the `dplyr::*_join` verbs, the `by` and `suffix` parameters are included because they help document the actual join and the source of join columns.  If the suffix parameter is excluded, it defaults to .x to refer to the first table and .y for the second table.  If the `dplyr` pipe has many joins, the suffix parameter makes it clearer which table the column came from.

In the next code block, we perform a Cartesian join to illustrate the default suffix behavior.  Note that:

* every column has a suffix of x or y except the key column; _and_
* the column values may or may not be the same based on the column name without the suffix.

If one has a lot of joins in the pipeline with tables that have many duplicate column names, it is difficult to keep track of the source of the column.


```r
store_table <- DBI::dbReadTable(con, "store")
store_table$key <- 1
cartesian_join <-
  inner_join(store_table, store_table, by = ('key' = 'key')) %>%
  select(-key, -last_update.x, -last_update.y)

sp_print_df(cartesian_join)
```

<!--html_preserve--><div id="htmlwidget-f60df00c20aebbfd761e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f60df00c20aebbfd761e">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9"],[1,1,1,2,2,2,10,10,10],[1,1,1,2,2,2,10,10,10],[1,1,1,2,2,2,10,10,10],[1,2,10,1,2,10,1,2,10],[1,2,10,1,2,10,1,2,10],[1,2,10,1,2,10,1,2,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id.x<\/th>\n      <th>manager_staff_id.x<\/th>\n      <th>address_id.x<\/th>\n      <th>store_id.y<\/th>\n      <th>manager_staff_id.y<\/th>\n      <th>address_id.y<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The suffix parameter helps distinguish the duplicate column names as shown in the next example.


```r
cartesian_join2 <-
  dplyr::inner_join(
    store_table,
    store_table,
    by = ('key' = 'key'),
    suffix = c('.store1', '.store2')
  ) %>%
  select(-key, -last_update.store1, -last_update.store2)
  
sp_print_df(cartesian_join2)
```

<!--html_preserve--><div id="htmlwidget-560b950fa13fc816f165" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-560b950fa13fc816f165">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9"],[1,1,1,2,2,2,10,10,10],[1,1,1,2,2,2,10,10,10],[1,1,1,2,2,2,10,10,10],[1,2,10,1,2,10,1,2,10],[1,2,10,1,2,10,1,2,10],[1,2,10,1,2,10,1,2,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id.store1<\/th>\n      <th>manager_staff_id.store1<\/th>\n      <th>address_id.store1<\/th>\n      <th>store_id.store2<\/th>\n      <th>manager_staff_id.store2<\/th>\n      <th>address_id.store2<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Natural Join is a Delayed Time Bomb

The `dplyr` default join is a natural join, joining tables on common column names.  One of many links why one should not use natural joins can be found [here](http://gplivna.blogspot.com/2007/10/natural-joins-are-evil-motto-if-you.html).  If two tables are joined via a natural join on column `C1` the join continues to work as long as no additional common columns are added to either table.  If a new column `C2` is added to one of the tables and `C2` already exists in the other table, BOOM!, the delayed time bomb goes off.  The natural join still executes, doesn't throw any errors, but the returned result set may be smaller, much smaller, than before the new `C2` column was added.

### SQL Customer store_id Distribution

The next code block calculates the `store_id` distribution in the `customer` and `store` tables across all their rows.  The results will be used in following sections to validate different join result sets.


```r
store_distribution_sql <- dbGetQuery(
  con,
  "select 'customer' tbl, store_id, count(*) count
    from customer group by store_id
  union
    select 'store' tbl, store_id, count(*) count
      from store group by store_id
  order by tbl, store_id;"
)

sp_print_df(store_distribution_sql)
```

<!--html_preserve--><div id="htmlwidget-1ea2c36d2dc6482e1ada" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1ea2c36d2dc6482e1ada">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9"],["customer","customer","customer","customer","customer","customer","store","store","store"],[1,2,3,4,5,6,1,2,10],[326,274,1,1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>tbl<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Sample Customer and Store Join Data

The following code block extracts sample customer and the store data.  The customer data is restricted to 10 rows to illustrate the different joins.  The 10 rows are used in the detail examples in order to perform a sanity check that the join is actually working.  Each detail example is followed by an aggregated summary across all rows of `customer` and `store` tables.


```r
sample_customers <- dbGetQuery(
  con,
  "select customer_id, first_name, last_name, store_id
    from customer
    where customer_id between 595 and 604"
)
stores <- dbGetQuery(con, "select * from store;")

sp_print_df(sample_customers)
```

<!--html_preserve--><div id="htmlwidget-8e535ae520f419a64908" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8e535ae520f419a64908">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],[595,596,597,598,599,600,601,602,603,604],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky"],[1,1,1,1,2,3,2,4,5,6]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
sp_print_df(stores)
```

<!--html_preserve--><div id="htmlwidget-9bf77d7f0a3e35e1769e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-9bf77d7f0a3e35e1769e">{"x":{"filter":"none","data":[["1","2","3"],[1,2,10],[1,2,10],[1,2,10],["2006-02-15T17:57:12Z","2006-02-15T17:57:12Z","2019-04-07T21:12:20Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
 

### `dplyr` store_id distribution Exercise

Execute and Review the output from the code block below.  Union and arrange the output to match the SQL output in the previous code block.  


```r
customer_table <- DBI::dbReadTable(con, "customer")
store_table <- DBI::dbReadTable(con, "store")

customer_summary <- customer_table %>% 
  group_by(store_id) %>% 
  summarize(count=n()) %>% 
  mutate(table='customer') %>% 
  select(table,store_id,count)

store_summary <- store_table %>% 
  group_by(store_id) %>% 
  summarize(count=n()) %>% 
  mutate(table='store') %>% 
  select(table,store_id,count)

sp_print_df(customer_summary)
```

<!--html_preserve--><div id="htmlwidget-5fd770d3f7cd78997c5a" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5fd770d3f7cd78997c5a">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["customer","customer","customer","customer","customer","customer"],[1,2,3,4,5,6],[326,274,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
sp_print_df(store_summary)
```

<!--html_preserve--><div id="htmlwidget-e9b8a9d74cd723d0b462" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-e9b8a9d74cd723d0b462">{"x":{"filter":"none","data":[["1","2","3"],["store","store","store"],[1,2,10],[1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
## UNION the two summary tables and ARRANGE the output to match the SQL output from the previouse code block
```

## Join Templates

In this section we perform various joins using `dplyr` and SQL.  Each `dplyr` code block has three purposes.  

1.  Show working detail/summary data join examples.  
2.  The code blocks can be used as templates for beginning more complex `dplyr` pipelines.
3.  The code blocks show the number of joins performed.

In these examples, the 'customer' is always the left table and 'store' is always the right table. The join condition shown in the `by` parameter
```
    by = c('store_id'='store_id')
```
is on the common foreign - primary key column `store_id`. This is technically an equi-join condition which makes our joins 1-to-1 and keeps the result set small.  

> In multi-column joins, each language_id would be replaced with a vector of column names used in the join by position. Note the column names do not need to be identical by position.

The suffix parameter is a way to distinguish the same column name in the joined tables.  The suffixes are usually a single letter to represent the name of the table.  

## Inner Joins

> For a conceptual refresher see: 
> 
> * [inner_join(superheroes, publishers)](http://stat545.com/bit001_dplyr-cheatsheet.html#inner_joinsuperheroes-publishers) 
> * [inner_join(publishers, superheroes)](http://stat545.com/bit001_dplyr-cheatsheet.html#inner_joinpublishers-superheroes) 


### SQL Inner Join Details {#example_140_inner-join-details-sql}

For an inner join between two tables, it doesn't matter which table is on the left, the first table, and which is on the right, the second table, because join conditions on both tables must be satisfied.  Reviewing the table below shows the inner join on our 10 sample customers and 3 store records returned only 6 rows.  The inner join detail shows only rows with matching store_id's.  


```r
customer_store_details_sij <- dbGetQuery(
  con,
  "select 'ij' join_type, customer_id, first_name, last_name, 
      c.store_id c_store_id, s.store_id s_store_id,
      s.manager_staff_id, s.address_id
    from customer c join store s on c.store_id = s.store_id
    where customer_id between 595 and 604;"
)

sp_print_df(customer_store_details_sij)
```

<!--html_preserve--><div id="htmlwidget-1b6843e66d577068f4b4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1b6843e66d577068f4b4">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["ij","ij","ij","ij","ij","ij"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### `dplyr` Inner Join Details {#example_140_inner-join-details-dplyr}


```r
customer_ij <- customer_table %>%
  inner_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
  filter(customer_id >= 595 & customer_id <= 604) %>%
  mutate(join_type = 'ij') %>%
  rename(s_address_id = address_id.y) %>%
  select(
    join_type,
    customer_id,
    first_name,
    last_name,
    store_id,
    store_id,
    manager_staff_id,
    s_address_id
  )

sp_print_df(customer_ij)
```

<!--html_preserve--><div id="htmlwidget-c1931b8dd0b6beedba3f" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c1931b8dd0b6beedba3f">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["ij","ij","ij","ij","ij","ij"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>s_address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Compare the output from the SQL and `dplyr` version.  The SQL output has a `c_store_id` and a `s_store_id` column and the `dplyr` output only has `store_id`.  In this case, because it is an inner join, it doesn't matter because the `store_id` in the `customer` table and the `store_id` in the `store` table will always be the same.

### SQL Inner Join Summary {#example_140_inner-join-summary-sql}

Note that the `store_id` is available from both the `customer` and `store` tables, selected by `c.store_id, s.store_id`, in the select clause.


```r
customer_store_summay_sij <- dbGetQuery(
  con,
  "select c.store_id c_store_id, s.store_id s_store_id, count(*) n
    from customer c join store s on c.store_id = s.store_id
    group by c.store_id,s.store_id;"
)

sp_print_df(customer_store_summay_sij)
```

<!--html_preserve--><div id="htmlwidget-57ee8a56708168f940c7" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-57ee8a56708168f940c7">{"x":{"filter":"none","data":[["1","2"],[1,2],[1,2],[326,274]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### `dplyr` Inner Join Summary {#example_140_inner-join-summary_dplyr}

In the previous SQL code block, `c.` and `s.` were used in the `inner join` as table aliases.  The `dplyr` suffix is similar to the SQL table alias. The role of the `dplyr` suffix and the SQL alias is to disambiguate duplicate table and column names referenced.    


```r
customer_store_summary_dij <- customer_table %>%
  inner_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
  mutate(
    join_type = "ij",
    c_store_id = if_else(is.na(customer_id), customer_id, store_id),
    s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)
  ) %>%
  group_by(join_type, c_store_id, s_store_id) %>%
  summarize(n = n())

sp_print_df(customer_store_summary_dij)
```

<!--html_preserve--><div id="htmlwidget-28f7c7d1c98c12cdd35c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-28f7c7d1c98c12cdd35c">{"x":{"filter":"none","data":[["1","2"],["ij","ij"],[1,2],[1,2],[326,274]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Left Joins

> For a conceptual refresher see: 
> 
> * [left_join(superheroes, publishers)](http://stat545.com/bit001_dplyr-cheatsheet.html#left_joinsuperheroes-publishers)
> * [left_join(publishers, superheroes)](http://stat545.com/bit001_dplyr-cheatsheet.html#left_joinpublishers-superheroes)  


### SQL Left Join Details {#example_140_left-join-details-sql}

The SQL block below shows all 10 sample `customer` rows in the detail output which join to 2 of the 3 rows in the `store` table, where the `customer` table is on the left and is the driving table.  All the rows with `customer` `store_id` greater than 2 have null/blank `store` column values.  


```r
customer_store_details_sloj <- dbGetQuery(
  con,
  "select 'loj' join_type, customer_id, first_name, last_name, 
      c.store_id c_store_id, s.store_id s_store_id, 
      s.manager_staff_id, s.address_id
    from customer c left join store s on c.store_id = s.store_id
    where customer_id between 595 and 604;"
)

sp_print_df(customer_store_details_sloj)
```

<!--html_preserve--><div id="htmlwidget-5aa87fa5ca597a0212e8" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5aa87fa5ca597a0212e8">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],["loj","loj","loj","loj","loj","loj","loj","loj","loj","loj"],[595,596,597,598,599,600,601,602,603,604],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky"],[1,1,1,1,2,3,2,4,5,6],[1,1,1,1,2,null,2,null,null,null],[1,1,1,1,2,null,2,null,null,null],[1,1,1,1,2,null,2,null,null,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### `dplyr` Left Join Details {#example_140_left-join-details-dplyr}

The next code block shows the left join details.  Note that the `s_store_id` column is derived via the mutate function, but not shown in the output below.  Without the `s_store_id` column, it might accidentally be assumed that the `store.store_id = customer.store_id` when the `store.store_id` values are actually NULL/NA based on the output without the `s_store_id` column.


```r
customer_store_detail_dloj <- customer_table %>%
  left_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
  filter(customer_id >= 595 & customer_id <= 604) %>%
  mutate(join_type = "loj",
         s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)) %>%
  rename(s_address_id = address_id.y) %>%
  select(
    join_type,
    customer_id,
    first_name,
    last_name,
    store_id,
    manager_staff_id,
    s_address_id
  )

sp_print_df(customer_store_detail_dloj)
```

<!--html_preserve--><div id="htmlwidget-00652361befaf729ca71" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-00652361befaf729ca71">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],["loj","loj","loj","loj","loj","loj","loj","loj","loj","loj"],[595,596,597,598,599,600,601,602,603,604],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky"],[1,1,1,1,2,3,2,4,5,6],[1,1,1,1,2,null,2,null,null,null],[1,1,1,1,2,null,2,null,null,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>s_address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The following code block includes the derived `s_store_id` value.  The output makes it explicit that the `s_store_id` value is missing.  The `sp_print_df` function is replaced with the print function to show the actual NA values.  


```r
customer_store_detail_dloj <- customer_table %>%
  left_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
  filter(customer_id >= 595 & customer_id <= 604) %>%
  mutate(
    join_type = "loj",
    s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)) %>%
  rename(c_store_id = store_id, s_address_id = address_id.y) %>%
  select(
    customer_id,
    first_name,
    last_name,
    c_store_id,
    s_store_id,
    manager_staff_id,
    s_address_id
  )

print(customer_store_detail_dloj)
```

```
##    customer_id first_name last_name c_store_id s_store_id manager_staff_id
## 1          595   Terrence Gunderson          1          1                1
## 2          596    Enrique  Forsythe          1          1                1
## 3          597    Freddie    Duggan          1          1                1
## 4          598       Wade  Delvalle          1          1                1
## 5          599     Austin   Cintron          2          2                2
## 6          600     Sophie      Yang          3         NA               NA
## 7          601     Sophie      Yang          2          2                2
## 8          602       John     Smith          4         NA               NA
## 9          603        Ian    Frantz          5         NA               NA
## 10         604         Ed   Borasky          6         NA               NA
##    s_address_id
## 1             1
## 2             1
## 3             1
## 4             1
## 5             2
## 6            NA
## 7             2
## 8            NA
## 9            NA
## 10           NA
```

In the remaining examples, the `dplyr` code blocks will show both the `customer` and `store` `store_id` values with the either `c_` or `s_` `store_id` prefix .  The `sp_print_df` function returns the SQL NULL and R NA values as blanks.

### SQL Left Join Summary {#example_140_left-join-summary-sql}

For a left outer join between two tables, it does matter which table is on the left and which is on the right, because every row in the left table is returned when there is no `where/filter` condition.  The second table returns row column values if the join condition exists or null collumn values if the join condition does not exist.  The left join is the most frequently used join type.

Note that SQL returns the `store_id` from both the `customer` and `store` tables, due to `c.store_id, s.store_id`, in the select clause.


```r
customer_store_summary_sloj <- dbGetQuery(
  con,
  "select c.store_id c_store_id, s.store_id s_store_id, count(*) loj
    from customer c left join store s on c.store_id = s.store_id
    group by c.store_id, s.store_id
    order by c.store_id;"
)

sp_print_df(customer_store_summary_sloj)
```

<!--html_preserve--><div id="htmlwidget-f1bcf35cc1468ea68e73" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f1bcf35cc1468ea68e73">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,2,3,4,5,6],[1,2,null,null,null,null],[326,274,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>loj<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The lojs column returns the number of rows found on the `store_id`, from the `customer` table and the `store` table if on both tables, rows 1 - 2.  The right table, the `store` table returned blank/NA, when the key only exists in the `customer` table, rows 3 - 6.

1.  The left outer join always returns all rows from the left table, the driving/key table, if not reduced via a filter()/where clause.  
2.  All inner join rows can reference all columns/derived columns specified in the select clause from both the left and right tables.  
3.  All rows from the left table, the outer table, without a matching row on the right returns all the columns/derived column values specified in the select clause from the left, but the values from right table have all values of NA. 

### `dplyr` Left Join Summary {#example_140_left-join-summary-dplyr}

The `dplyr` outer join verbs do not return the non-driving table join values.  Compare the `mutate` verb parameter, `s_store_id`, in the code block below with `s.store_id` in the equivalent SQL code block above.


```r
customer_store_summary_dloj <- customer_table %>%
  left_join(store_table, by = c("store_id", "store_id"), suffix(c(".c", ".s"))) %>%
  mutate(
    join_type = "loj",
    s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)
  ) %>%
  group_by(join_type, store_id, s_store_id) %>%
  summarize(n = n()) %>%
  rename(c_store_id = store_id) %>%
  select(join_type, c_store_id, s_store_id, n)

sp_print_df(customer_store_summary_dloj)
```

<!--html_preserve--><div id="htmlwidget-64da44eb9c120ee2cef4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-64da44eb9c120ee2cef4">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["loj","loj","loj","loj","loj","loj"],[1,2,3,4,5,6],[1,2,null,null,null,null],[326,274,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->




```r
print(customer_store_summary_dloj)
```

```
## # A tibble: 6 x 4
## # Groups:   join_type, c_store_id [6]
##   join_type c_store_id s_store_id     n
##   <chr>          <int>      <int> <int>
## 1 loj                1          1   326
## 2 loj                2          2   274
## 3 loj                3         NA     1
## 4 loj                4         NA     1
## 5 loj                5         NA     1
## 6 loj                6         NA     1
```

## Why Include one of the Inner Join Key columns?

It is not uncommon to have many many tables joined together as a series of left outer joins.  If the inner join key column is included in the output, one knows that the inner join condition was met or not.  If the key column is not shown and non-key columns are shown from the inner table, they may actually be null.  It is often the case that a long series of left outer joins just join on the key column to get one value out of the table to join to the next table in the series.  

One can think of the two components of an inner join as a transaction that is either in:

1. an open state with no matching rows in the inner table; _or_
2. a closed state with one or more matching rows in the inner table. 

Assume that we have a four DVD rental step process represented via table A, B, C, and D left outer joined together.  Summing the null and non-null keys together across all four tables gives a quick snap shot of the business in the four different steps.  We will review this concept in some detail in one of the future exercises.

## Right Joins

### SQL Right Join Details {#example_140_right-join-details-sql}

The SQL block below shows only our sample customer rows, (`customer_id` between 595 and 604). The driving table is on the right, the `store` table.  Only six of the 10 sample customer rows appear which have `store_id` = {1, 2}.  All three `store` rows appear, `row_id` = {1, 2, 10}.  The right join is the least frequently used join type.


```r
customer_store_detail_sroj <- dbGetQuery(
  con,
  "select 'roj' join_type, customer_id, first_name, last_name,
      c.store_id c_store_id, s.store_id s_store_id,
      s.manager_staff_id, s.address_id
    from customer c right join store s on c.store_id = s.store_id
    where coalesce(customer_id,595) between 595 and 604;"
)

sp_print_df(customer_store_detail_sroj)
```

<!--html_preserve--><div id="htmlwidget-f043235de15223ef4ae6" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f043235de15223ef4ae6">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["roj","roj","roj","roj","roj","roj","roj"],[595,596,597,598,599,601,null],["Terrence","Enrique","Freddie","Wade","Austin","Sophie",null],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang",null],[1,1,1,1,2,2,null],[1,1,1,1,2,2,10],[1,1,1,1,2,2,10],[1,1,1,1,2,2,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Compare the SQL left join where clause
```
    where customer_id between 595 and 604
```
with the SQL right join where clause 
```
    where coalesce(customer_id,595) between 595 and 604
```

The `customer` table is the driving table in the left join and always returns all rows from the `customer` table on the left that match the join and satisfy the where clause.  The `store` table is the driving table in the right join and always returns all rows from the `store` table on the right that match the join and satisfy the where clause.  The right outer join condition shown always returns the `store.store_id=10` row.  Since the `customer` table does not have the corresponding row to join to, the right outer join returns a customer row with all null column values.  The `coalesce` is a NULL if-then-else test.  If the `customer_id` is null, it returns 595 to prevent the store_id = 10 row from being dropped from the result set.

The right outer join clause can be rewritten as
```
     where customer_id between 595 and 604 or customer_id is null;
```

See the next `dplyr` code block to see the alternative `where` clause shown above.

### `dplyr` Right Join Details {#example_140_right-join-details-dplyr}


```r
customer_store_detail_droj <- customer_table %>%
  right_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
  filter((customer_id >= 595 & customer_id <= 604) | is.na(customer_id)) %>%
  mutate(
    join_type = "roj", 
    c_store_id = if_else(is.na(customer_id), customer_id, store_id)
  ) %>%
  rename(
    s_store_id = store_id,
    s_address_id = address_id.y
  ) %>%
  select(
    customer_id, 
    first_name, 
    last_name, 
    s_store_id, 
    c_store_id,
    manager_staff_id, 
    s_address_id
  ) 

sp_print_df(customer_store_detail_droj)
```

<!--html_preserve--><div id="htmlwidget-bc969903c70788e6d295" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-bc969903c70788e6d295">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[595,596,597,598,599,601,null],["Terrence","Enrique","Freddie","Wade","Austin","Sophie",null],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang",null],[1,1,1,1,2,2,10],[1,1,1,1,2,2,null],[1,1,1,1,2,2,10],[1,1,1,1,2,2,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>s_store_id<\/th>\n      <th>c_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>s_address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### SQL Right Outer Join Summary {#example_140_right-join-summary-sql}


```r
customer_store_summary_sroj <- dbGetQuery(
  con,
  "select 'roj' join_type, c.store_id c_store_id, s.store_id s_store_id, count(*) rojs
    from customer c right outer join store s on c.store_id = s.store_id
    group by c.store_id,s.store_id
    order by s.store_id;"
)

sp_print_df(customer_store_summary_sroj)
```

<!--html_preserve--><div id="htmlwidget-75bd3fb3d91522396188" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-75bd3fb3d91522396188">{"x":{"filter":"none","data":[["1","2","3"],["roj","roj","roj"],[1,2,null],[1,2,10],[326,274,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>rojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The rojs column returns the number of rows found on the keys from the right table, `store`, and the left table, the `customer` table.    

1.  The right outer join always returns all rows from the right table, the driving/key table, if not reduced via a filter()/where clause.  
2.  Right outer join returns all the columns/derived columns specified in the select clause from both the left and right tables.  
3.  All rows from the right table, the outer table, without a matching row on the left returns all the columns/derived column values specified in the select clause from the right, but the values from left table have all values of NA. For example, see the row above where `store.store_id = 10` and `c_store_id` is NULL. 

### `dplyr` Right Join Summary {#example_140_right-join-summary-dplyr}


```r
customer_store_summary_droj <- customer_table %>%
  right_join(store_table, by = c("store_id", "store_id"), suffix(c(".c", ".s")), all = store_table) %>%
  mutate(
    c_store_id = if_else(is.na(customer_id),customer_id, store_id),
    join_type = "rojs"
  ) %>%
  group_by(join_type, store_id, c_store_id) %>%
  summarize(n = n()) %>% 
  rename(s_store_id = store_id) %>%
  select(join_type, s_store_id, c_store_id, n)

sp_print_df(customer_store_summary_droj)
```

<!--html_preserve--><div id="htmlwidget-76a77f38d9e071bf1bf7" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-76a77f38d9e071bf1bf7">{"x":{"filter":"none","data":[["1","2","3"],["rojs","rojs","rojs"],[1,2,10],[1,2,null],[326,274,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>s_store_id<\/th>\n      <th>c_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Full Join

> For a conceptual refresher see: 
> 
> * [full_join(superheroes, publishers)](http://stat545.com/bit001_dplyr-cheatsheet.html#full_joinsuperheroes-publishers)  

### SQL Full Join Details {#example_140_full-join-details-sql-a}

The full outer join is a combination of the left and right outer joins and returns all matched and unmatched rows from the `ON` clause.  The matched rows return their table column values and the unmatched rows return NULL column values.  This can result in a very large result set.

The next SQL block implements a full outer join and returns 11 rows.  Change the `Show entries` field from 10 to 25 to see all the entries.  


```r
customer_store_details_sfoj <- dbGetQuery(
  con,
  "select 'foj' join_type, c.customer_id, c.first_name, c.last_name,
      c.store_id c_store_id, s.store_id s_store_id,
      s.manager_staff_id,s.address_id
    from customer c full outer join store s on c.store_id = s.store_id 
    where coalesce(c.customer_id,595) between 595 and 604;"
)

sp_print_df(customer_store_details_sfoj)
```

<!--html_preserve--><div id="htmlwidget-8ee905499984eb6db9c6" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8ee905499984eb6db9c6">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11"],["foj","foj","foj","foj","foj","foj","foj","foj","foj","foj","foj"],[595,596,597,598,599,600,601,602,603,604,null],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed",null],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky",null],[1,1,1,1,2,3,2,4,5,6,null],[1,1,1,1,2,null,2,null,null,null,10],[1,1,1,1,2,null,2,null,null,null,10],[1,1,1,1,2,null,2,null,null,null,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### `dplyr` Full Join Details {#example_140_full-join-details-sql-b}


```r
customer_store_detail_dfoj <- customer_table %>%
  full_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
  filter((customer_id >= 595 & customer_id <= 604) | is.na(customer_id)) %>%
  mutate(
    join_type = "roj",
    c_store_id = if_else(is.na(customer_id), customer_id, store_id)
  ) %>%
  rename(
    s_store_id = store_id,
    s_address_id = address_id.y
  ) %>%
  select(customer_id, first_name, last_name, s_store_id, c_store_id, manager_staff_id, s_address_id) 

sp_print_df(customer_store_detail_dfoj)
```

<!--html_preserve--><div id="htmlwidget-dd8a39379132dc76f8e0" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-dd8a39379132dc76f8e0">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11"],[595,596,597,598,599,600,601,602,603,604,null],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed",null],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky",null],[1,1,1,1,2,3,2,4,5,6,10],[1,1,1,1,2,3,2,4,5,6,null],[1,1,1,1,2,null,2,null,null,null,10],[1,1,1,1,2,null,2,null,null,null,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>s_store_id<\/th>\n      <th>c_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>s_address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### SQL Full Join Summary {#example_140_full-join-summary-sql}

The result set below is ordered by the `store.store_id`.  


```r
customer_store_summary_sfoj <- dbGetQuery(
  con,
  "select 'foj' join_type, c.store_id c_store_id, s.store_id s_store_id, count(*) fojs
    from customer c full outer join store s on c.store_id = s.store_id
    group by c.store_id,s.store_id
    order by s.store_id,c.store_id;"
)

sp_print_df(customer_store_summary_sfoj)
```

<!--html_preserve--><div id="htmlwidget-b9eade0394198b25015e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b9eade0394198b25015e">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["foj","foj","foj","foj","foj","foj","foj"],[1,2,null,3,4,5,6],[1,2,10,null,null,null,null],[326,274,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### `dplyr` Full Join Summary {#example_140_full-join-summary-dplyr}

The full outer join summary has seven rows.  Store_id = {1, 2} values appear in both tables.  Store_id = {3 - 6} appear only in the `customer` table which is on the left.  Store_id = 10 appears only in the `store` table which is on the right.


```r
customer_store_summary_dfoj <- customer_table %>%
  full_join(store_table, by = c("store_id", "store_id"), suffix(c(".c", ".s"))) %>%
  mutate(
    join_type = "fojs",
    c_store_id = if_else(is.na(customer_id), customer_id, store_id),
    s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)
  ) %>%
  group_by(join_type, c_store_id, s_store_id) %>%
  summarize(n = n()) %>%
  arrange(s_store_id)

sp_print_df(customer_store_summary_dfoj)
```

<!--html_preserve--><div id="htmlwidget-55deec5fcf35d2d52864" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-55deec5fcf35d2d52864">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["fojs","fojs","fojs","fojs","fojs","fojs","fojs"],[1,2,null,3,4,5,6],[1,2,10,null,null,null,null],[326,274,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Semi Join 

> For a conceptual refresher see: 
> 
> * [semi_join(publishers, superheroes)](http://stat545.com/bit001_dplyr-cheatsheet.html#semi_joinpublishers-superheroes)  

Below is the `dplyr` semi_join documentation:

> semi_join()  
> return all rows from x where there are matching values in y, keeping just columns from x.
> 
> A semi join differs from an inner join because an inner join will return one row of x for each matching row of y, where a semi join will never duplicate rows of x.

The semi join always returns one and only one row from the x table that satisfies the inner join condition.  If we look at one key value on both x and y where the x table has 1 x.key row and y has n y.key rows, then the inner join returns n x.key rows, (1-to-n), and the semi-join returns just one x.key row, (1-to-1).

### SQL Semi Join Customer to Store {#example_140_semi-join-sql-1}

SQL does not have an explicit 'semi join' key word.  The `semi join` reduces relationships from 1-to-n to 1-to-1.  SQL uses an EXISTS - subquery syntax to implement the `semi join`.

#### SQL EXISTS and Correlated SubQuery Syntax 

```
SELECT * 
  FROM table1 l
  WHERE EXISTS(SELECT 1 FROM table2 r WHERE l.c = r.c)
```
 
> The EXISTS keyword checks if one or more rows satisfy the SELECT clause enclosed in parenthesis, the correlated subquery.  The r.c column from table2, the inner/right table, is correlated to the l.c column from table1, the outer/left table. 

For all the table1 rows where the EXISTS clause returns TRUE, the table1 rows are returned. There is no way to reference table2 columns in the outer select, hence the semi join. 

All the previous joins were _mutating joins_, meaning the joins resulted in a blending of columns from both tables.  A semi join only returns rows from a single table and is a filtering join. The mutating examples included a count column to show the 1-to-n relationships.  Filtering joins are 1-to-1 and the count column is dropped in the following examples.


```r
customer_store_ssj <- dbGetQuery(
  con,
  "select 'sj' join_type, customer_id, first_name, last_name, c.store_id c_store_id
    from customer c 
    where customer_id > 594 
      and exists(
        select 1 from store s where c.store_id = s.store_id
      );
;")

sp_print_df(customer_store_ssj)
```

<!--html_preserve--><div id="htmlwidget-886b72303963ca110dca" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-886b72303963ca110dca">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["sj","sj","sj","sj","sj","sj"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Note that this returned the six rows from the customer table that satisfied the `c.store_id = s.store_id` join condition.  It is the same as the SQL Inner Join example earlier, but without the store columns.  All the relationships are 1-to-1.

### `dplyr` Semi Join Customer to Store {#example_140_semi-join-dplyr-1}

The corresponding `dplyr` version is shown in the next code block.


```r
customer_store_dsj <- customer_table %>% 
  semi_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
  filter(customer_id >= 595 & customer_id <= 604 ) %>%
  mutate(join_type = 'sj') %>%
  select(join_type, customer_id, first_name, last_name, store_id, store_id) 

sp_print_df(customer_store_dsj)
```

<!--html_preserve--><div id="htmlwidget-a80e2fa15ed724ec75b2" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a80e2fa15ed724ec75b2">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["sj","sj","sj","sj","sj","sj"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### SQL Semi Join Store to Customer {#example_140_semi-join-sql-2}

In the following Semi Join, the driving table is switched to the `store` table and our 10 sample customers as the right table.  


```r
store_customer_detail_ssj <- dbGetQuery(
  con,
  "select 'sj' join_type, s.store_id s_store_id, s.manager_staff_id, s.address_id
    from store s
    where EXISTS(
      select 1 
        from customer c 
        where c.store_id = s.store_id 
          and c.customer_id between 595 and 604
    )
;")

sp_print_df(store_customer_detail_ssj)
```

<!--html_preserve--><div id="htmlwidget-3db5b81b21ea6826b28d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-3db5b81b21ea6826b28d">{"x":{"filter":"none","data":[["1","2"],["sj","sj"],[1,2],[1,2],[1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Here we see that we get the two rows from the store table that satisfy the `s.store_id = c.store_id` condition,  where `store_id` = {1, 2}.  In this example the relationship between store and customer is 1-to-n, but we do not know that from the output.

### `dplyr` Semi Join Store to Customer {#example_140_semi-join-dplyr-2}

The corresponding `dplyr` version is shown in the next code block.  Note that the filter condition on the `customer` table has been removed because the semi_join does not return any customer columns.


```r
store_customer_dsj <-  store_table %>%
  semi_join(customer_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
  mutate(join_type = 'sj') %>%
  select(join_type, store_id, manager_staff_id, address_id)

sp_print_df(store_customer_dsj)
```

<!--html_preserve--><div id="htmlwidget-3a49d8e0661245432c4d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-3a49d8e0661245432c4d">{"x":{"filter":"none","data":[["1","2"],["sj","sj"],[1,2],[1,2],[1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### SQL Semi Join Store to Customer Take 2 {#example_140_semi-join-sql-3}

In the `Semi Join Customer to Store` examples, we saw four rows with store_id = 1 and two rows with store_id = 2.  The `EXISTS` key word is replaced with a count of the matching rows.  


```r
store_customer_detail_ssj2 <- dbGetQuery(
  con,
  "select 'sj' join_type, s.store_id s_store_id, s.manager_staff_id, s.address_id
    from store s
    where
      (select count(*)
        from customer c 
        where c.store_id = s.store_id 
          and c.customer_id between 595 and 604
      ) in (2, 4)
;")

sp_print_df(store_customer_detail_ssj2)
```

<!--html_preserve--><div id="htmlwidget-8ffa30567256ad641727" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8ffa30567256ad641727">{"x":{"filter":"none","data":[["1","2"],["sj","sj"],[1,2],[1,2],[1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

To generalize the test above, replace `in (2, 4)` with `> 0`.  

## Anti Joins

> For a conceptual refresher see: 
> 
> * [anti_join(superheroes, publishers)](http://stat545.com/bit001_dplyr-cheatsheet.html#anti_joinsuperheroes-publishers) 
> * [anti_join(publishers, superheroes)](http://stat545.com/bit001_dplyr-cheatsheet.html#anti_joinpublishers-superheroes)  



A `semi join` returns rows from one table that has one or more matching rows in the other table.  The `anti join` returns rows from one table that has no matching rows in the other table.    

#### `dplyr::anti_join` {#example_140_anti-join-dplyr}

The anti join is an outer join without the inner joined rows.  It only returns the rows from the driving table that do not have a matching row from the other table.  


```r
customer_store_aj <- customer_table %>% 
    filter(customer_id > 594) %>%
    anti_join(store_table, by = c("store_id", "store_id"), suffix(c(".c", ".s"))) %>%
    mutate(join_type = "anti_join")  

sp_print_df(customer_store_aj)
```

<!--html_preserve--><div id="htmlwidget-ebbe1e63c0bbb57abe6c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-ebbe1e63c0bbb57abe6c">{"x":{"filter":"none","data":[["1","2","3","4"],[600,602,603,604],[3,4,5,6],["Sophie","John","Ian","Ed"],["Yang","Smith","Frantz","Borasky"],["sophie.yang@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org","ed.borasky@sakilacustomer.org"],[1,2,3,4],[true,true,true,true],["2019-04-07","2019-04-07","2019-04-07","2019-04-07"],["2019-04-07T07:00:00Z","2019-04-07T07:00:00Z","2019-04-07T07:00:00Z","2019-04-07T07:00:00Z"],[1,1,1,1],["anti_join","anti_join","anti_join","anti_join"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n      <th>join_type<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

All of the rows returned from the customer table have store_id = {3 - 6} which do not exist in the store_id.

#### SQL anti Join 1, NOT EXISTS and Correlated subquery {#example_140_anti-join-sql-1-a}

SQL doesn't have an anti join key word.  Here are three different ways to achieve the same result.

This is the negation of the same construct used in the semi join discusion.  The anti-join tests for 0 matches instead of 1 or more matches for the semi-join.


```r
rs <- dbGetQuery(
  con,
  "select 'aj' join_type, customer_id, first_name, last_name, c.store_id
    from customer c 
    where not exists (
      select 1 from store s where s.store_id = c.store_id
    )
    order by c.customer_id"
)

sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-7f4ee133238bc8a462c7" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-7f4ee133238bc8a462c7">{"x":{"filter":"none","data":[["1","2","3","4"],["aj","aj","aj","aj"],[600,602,603,604],["Sophie","John","Ian","Ed"],["Yang","Smith","Frantz","Borasky"],[3,4,5,6]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### SQL anti Join 2, Left Outer Join where NULL on Right {#example_140_anti-join-sql-1-b}


```r
rs <- dbGetQuery(
  con,
  "select 'aj' join_type, customer_id, first_name, last_name, c.store_id ajs
    from customer c left outer join store s on c.store_id = s.store_id
    where s.store_id is null
    order by c.customer_id;"
)

sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-78af60494c5d19234c4c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-78af60494c5d19234c4c">{"x":{"filter":"none","data":[["1","2","3","4"],["aj","aj","aj","aj"],[600,602,603,604],["Sophie","John","Ian","Ed"],["Yang","Smith","Frantz","Borasky"],[3,4,5,6]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>ajs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### SQL anti Join 3, ID in driving table and NOT IN lookup table {#example_140_anti-join-sql-3}


```r
rs <- dbGetQuery(
  con,
  "select 'aj' join_type, customer_id, first_name, last_name, c.store_id
    from customer c 
    where c.store_id NOT IN (select store_id from store)
    order by c.customer_id;"
)

sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-925b76f2ab23806aa77f" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-925b76f2ab23806aa77f">{"x":{"filter":"none","data":[["1","2","3","4"],["aj","aj","aj","aj"],[600,602,603,604],["Sophie","John","Ian","Ed"],["Yang","Smith","Frantz","Borasky"],[3,4,5,6]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


<!-- Show all different joins together with filter to allow comparison between different mutating joins


```r
customer_store_summary_dfoj %>%
  union(customer_store_summary_droj) %>%
  union(customer_store_summary_dloj) %>%
  union(customer_store_summary_dij) %>%
  arrange(join_type, s_store_id, c_store_id)
```


```r
sp_print_df(customer_store_summary_dfoj)
```

<!--html_preserve--><div id="htmlwidget-b0e5f5dec46abbe63dcf" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b0e5f5dec46abbe63dcf">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["fojs","fojs","fojs","fojs","fojs","fojs","fojs"],[1,2,null,3,4,5,6],[1,2,10,null,null,null,null],[326,274,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


```r
customer_store_details_sij %>%
  union(customer_store_details_sloj) %>%
  union(customer_store_detail_sroj) %>%
  union(customer_store_details_sfoj) %>%
  arrange(join_type, s_store_id)
```

```r
sp_print_df(customer_store_details_sij)
```

<!--html_preserve--><div id="htmlwidget-5696ce52334a8f202efb" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5696ce52334a8f202efb">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["ij","ij","ij","ij","ij","ij"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

--->

## Non-Equi-Join Example

All the previous examples are equi-joins, which is the most common type of join.  The next example is made up and shows a '<=' join.  The `store` table is used.  Assume that the `store_id` actually represents some distance.  The example shows all distances <= to all other distances.   


```r
store_store_slej <- dbGetQuery(
  con,
  "select 'lej' join_type, s1.store_id starts, s2.store_id stops, 
      s2.store_id - s1.store_id delta
    from store s1 join store s2 on s1.store_id <= s2.store_id
    order by s1.store_id;"
)

sp_print_df(store_store_slej)
```

<!--html_preserve--><div id="htmlwidget-eedebfb7f46972f489be" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-eedebfb7f46972f489be">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["lej","lej","lej","lej","lej","lej"],[1,1,1,2,2,10],[1,2,10,2,10,10],[0,1,9,0,8,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>starts<\/th>\n      <th>stops<\/th>\n      <th>delta<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### `dplyr` Non-equi Join {#example_140_inner-join-dplyr}

`dplyr` doesn't currently support a non-equi join.  In the `by` parameter, one can not change the '=' to '<=' as shown below.

``` 
{r}

store_store_slej <- store_table %>%
  inner_join(store_table, by =  c("store_id" <= "store_id"), suffix(c(".c", ".s"))) 
    
```

The above code block throws the following error message.

```
Error: `by` must be a (named) character vector, list, or NULL for natural joins (not 
recommended in production code), not logical Call `rlang::last_error()` to see a backtrace
```

The explanation below is from [here](https://stackoverflow.com/questions/47485779/dplyr-joins-how-do-you-do-a-non-standard-join-col1-col2-when-working-with), a Stack Overflow discussion that was posted Nov 25, 2017.

In `by = c("col1" = "col2")`,  `=` is _not_ the equality operator, but an assignment operator (the equality operator in R is `==`). The expression inside `c(...)` creates a _named character vector_ (name: col1 value: col2) that `dplyr` uses for the join. Nowhere do you define the kind of comparison that is made during the join. The comparison is hard-coded in `dplyr`. I don't think `dplyr` supports non-equi joins (yet).


```r
# disconnect from the db
 dbDisconnect(con)

 sp_docker_stop("sql-pet")
```


```r
knitr::knit_exit()
```
