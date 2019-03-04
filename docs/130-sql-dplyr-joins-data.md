# SQL & dplyr joins additional data {#chapter_sql-dplyr-data}

> This chapter demonstrates how to:
> 
> * Use primary and foreign keys to retrieve specific rows of a table
> * do different kinds of join queries
> * Exercises
> * Query the database to get basic information about each dvdrental story
> * How to interact with the database using different strategies

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
## 5bda842389fb        postgres-dvdrental   "docker-entrypoint.s…"   36 seconds ago      Exited (0) 2 seconds ago                       sql-pet
```

Start up the `docker-pet` container


```r
sp_docker_start("sql-pet")
```

Now connect to the database with R. Need to wait for Docker & Postgres to come up before connecting.


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

### Delete New Practice Store from the Store Table.

In the next code block we delete out the new stores that were added when the book was compliled or added working through the exercises.  Out of the box, the DVD rental database's highest store_id = 2.


```r
dbExecute(con, "delete from store where store_id > 2;")
```

```
## [1] 1
```

### Delete film 1001, Sophie's Choice, records in film_category, rental, inventory, and film

The records need to be deleted in a specific order to not violate constraints.


```r
dbExecute(con, "delete from film_category where film_id >= 1001;")
```

```
## [1] 0
```

```r
dbExecute(con, "delete from rental where rental_id >= 16050;")
```

```
## [1] 0
```

```r
dbExecute(con, "delete from inventory where film_id >= 1001;")
```

```
## [1] 0
```

```r
dbExecute(con, "delete from film where film_id >= 1001;")
```

```
## [1] 0
```

### Delete New Practice Customers from the Customer table.

In the next code block we delete out the new customers that were added when the book was compliled or added while working through the chapter.  Out of the box, the DVD rental database's highest customer_id = 599.


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
## [1] 7
```

The number above tells us how many rows were actually deleted from the customer table.

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
<script type="application/json" data-for="htmlwidget-dd0a51033db44e820d90">{"x":{"filter":"none","data":[["1","2","3"],[1,2,10],[1,2,10],[1,2,10],["2006-02-15T17:57:12Z","2006-02-15T17:57:12Z","2019-03-04T17:11:07Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>manager_staff_id<\/th>\n      <th>address_id<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->



## Create a film record


```r
dbExecute(
  con,
  "insert into film
  (film_id,title,description,release_year,language_id
  ,rental_duration,rental_rate,length,replacement_cost,rating
   ,last_update,special_features,fulltext)
  values(1001,'Sophie''s Choice','orphaned language_id=10',2018,1
        ,7,4.99,120,14.99,'PG'
        ,now()::date,'{Trailers}','')
        ,(1002,'Sophie''s Choice','orphaned language_id=10',2018,1
        ,7,4.99,120,14.99,'PG'
        ,now()::date,'{Trailers}','')
  ;
  ")
```

```
## [1] 2
```


```r
dbExecute(
  con,
  "insert into film_category
  (film_id,category_id,last_update)
  values(1001,6,now()::date)
       ,(1001,7,now()::date)
       ,(1002,6,now()::date)
       ,(1002,7,now()::date)
  ;")  
```

```
## [1] 4
```


```r
dbExecute(
  con,
  "insert into inventory
  (inventory_id,film_id,store_id,last_update)
  values(4582,1001,1,now()::date)
       ,(4583,1001,2,now()::date)
  ;")  
```

```
## [1] 2
```


```r
dbExecute(
  con,
  "insert into rental
  (rental_id,rental_date,inventory_id,customer_id,return_date,staff_id,last_update)
  values(16050,now()::date - interval '1 week',4582,600,now()::date,1,now()::date)
  ;")  
```

```
## [1] 1
```

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
<script type="application/json" data-for="htmlwidget-1fe403c81784621152ab">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24"],[595,595,596,596,597,597,598,598,599,599,600,600,601,601,602,602,603,603,604,604,605,605,606,606],[1,1,1,1,1,1,1,1,2,2,3,3,2,2,4,4,5,5,6,6,3,3,4,4],["Terrence","Terrence","Enrique","Enrique","Freddie","Freddie","Wade","Wade","Austin","Austin","Sophie","Sophie","Sophie","Sophie","John","John","Ian","Ian","Ed","Ed","John","John","Ian","Ian"],["Gunderson","Gunderson","Forsythe","Forsythe","Duggan","Duggan","Delvalle","Delvalle","Cintron","Cintron","Yang","Yang","Yang","Yang","Smith","Smith","Frantz","Frantz","Borasky","Borasky","Smith","Smith","Frantz","Frantz"],["terrence.gunderson@sakilacustomer.org","terrence.gunderson@sakilacustomer.org","enrique.forsythe@sakilacustomer.org","enrique.forsythe@sakilacustomer.org","freddie.duggan@sakilacustomer.org","freddie.duggan@sakilacustomer.org","wade.delvalle@sakilacustomer.org","wade.delvalle@sakilacustomer.org","austin.cintron@sakilacustomer.org","austin.cintron@sakilacustomer.org","sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org","john.smith@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org","ian.frantz@sakilacustomer.org","ed.borasky@sakilacustomer.org","ed.borasky@sakilacustomer.org","john.smith@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org","ian.frantz@sakilacustomer.org"],[601,601,602,602,603,603,604,604,605,605,1,1,1,1,2,2,3,3,4,4,3,3,4,4],[true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04","2019-03-04"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2019-03-04T08:00:00Z","2019-03-04T08:00:00Z","2019-03-04T17:11:07Z","2019-03-04T17:11:07Z","2019-03-04T08:00:00Z","2019-03-04T08:00:00Z","2019-03-04T08:00:00Z","2019-03-04T08:00:00Z","2019-03-04T08:00:00Z","2019-03-04T08:00:00Z","2019-03-04T17:11:07Z","2019-03-04T17:11:07Z","2019-03-04T17:11:07Z","2019-03-04T17:11:07Z"],[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
-->

Diconnect from the db:

```r
 dbDisconnect(con)

 sp_docker_stop("sql-pet")
```


```r
knitr::knit_exit()
```

