# Introduction to SQL Joins {#chapter_sql-joins}

> This chapter demonstrates how to:
> 
> * Use primary and foreign keys to retrieve specific rows of a table
> * do different kinds of join queries
> * Exercises
> * Query the database to get basic information about each dvdrental story
> * How to interact with the database using different strategies

## Setup

These packages are called in almost every chapter of the book:


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
## 60a61f1e10f7        postgres-dvdrental   "docker-entrypoint.s…"   31 seconds ago      Exited (0) 2 seconds ago                       sql-pet
```

Start up the `docker-pet` container


```r
sp_docker_start("sql-pet")
```

Now connect to the database with R.  Need to wait for Docker & Postgres to come up before connecting.


```r
con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 30
)
```

## Making up data for Join Examples

Each chapter in the book stands on its own.  If you have worked through the code blocks in this chapter in a previous session, you created some new customer records in order to work through material in the rest of the chapter. 

The DVD rental database data is too clean to demonstrate some join concepts.  To dirty the data, this chapter performs a number of database operations on data tables that a data analyst is typically restricted from doing in the real world.  

1.  Deleting records from tables.
2.  Inserting records from tables.
3.  Enabling and disabling table constraints.

In our Docker environment, you have no restrictions on the database operations you can perform.

In the next couple of code blocks, we delete the new data and then recreate the data for the join examples in this next chapter.

### SQL Delete Data Syntax

```
    DELETE FROM <source> WHERE <where_clause>;
```

### Delete New Practice Customers from the Customer table.

In the next code block we delete out the new customers that were added when the book was compliled or added while working through the chapter.  Out of the box, the DVD rental database's highest customer_id = 599.

```
dbExecute() always returns a scalar numeric that specifies the number of rows affected by the statement. 
```


```r
dbExecute(
  con,
  "delete from customer 
   where customer_id >= 600;
  "
)
```

```
## [1] 0
```

The number above tells us how many rows were actually deleted from the customer table.

### Delete New Practice Store from the Store Table.

In the next code block we delete out the new stores that were added when the book was compliled or added working through the exercises.  Out of the box, the DVD rental database's highest store_id = 2.


```r
dbExecute(con, "delete from store where store_id > 2;")
```

```
## [1] 0
```

### SQL Single Row Insert Data Syntax

```
    INSERT INTO <target> <column_list> VALUES <values list>;
    <target> : target table/view
    <column list> : csv list of columns
    <values list> : values assoicated with the column list.
```

The `column list` is the list of column names on the table and the corresponding list of values must have the correct data type.  The following code block returns the `CUSTOMER` column names and data types.


```r
customer_cols <- dbGetQuery(
  con,
  "select table_name, column_name, ordinal_position, data_type 
          from information_schema.columns 
         where table_catalog = 'dvdrental' 
           and table_name = 'customer'
       ;"
)

sp_print_df(customer_cols)
```

<!--html_preserve--><div id="htmlwidget-1d9f9b9fdca3023baa83" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1d9f9b9fdca3023baa83">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],["customer","customer","customer","customer","customer","customer","customer","customer","customer","customer"],["customer_id","store_id","first_name","last_name","email","address_id","activebool","create_date","last_update","active"],[1,2,3,4,5,6,7,8,9,10],["integer","smallint","character varying","character varying","character varying","smallint","boolean","date","timestamp without time zone","integer"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>ordinal_position<\/th>\n      <th>data_type<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":3},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

In the next code block, we insert Sophie as a new customer into the customer table via a SQL insert statement.  The columns list clause has three id columns, customer_id, store_id, and address_id.  The customer_id is a primary key column and the other two 'look like' foreign key columns.

For now, we are interested in getting some new customers into the customer table.  We look at the relations between the customer and the store tables later in this chapter.



```r
dbExecute(
  con,
  "
insert into customer 
  (customer_id,store_id,first_name,last_name,email,address_id,activebool
  ,create_date,last_update,active)
  values(600,3,'Sophie','Yang','sophie.yang@sakilacustomer.org',1,TRUE,now(),now()::date,1)
  "
)
```

```
## [1] 1
```

The number above should be 1 indicating that one record was inserted.


```r
new_customers <- dbGetQuery(con
                ,"select customer_id,store_id,first_name,last_name
                     from customer where customer_id >= 600;")
sp_print_df(new_customers)
```

<!--html_preserve--><div id="htmlwidget-b18b48ec4ad649442f3b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b18b48ec4ad649442f3b">{"x":{"filter":"none","data":[["1"],[600],[3],["Sophie"],["Yang"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Primary Key Constraint Error Message

For the new customers, we are concerned with not violating the PK and FK constraints.
In the next SQL code block, we try and reinsert the newly created customer record inserted above.  Instead of having the code block fail, it throws a duplicate key exception error message.  If you `knit` the document, the exception error message is thrown to the `R Markdown` tab.   


```r
dbExecute(con, "
do $$
DECLARE v_customer_id INTEGER;
begin
    v_customer_id = 600;
    insert into customer 
    (customer_id,store_id,first_name,last_name,email,address_id,activebool
    ,create_date,last_update,active)
     values(v_customer_id,3,'Sophie','Yang','sophie.yang@sakilacustomer.org',1,TRUE
           ,now(),now()::date,1);
exception
when unique_violation then
    raise notice 'SQLERRM = %, customer_id = %', SQLERRM, v_customer_id;
when others then 
    raise 'SQLERRM = % SQLSTATE =%', SQLERRM, SQLSTATE;
end;
$$ language 'plpgsql';")
```

```
## [1] 0
```

The number above shows how many rows were inserted.  To ensure that the thrown error message is part of the book, the error message is shown below.

```
NOTICE:  SQLERRM = duplicate key value violates unique constraint "customer_pkey", customer_id = 600
CONTEXT:  PL/pgSQL function inline_code_block line 12 at RAISE
```

### R Exercise: Inserting a Single Row via a Dataframe

In the following code block replace Sophie Yang with your name where appropriate.  
Note:

1.  The last data frame parameter sets the stringsAsFactors is `FALSE`.  Databases do not have a native `FACTOR` type.
2.  The dataframe column names must match the table column names. 
3.  The dbWriteTable function needs `append` = true to actually insert the new row.
4.  The dbWriteTable function has an option 'overwrite'.  It is set to FALSE  by default.  If it is set to TRUE, the table is first truncated before the row is inserted.  
5.  No write occurs if both overwrite and append = FALSE.


```r
df <- data.frame(
  customer_id = 601
  , store_id = 2
  , first_name = "Sophie"
  , last_name = "Yang"
  , email = "sophie.yang@sakilacustomer.org"
  , address_id = 1
  , activebool = TRUE
  , create_date = Sys.Date()
  , last_update = Sys.time()
  , active = 1
  , stringsAsFactors = FALSE
)
dbWriteTable(con, "customer", value = df, append = TRUE, row.names = FALSE)

new_customers <- dbGetQuery(con
                , "select customer_id,store_id,first_name,last_name
                     from customer where customer_id >= 600;")
sp_print_df(new_customers)
```

<!--html_preserve--><div id="htmlwidget-514d280a38cf86ead40b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-514d280a38cf86ead40b">{"x":{"filter":"none","data":[["1","2"],[600,601],[3,2],["Sophie","Sophie"],["Yang","Yang"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## SQL Multi-Row Insert Data Syntax

```
    INSERT INTO <target> <column_list> VALUES <values list1>, ... <values listn>;
    <target>       : target table/view
    <column list>  : csv list of columns
   (<values list>) : values assoicated with the column list.
```

Postgres and some other flavors of SQL allow multiple rows to be inserted at a time.  The syntax is identical to the Single Row syntax, but includes multiple `(<values list>)` clauses separated by commas.  Note that each value list is enclosed it a set of parenthesis.  The following code block illustrates the SQL multi-row insert.  Note that the customer_id column takes on sequential values to satisfy the PK constraint.


## SQL Multi-Row Insert Data Example


```r
#
dbExecute(
  con,
  "insert into customer 
  (customer_id,store_id,first_name,last_name,email,address_id,activebool
  ,create_date,last_update,active)
   values(602,4,'John','Smith','john.smith@sakilacustomer.org',2,TRUE
         ,now()::date,now()::date,1)
         ,(603,5,'Ian','Frantz','ian.frantz@sakilacustomer.org',3,TRUE
         ,now()::date,now()::date,1)
         ,(604,6,'Ed','Borasky','ed.borasky@sakilacustomer.org',4,TRUE
         ,now()::date,now()::date,1)
         ;"
)
```

```
## [1] 3
```

## DPLYR Multi-Row Insert Data Example

The Postgres R multi-row insert is similar to the single row insert.  The single column values are converted to a vector of values.

### R Exercise: Inserting Multiple Rows via a Dataframe

Replace the two first_name, last_name, and email column values with your own made up values in the following code block.  The output should be all of our new customers, customer_id = {600 - 606}.


```r
customer_id <- c(605, 606)
store_id <- c(3, 4)
first_name <- c("John", "Ian")
last_name <- c("Smith", "Frantz")
email <- c("john.smith@sakilacustomer.org", "ian.frantz@sakilacustomer.org")
address_id <- c(3, 4)
activebool <- c(TRUE, TRUE)
create_date <- c(Sys.Date(), Sys.Date())
last_update <- c(Sys.time(), Sys.time())
active <- c(1, 1)

df2 <- data.frame(customer_id, store_id, first_name, last_name, email,
  address_id, activebool, create_date, last_update, active,
  stringsAsFactors = FALSE
)


dbWriteTable(con, "customer",
  value = df2, append = TRUE, row.names = FALSE
)

new_customers <- dbGetQuery(con
                , "select customer_id,store_id,first_name,last_name
                     from customer where customer_id >= 600;")
sp_print_df(new_customers)
```

<!--html_preserve--><div id="htmlwidget-74434d812ec23342fdce" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-74434d812ec23342fdce">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[600,601,602,603,604,605,606],[3,2,4,5,6,3,4],["Sophie","Sophie","John","Ian","Ed","John","Ian"],["Yang","Yang","Smith","Frantz","Borasky","Smith","Frantz"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Confirm that the two new rows, customer_id = { 605, 606} are in the output.

The next two code block show all the rows in the  store and staff tables.  Notice that neither table has a staff_id or a manager_staff_id = 10.  We will attempt to insert such a row in the upcoming code blocks.


```r
stores <- dbGetQuery(con,"select * from store;")
sp_print_df(stores)
```

<!--html_preserve--><div id="htmlwidget-8da54f9f5480ad7c3ec3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8da54f9f5480ad7c3ec3">{"x":{"filter":"none","data":[["1","2"],[1,2],[1,2],[1,2],["2006-02-15T17:57:12Z","2006-02-15T17:57:12Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


```r
staff  <- dbGetQuery(con
            ,"select staff_id, first_name, last_name, address_id, email, store_id
                from staff;")
sp_print_df(staff)
```

<!--html_preserve--><div id="htmlwidget-124fb78127817ec02cd9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-124fb78127817ec02cd9">{"x":{"filter":"none","data":[["1","2"],[1,2],["Mike","Jon"],["Hillyer","Stephens"],[3,4],["Mike.Hillyer@sakilastaff.com","Jon.Stephens@sakilastaff.com"],[1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>staff_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>address_id<\/th>\n      <th>email<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Creating a Messy Store Row

A new store row is needed to illustrate a right outer join in a future code block.  However, one cannot insert/update a row into the `store` table with a manager_staff_id = 10 because of a foreign key constraint on the manager_staff_id column.  

The manager_staff_id value must satisfy two conditions before the database will allow the new store row to be inserted into the table when the table constraints are enabled.:

1.  The manager_staff_id must be unique when inserted into the store table.
2.  The manager_staff_id must match a `staff` table staff_id value.

Next we show both error messages:

1.  The next code block attempts to insert a new store, `store_id = 10`, with manager_staff_id = 1, but fails with a unique constraint error message.  The manager_staff_id = 1 already exists in the store table.


```r
dbExecute(con, "
do $$
DECLARE v_manager_staff_id INTEGER;
begin
    v_manager_staff_id = 1;
    insert into store (store_id,manager_staff_id,address_id,last_update)
         values (10,v_manager_staff_id,10,now()::date);
exception
when foreign_key_violation then
    raise notice 'SQLERRM = %, manager_staff_id = %', SQLERRM, v_manager_staff_id;
when others then
    raise notice 'SQLERRM = % SQLSTATE =%', SQLERRM, SQLSTATE;
end;
$$ language 'plpgsql';")
```

```
## [1] 0
```

```
Error in result_create(conn@ptr, statement) : Failed to prepare query: server closed the connection unexpectedly This probably means the server terminated abnormally before or while processing the request.
```

The number above should be 0 and indicates no row was inserted.

2.  The next code block attempts to insert a new store, `store_id = 10`, with manager_staff_id = 10, but fails with a foreign key constraint error message because there does not exist a staff table row with staff_id = 10.


```r
dbExecute(con, "
do $$
DECLARE v_manager_staff_id INTEGER;
begin
    v_manager_staff_id = 10;
    insert into store (store_id,manager_staff_id,address_id,last_update)
         values (10,v_manager_staff_id,10,now()::date);
exception
when foreign_key_violation then
    raise notice 'SQLERRM = %, manager_staff_id = %', SQLERRM, v_manager_staff_id;
when others then
    raise notice 'SQLERRM = % SQLSTATE =%', SQLERRM, SQLSTATE;
end;
$$ language 'plpgsql';")
```

```
## [1] 0
```

```
NOTICE:  SQLERRM = insert or update on table "store" violates foreign key constraint "store_manager_staff_id_fkey", manager_staff_id = 10
CONTEXT:  PL/pgSQL function inline_code_block line 9 at RAISE
```

Again, the number above should be 0 and indicates no row was inserted.

The following three code blocks

1.  disables all the database constraints on the `store` table
2.  Inserts the store row with store_id = 10 via a dataframe.
3.  Re-enabes the database constraints on the store table


```r
#
dbExecute(con, "ALTER TABLE store DISABLE TRIGGER ALL;")
```

```
## [1] 0
```


```r
df <- data.frame(
    store_id = 10
  , manager_staff_id = 10
  , address_id = 10
  , last_update = Sys.time()
)
dbWriteTable(con, "store", value = df, append = TRUE, row.names = FALSE)
```


```r
dbExecute(con, "ALTER TABLE store ENABLE TRIGGER ALL;")
```

```
## [1] 0
```

The zeros after the dbExecute code blocks indicate that the dbExecute calls did not alter any rows on the table.

In the next code block we confirm our new row, store_id = 10, was actually inserted.


```r
stores <- dbGetQuery(con,"select * from store;")
sp_print_df(stores)
```

<!--html_preserve--><div id="htmlwidget-dd0a51033db44e820d90" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-dd0a51033db44e820d90">{"x":{"filter":"none","data":[["1","2","3"],[1,2,10],[1,2,10],[1,2,10],["2006-02-15T17:57:12Z","2006-02-15T17:57:12Z","2019-02-18T02:43:36Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<!--

## Creating Duplicate Customer Rows 

In the next section we create a new table, `smy_customer`.  We will load all customers with customer_id > 594 twice.  The `smy_customer` table will be used in the dplyr semi-join section. 


```r
dbExecute(con,"drop table if exists smy_customer;")
```

```
## [1] 0
```

```r
dbExecute(con,"create table smy_customer 
    as select * 
         from customer  
        where customer_id > 594;")
```

```
## [1] 12
```

```r
dbExecute(con,"insert into smy_customer 
               select * 
                 from customer  
                where customer_id > 594;")
```

```
## [1] 12
```

```r
smy_cust_dupes <- dbGetQuery(con,'select * 
                                    from smy_customer 
                                  order by customer_id')

sp_print_df(smy_cust_dupes)
```

<!--html_preserve--><div id="htmlwidget-1fe403c81784621152ab" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1fe403c81784621152ab">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24"],[595,595,596,596,597,597,598,598,599,599,600,600,601,601,602,602,603,603,604,604,605,605,606,606],[1,1,1,1,1,1,1,1,2,2,3,3,2,2,4,4,5,5,6,6,3,3,4,4],["Terrence","Terrence","Enrique","Enrique","Freddie","Freddie","Wade","Wade","Austin","Austin","Sophie","Sophie","Sophie","Sophie","John","John","Ian","Ian","Ed","Ed","John","John","Ian","Ian"],["Gunderson","Gunderson","Forsythe","Forsythe","Duggan","Duggan","Delvalle","Delvalle","Cintron","Cintron","Yang","Yang","Yang","Yang","Smith","Smith","Frantz","Frantz","Borasky","Borasky","Smith","Smith","Frantz","Frantz"],["terrence.gunderson@sakilacustomer.org","terrence.gunderson@sakilacustomer.org","enrique.forsythe@sakilacustomer.org","enrique.forsythe@sakilacustomer.org","freddie.duggan@sakilacustomer.org","freddie.duggan@sakilacustomer.org","wade.delvalle@sakilacustomer.org","wade.delvalle@sakilacustomer.org","austin.cintron@sakilacustomer.org","austin.cintron@sakilacustomer.org","sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org","john.smith@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org","ian.frantz@sakilacustomer.org","ed.borasky@sakilacustomer.org","ed.borasky@sakilacustomer.org","john.smith@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org","ian.frantz@sakilacustomer.org"],[601,601,602,602,603,603,604,604,605,605,1,1,1,1,2,2,3,3,4,4,3,3,4,4],[true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2019-02-18","2019-02-18","2019-02-17","2019-02-17","2019-02-18","2019-02-18","2019-02-18","2019-02-18","2019-02-18","2019-02-18","2019-02-17","2019-02-17","2019-02-17","2019-02-17"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T02:43:36Z","2019-02-18T02:43:36Z","2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T02:43:36Z","2019-02-18T02:43:36Z","2019-02-18T02:43:36Z","2019-02-18T02:43:36Z"],[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
-->

## Joins

In section 'SQL Quick Start Simple Retrieval', there is a brief discussion of databases and 3NF.  One of the goals of normalization is to eliminate redundant data being kept in multiple tables and having each table contain a very granular level of detail.  If a record then needs to be updated, it is updated in one table instead of multiple tables improving overall system performance.  This also helps simplify and maintain referential integrity between tables.
 
Normalization breaks data down and JOINs denormalizes the data and builds it back up.  The tables are typically related via a primary key - foreign key relationship. The Postgres database enforces the primary and foreign key constraints in the DVD rental database.  

### Join Types

<!--html_preserve--><div id="htmlwidget-ed78248b32e6634f28e5" style="width:672px;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-ed78248b32e6634f28e5">{"x":{"diagram":"\ndigraph SQL_TYPES {\n\n  # a \"graph\" statement\n  graph [overlap = true, fontsize = 10]\n\n  node [shape = box,\n        fixedsize = false,\n        hegith = 1.5\n        width = 1.50]\n  0[label=\"0.  SQL Joins\"]\n  1[label=\"1.  Inner Join\nL.col1 {<,=,>} R.col2\"]\n  2[label=\"2.  Outer Join\nL.col1=tbl1.col2\"]\n  3[label=\"3.  Self Join\nL.col1=tbl1.col2\"]\n  4[label=\"4.  Cross Join\nL.col1=R.col2\"]\n  5[label=\"5.  Equi Join\nL.col1=R.col2\"] \n  6[label=\"6.  Natural Join\nL.col1=R.col1\"]\n  7[label=\"7.  Left Join\nL.col1=R.col1\"]\n  8[label=\"8.  Right Join\nL.col1=R.col1\"]\n  9[label=\"9.  Full Join\nL.col1=tbl2.col1\"]\n  # several \"edge\" statements\n  0 -> {1,2,3,4} [arrowhead=none]\n  1 -> 5 [arrowhead=none]\n  5 -> 6 [arrowhead=none]\n  2 -> {7,8,9} [arrowhead=none]\n  #3 -> {7,8,9}\n}\n","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The diagram above shows the hierarchy of the different types of joins.  In the boxes above:

*  The joins are based on a single column from the two tables, the left and right tables.  Joins can be based on multiple columns from both tables.
*  The `L.` and `R.` are aliases for the left and right table names.  
*  Often the joining columns have the same name as in the Natural Join, L.col1 = R.col1 
*  However, the joining column names can be different L.col1 = R.col2.  
*  All joins are based on equality between the table columns, L.col1 = R.col2, except the inner join which can use non-equality column conditions.  Non-equality column conditions are rare.  Equa Joins are subset of the Inner Join.


For this tutorial, we can think of joins as either an Inner/eqau Join or an Outer Join.

Instead of showing standard Venn diagrams showing the different JOINS, we use an analogy. For those interested though, the typical Venn diagrams can be found [here](http://www.sql-join.com/sql-join-types/).

### Valentines Party

Imagine you are at a large costume Valentine's Day dance party.  The hostess of the party, a data scientist, would like to learn more about the people attending her party.  When the band takes a break, she lets everyone know it is time for the judges to evaluate the winners for best costumes and associated prizes.

![ValentinesDay](screenshots/ValentinesDay.PNG)

She requests the following:

1.  All the couples at the party line up in front of her in a single line with the men on her left and the women on her right, (inner join)

2.  All the remaining men to form a second line two feet behind the married men, (left outer join, all couples + unattached men)

3.  All the remaining women to form a third line two feet in front of the married women, (right outer join, all couples + unattached women)

As our data scientist looks out, she can clearly see the three distinct lines, the single men, the man woman couples, and the single women, a full outer join.  

As the three judges start walking down the lines, she makes one more announcement.

4.  There is a special prize for the man and woman who can guess the average age of the members of the opposite sex. To give everyone a chance to come up with an average age, she asks the men to stay in line and the women to move down the men's line in order circling back around until they get back to their starting point in line, (Cartesian join, every man seen by every woman and vice versa).  

It is hard enough to tell someone's age when they don't have a mask, how do you get the average age when people have masks?

The hostess knows that there is usually some data anomalies.  As she looks out she sees a small cluster of people who did not line up.  Being the hostess with the mostest, she wants to get to know that small cluster better.  Since they are far off and in costume, she cannot tell if they are men or women.  More importantly, she does not know if they identify as a man or a woman, both -- (kind of a stretch for a self join), neither, or something else.  Ah, the inquisitive mind wants to know.

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

The dplyr join documentation describes two different types of joins, `mutating` and `filtering` joins.  For those coming to R with a SQL background, the mutating documentation is misleading in one respect.  Here is the inner_join documentation.

```
    inner_join()
    
    return all rows from x where there are matching values in y, and all columns from x and y. 
    If there are multiple matches between x and y, all combination of the matches are returned.
```

The misleading part is 'and all the columns from *x* and *y*.'  If the join column is `KEY`, SQL will return x.KEY and y.KEY.  Dplyr returns just KEY.  It appears that the KEY value comes from the driving table.  This is important if you are translating SQL to R because SQL developers will reference both columns x.KEY and y.KEY.  One needs to mutate the the y.KEY column.  This difference should become clear in the outer join examples.  

In the next couple of examples, we will use a small sample of the `customer` and `store` table data from the database to illustrate the diffent joins.  In the *_join verbs, the `by` and `suffix` parameters are included because it helps document the actual join and the source of join columns.

## Natural Join Delayed Time Bomb

The dplyr default join is a natural join, joining tables on common column names.  One of many links why one should not use natural joins can be found [here](http://gplivna.blogspot.com/2007/10/natural-joins-are-evil-motto-if-you.html).  If two tables are joined via a natural join on column `C1` the join continues to work as long as no additional common columns are added to either table.  If a new new column `C2` is added to one of the tables and `C2` already exists in the other table, BOOM, the delayed time bomb goes off.  The natural join still executes, doesn't throw any errors, but the returned result set may be smaller, much smaller, than before the new `C2` column was added.

### SQL Customer store_id Distribution

The next code block calculates the `store_id` distribution in the `customer` and `store` tables across all their rows.  The results will be used in following sections to validate different join result sets.


```r
store_distribution_sql <- dbGetQuery(con
          ,"select 'customer' tbl, store_id,count(*) count 
              from customer group by store_id
            union
            select 'store' tbl,store_id,count(*) count 
              from store group by store_id
            order by tbl,store_id;"
          )
sp_print_df(store_distribution_sql)
```

<!--html_preserve--><div id="htmlwidget-2ae622211a824c064fbd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-2ae622211a824c064fbd">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9"],["customer","customer","customer","customer","customer","customer","store","store","store"],[1,2,3,4,5,6,1,2,10],[326,274,2,2,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>tbl<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Sample Customer and Store Join Data

The following code block extracts sample customer and the store data.  The customer data is restricted to 10 rows to illustrate the different joins.  The 10 rows are used in the detail examples in order to perform a sanity check that the join is actually working.  Each detail example is followed by an aggregated summary across all rows of `customer` and `store` table.


```r
sample_customers <- dbGetQuery(con,"select customer_id,first_name,last_name,store_id
                                      from customer 
                                     where customer_id between 595 and 604")
stores <- dbGetQuery(con,"select * from store;")
sp_print_df(sample_customers)
```

<!--html_preserve--><div id="htmlwidget-09904734225327216f09" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-09904734225327216f09">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],[595,596,597,598,599,600,601,602,603,604],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky"],[1,1,1,1,2,3,2,4,5,6]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
sp_print_df(stores)
```

<!--html_preserve--><div id="htmlwidget-b619f31f38e9f2471fcc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b619f31f38e9f2471fcc">{"x":{"filter":"none","data":[["1","2","3"],[1,2,10],[1,2,10],[1,2,10],["2006-02-15T17:57:12Z","2006-02-15T17:57:12Z","2019-02-18T02:43:36Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
 

### dplyr store_id distribution Exercise

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

<!--html_preserve--><div id="htmlwidget-beeafef17c4840807f51" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-beeafef17c4840807f51">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["customer","customer","customer","customer","customer","customer"],[1,2,3,4,5,6],[326,274,2,2,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
sp_print_df(store_summary)
```

<!--html_preserve--><div id="htmlwidget-f6a2206cea77e899a1de" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f6a2206cea77e899a1de">{"x":{"filter":"none","data":[["1","2","3"],["store","store","store"],[1,2,10],[1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
## UNION the two summary tables and ARRANGE the output to match the SQL output from the previouse code block
```

## Join Templates

In this section we perform various joins using dplyr and SQL.  Each dplyr code block has three purposes.  

1.  Show working detail/summary data join examples.  
2.  The code blocks can be used as templates for beginning more complex dplyr pipes.
3.  The code blocks show the number of joins performed.

In these examples the 'customer' is always the left table and 'store' is always the right table. The join condition shown in the `by` parameter

    by = c('store_id'='store_id')

is on the common foreign - primary key column store_id. This is technically an equi-join condition which makes our joins 1-to-1 and keeps the result set small.  

```
In multi-column joins, each language_id would be replaced with a vector of column names used in the join by position.  Note the column names do not need to be identical by position.
```

The suffix parameter is a way to distinguish the same column name in the joined tables.  The suffixes are usually an single letter to represent the name of the table.  

## Inner Joins

### SQL Inner Join Details {example_inner-join-details-sql}

For an inner join between two tables, it doesn't matter which table is on the left, the first table, and which is on the right, the second table, because join conditions on both tables must be satisfied.  Reviewing the table below shows the inner join on our 10 sample customers and 3 store records returned only 6 rows.  The inner join detail shows only rows with matching store_id's.  



```r
customer_store_details_sij <- dbGetQuery(con,
"select 'ij' join_type,customer_id,first_name,last_name,c.store_id c_store_id
       ,s.store_id s_store_id,s.manager_staff_id, s.address_id
   from customer c join store s on c.store_id = s.store_id 
  where customer_id between 595 and 604;")
sp_print_df(customer_store_details_sij)
```

<!--html_preserve--><div id="htmlwidget-80fb537b5ba0bd90fb93" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-80fb537b5ba0bd90fb93">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["ij","ij","ij","ij","ij","ij"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Dplyr Inner Join Details {example_inner-join-details-dplyr}


```r
customer_ij <- customer_table %>%
  inner_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
    filter(customer_id >= 595 & customer_id <= 604 ) %>%
    select(customer_id,first_name,last_name,store_id 
       ,store_id,manager_staff_id, address_id) 
sp_print_df(customer_ij)
```

<!--html_preserve--><div id="htmlwidget-703a15d93cfc9aff608e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-703a15d93cfc9aff608e">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Compare the output from the SQL and Dplyr version.  The SQL output has a `c_store_id` and a `s_store_id` column and the Dplyr output only has `store_id`.  In this case, because it is an inner join, it doesn't matter because they will always the same.

### SQL Inner Join Summary {example_inner-join-summary-sql}

Note that both the store_id is available from both the customer and store tables, c.store_id,s.store_id, in the select clause.


```r
customer_store_summay_sij <- dbGetQuery(
  con,
  "select c.store_id c_store_id,s.store_id s_store_id,count(*) n
   from customer c join store s on c.store_id = s.store_id
  group by c.store_id,s.store_id;"
)

sp_print_df(customer_store_summay_sij)
```

<!--html_preserve--><div id="htmlwidget-6d936e3915a36e12cd53" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6d936e3915a36e12cd53">{"x":{"filter":"none","data":[["1","2"],[1,2],[1,2],[326,274]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Dplyr Inner Join Summary {example_inner-join-summary_dplyr}

In the previous SQL code block, `c.` and `s.` were used in the `inner join` as table aliases.  The `dplyr` suffix is similar to the SQL table alias. The role of the dplyr suffix and the SQL alias is to disambiguate duplicate table and column names referenced.    


```r
customer_store_summary_dij <- customer_table %>%
  inner_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
     mutate( join_type = "ij"
        ,c_store_id = if_else(is.na(customer_id),customer_id, store_id)         
        ,s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)) %>%
  group_by(join_type,c_store_id,s_store_id) %>%
  summarize(n = n())

sp_print_df(customer_store_summary_dij)
```

<!--html_preserve--><div id="htmlwidget-c195b56d57c26c8f1d4d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c195b56d57c26c8f1d4d">{"x":{"filter":"none","data":[["1","2"],["ij","ij"],[1,2],[1,2],[326,274]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Left Joins

### SQL Left Join Details {example_left-join-details-sql}

The SQL block below shows all 10 sample customer rows, the customer table is on the left and is the driving table, in the detail output which join to 2 of the 3 rows in the store table.  All the rows with customer store_id greater than 2 have null/blank store column values.  


```r
customer_store_details_sloj <- dbGetQuery(con,
"select 'loj' join_type,customer_id,first_name,last_name,c.store_id c_store_id
       ,s.store_id s_store_id,s.manager_staff_id, s.address_id
   from customer c left join store s on c.store_id = s.store_id 
  where customer_id between 595 and 604;")
sp_print_df(customer_store_details_sloj)
```

<!--html_preserve--><div id="htmlwidget-7a589913f405d7a14fbe" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-7a589913f405d7a14fbe">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],["loj","loj","loj","loj","loj","loj","loj","loj","loj","loj"],[595,596,597,598,599,600,601,602,603,604],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky"],[1,1,1,1,2,3,2,4,5,6],[1,1,1,1,2,null,2,null,null,null],[1,1,1,1,2,null,2,null,null,null],[1,1,1,1,2,null,2,null,null,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Dplyr Left Join Details {example_left-join-details-dplyr}

The next code block shows the left join details.  Note that the s_store_id column is derived via the mutate function, but not shown in the output below.  Without the s_store_id column, it might accidentally be assumed that the store.store_id = customer.store_id when the store.store_id values are actually NULL/NA based on the output without the s_store_id column.


```r
customer_store_detail_dloj <- customer_table %>%
  left_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
    filter(customer_id >= 595 & customer_id <= 604 ) %>%
      mutate(join_type = "loj"
             ,s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)
            ) %>%
    select(customer_id,first_name,last_name,store_id 
       ,manager_staff_id, address_id) 

sp_print_df(customer_store_detail_dloj)
```

<!--html_preserve--><div id="htmlwidget-a3fe20e2cfd2d5bbfba3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a3fe20e2cfd2d5bbfba3">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],[595,596,597,598,599,600,601,602,603,604],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky"],[1,1,1,1,2,3,2,4,5,6],[1,1,1,1,2,null,2,null,null,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The following code block includes the derived s_store_id value.  The output makes it explicit that the s_store_id value is missing.  The sp_print_df function is replaced with the print function to show the actual NA values.  




```r
customer_store_detail_dloj <- customer_table %>%
  left_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
    filter(customer_id >= 595 & customer_id <= 604 ) %>%
      mutate(join_type = "loj"
             ,s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)
            ) %>%
    rename(c_store_id = store_id) %>%
    select(customer_id,first_name,last_name,c_store_id 
       ,s_store_id,manager_staff_id, address_id) 

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
```

In the remaining examples, the `dplyr` code blocks will show both the customer and store store_id values with the either `c_` or `s_` store_id prefix .  The sp_print_df function returns the SQL NULL and R NA values as blanks.

### SQL Left Join Summary {example_left-join-summary-sql}

For a left outer join between two tables, it does matter which table is on the left and which is on the right, because every row in the left table is returned when there is no `where/filter` condition.  The second table returns row column values if the join condition exists or null collumn values if the join condition does not exist.  The left join is the most frequently used join type.

Note that SQL returns the store_id from both the customer and store tables, c.store_id,s.store_id, in the select clause.


```r
customer_store_summary_sloj <- dbGetQuery(
  con,
  "select c.store_id c_store_id,s.store_id s_store_id,count(*) loj
   from customer c left join store s on c.store_id = s.store_id
  group by c.store_id,s.store_id
  order by c.store_id;"
)

sp_print_df(customer_store_summary_sloj)
```

<!--html_preserve--><div id="htmlwidget-a98751c486bb4e6734fc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a98751c486bb4e6734fc">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,2,3,4,5,6],[1,2,null,null,null,null],[326,274,2,2,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>loj<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The lojs column returns the number of rows found on the store_id, from the customer table and the store table if on both tables, rows 1 - 2.  The right table, the store table returned blank/NA, when the key only exists in the customer table, rows 3 - 6.

1.  The left outer join always returns all rows from the left table, the driving/key table, if not reduced via a filter()/where clause.  
2.  All inner join rows can reference all columns/derived columns specified in the select clause from both the left and right tables.  
3.  All rows from the left table, the outer table, without a matching row on the right returns all the columns/derived column values specified in the select clause from the left, but the values from right table have all values of NA. 

### Dplyr Left Join Summary {example_left-join-summary-dplyr}

The dplyr outer join verbs do not return the non-driving table join values.  Compare the mutate verb s_store_id in the code block below with s.store_id in the equivalent SQL code block above.


```r
customer_store_summary_dloj <- customer_table %>%
  left_join(store_table, by = c("store_id", "store_id"), suffix(c(".c", ".s"))) %>%
  mutate(
    join_type = "loj"
   ,s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)
  ) %>%
  group_by(join_type, store_id, s_store_id) %>%
  summarize(n = n()) %>%
  rename(c_store_id = store_id) %>%
  select(join_type, c_store_id, s_store_id, n)

sp_print_df(customer_store_summary_dloj)
```

<!--html_preserve--><div id="htmlwidget-90472fc291eea3b37ad9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-90472fc291eea3b37ad9">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["loj","loj","loj","loj","loj","loj"],[1,2,3,4,5,6],[1,2,null,null,null,null],[326,274,2,2,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->




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
## 3 loj                3         NA     2
## 4 loj                4         NA     2
## 5 loj                5         NA     1
## 6 loj                6         NA     1
```

## Why Include one of the Inner Join Key columns?

It is not uncommon to have many many tables joined together as a series of left outer joins.  If the inner join key column is included in the output, one knows that the inner join condition was met or not.  If the key column is not shown and non-key columns are shown from the inner table, they may actually be null.  It is often the case that a long series of left outer joins just join on the key column to get one value out of the table to join to the next table in the series.  

One can think of the two components of an inner join as a transaction is either in an open state, no matching rows in the inner table or a closed state with one or more matching rows in the inner table.  Assume that we have a four DVD rental step process represented via table A, B, C, and D left outer joined together.  Summing the null and non-null keys together across all four tables gives a quick snap shot of the business in the four different steps.  We will review this concept in some detail in one of the future exercises.

## Right Joins

### SQL Right Join Details {example_right-join-details-sql}

The SQL block below shows only our sample customer rows, (customer_id between 595 and 604). The driving table is on the right, the `store` table.  Only six of the 10 sample customer rows appear which have store_id = {1, 2}.  All three `store` rows appear, row_id = {1,2,10}.  The right join is least frequently used join type.


```r
customer_store_detail_sroj <- dbGetQuery(con,
"select 'roj' join_type,customer_id,first_name,last_name,c.store_id c_store_id
       ,s.store_id s_store_id,s.manager_staff_id, s.address_id
   from customer c right join store s on c.store_id = s.store_id 
where coalesce(customer_id,595) between 595 and 604;")
sp_print_df(customer_store_detail_sroj)
```

<!--html_preserve--><div id="htmlwidget-6c084255227fcd56827e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6c084255227fcd56827e">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["roj","roj","roj","roj","roj","roj","roj"],[595,596,597,598,599,601,null],["Terrence","Enrique","Freddie","Wade","Austin","Sophie",null],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang",null],[1,1,1,1,2,2,null],[1,1,1,1,2,2,10],[1,1,1,1,2,2,10],[1,1,1,1,2,2,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Compare the SQL left join where clause

    where customer_id between 595 and 604;")
    
with the SQL right join where clause 

    where coalesce(customer_id,595) between 595 and 604;")
    
The `customer` table is the driving table in the left join and always returns all rows from the `customer` table on the left that match the join and satisfy the where clause.  The `store` table is the driving table in the right join and always returns all rows from the `store` table on the right that match the join and satisfy the where clause.  The right outer join condition shown always returns the `store.store_id=10` row.  Since the customer table does not have the corresponding row to join to, the right outer join return a customer row with all null column values.  The `coalesce` is a NULL if-then-else test.  If the customer_id is null, it returns 595 to prevent the store_id = 10 row from being dropped from the result set.

The right outer join clause can be rewritten as
```
     where customer_id between 595 and 604 or customer_id is null;
```

See the next dplyr code block to see the alternative where clause shown above.

### Dplyr Right Join Details {example_right-join-details-dplyr}


```r
customer_store_detail_droj <- customer_table %>%
  right_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
    filter((customer_id >= 595 & customer_id <= 604) | is.na(customer_id)) %>%
      mutate(join_type = "roj"
             ,c_store_id = if_else(is.na(customer_id), customer_id, store_id)
            ) %>%
    rename(s_store_id = store_id) %>%
    select(customer_id,first_name,last_name,s_store_id 
       ,c_store_id,manager_staff_id, address_id) 

sp_print_df(customer_store_detail_droj)
```

<!--html_preserve--><div id="htmlwidget-cc911bce9136bf4e7dfd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-cc911bce9136bf4e7dfd">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[595,596,597,598,599,601,null],["Terrence","Enrique","Freddie","Wade","Austin","Sophie",null],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang",null],[1,1,1,1,2,2,10],[1,1,1,1,2,2,null],[1,1,1,1,2,2,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>s_store_id<\/th>\n      <th>c_store_id<\/th>\n      <th>manager_staff_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### SQL Right Outer Join Summary {example_right-join-summary-sql}


```r
customer_store_summary_sroj <- dbGetQuery(
  con,
  "select 'roj' join_type,c.store_id c_store_id,s.store_id s_store_id,count(*) rojs
   from customer c right outer join store s on c.store_id = s.store_id
  group by c.store_id,s.store_id
order by s.store_id;"
)
sp_print_df(customer_store_summary_sroj)
```

<!--html_preserve--><div id="htmlwidget-6c3e37b0fa7ac693f7cc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6c3e37b0fa7ac693f7cc">{"x":{"filter":"none","data":[["1","2","3"],["roj","roj","roj"],[1,2,null],[1,2,10],[326,274,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>rojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The rojs column returns the number of rows found on the keys from the right table, `store`, and the left table, the `customer` table.    

1.  The right outer join always returns all rows from the right table, the driving/key table, if not reduced via a filter()/where clause.  
2.  All rows that inner join returns all the columns/derived columns specified in the select clause from both the left and right tables.  
3.  All rows from the right table, the outer table, without a matching row on the left returns all the columns/derived column values specified in the select clause from the right, but the values from left table have all values of NA.  This line 3, store.store_id = 10. 

### dplyr Right Join Summary {example_right-join-summary-dplyr}


```r
customer_store_summary_droj <- customer_table %>%
  right_join(store_table, by = c("store_id", "store_id"), suffix(c(".c", ".s")), all = store_table) %>%
  mutate(
    c_store_id = if_else(is.na(customer_id),customer_id, store_id)
    , join_type = "rojs"
  ) %>%
    group_by(join_type, store_id,c_store_id) %>%
    summarize(n = n()) %>% 
    rename(s_store_id = store_id) %>%
    select(join_type, s_store_id,c_store_id, n)

sp_print_df(customer_store_summary_droj)
```

<!--html_preserve--><div id="htmlwidget-88984347109043009685" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-88984347109043009685">{"x":{"filter":"none","data":[["1","2","3"],["rojs","rojs","rojs"],[1,2,10],[1,2,null],[326,274,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>s_store_id<\/th>\n      <th>c_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Full Join

### SQL Full Join Details {example_full-join-details-sql}

The full outer join is a conbination of the left and right outer joins and returns all matched and unmatched rows from the `ON` clause.  The matched rows return their table column values and the unmatched rows return NULL column values.  This can result in a very large result set.

The next SQL block implements a full outer join and returns 12 rows.  Change the `Show entries` from 10 to 25 to see all the entries.  


```r
customer_store_details_sfoj <- dbGetQuery(con,
  "select 'foj' join_type, c.customer_id,c.first_name,c.last_name,c.store_id c_store_id
          ,s.store_id s_store_id,s.manager_staff_id,s.address_id
     from customer c full outer join store s on c.store_id = s.store_id 
    where coalesce(c.customer_id,595) between 595 and 604;")
sp_print_df(customer_store_details_sfoj)
```

<!--html_preserve--><div id="htmlwidget-d80799441e19bf040cbf" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d80799441e19bf040cbf">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11"],["foj","foj","foj","foj","foj","foj","foj","foj","foj","foj","foj"],[595,596,597,598,599,600,601,602,603,604,null],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed",null],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky",null],[1,1,1,1,2,3,2,4,5,6,null],[1,1,1,1,2,null,2,null,null,null,10],[1,1,1,1,2,null,2,null,null,null,10],[1,1,1,1,2,null,2,null,null,null,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Dplyr Full Join Details {example_full-join-details-sql}


```r
customer_store_detail_dfoj <- customer_table %>%
  full_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
    filter((customer_id >= 595 & customer_id <= 604) | is.na(customer_id)) %>%
      mutate(join_type = "roj"
             ,c_store_id = if_else(is.na(customer_id), customer_id, store_id)
            ) %>%
    rename(s_store_id = store_id) %>%
    select(customer_id,first_name,last_name,s_store_id 
       ,c_store_id,manager_staff_id, address_id) 

sp_print_df(customer_store_detail_dfoj)
```

<!--html_preserve--><div id="htmlwidget-5bc260cc0681d28b4458" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5bc260cc0681d28b4458">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11"],[595,596,597,598,599,600,601,602,603,604,null],["Terrence","Enrique","Freddie","Wade","Austin","Sophie","Sophie","John","Ian","Ed",null],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang","Yang","Smith","Frantz","Borasky",null],[1,1,1,1,2,3,2,4,5,6,10],[1,1,1,1,2,3,2,4,5,6,null],[1,1,1,1,2,null,2,null,null,null,10]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>s_store_id<\/th>\n      <th>c_store_id<\/th>\n      <th>manager_staff_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### SQL Full Join Summary {example_full-join-summary-sql}

The result set below is ordered by the store.store_id.  


```r
customer_store_summary_sfoj <- dbGetQuery(
  con,
  "select 'foj' join_type,c.store_id c_store_id,s.store_id s_store_id,count(*) fojs
   from customer c full outer join store s on c.store_id = s.store_id
  group by c.store_id,s.store_id
order by s.store_id,c.store_id;"
)
sp_print_df(customer_store_summary_sfoj)
```

<!--html_preserve--><div id="htmlwidget-5e6debc8bc477449b2d2" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5e6debc8bc477449b2d2">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["foj","foj","foj","foj","foj","foj","foj"],[1,2,null,3,4,5,6],[1,2,10,null,null,null,null],[326,274,1,2,2,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Dplyr Full Join Summary {example_full-join-summary-dplyr}

The full outer join summary seven rows.  Store_id = {1,2} appear in both table tables.  Store_id = {3 - 6} appear only in the customer table which is on the left.  Store_id = 10 appears only in the `store` table which is on the right.


```r
customer_store_summary_dfoj <- customer_table %>%
  full_join(store_table, by = c("store_id", "store_id"), suffix(c(".c", ".s"))) %>%
  mutate(join_type = "fojs"
        ,c_store_id = if_else(is.na(customer_id),customer_id, store_id)         
        ,s_store_id = if_else(is.na(manager_staff_id), manager_staff_id, store_id)) %>%
  group_by(join_type,c_store_id, s_store_id) %>%
  summarize(n = n()) %>%
    arrange(s_store_id)

sp_print_df(customer_store_summary_dfoj)
```

<!--html_preserve--><div id="htmlwidget-a769f33e9bc2b11da24f" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a769f33e9bc2b11da24f">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["fojs","fojs","fojs","fojs","fojs","fojs","fojs"],[1,2,null,3,4,5,6],[1,2,10,null,null,null,null],[326,274,1,2,2,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Semi Join 

Below is the `dplyr` semi_join documentation.

```
semi_join()
return all rows from x where there are matching values in y, keeping just columns from x.

A semi join differs from an inner join because an inner join will return one row of x for each matching row of y, where a semi join will never duplicate rows of x.
```

The semi join always returns one and only one row from the x table that satisfies the inner join condition.  If we look at one key value on both x and y where the x table has 1 x.key row and y and n y.key rows, then the inner join returns n x.key rows, (1-to-n), and the semi-join returns just one x.key row, (1-to-1).

### SQL Semi Join Customer to Store {example_semi-join-sql-1}

SQL does not have an explicity 'semi join' key word.  The `semi join` reduces relationships from 1-to-n to 1-to-1.  SQL uses an EXISTS - subquery syntax to implement the `semi join`.

#### SQL EXISTS and Correlated SubQuery Syntax 

```
select * 
  FROM table1 l
 WHERE EXISTS(SELECT 1 FROM table2 r where l.c = r.c)
 
The EXISTS keyword checks if one or more rows satsify the SELECT clause enclosed in parenthesis, the correlated subquery.  The r.c column from table2, the inner/right table, is correlated to the l.c column from table1, the outer/left table. 
```

For all the table1 rows where the  EXISTS clause returns TRUE, the table1 rows are returned.   There is no way to reference table2 columns in the outer select, hence the semi join. 

All the previous joins were mutating joins, the joins resulted in a blending of columns from both tables.  A semi join only returns rows from a single table and is a filtering join. The mutating examples included a count column to show the 1-to-n relationships.  Filtering joins are 1-to-1 and the count column  is dropped in the following examples.


```r
customer_store_ssj <- dbGetQuery(con,
"select 'sj' join_type,customer_id,first_name,last_name,c.store_id c_store_id
   from customer c 
  where customer_id > 594 
    and exists( select 1 from store s where c.store_id = s.store_id);
;")
sp_print_df(customer_store_ssj)
```

<!--html_preserve--><div id="htmlwidget-5afb8971f37330fd8cc4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5afb8971f37330fd8cc4">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["sj","sj","sj","sj","sj","sj"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Note that this returned the six rows from the customer table that satisfied the c.store_id = s.store_id join condition.  It is the same as the SQL Inner Join example earlier, but without the store columns.  All the relationships are 1-to-1.

### Dplyr Semi Join Customer to Store {example_semi-join-dplyr-1}

The corresponding Dplyr version is shown in the next code block.


```r
customer_store_dsj <- customer_table %>% 
  semi_join(store_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
    filter(customer_id >= 595 & customer_id <= 604 ) %>%
    mutate(join_type = 'sj') %>%
    select(join_type,customer_id,first_name,last_name,store_id 
       ,store_id) 
sp_print_df(customer_store_dsj)
```

<!--html_preserve--><div id="htmlwidget-e9ae68682532316859d5" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-e9ae68682532316859d5">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["sj","sj","sj","sj","sj","sj"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### SQL Semi Join Store to Customer {example_semi-join-sql-2}

In the following Semi Join, the driving table is switched to the `store` table and our 10 sample customers as the right table.  


```r
store_customer_detail_ssj <- dbGetQuery(con,
"select 'sj' join_type,s.store_id s_store_id,s.manager_staff_id, s.address_id
   from store s
  where  EXISTS(select 1 
                 from customer c 
                where c.store_id = s.store_id 
                  and c.customer_id between 595 and 604
                )
;")
sp_print_df(store_customer_detail_ssj)
```

<!--html_preserve--><div id="htmlwidget-32dc6527565d6d2fa8eb" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-32dc6527565d6d2fa8eb">{"x":{"filter":"none","data":[["1","2"],["sj","sj"],[1,2],[1,2],[1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Here we see that we get the two rows from the store table that satisfy the s.store_id = c.store_id, store_id = {1,2}.  In this example the relationship between store and customer is 1-to-n, but we do not know that from the output.

### Dplyr Semi Join Store to Customer {example_semi-join-dplyr-2}

The corresponding Dplyr version is shown in the next code block.  Note that the filter condition on the customer table has been removed because the semi_join does not return any customer columns.


```r
store_customer_dsj <-  store_table %>%
  semi_join(customer_table, by = c("store_id" = "store_id"), suffix(c(".c", ".s"))) %>%
    mutate(join_type = 'sj') %>%
    select(join_type,store_id,manager_staff_id, address_id) 
sp_print_df(store_customer_dsj)
```

<!--html_preserve--><div id="htmlwidget-bbe1f43178625f07ed69" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-bbe1f43178625f07ed69">{"x":{"filter":"none","data":[["1","2"],["sj","sj"],[1,2],[1,2],[1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### SQL Semi Join Store to Customer Take 2 {example_semi-join-sql-3}

In the `Semi Join Customer to Store` examples, we saw four rows with store_id = 1 and two rows with store_id = 2.  The EXISTS key word is replaced with a count of the matching rows.  


```r
store_customer_detail_ssj2 <- dbGetQuery(con,
"select 'sj' join_type,s.store_id s_store_id,s.manager_staff_id, s.address_id
   from store s
  where (select count(*)
           from customer c 
          where c.store_id = s.store_id 
            and c.customer_id between 595 and 604
         ) in (2,4)
;")
sp_print_df(store_customer_detail_ssj2)
```

<!--html_preserve--><div id="htmlwidget-f44584fa5e4f08aaeb0b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f44584fa5e4f08aaeb0b">{"x":{"filter":"none","data":[["1","2"],["sj","sj"],[1,2],[1,2],[1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

To generalize the test above, replace `in {2,4}` with `> 0`.  

## Anti Joins

A `semi join` returns rows from one table that has one or more matching rows in the other table.  The `anti join` returns rows from one table that has no matching rows in the other table.    

#### dplyr anti Join {example_anti-join-dplyr}

The anti join is an outer join without the inner joined rows.  It only returns the rows from the driving table that do not have a matching row from the other table.  


```r
customer_store_aj <- customer_table %>% 
    filter(customer_id > 594) %>%
    anti_join(store_table, by = c("store_id", "store_id"), suffix(c(".c", ".s"))) %>%
    mutate(join_type = "anti_join")  

sp_print_df(customer_store_aj)
```

<!--html_preserve--><div id="htmlwidget-33be21b5fff197bb7cc4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-33be21b5fff197bb7cc4">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[600,602,603,604,605,606],[3,4,5,6,3,4],["Sophie","John","Ian","Ed","John","Ian"],["Yang","Smith","Frantz","Borasky","Smith","Frantz"],["sophie.yang@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org","ed.borasky@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org"],[1,2,3,4,3,4],[true,true,true,true,true,true],["2019-02-18","2019-02-18","2019-02-18","2019-02-18","2019-02-17","2019-02-17"],["2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T08:00:00Z","2019-02-18T02:43:36Z","2019-02-18T02:43:36Z"],[1,1,1,1,1,1],["anti_join","anti_join","anti_join","anti_join","anti_join","anti_join"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n      <th>join_type<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

All of the rows returned from the customer table have store_id = {3 - 6} which do not exist in the store_id.

#### SQL anti Join 1, NOT EXISTS and Correlated subquery {example_anti-join-sql-1}

SQL doesn't have an anti join key word.  Here are three different ways to achieve the same result.

This is the negation of the same construct used in the semi join discusion.  The anit-join tests for 0 matches instead of 1 or more matches for the semi-join.


```r
rs <- dbGetQuery(
  con,
  "select 'aj' join_type, customer_id, first_name, last_name, c.store_id
   from customer c 
  where not exists (select 1 from store s where s.store_id = c.store_id)
order by c.customer_id
"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-008e7554d5faa93bd1b9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-008e7554d5faa93bd1b9">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["aj","aj","aj","aj","aj","aj"],[600,602,603,604,605,606],["Sophie","John","Ian","Ed","John","Ian"],["Yang","Smith","Frantz","Borasky","Smith","Frantz"],[3,4,5,6,3,4]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### SQL anti Join 2, Left Outer Join where NULL on Right {example_anti-join-sql-1}


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

<!--html_preserve--><div id="htmlwidget-f943e07c4e65c2196ba8" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f943e07c4e65c2196ba8">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["aj","aj","aj","aj","aj","aj"],[600,602,603,604,605,606],["Sophie","John","Ian","Ed","John","Ian"],["Yang","Smith","Frantz","Borasky","Smith","Frantz"],[3,4,5,6,3,4]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>ajs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### SQL anti Join 3, ID in driving table and NOT IN lookup table {example_anti-join-sql-3}


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

<!--html_preserve--><div id="htmlwidget-4b34001b371daf31fcf2" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-4b34001b371daf31fcf2">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["aj","aj","aj","aj","aj","aj"],[600,602,603,604,605,606],["Sophie","John","Ian","Ed","John","Ian"],["Yang","Smith","Frantz","Borasky","Smith","Frantz"],[3,4,5,6,3,4]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>store_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


<!-- Show all different joins together with filter to allow comparison between different mutating joins


```r
customer_store_summary_dfoj %>%
    union(customer_store_summary_droj) %>%
    union(customer_store_summary_dloj) %>%
    union(customer_store_summary_dij) %>%
    arrange(join_type,s_store_id,c_store_id)
```


```r
sp_print_df(customer_store_summary_dfoj)
```

<!--html_preserve--><div id="htmlwidget-b1bdbba72aec9089045d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b1bdbba72aec9089045d">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["fojs","fojs","fojs","fojs","fojs","fojs","fojs"],[1,2,null,3,4,5,6],[1,2,10,null,null,null,null],[326,274,1,2,2,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


```r
customer_store_details_sij %>%
union(customer_store_details_sloj) %>%
union(customer_store_detail_sroj) %>%
union(customer_store_details_sfoj) %>%
arrange(join_type,s_store_id)
```

```r
sp_print_df(customer_store_details_sij)
```

<!--html_preserve--><div id="htmlwidget-af6ac1c69230c2179f6a" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-af6ac1c69230c2179f6a">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["ij","ij","ij","ij","ij","ij"],[595,596,597,598,599,601],["Terrence","Enrique","Freddie","Wade","Austin","Sophie"],["Gunderson","Forsythe","Duggan","Delvalle","Cintron","Yang"],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2],[1,1,1,1,2,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>c_store_id<\/th>\n      <th>s_store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

--->

## Non-Equa-Join Example

All the previous examples are equa-joins and is the most common type of join.  The next example is made up and shows a '<=' join.  The `store` table is usd.  Assume that the store_id actually represents some distance.  The example shows all distances <= to all other distances.   


```r
store_store_slej <- dbGetQuery(
  con,
  "select 'lej' join_type,s1.store_id starts,s2.store_id stops, s2.store_id - s1.store_id delta
   from store s1 join store s2 on s1.store_id <= s2.store_id
order by s1.store_id;"
)
sp_print_df(store_store_slej)
```

<!--html_preserve--><div id="htmlwidget-c6cef737dd6a83c62169" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c6cef737dd6a83c62169">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["lej","lej","lej","lej","lej","lej"],[1,1,1,2,2,10],[1,2,10,2,10,10],[0,1,9,0,8,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>starts<\/th>\n      <th>stops<\/th>\n      <th>delta<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Dplyr Non-equa Join {example_inner-join-dplyr}

Dplyr doesn't currently support a non-equa join.  In the by parameter, one can not change the '=' to '<=' as shown below.


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

The explaination below is from [here](https://stackoverflow.com/questions/47485779/dplyr-joins-how-do-you-do-a-non-standard-join-col1-col2-when-working-with) and it was posted Nov 25 '17.


In by = c("col1" = "col2"),  = is not and equality operator, but an assignment operator (the equality operator in R is ==). The expression inside c(...) creates a named character vector (name: col1 value: col2) that dplyr uses for the join. Nowhere do you define the kind of comparison that is made during the join, the comparison is hard-coded in dplyr. I don't think dplyr supports non-equi joins (yet).

Diconnect from the db:

```r
 dbDisconnect(con)

 sp_docker_stop("sql-pet")
```


```r
knitr::knit_exit()
```

