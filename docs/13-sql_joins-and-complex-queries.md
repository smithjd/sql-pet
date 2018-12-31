# Joins and complex queries (13)

> This chapter demonstrates how to:
> 
> * Use primary and foreign keys to retrieve specific rows of a table
> * do different kinds of join queries
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
## 83bbf73ee0e2        postgres-dvdrental   "docker-entrypoint.s…"   31 seconds ago      Exited (0) 2 seconds ago                       sql-pet
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
  seconds_to_test = 30
)
```

## Database Privileges

In the DVD rental database, you have all database privileges to perform any CRUD operaion, create, read, update, and delete on any database object.  As a data analyst, you typically only get select privilege which allows you to read only a subset of the tables in a database.  Occasionally, a proof of concept project may have a sandbox spun up where users are granted additional priviledges.

## Database constraints

As a data analyst, you really do not need to worry about database constraints since you are primarily writing dplyr/SQL queries to pull data out of the database. Constraints can be enforced at multiple levels: column, table, multiple tables, or at the schema itself.  The common database constraints are a column is `NOT NULL`, a column is `UNIQUE`, a column is a `PRIMARY KEY`, both `NOT NULL` and `UNIQUE`, or a column is a `FOREIGN KEY`, the `PRIMARY KEY` on another table.  Constraints restrict column values to a set of defined values and help enforce referential integrity between tables.

### DVD Rental Primary Foreign Key Constraints

For this tutorial, we are primarily concerned with primary and foreign key relationships between tables in order to correctly join the data between tables.  If one looks at all the tables in the DVD Rental ERD, add link here, the first column is the name of the table followed by "_id".  This is the primary key on the table.  In some of the tables, there are other columns that begin with the name of a different table, the foreign table, and end in "_id".  These are foreign keys and the foreign key value is the primary key value on the foreign table.  The DBA will index the primary and foreign key columns to speed up query performanace.

In the table below, all the primary foreign key relationships are shown because the DVD rental system is small.  Real world databases typically have hundreds or thousands of primary foreign key relationships.  In the search box, enter 'PRIMARY' or 'FOREIGN' to see the table primary key or the table's foreign key relationships.

<!--html_preserve--><div id="htmlwidget-1d9f9b9fdca3023baa83" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1d9f9b9fdca3023baa83">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35"],["actor","address","address","category","city","city","country","customer","customer","film","film","film_actor","film_actor","film_actor","film_actor","film_category","film_category","film_category","film_category","inventory","inventory","language","payment","payment","payment","payment","rental","rental","rental","rental","staff","staff","store","store","store"],["actor_id","address_id","city_id","category_id","city_id","country_id","country_id","customer_id","address_id","film_id","language_id","actor_id","actor_id","film_id","film_id","category_id","film_id","category_id","film_id","film_id","inventory_id","language_id","staff_id","customer_id","rental_id","payment_id","customer_id","rental_id","staff_id","inventory_id","staff_id","address_id","store_id","address_id","manager_staff_id"],["PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY"],["","","city","","","country","","","address","","language","actor","","","film","category","","","film","film","","","staff","customer","rental","","customer","","staff","inventory","","address","","address","staff"],["","","city_id","","","country_id","","","address_id","","language_id","actor_id","","","film_id","category_id","","","film_id","film_id","","","staff_id","customer_id","rental_id","","customer_id","","staff_id","inventory_id","","address_id","","address_id","staff_id"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>constraint_type<\/th>\n      <th>ref_table<\/th>\n      <th>ref_table_col<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Searching for 'FOREIGN' in the table above, one sees that the `column_name` matches the `ref_table_col`. This is pretty typical, but not always the case.  This can occur because of an inconsistent naming convention in the application design or a table contains multiple references to the same table foreign table and each reference indicates a different role.  A non-DVD rental example of the latter is a patient transaction record that has a referring doctor and and performing doctor. The two columns will have different names, but may refer to the same or different doctors in the doctor table.  In this case you may hear one say that the doctor table is performing two different roles.  


## Making up data for Join Examples

Each chapter in the book stands on its own.  If you have worked through the code blocks in this chapter in a previous session, you created some new customer records in order to work through material in the rest of the chapter. In the next couple of code blocks, we delete the new data and then recreate the data for the join examples in the next chapter.

### SQL Delete Data Syntax

```
    DELETE FROM <source> WHERE <where_clause>;
```

### Delete New Practice Customers from the Customer table.

In the next code block we delete out the new customers that were added when the book was compliled or added working through the exercises.  Out of the box, the DVD rental database's highest customer_id = 599.

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

### Delete New Practice Films from the Film table.

In the next code block we delete out the new films that were added when the book was compliled or added working through the exercises.  Out of the box, the DVD film database's highest film_id = 1000.


```r
dbExecute(
  con,
  "delete from film
   where film_id > 1000;
  "
)
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

The `column list` is the list of column names on the table and the corresponding list of values have to have the correct data type.  The following code block returns the `CUSTOMER` column names and data types.


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

<!--html_preserve--><div id="htmlwidget-b18b48ec4ad649442f3b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b18b48ec4ad649442f3b">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],["customer","customer","customer","customer","customer","customer","customer","customer","customer","customer"],["customer_id","store_id","first_name","last_name","email","address_id","activebool","create_date","last_update","active"],[1,2,3,4,5,6,7,8,9,10],["integer","smallint","character varying","character varying","character varying","smallint","boolean","date","timestamp without time zone","integer"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>ordinal_position<\/th>\n      <th>data_type<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":3},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

In the next code block, we insert Sophie as a new customer into the customer table via a SQL insert statement.  The columns list clause has three id columns, customer_id, store_id, and address_id.  The customer_id is a primary key column and the other two 'look like' foreign key columns.

For now, we are interested in getting some new customers into the customer table.  We look at the relations between the customer table and the store and address tables later in this chapter.



```r
dbExecute(
  con,
  "insert into customer 
  (customer_id,store_id,first_name,last_name,email,address_id,activebool
  ,create_date,last_update,active)
  values(600,3,'Sophie','Yang','sophie.yang@sakilacustomer.org',1,TRUE,now(),now()::date,1)
  "
)
```

```
## [1] 1
```

```r
new_customers <- dbGetQuery(con, "select * from customer where customer_id >= 600;")
sp_print_df(new_customers)
```

<!--html_preserve--><div id="htmlwidget-514d280a38cf86ead40b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-514d280a38cf86ead40b">{"x":{"filter":"none","data":[["1"],[600],[3],["Sophie"],["Yang"],["sophie.yang@sakilacustomer.org"],[1],[true],["2018-12-31"],["2018-12-31T08:00:00Z"],[1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Primary and Foreign Key Constraint Error Messages

For the new customers, we are concerned with not violating the PK and FK constraints.

If the customer_id = 600 value is changed to 599, the database throws the following error message.

```
Error in result_create(conn@ptr, statement) : Failed to fetch row: ERROR: duplicate key value violates unique constraint "customer_pkey" DETAIL: Key (customer_id)=(599) already exists.
```

If the address_id value = 1 is changed to 611, the database throws the following error message:

```
Error in result_create(conn@ptr, statement) : Failed to fetch row: ERROR: insert or update on table "customer" violates foreign key constraint "customer_address_id_fkey" DETAIL: Key (address_id)=(611) is not present in table "address".
```

### R Exercise: Inserting a Single Row via a Dataframe

In the following code block replace Sophie Yang with your name where appropriate.  
Note:

1.  The last data frame parameter sets the stringsAsFactors is `FALSE`.  Databases do not have a native `FACTOR` type.
2.  The dataframe column names must match the table column names. 
3.  The dbWriteTable function needs `append` = true to actually insert the new row.
4.  The dbWriteTable function has an option 'overwrite'.  It is set to FALSE  by default.  If it is set to TRUE, the table is first truncated.
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

new_customers <- dbGetQuery(con, "select * from customer where customer_id >= 600;")
sp_print_df(new_customers)
```

<!--html_preserve--><div id="htmlwidget-74434d812ec23342fdce" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-74434d812ec23342fdce">{"x":{"filter":"none","data":[["1","2"],[600,601],[3,2],["Sophie","Sophie"],["Yang","Yang"],["sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org"],[1,1],[true,true],["2018-12-31","2018-12-30"],["2018-12-31T08:00:00Z","2018-12-31T00:46:56Z"],[1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## SQL Multi-Row Insert Data Syntax

```
    INSERT INTO <target> <column_list> VALUES <values list1>, ... <values listn>;
    <target> : target table/view
    <column list> : csv list of columns
    <values list> : values assoicated with the column list.
```

Postgres and some other flavors of SQL allow multiple rows to be inserted at a time.  The syntax is identical to the Single Row syntax, but includes multiple `<values list>` clauses separated by commas.  The following code block illustrates the SQL multi-row insert.  Note that the customer_id column takes on sequential values to satisfy the PK constraint.


## SQL Multi-Row Insert Data Example


```r
#
dbExecute(
  con,
  "insert into customer 
  (customer_id,store_id,first_name,last_name,email,address_id,activebool
  ,create_date,last_update,active)
   values(602,1,'John','Smith','john.smith@sakilacustomer.org',2,TRUE
         ,now()::date,now()::date,1)
         ,(603,1,'Ian','Frantz','ian.frantz@sakilacustomer.org',3,TRUE
         ,now()::date,now()::date,1)
         ,(604,1,'Ed','Borasky','ed.borasky@sakilacustomer.org',4,TRUE
         ,now()::date,now()::date,1)
         ;"
)
```

```
## [1] 3
```

The Postgres R multi-row insert is similar to the single row insert.  The single column values are converted to a vector of values.

### R Exercise: Inserting Multiple Rows via a Dataframe

Replace the two first_name, last_name, and email column values with your own made up values.


```r
customer_id <- c(605, 606)
store_id <- c(3, 4)
first_name <- c("John", "Ian")
last_name <- c("Smith", "Frantz")
email <- c(
  "john.smith@sakilacustomer.org", "ian.frantz@sakilacustomer.org"
)
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

new_customers <- dbGetQuery(con, "select * from customer where customer_id >= 600;")
sp_print_df(new_customers)
```

<!--html_preserve--><div id="htmlwidget-8da54f9f5480ad7c3ec3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8da54f9f5480ad7c3ec3">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[600,601,602,603,604,605,606],[3,2,1,1,1,3,4],["Sophie","Sophie","John","Ian","Ed","John","Ian"],["Yang","Yang","Smith","Frantz","Borasky","Smith","Frantz"],["sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org","ed.borasky@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org"],[1,1,2,3,4,3,4],[true,true,true,true,true,true,true],["2018-12-31","2018-12-30","2018-12-31","2018-12-31","2018-12-31","2018-12-30","2018-12-30"],["2018-12-31T08:00:00Z","2018-12-31T00:46:56Z","2018-12-31T08:00:00Z","2018-12-31T08:00:00Z","2018-12-31T08:00:00Z","2018-12-31T00:46:56Z","2018-12-31T00:46:56Z"],[1,1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The `film` table has a primary key, film_id, and a foreign key column, language_id.  In the next code bloock we see five sample rows from the film table.


```r
films <- dbGetQuery(
  con,
  "select film_id,title, language_id
          from film 
        order by film_id
        limit 5
       ;"
)

sp_print_df(films)
```

<!--html_preserve--><div id="htmlwidget-124fb78127817ec02cd9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-124fb78127817ec02cd9">{"x":{"filter":"none","data":[["1","2","3","4","5"],[1,2,3,4,5],["Academy Dinosaur","Ace Goldfinger","Adaptation Holes","Affair Prejudice","African Egg"],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>language_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The next code block shows all the rows in the  language table.


```r
languages <- dbGetQuery(
  con,
  "select language_id, name, last_update from language
       ;"
)

sp_print_df(languages)
```

<!--html_preserve--><div id="htmlwidget-dd0a51033db44e820d90" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-dd0a51033db44e820d90">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,2,3,4,5,6],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              "],["2006-02-15T18:02:19Z","2006-02-15T18:02:19Z","2006-02-15T18:02:19Z","2006-02-15T18:02:19Z","2006-02-15T18:02:19Z","2006-02-15T18:02:19Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":1},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

One cannot insert/update a row into the `film` table with a language_id = 10 because of a constraint on the language_id column.  The language_id value must already exist in the `language` table, values 1 - 6, before the database will allow the new row to be inserted into the table.

## Messy Data

The data in the DVD rental system is too clean to show some of the issues one comes across in the real world.  In the following `xxxx` code blocks, we look at one row in the film table where the film_id = 1.  We first reinitialize language_id to 1 and display the row.  


```r
dbExecute(con, "update film set language_id = 1 where film_id = 1;")
```

```
## [1] 1
```

```r
dbGetQuery(con, "select '1. Update language_id = 1 successful' step
                        ,film_id, language_id
                   from film where film_id = 1;")
```

```
##                                   step film_id language_id
## 1 1. Update language_id = 1 successful       1           1
```

The following code block is an example of a SQL anonymous code block that gracefully handles the exception error when we try and update the row with language_id = 10.  Note that the language_id is still 1.  


```r
dbExecute(con, "
do $$
DECLARE v_id INTEGER;
begin
    v_id = 10;
    update film set language_id = v_id where film_id = 1;
exception
when foreign_key_violation then
    raise notice 'SQLERRM = %, language_id = %', SQLERRM, v_id;
when others then
    raise notice 'SQLERRM = % SQLSTATE =%', SQLERRM, SQLSTATE;
end;
$$ language 'plpgsql';")
```

```
## [1] 0
```

```r
dbGetQuery(con, "select '2. Update language_id = 10 failed' step
                        ,film_id, language_id
                   from film where film_id = 1;")
```

```
##                                step film_id language_id
## 1 2. Update language_id = 10 failed       1           1
```

### Messing up the row

The following code block 

1.  disables all the database constraints on the `film` table
2.  Updates the row with language_id = 10.
3.  Re-enabes the database constraints on the film table


```r
#
dbExecute(con, "ALTER TABLE film DISABLE TRIGGER ALL;")
```

```
## [1] 0
```

```r
count <- dbExecute(con, "update film set language_id = 10 where film_id = 1;")
```

While the `film` table constraints are disabled, we will insert a new film with a language_id = 10. 


```r
dbExecute(
  con,
  "insert into film
  (film_id,title,description,release_year,language_id
  ,rental_duration,rental_rate,length,replacement_cost,rating
   ,last_update,special_features,fulltext)
  values(1001,'Sophie''s Choice','orphaned language_id=10',2018,10
        ,7,4.99,120,14.99,'PG'
        ,now()::date,'{Trailers}','')
  ;
  "
)
```

```
## [1] 1
```

In the following code block we re-enable the `film` table constraints and confirm that the new record exists.

```r
dbExecute(con, "ALTER TABLE film ENABLE TRIGGER ALL;")
```

```
## [1] 0
```

```r
dbGetQuery(
  con,
  "select film_id,title,description,language_id from film where film_id = 1001;"
)
```

```
##   film_id           title             description language_id
## 1    1001 Sophie's Choice orphaned language_id=10          10
```

## Joins

In section 'SQL Quick Start Simple Retrieval', there is a brief discussion of databases and 3NF.  One of the goals of normalization is to eliminate redundant data being kept in multiple tables and having each table contain a very granular level of detail.  If a record then needs to be updated, it is updated in one table instead of multiple tables improving overall system performance.  This also helps simplify and maintain referential integerity between tables.

Bill Kent famously summarized 3NF as every non-key column "must provide a fact about the key,the whole key, and nothing but the key, so help me Codd." 

Normalization breaks data down and JOINs denormalizes the data and builds it back up.  The tables are typically related via a primary key - foreign key relationship. The Postgres database enforces the primary and foreign key constraints in the DVD rental database.  



### Join Types

![SQL_JOIN_TYPES](screenshots/SQL_JOIN_TYPES.PNG)

The above diagram can be found [here](https://way2tutorial.com/sql/sql_join_types_visual_venn_diagram.php)  There are additional graphics at the link, but the explanations are poorly worded and hard to follow.  

The diagram above shows nicely the hierarchy of different types of joins.  For this tutorial, we can think of joins as either an Inner Join or an Outer Join.

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

4.  There is a special prize for the man and woman who can guess the average age of the members of the opposite sex. To give everyone a chance to come up with an average age, she asks the men to stay in line and the women to move down the mens line in order circling back around until they get back to their starting point in line, (cartesian join, every man seen by every woman and vice versa).  

It is hard enough to tell someone's age when they don't have a mask, how do you get the average age when people have masks?

The hostess knows that there is usually some data anomolies.  As she looks out she sees a small cluster of people who did not line up.  Being the hostess with the mostest, she wants to get to know that small cluster better.  Since they are far off and in costume, she cannot tell if they are men or women.  More importantly, she does not know if they identify as a man or a woman, both -- (kind of a stretch for a self join), neither, or something else.  Ahh, the inquisitive mind wants to know.

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


### Join Tables

The dplyr join documentation describes two different types of joins, `mutating` and `filtering` joins.  For those coming to R with a SQL background, the mutating documentation is misleading in one respect.  Here is the inner_join documentation.

```
    inner_join()
    
    return all rows from x where there are matching values in y, and all columns from x and y. If there are multiple matches between x and y, all combination of the matches are returned.
```

The misleading part is that all the columns from *x* and *y*.  If the join column is `KEY`, SQL will return x.KEY and y.KEY.  Dplyr retuns KEY.  It appears that the KEY value comes from the driving table.  This difference should become clear in the outer join examples.

In the next couple of examples, we will pull all the language and `film` table data from the database into memory because the tables are small.  In the *_join verbs, the `by` and `suffix` parameters are included because it helps document the actual join and the source of join columns.

## Natural Join Delayed Time Bomb

The dplyr default join is a natural join, joining tables on common column names.  One of many links why one should not use natural joins can be found [here](http://gplivna.blogspot.com/2007/10/natural-joins-are-evil-motto-if-you.html).  If two tables are joined via a natural join on column `C1` the join continues to work as long as no additional common columns are added to either table.  If a new new column `C2` is added to one of the tables and `C2` already exists in the other table, BOOM, the delayed time bomb goes off.  The natural join still executes, doesn't throw any errors, but the returned result set may be smaller, much smaller, than before the new `C2` column was added.  
### SQL Language_id Distribution

The next code block calculates the `language_id` distribution in the `film` and `language` tables.  The results will be used in following sections to validate different join result sets.


```r
lang_distribution_sql <- dbGetQuery(con
          ,"select 'film' tbl,language_id,count(*) count 
              from film group by language_id
            union
            select 'language' tbl,language_id,count(*) count 
              from language group by language_id
            order by tbl,language_id;"
          )
sp_print_df(lang_distribution_sql)
```

<!--html_preserve--><div id="htmlwidget-1fe403c81784621152ab" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1fe403c81784621152ab">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8"],["film","film","language","language","language","language","language","language"],[1,10,1,2,3,4,5,6],[999,2,1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>tbl<\/th>\n      <th>language_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

 

### dplyr language distribution Exercise

Execute and Review the output from the code block below.  Union and arrange the output to match the SQL output in the previous code block.  


```r
language_table <- DBI::dbReadTable(con, "language")
film_table <- DBI::dbReadTable(con, "film")

language_summary <- language_table %>% 
  group_by(language_id) %>% 
  summarize(count=n()) %>% 
  mutate(table='language') %>% 
  select(table,language_id,count)

film_summary <- film_table %>% 
  group_by(language_id) %>% 
  summarize(count=n()) %>% 
  mutate(table='film') %>% 
  select(table,language_id,count)

sp_print_df(language_summary)
```

<!--html_preserve--><div id="htmlwidget-ed78248b32e6634f28e5" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-ed78248b32e6634f28e5">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["language","language","language","language","language","language"],[1,2,3,4,5,6],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table<\/th>\n      <th>language_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
sp_print_df(film_summary)
```

<!--html_preserve--><div id="htmlwidget-2ae622211a824c064fbd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-2ae622211a824c064fbd">{"x":{"filter":"none","data":[["1","2"],["film","film"],[1,10],[999,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table<\/th>\n      <th>language_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
## UNION the two summary tables and ARRANGE the output to match the SQL output from the previouse code block
```

## Join Templates

In this section we perform various joins using dplyr and SQL.  Each dplyr code block has three purposes.  

1.  Show a working join example.  
2.  The code blocks can be used as templates for beginning more complex dplyr pipes.
3.  The code blocks show the number of joins performed.

In these examples, the join condition, the `by` parameter, 

    by = c('language_id','language_id')

the two columns are the same.  

```
In multi-column joins, each language_id would be replaced with a vector of column names used in the join by position.  Note the column names do not need to be identical by position.
```

The suffix parameter is a way to distinguish the same column name in the joined tables.  The suffixes are usually an single letter to represent the name of the table.  


### dplyr Inner Join Template 

For an inner join between two tables, it doesn't matter which table is on the left, the first table, and which is on the right, the second table, because join conditions on both tables must be satisfied.


```r
languages_ij <- language_table %>%
  inner_join(film_table, by = c("language_id" = "language_id"), suffix(c(".l", ".f"))) %>%
  group_by(language_id, name) %>%
  summarize(inner_joins = n())

sp_print_df(languages_ij)
```

<!--html_preserve--><div id="htmlwidget-09904734225327216f09" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-09904734225327216f09">{"x":{"filter":"none","data":[["1"],[1],["English             "],[999]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>inner_joins<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### SQL Inner Join

The `dplyr` suffix is similar to the SQL table.  In the previous code block, `.l` and `.f` were used in the `inner_join` suffix parameter.  `l.` and `f.` are used as aliases in the SQL version below.  The role of the dplyr suffix and the SQL alias is to disambiguate duplicate table and column names referenced.  


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,count(*) n
   from language l join film f on l.language_id = f.language_id
  group by l.language_id,l.name;"
)

sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-b619f31f38e9f2471fcc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b619f31f38e9f2471fcc">{"x":{"filter":"none","data":[["1"],[1],["English             "],[999]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

The output tells us that there are 0 inner joins occurred between the language_table and the film_table.

### dplyr Left Outer Join Template

For a left outer join between two tables, it does matter which table is on the left, the first table, and which is on the right, the second table, because every row in the left table that satsifies the filter/where conditions are returned.  The second table returns rows if the join condition is met or returns a row of all null column values.


```r
languages_loj <- language_table %>%
  left_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f"))) %>%
  mutate(
    join_type =
      "loj", film_lang_id = if_else(is.na(film_id), film_id, language_id)
  ) %>%
  group_by(join_type, language_id, name, film_lang_id) %>%
  summarize(lojs = n()) %>%
  select(join_type, language_id, film_lang_id, name, lojs)
print(languages_loj)
```

```
## # A tibble: 6 x 5
## # Groups:   join_type, language_id, name [6]
##   join_type language_id film_lang_id name                    lojs
##   <chr>           <int>        <int> <chr>                  <int>
## 1 loj                 1            1 "English             "   999
## 2 loj                 2           NA "Italian             "     1
## 3 loj                 3           NA "Japanese            "     1
## 4 loj                 4           NA "Mandarin            "     1
## 5 loj                 5           NA "French              "     1
## 6 loj                 6           NA "German              "     1
```

```r
View(languages_loj)
sp_print_df(languages_loj)
```

<!--html_preserve--><div id="htmlwidget-beeafef17c4840807f51" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-beeafef17c4840807f51">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["loj","loj","loj","loj","loj","loj"],[1,2,3,4,5,6],[1,null,null,null,null,null],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[999,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>language_id<\/th>\n      <th>film_lang_id<\/th>\n      <th>name<\/th>\n      <th>lojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

Compare the mutate verb in the above code block with film_lang_id in the equivalent SQL code block below.

#### SQL Left Outer Join


```r
rs <- dbGetQuery(
  con,
  "select l.language_id
       ,f.language_id film_lang_id
       ,trim(l.name) as name
       ,count(*) lojs
   from language l left outer join film f 
        on l.language_id = f.language_id
  group by l.language_id,l.name,f.language_id
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-f6a2206cea77e899a1de" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f6a2206cea77e899a1de">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,2,3,4,5,6],[1,null,null,null,null,null],["English","Italian","Japanese","Mandarin","French","German"],[999,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>film_lang_id<\/th>\n      <th>name<\/th>\n      <th>lojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
# rs
```

The lojs column returns the number of rows found on the keys from the left table, language, and the right table, the film table.  For the "English" row, the language_id and film_lang_id match and 0 inner joins were performed.  For all the other languages, there was only 1 join and they all came from the left outer table, the language table, language_id's 2 - 6.  The right table, the film table returned NA, because no match was found.

1.  The left outer join always returns all rows from the left table, the driving/key table, if not reduced via a filter()/where clause.  
2.  All rows that inner join returns all the columns/derived columns specified in the select clause from both the left and right tables.  
3.  All rows from the left table, the outer table, without a matching row on the right returns all the columns/derived column values specified in the select clause from the left, but the values from right table have all values of NA. 

#### dplyr Right Outer Join


```r
languages_roj <- language_table %>%
  right_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f")), all = film_table) %>%
  mutate(
    lang_id =
      if_else(is.na(name), 0L, language_id), join_type = "rojs"
  ) %>%
  group_by(join_type, language_id, name, lang_id) %>%
  summarize(rojs = n()) %>%
  select(join_type, lang_id, language_id, name, rojs)

sp_print_df(languages_roj)
```

<!--html_preserve--><div id="htmlwidget-80fb537b5ba0bd90fb93" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-80fb537b5ba0bd90fb93">{"x":{"filter":"none","data":[["1","2"],["rojs","rojs"],[1,0],[1,10],["English             ",null],[999,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>lang_id<\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>rojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
languages_roj
```

```
## # A tibble: 2 x 5
## # Groups:   join_type, language_id, name [2]
##   join_type lang_id language_id name                    rojs
##   <chr>       <int>       <int> <chr>                  <int>
## 1 rojs            1           1 "English             "   999
## 2 rojs            0          10 <NA>                       2
```

Review the mutate above with l.language_id below.

#### SQL Right Outer Join


```r
rs <- dbGetQuery(
  con,
  "select 'roj' join_type,l.language_id,f.language_id language_id_f,l.name,count(*) rojs
   from language l right outer join film f on l.language_id = f.language_id
  group by l.language_id,l.name,f.language_id
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-703a15d93cfc9aff608e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-703a15d93cfc9aff608e">{"x":{"filter":"none","data":[["1","2"],["roj","roj"],[1,null],[1,10],["English             ",null],[999,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>language_id<\/th>\n      <th>language_id_f<\/th>\n      <th>name<\/th>\n      <th>rojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   join_type language_id language_id_f                 name rojs
## 1       roj           1             1 English               999
## 2       roj          NA            10                 <NA>    2
```

The rojs column returns the number of rows found on the keys from the right table, film, and the left table, the language table.  For the "English" row, the language_id and film_lang_id match and a 1000 inner joins were performed.  For language_id = 30 from the right table, there was only 1 join to a non-existant row in the language table on the left.  

1.  The right outer join always returns all rows from the right table, the driving/key table, if not reduced via a filter()/where clause.  
2.  All rows that inner join returns all the columns/derived columns specified in the select clause from both the left and right tables.  
3.  All rows from the right table, the outer table, without a matching row on the left returns all the columns/derived column values specified in the select clause from the right, but the values from left table have all values of NA. 

#### dplyr Full Outer Join


```r
languages_foj <- language_table %>%
  full_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f"))) %>%
  mutate(film_lang = if_else(is.na(film_id), paste0("No ", name, " films."), if_else(is.na(name), "Alien", name))) %>%
  group_by(language_id, name, film_lang) %>%
  summarize(n = n())

sp_print_df(languages_foj)
```

<!--html_preserve--><div id="htmlwidget-6d936e3915a36e12cd53" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6d936e3915a36e12cd53">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[1,2,3,4,5,6,10],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              ",null],["English             ","No Italian              films.","No Japanese             films.","No Mandarin             films.","No French               films.","No German               films.","Alien"],[999,1,1,1,1,1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>film_lang<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
languages_foj
```

```
## # A tibble: 7 x 4
## # Groups:   language_id, name [?]
##   language_id name                   film_lang                          n
##         <int> <chr>                  <chr>                          <int>
## 1           1 "English             " "English             "           999
## 2           2 "Italian             " No Italian              films.     1
## 3           3 "Japanese            " No Japanese             films.     1
## 4           4 "Mandarin            " No Mandarin             films.     1
## 5           5 "French              " No French               films.     1
## 6           6 "German              " No German               films.     1
## 7          10 <NA>                   Alien                              2
```

#### SQL full Outer Join


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,f.language_id language_id_f,count(*) fojs
   from language l full outer join film f on l.language_id = f.language_id
  group by l.language_id,l.name,f.language_id
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-c195b56d57c26c8f1d4d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c195b56d57c26c8f1d4d">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[1,2,3,4,5,6,null],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              ",null],[1,null,null,null,null,null,10],[999,1,1,1,1,1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>language_id_f<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name language_id_f fojs
## 1           1 English                          1  999
## 2           2 Italian                         NA    1
## 3           3 Japanese                        NA    1
## 4           4 Mandarin                        NA    1
## 5           5 French                          NA    1
## 6           6 German                          NA    1
## 7          NA                 <NA>            10    2
```

Looking at the SQL output, the full outer join is the combination of the left and right outer joins.  

1.  Language_id = 1 is the inner join.
2.  Language_id = 2 - 6 is the left outer join
3.  Language_id = 30 is the right outer join.

One can also just look at the language_id on the left and language_id_f on the right for a non NA value to see which side  is outer side/driving side of the join.

#### dplyr anti Join

The anti join is a left outer join without the inner joined rows.  It only returns the rows from the left table that do not have a match from the right table.


```r
languages_aj <- language_table %>%
  anti_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f"))) %>%
  mutate(type = "anti_join") %>%
  group_by(type, language_id, name) %>%
  summarize(anti_joins = n()) %>%
  select(type, language_id, name, anti_joins)
sp_print_df(languages_aj)
```

<!--html_preserve--><div id="htmlwidget-7a589913f405d7a14fbe" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-7a589913f405d7a14fbe">{"x":{"filter":"none","data":[["1","2","3","4","5"],["anti_join","anti_join","anti_join","anti_join","anti_join"],[2,3,4,5,6],["Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>type<\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>anti_joins<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
languages_aj
```

```
## # A tibble: 5 x 4
## # Groups:   type, language_id [5]
##   type      language_id name                   anti_joins
##   <chr>           <int> <chr>                       <int>
## 1 anti_join           2 "Italian             "          1
## 2 anti_join           3 "Japanese            "          1
## 3 anti_join           4 "Mandarin            "          1
## 4 anti_join           5 "French              "          1
## 5 anti_join           6 "German              "          1
```

#### SQL anti Join 1, Left Outer Join where NULL on Right

SQL doesn't have an anti join key word.  Here are three different ways to achieve the same result.


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,count(*) fojs
   from language l left outer join film f on l.language_id = f.language_id
  where f.language_id is null
  group by l.language_id,l.name
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-a3fe20e2cfd2d5bbfba3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a3fe20e2cfd2d5bbfba3">{"x":{"filter":"none","data":[["1","2","3","4","5"],[2,3,4,5,6],["Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name fojs
## 1           2 Italian                 1
## 2           3 Japanese                1
## 3           4 Mandarin                1
## 4           5 French                  1
## 5           6 German                  1
```

#### SQL anti Join 2, ID in driving table and NOT IN lookup table


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,count(*) fojs
   from language l 
  where l.language_id NOT IN (select language_id from film)
  group by l.language_id,l.name
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-a98751c486bb4e6734fc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a98751c486bb4e6734fc">{"x":{"filter":"none","data":[["1","2","3","4","5"],[2,3,4,5,6],["Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name fojs
## 1           2 Italian                 1
## 2           3 Japanese                1
## 3           4 Mandarin                1
## 4           5 French                  1
## 5           6 German                  1
```

#### SQL anti Join 3, NOT EXISTS and Correlated subquery


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,count(*) fojs
   from language l 
  where not exists (select language_id from film f where f.language_id = l.language_id)
 group by l.language_id,l.name
"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-90472fc291eea3b37ad9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-90472fc291eea3b37ad9">{"x":{"filter":"none","data":[["1","2","3","4","5"],[2,3,4,5,6],["Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name fojs
## 1           2 Italian                 1
## 2           3 Japanese                1
## 3           4 Mandarin                1
## 4           5 French                  1
## 5           6 German                  1
```

## SQL anti join Costs


```r
sql_aj1 <- dbGetQuery(
  con,
  "explain analyze select l.language_id,l.name,count(*) fojs
   from language l left outer join film f on l.language_id = f.language_id
  where f.language_id is null
  group by l.language_id,l.name
"
)

sql_aj2 <- dbGetQuery(
  con,
  "explain analyze select l.language_id,l.name,count(*) fojs
   from language l 
  where l.language_id NOT IN (select language_id from film)
  group by l.language_id,l.name
"
)

sql_aj3 <- dbGetQuery(
  con,
  "explain analyze select l.language_id,l.name,count(*) fojs
   from language l 
  where not exists (select language_id from film f where f.language_id = l.language_id)
 group by l.language_id,l.name
"
)
```

##### SQL Costs


```r
print(glue("sql_aj1 loj-null costs=", sql_aj1[1, 1]))
```

```
## sql_aj1 loj-null costs=GroupAggregate  (cost=24.24..24.30 rows=3 width=96) (actual time=0.371..0.476 rows=5 loops=1)
```

```r
print(glue("sql_aj2 not in costs=", sql_aj2[1, 1]))
```

```
## sql_aj2 not in costs=GroupAggregate  (cost=67.60..67.65 rows=3 width=96) (actual time=16.187..16.289 rows=5 loops=1)
```

```r
print(glue("sql_aj3 not exist costs=", sql_aj3[1, 1]))
```

```
## sql_aj3 not exist costs=GroupAggregate  (cost=24.24..24.30 rows=3 width=96) (actual time=0.413..0.523 rows=5 loops=1)
```

## dplyr Anti joins  

In this next section we look at two methods to implemnt an anti join in dplyr.


```r
customer_table <- tbl(con, "customer") # DBI::dbReadTable(con, "customer")
rental_table <- tbl(con, "rental") # DBI::dbReadTable(con, "rental")

# Method 1.  dplyr anti_join
daj1 <-
  anti_join(customer_table, rental_table, by = "customer_id", suffix = c(".c", ".r")) %>%
  select(c("first_name", "last_name", "email")) %>%
  explain()
```

```
## <SQL>
## SELECT "first_name", "last_name", "email"
## FROM (SELECT * FROM "customer" AS "TBL_LEFT"
## 
## WHERE NOT EXISTS (
##   SELECT 1 FROM "rental" AS "TBL_RIGHT"
##   WHERE ("TBL_LEFT"."customer_id" = "TBL_RIGHT"."customer_id")
## )) "cqpqwqagrn"
```

```
## 
```

```
## <PLAN>
## Hash Anti Join  (cost=510.99..552.63 rows=300 width=334)
##   Hash Cond: ("TBL_LEFT".customer_id = "TBL_RIGHT".customer_id)
##   ->  Seq Scan on customer "TBL_LEFT"  (cost=0.00..14.99 rows=599 width=338)
##   ->  Hash  (cost=310.44..310.44 rows=16044 width=2)
##         ->  Seq Scan on rental "TBL_RIGHT"  (cost=0.00..310.44 rows=16044 width=2)
```


```r
customer_table <- tbl(con, "customer") # DBI::dbReadTable(con, "customer")
rental_table <- tbl(con, "rental") # DBI::dbReadTable(con, "rental")

# Method 2.  dplyr loj with NA
daj2 <-
  left_join(customer_table, rental_table, by = c("customer_id", "customer_id"), suffix = c(".c", ".r")) %>%
  filter(is.na(rental_id)) %>%
  select(c("first_name", "last_name", "email")) %>%
  explain()
```

```
## <SQL>
## SELECT "first_name", "last_name", "email"
## FROM (SELECT "TBL_LEFT"."customer_id" AS "customer_id", "TBL_LEFT"."store_id" AS "store_id", "TBL_LEFT"."first_name" AS "first_name", "TBL_LEFT"."last_name" AS "last_name", "TBL_LEFT"."email" AS "email", "TBL_LEFT"."address_id" AS "address_id", "TBL_LEFT"."activebool" AS "activebool", "TBL_LEFT"."create_date" AS "create_date", "TBL_LEFT"."last_update" AS "last_update.c", "TBL_LEFT"."active" AS "active", "TBL_RIGHT"."rental_id" AS "rental_id", "TBL_RIGHT"."rental_date" AS "rental_date", "TBL_RIGHT"."inventory_id" AS "inventory_id", "TBL_RIGHT"."return_date" AS "return_date", "TBL_RIGHT"."staff_id" AS "staff_id", "TBL_RIGHT"."last_update" AS "last_update.r"
##   FROM "customer" AS "TBL_LEFT"
##   LEFT JOIN "rental" AS "TBL_RIGHT"
##   ON ("TBL_LEFT"."customer_id" = "TBL_RIGHT"."customer_id")
## ) "ihebfvnxvb"
## WHERE ((("rental_id") IS NULL))
```

```
## 
```

```
## <PLAN>
## Hash Right Join  (cost=22.48..375.33 rows=80 width=334)
##   Hash Cond: ("TBL_RIGHT".customer_id = "TBL_LEFT".customer_id)
##   Filter: ("TBL_RIGHT".rental_id IS NULL)
##   ->  Seq Scan on rental "TBL_RIGHT"  (cost=0.00..310.44 rows=16044 width=6)
##   ->  Hash  (cost=14.99..14.99 rows=599 width=338)
##         ->  Seq Scan on customer "TBL_LEFT"  (cost=0.00..14.99 rows=599 width=338)
```


### dplyr Costs

```
<PLAN>
Hash Anti Join  (cost=510.99..529.72 rows=1 width=45)
  Hash Cond: ("TBL_LEFT".customer_id = "TBL_RIGHT".customer_id)
  ->  Seq Scan on customer "TBL_LEFT"  (cost=0.00..14.99 rows=599 width=49)
  ->  Hash  (cost=310.44..310.44 rows=16044 width=2)
        ->  Seq Scan on rental "TBL_RIGHT"  (cost=0.00..310.44 rows=16044 width=2)
```

```
<PLAN>
Hash Right Join  (cost=22.48..375.33 rows=1 width=45)
  Hash Cond: ("TBL_RIGHT".customer_id = "TBL_LEFT".customer_id)
  Filter: ("TBL_RIGHT".rental_id IS NULL)
  ->  Seq Scan on rental "TBL_RIGHT"  (cost=0.00..310.44 rows=16044 width=6)
  ->  Hash  (cost=14.99..14.99 rows=599 width=49)
        ->  Seq Scan on customer "TBL_LEFT"  (cost=0.00..14.99 rows=599 width=49)
```

In this example, the dplyr anti_join verb is *1.4113447 to 22.7308719* times more expensive than the left outer join with a null condition.



```r
sql_aj1 <- dbGetQuery(
  con,
  "explain analyze select c.customer_id,count(*) lojs
   from customer c left outer join rental r on c.customer_id = r.customer_id
  where r.customer_id is null
  group by c.customer_id
order by c.customer_id;"
)
sp_print_df(sql_aj1)
```

<!--html_preserve--><div id="htmlwidget-6c084255227fcd56827e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6c084255227fcd56827e">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13"],["GroupAggregate  (cost=564.97..570.22 rows=300 width=12) (actual time=258.494..258.634 rows=7 loops=1)","  Group Key: c.customer_id","  -&gt;  Sort  (cost=564.97..565.72 rows=300 width=4) (actual time=258.462..258.516 rows=7 loops=1)","        Sort Key: c.customer_id","        Sort Method: quicksort  Memory: 25kB","        -&gt;  Hash Anti Join  (cost=510.99..552.63 rows=300 width=4) (actual time=258.245..258.396 rows=7 loops=1)","              Hash Cond: (c.customer_id = r.customer_id)","              -&gt;  Seq Scan on customer c  (cost=0.00..14.99 rows=599 width=4) (actual time=0.012..4.325 rows=606 loops=1)","              -&gt;  Hash  (cost=310.44..310.44 rows=16044 width=2) (actual time=249.436..249.443 rows=16044 loops=1)","                    Buckets: 16384  Batches: 1  Memory Usage: 661kB","                    -&gt;  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=2) (actual time=0.054..124.306 rows=16044 loops=1)","Planning time: 0.172 ms","Execution time: 258.821 ms"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>QUERY PLAN<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
sql_aj1
```

```
##                                                                                                                              QUERY PLAN
## 1                                 GroupAggregate  (cost=564.97..570.22 rows=300 width=12) (actual time=258.494..258.634 rows=7 loops=1)
## 2                                                                                                              Group Key: c.customer_id
## 3                                        ->  Sort  (cost=564.97..565.72 rows=300 width=4) (actual time=258.462..258.516 rows=7 loops=1)
## 4                                                                                                               Sort Key: c.customer_id
## 5                                                                                                  Sort Method: quicksort  Memory: 25kB
## 6                              ->  Hash Anti Join  (cost=510.99..552.63 rows=300 width=4) (actual time=258.245..258.396 rows=7 loops=1)
## 7                                                                                            Hash Cond: (c.customer_id = r.customer_id)
## 8                           ->  Seq Scan on customer c  (cost=0.00..14.99 rows=599 width=4) (actual time=0.012..4.325 rows=606 loops=1)
## 9                                  ->  Hash  (cost=310.44..310.44 rows=16044 width=2) (actual time=249.436..249.443 rows=16044 loops=1)
## 10                                                                                      Buckets: 16384  Batches: 1  Memory Usage: 661kB
## 11                     ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=2) (actual time=0.054..124.306 rows=16044 loops=1)
## 12                                                                                                              Planning time: 0.172 ms
## 13                                                                                                           Execution time: 258.821 ms
```

```r
sql_aj3 <- dbGetQuery(
  con,
  "explain analyze 
select c.customer_id,count(*) lojs
   from customer c 
  where not exists (select customer_id from rental r where c.customer_id = r.customer_id)
 group by c.customer_id
"
)

print(glue("sql_aj1 loj-null costs=", sql_aj1[1, 1]))
```

```
## sql_aj1 loj-null costs=GroupAggregate  (cost=564.97..570.22 rows=300 width=12) (actual time=258.494..258.634 rows=7 loops=1)
```

```r
print(glue("sql_aj3 not exist costs=", sql_aj3[1, 1]))
```

```
## sql_aj3 not exist costs=HashAggregate  (cost=554.13..557.13 rows=300 width=12) (actual time=244.779..244.837 rows=7 loops=1)
```

## Exercises

### Anti joins  -- Find customers who have never rented a movie, take 2.

This is a left outer join from customer to the rental table with an NA rental_id.

#### SQL Anti-Join


```r
rs <- dbGetQuery(
  con,
  "select c.first_name
                        ,c.last_name
                        ,c.email
                    from customer c
                         left outer join rental r
                              on c.customer_id = r.customer_id
                   where r.rental_id is null;
                 "
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-cc911bce9136bf4e7dfd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-cc911bce9136bf4e7dfd">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["Sophie","Ian","Sophie","Ian","John","Ed"],["Yang","Frantz","Yang","Frantz","Smith","Borasky"],["sophie.yang@sakilacustomer.org","ian.frantz@sakilacustomer.org","sophie.yang@sakilacustomer.org","ian.frantz@sakilacustomer.org","john.smith@sakilacustomer.org","ed.borasky@sakilacustomer.org"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<-- Add dplyr semi-join example -->



### SQL Rows Per Table 

In the examples above, we looked at how many rows were involved in each of the join examples and which side of the join they came from.  It is often helpful to know how many rows are in each table as a sanity check on the joins.  

Below is the SQL version to return all the row counts from each table in the DVD Rental System.


```r
rs <- dbGetQuery(
  con,
  "select *
                 from (      select 'actor' tbl_name,count(*) from actor 
                       union select 'category' tbl_name,count(*) from category
                       union select 'film' tbl_name,count(*) from film
                       union select 'film_actor' tbl_name,count(*) from film_actor
                       union select 'film_category' tbl_name,count(*) from film_category
                       union select 'language' tbl_name,count(*) from language
                       union select 'inventory' tbl_name,count(*) from inventory
                       union select 'rental' tbl_name,count(*) from rental
                       union select 'payment' tbl_name,count(*) from payment
                       union select 'staff' tbl_name,count(*) from staff
                       union select 'customer' tbl_name,count(*) from customer
                       union select 'address' tbl_name,count(*) from address
                       union select 'city' tbl_name,count(*) from city
                       union select 'country' tbl_name,count(*) from country
                       union select 'store' tbl_name,count(*) from store
                       ) counts
                  order by tbl_name
                 ;
                "
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-6c3e37b0fa7ac693f7cc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6c3e37b0fa7ac693f7cc">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["actor","address","category","city","country","customer"],[200,603,16,600,109,606]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>tbl_name<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##         tbl_name count
## 1          actor   200
## 2        address   603
## 3       category    16
## 4           city   600
## 5        country   109
## 6       customer   606
## 7           film  1001
## 8     film_actor  5462
## 9  film_category  1000
## 10     inventory  4581
## 11      language     6
## 12       payment 14596
## 13        rental 16044
## 14         staff     2
## 15         store     2
```

#### Exercise dplyr Rows Per Table 

In the code block below 

1.  Get the row counts for a couple more tables
2.  What is the structure of film_table object?



```r
film_table <- tbl(con, "film") # DBI::dbReadTable(con, "customer")
language_table <- tbl(con, "language") # DBI::dbReadTable(con, "rental")

film_rows <- film_table %>% mutate(name = "film") %>% group_by(name) %>% summarize(rows = n())
language_rows <- language_table %>%
  mutate(name = "language") %>%
  group_by(name) %>%
  summarize(rows = n())
rows_per_table <- rbind(as.data.frame(film_rows), as.data.frame(language_rows))
rows_per_table
```

```
##       name rows
## 1     film 1001
## 2 language    6
```

#### SQL film distribution based on language

The SQL below is very similar to the `SQL full Outer Join` above.  Instead of counting the joins, it counts the number films associated with each language.


```r
rs <- dbGetQuery(
  con,
  "select l.language_id id
                       ,l.name
                       ,sum(case when f.language_id is not null then 1 else 0 end) total
                   from language l
                        full outer join film f
                             on l.language_id = f.language_id
                  group by l.language_id,l.name 
                  order by l.name;
                 ;
                "
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-88984347109043009685" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-88984347109043009685">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,5,6,2,3,4],["English             ","French              ","German              ","Italian             ","Japanese            ","Mandarin            "],[999,0,0,0,0,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>name<\/th>\n      <th>total<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   id                 name total
## 1  1 English                999
## 2  5 French                   0
## 3  6 German                   0
## 4  2 Italian                  0
## 5  3 Japanese                 0
## 6  4 Mandarin                 0
## 7 NA                 <NA>     2
```

#### Exercise dplyr film distribution based on language

Below is the code block from the `dplyr Full Outer Join` section above.  Modify the code block to match the output from the SQL version.


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,f.language_id language_id_f,count(*) fojs
   from language l full outer join film f on l.language_id = f.language_id
  group by l.language_id,l.name,f.language_id
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-d80799441e19bf040cbf" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d80799441e19bf040cbf">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[1,2,3,4,5,6,null],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              ",null],[1,null,null,null,null,null,10],[999,1,1,1,1,1,2]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>language_id_f<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name language_id_f fojs
## 1           1 English                          1  999
## 2           2 Italian                         NA    1
## 3           3 Japanese                        NA    1
## 4           4 Mandarin                        NA    1
## 5           5 French                          NA    1
## 6           6 German                          NA    1
## 7          NA                 <NA>            10    2
```

## Store analysis

How are the stores performing.  

### SQL store revenue stream

How are the stores performing?  The SQL code shows the payments made to each store in the business.


```r
rs <- dbGetQuery(
  con,
  "select store_id,sum(p.amount) amt,count(*) cnt 
                   from payment p 
                        join staff s 
                          on p.staff_id = s.staff_id  
                 group by store_id order by 2 desc
                 ;
                "
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-5bc260cc0681d28b4458" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5bc260cc0681d28b4458">{"x":{"filter":"none","data":[["1","2"],[2,1],[31059.92,30252.12],[7304,7292]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>amt<\/th>\n      <th>cnt<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### Exercise dplyr store revenue stream

Complete the following code block to return the payments made to each store.


```r
payment_table <- tbl(con, "payment") # DBI::dbReadTable(con, "payment")
staff_table <- tbl(con, "staff") # DBI::dbReadTable(con, "staff")

store_revenue <- payment_table %>%
  inner_join(staff_table, by = "staff_id", suffix = c(".p", ".s")) %>%
  head()

store_revenue
```

```
## # Source:   lazy query [?? x 16]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   payment_id customer_id staff_id rental_id amount payment_date       
##        <int>       <int>    <int>     <int>  <dbl> <dttm>             
## 1      17503         341        2      1520   7.99 2007-02-15 22:25:46
## 2      17504         341        1      1778   1.99 2007-02-16 17:23:14
## 3      17505         341        1      1849   7.99 2007-02-16 22:41:45
## 4      17506         341        2      2829   2.99 2007-02-19 19:39:56
## 5      17507         341        2      3130   7.99 2007-02-20 17:31:48
## 6      17508         341        1      3382   5.99 2007-02-21 12:33:49
## # ... with 10 more variables: first_name <chr>, last_name <chr>,
## #   address_id <int>, email <chr>, store_id <int>, active <lgl>,
## #   username <chr>, password <chr>, last_update <dttm>, picture <blob>
```

<!-- answer
    # group_by(store_id) %>%
    # summarize (amt=sum(amount,na.rm=TRUE),n=n()) %>%
    # arrange (desc(amt))
-->    


### SQL:Estimate Outstanding Balance

The following SQL code calculates for each store

1.  the number of payments still open and closed from the DVD Rental Stores customer base.
2.  the total amount that their customers have paid
3.  the average price per/movie based off of the movies that have been paid.
4.  the estimated outstanding balance based off the open unpaid rentals * the average price per paid movie.


```r
rs <- dbGetQuery(
  con,
  "SELECT s.store_id store,sum(CASE WHEN payment_id IS NULL THEN 1 ELSE 0 END) open
    ,sum(CASE WHEN payment_id IS NOT NULL THEN 1 ELSE 0 END) paid
    ,sum(p.amount) paid_amt
    ,count(*) rentals
    ,round(sum(p.amount) / sum(CASE WHEN payment_id IS NOT NULL 
                                    THEN 1 
                                    ELSE 0 
                               END), 2) avg_price
    ,round(round(sum(p.amount) / sum(CASE WHEN payment_id IS NOT NULL 
                                          THEN 1 
                                          ELSE 0 
                                     END), 2) * sum(CASE WHEN payment_id IS NULL 
                                                         THEN 1 
                                                         ELSE 0 
                                                    END), 2) est_balance
FROM rental r
LEFT JOIN payment p
    ON r.rental_id = p.rental_id
JOIN staff s
    ON r.staff_id = s.staff_id
group by s.store_id;
"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-5e6debc8bc477449b2d2" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5e6debc8bc477449b2d2">{"x":{"filter":"none","data":[["1","2"],[1,2],[713,739],[7331,7265],[30498.71,30813.33],[8044,8004],[4.16,4.24],[2966.08,3133.36]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store<\/th>\n      <th>open<\/th>\n      <th>paid<\/th>\n      <th>paid_amt<\/th>\n      <th>rentals<\/th>\n      <th>avg_price<\/th>\n      <th>est_balance<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   store open paid paid_amt rentals avg_price est_balance
## 1     1  713 7331 30498.71    8044      4.16     2966.08
## 2     2  739 7265 30813.33    8004      4.24     3133.36
```

#### Exercise Dplyr Modify the following dplyr code to match the SQL output from above.


```r
payment_table <- tbl(con, "payment") # DBI::dbReadTable(con, "payment")
rental_table <- tbl(con, "rental") # DBI::dbReadTable(con, "rental")

est_bal <- rental_table %>%
  left_join(payment_table, by = c("rental_id", "rental_id"), suffix = c(".r", ".p")) %>%
  mutate(
    missing =
      ifelse(is.na(payment_id), 1, 0), found = ifelse(!is.na(payment_id), 1, 0)
  ) %>%
  summarize(
    open =
      sum(missing, na.rm = TRUE), paid =
      sum(found, na.rm = TRUE), paid_amt =
      sum(amount, na.rm = TRUE), rentals = n()
  ) %>%
  summarize(
    open =
      open, paid =
      paid, paid_amt =
      paid_amt, rentals =
      rentals, avg_price =
      paid_amt / paid, est_balance = paid_amt / paid * open
  )
est_bal
```

```
## # Source:   lazy query [?? x 6]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    open  paid paid_amt rentals         avg_price est_balance
##   <dbl> <dbl>    <dbl> <S3: integer64>     <dbl>       <dbl>
## 1  1452 14596   61312. 16048                4.20       6099.
```

### SQL actual outstanding balance

In the previous exercise, we estimated the outstanding amount.  After reviewing the rental table, the actual movie rental rate is in the table.  We use that to calculate the outstanding balance below.


```r
rs <- dbGetQuery(
  con,
  "SELECT sum(f.rental_rate) open_amt
    ,count(*) count
FROM rental r
LEFT JOIN payment p
    ON r.rental_id = p.rental_id
INNER JOIN inventory i
    ON r.inventory_id = i.inventory_id
INNER JOIN film f
    ON i.film_id = f.film_id
WHERE p.rental_id IS NULL
;"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-a769f33e9bc2b11da24f" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a769f33e9bc2b11da24f">{"x":{"filter":"none","data":[["1"],[4297.48],[1452]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   open_amt count
## 1  4297.48  1452
```


```r
payment_table <- tbl(con, "payment") # DBI::dbReadTable(con, "payment")
rental_table <- tbl(con, "rental") # DBI::dbReadTable(con, "rental")
inventory_table <- tbl(con, "inventory") # DBI::dbReadTable(con, "inventory")
film_table <- tbl(con, "film") # DBI::dbReadTable(con, "film")

act_bal <- rental_table %>%
  left_join(payment_table, by = c("rental_id", "rental_id"), suffix = c(".r", ".p")) %>%
  inner_join(inventory_table, by = c("inventory_id", "inventory_id"), suffix = c(".r", ".i")) %>%
  inner_join(film_table, by = c("film_id", "film_id"), suffix = c(".i", ".f")) %>%
  head()

act_bal
```

```
## # Source:   lazy query [?? x 27]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   rental_id rental_date         inventory_id customer_id.r
##       <int> <dttm>                     <int>         <int>
## 1         1 2005-05-24 22:53:30          367           130
## 2         2 2005-05-24 22:54:33         1525           459
## 3         3 2005-05-24 23:03:39         1711           408
## 4         4 2005-05-24 23:04:41         2452           333
## 5         5 2005-05-24 23:05:21         2079           222
## 6         6 2005-05-24 23:08:07         2792           549
## # ... with 23 more variables: return_date <dttm>, staff_id.r <int>,
## #   last_update.r <dttm>, payment_id <int>, customer_id.p <int>,
## #   staff_id.p <int>, amount <dbl>, payment_date <dttm>, film_id <int>,
## #   store_id <int>, last_update.i <dttm>, title <chr>, description <chr>,
## #   release_year <int>, language_id <int>, rental_duration <int>,
## #   rental_rate <dbl>, length <int>, replacement_cost <dbl>, rating <S3:
## #   pq_mpaa_rating>, last_update <dttm>, special_features <S3: pq__text>,
## #   fulltext <S3: pq_tsvector>
```

<!--
    filter(is.na(customer_id.p)) %>%
    summarize(open_amount=sum(rental_rate,na.rm = TRUE)
             ,open = n()
             )
-->             

### Rank customers with highest open amounts


```r
rs <- dbGetQuery(
  con,
  "select c.customer_id,c.first_name,c.last_name,sum(f.rental_rate) open_amt,count(*) count
                   from rental r 
                        left outer join payment p 
                          on r.rental_id = p.rental_id  
                        join inventory i
                          on r.inventory_id = i.inventory_id
                        join film f
                          on i.film_id = f.film_id
                        join customer c
                          on r.customer_id = c.customer_id
                  where p.rental_id is null
                  group by c.customer_id,c.first_name,c.last_name
                  order by open_amt desc
                  limit 25
                 ;"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-5afb8971f37330fd8cc4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5afb8971f37330fd8cc4">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[293,307,316,299,274,326],["Mae","Joseph","Steven","James","Naomi","Jose"],["Fletcher","Joy","Curley","Gannon","Jennings","Andrew"],[35.9,31.9,31.9,30.91,29.92,28.93],[10,10,10,9,8,7]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##    customer_id first_name   last_name open_amt count
## 1          293        Mae    Fletcher    35.90    10
## 2          307     Joseph         Joy    31.90    10
## 3          316     Steven      Curley    31.90    10
## 4          299      James      Gannon    30.91     9
## 5          274      Naomi    Jennings    29.92     8
## 6          326       Jose      Andrew    28.93     7
## 7          338     Dennis      Gilman    27.92     8
## 8          277       Olga     Jimenez    27.92     8
## 9          327      Larry    Thrasher    26.93     7
## 10         330      Scott     Shelley    26.93     7
## 11         322      Jason   Morrissey    26.91     9
## 12         340    Patrick      Newsom    25.92     8
## 13         336     Joshua        Mark    25.92     8
## 14         304      David       Royal    24.93     7
## 15         339     Walter    Perryman    23.94     6
## 16         239     Minnie      Romero    23.94     6
## 17         310     Daniel      Cabral    22.93     7
## 18         296     Ramona        Hale    22.93     7
## 19         313     Donald       Mahon    22.93     7
## 20         287      Becky       Miles    22.93     7
## 21         272        Kay    Caldwell    22.93     7
## 22         303    William Satterfield    22.93     7
## 23         329      Frank    Waggoner    22.91     9
## 24         311       Paul       Trout    21.92     8
## 25         109       Edna        West    20.93     7
```
### what film has been rented the most

```r
rs <- dbGetQuery(
  con,
  "SELECT i.film_id
    ,f.title
    ,rental_rate
    ,sum(rental_rate) revenue
    ,count(*) count --16044
FROM rental r
INNER JOIN inventory i
    ON r.inventory_id = i.inventory_id
INNER JOIN film f
    ON i.film_id = f.film_id
GROUP BY i.film_id
    ,f.title
    ,rental_rate
ORDER BY count DESC
LIMIT 25
;"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-e9ae68682532316859d5" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-e9ae68682532316859d5">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[103,738,489,730,767,331],["Bucket Brotherhood","Rocketeer Mother","Juggler Hardly","Ridgemont Submarine","Scalawag Duck","Forward Temple"],[4.99,0.99,0.99,0.99,4.99,2.99],[169.66,32.67,31.68,31.68,159.68,95.68],[34,33,32,32,32,32]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>revenue<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##    film_id               title rental_rate revenue count
## 1      103  Bucket Brotherhood        4.99  169.66    34
## 2      738    Rocketeer Mother        0.99   32.67    33
## 3      489      Juggler Hardly        0.99   31.68    32
## 4      730 Ridgemont Submarine        0.99   31.68    32
## 5      767       Scalawag Duck        4.99  159.68    32
## 6      331      Forward Temple        2.99   95.68    32
## 7      382      Grit Clockwork        0.99   31.68    32
## 8      735        Robbers Joon        2.99   92.69    31
## 9      973           Wife Turn        4.99  154.69    31
## 10     621        Network Peak        2.99   92.69    31
## 11    1000           Zorro Ark        4.99  154.69    31
## 12      31       Apache Divine        4.99  154.69    31
## 13     369   Goodfellas Salute        4.99  154.69    31
## 14     753     Rush Goodfellas        0.99   30.69    31
## 15     891      Timberland Sky        0.99   30.69    31
## 16     418        Hobbit Alien        0.99   30.69    31
## 17     127       Cat Coneheads        4.99  149.70    30
## 18     559          Married Go        2.99   89.70    30
## 19     374       Graffiti Love        0.99   29.70    30
## 20     748 Rugrats Shakespeare        0.99   29.70    30
## 21     239        Dogma Family        4.99  149.70    30
## 22     285    English Bulworth        0.99   29.70    30
## 23     109  Butterfly Chocolat        0.99   29.70    30
## 24     450     Idols Snatchers        2.99   89.70    30
## 25     609       Muscle Bright        2.99   89.70    30
```

### what film has been generated the most revenue assuming all amounts are collected

```r
rs <- dbGetQuery(
  con,
  "select i.film_id,f.title,rental_rate
                       ,sum(rental_rate) revenue,count(*) count  --16044
                   from rental r 
                        join inventory i
                          on r.inventory_id = i.inventory_id
                        join film f
                          on i.film_id = f.film_id
                 group by i.film_id,f.title,rental_rate
                 order by revenue desc
                 ;"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-32dc6527565d6d2fa8eb" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-32dc6527565d6d2fa8eb">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[103,767,973,31,369,1000],["Bucket Brotherhood","Scalawag Duck","Wife Turn","Apache Divine","Goodfellas Salute","Zorro Ark"],[4.99,4.99,4.99,4.99,4.99,4.99],[169.66,159.68,154.69,154.69,154.69,154.69],[34,32,31,31,31,31]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>revenue<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### which films are in one store but not the other.

```r
rs <- dbGetQuery(
  con,
  "select coalesce(i1.film_id,i2.film_id) film_id
                       ,f.title,f.rental_rate,i1.store_id,i1.count,i2.store_id,i2.count
                   from     (select film_id,store_id,count(*) count 
                               from inventory where store_id = 1 
                             group by film_id,store_id) as i1
                         full outer join 
                            (select film_id,store_id,count(*) count
                               from inventory where store_id = 2 
                             group by film_id,store_id
                            ) as i2
                           on i1.film_id = i2.film_id 
                         join film f 
                           on coalesce(i1.film_id,i2.film_id) = f.film_id
                  where i1.film_id is null or i2.film_id is null 
                 order by f.title  ;
               "
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-bbe1f43178625f07ed69" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-bbe1f43178625f07ed69">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[2,3,5,8,13,20],["Ace Goldfinger","Adaptation Holes","African Egg","Airport Pollock","Ali Forever","Amelie Hellfighters"],[4.99,2.99,2.99,4.99,4.99,4.99],[null,null,null,null,null,1],[null,null,null,null,null,3],[2,2,2,2,2,null],[3,4,3,4,4,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n      <th>store_id..6<\/th>\n      <th>count..7<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Compute the outstanding balance.

```r
rs <- dbGetQuery(
  con,
  "select sum(f.rental_rate) open_amt,count(*) count
                   from rental r 
                        left outer join payment p 
                          on r.rental_id = p.rental_id  
                        join inventory i
                          on r.inventory_id = i.inventory_id
                        join film f
                          on i.film_id = f.film_id
                  where p.rental_id is null
                 ;"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-f44584fa5e4f08aaeb0b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f44584fa5e4f08aaeb0b">{"x":{"filter":"none","data":[["1"],[4297.48],[1452]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
### Which Stores Have Movies That Have Never Rented?


```r
not_rented <- dbGetQuery(con,
          "select i.store_id,f.film_id,f.title,f.description,i.last_update
             from inventory i left outer join rental r 
                      on i.inventory_id = r.inventory_id
                  join film f
                      on i.film_id = f.film_id
            where r.inventory_id is null 
          ")

sp_print_df(not_rented)
```

<!--html_preserve--><div id="htmlwidget-33be21b5fff197bb7cc4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-33be21b5fff197bb7cc4">{"x":{"filter":"none","data":[["1"],[2],[1],["Academy Dinosaur"],["A Epic Drama of a Feminist And a Mad Scientist who must Battle a Teacher in The Canadian Rockies"],["2006-02-15T18:09:17Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>description<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
View(dbGetQuery(con,"select min(last_update) mn, max(last_update) mx from inventory;"))

View(dbGetQuery(con,"select rental_date,count(*) 
                       from rental
                     group by rental_date
                     order by rental_date;"))
```

## Different strategies for interacting with the database


select examples
    dbGetQuery returns the entire result set as a data frame.  
        For large returned datasets, complex or inefficient SQL statements, this may take a 
        long time.

      dbSendQuery: parses, compiles, creates the optimized execution plan.  
          dbFetch: Execute optimzed execution plan and return the dataset.
    dbClearResult: remove pending query results from the database to your R environment

### Use dbGetQuery

How many customers are there in the DVD Rental System

```r
rs1 <- dbGetQuery(con, "select * from customer;")
sp_print_df(head(rs1))
```

<!--html_preserve--><div id="htmlwidget-008e7554d5faa93bd1b9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-008e7554d5faa93bd1b9">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[524,1,2,3,4,5],[1,1,1,1,2,1],["Jared","Mary","Patricia","Linda","Barbara","Elizabeth"],["Ely","Smith","Johnson","Williams","Jones","Brown"],["jared.ely@sakilacustomer.org","mary.smith@sakilacustomer.org","patricia.johnson@sakilacustomer.org","linda.williams@sakilacustomer.org","barbara.jones@sakilacustomer.org","elizabeth.brown@sakilacustomer.org"],[530,5,6,7,8,9],[true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
pco <- dbSendQuery(con, "select * from customer;")
rs2 <- dbFetch(pco)
dbClearResult(pco)
sp_print_df(head(rs2))
```

<!--html_preserve--><div id="htmlwidget-f943e07c4e65c2196ba8" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f943e07c4e65c2196ba8">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[524,1,2,3,4,5],[1,1,1,1,2,1],["Jared","Mary","Patricia","Linda","Barbara","Elizabeth"],["Ely","Smith","Johnson","Williams","Jones","Brown"],["jared.ely@sakilacustomer.org","mary.smith@sakilacustomer.org","patricia.johnson@sakilacustomer.org","linda.williams@sakilacustomer.org","barbara.jones@sakilacustomer.org","elizabeth.brown@sakilacustomer.org"],[530,5,6,7,8,9],[true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Use dbExecute


### Anti join -- Find Sophie who has never rented a movie.


```r
customer_table <- DBI::dbReadTable(con, "customer")
rental_table <- DBI::dbReadTable(con, "rental")

customer_tbl <- dplyr::tbl(con, "customer")
rental_tbl <- dplyr::tbl(con, "rental")

dplyr_tbl_loj <-
  left_join(customer_tbl, rental_tbl, by = "customer_id", suffix = c(".c", ".r")) %>%
  filter(is.na(rental_id)) %>%
  select(c("first_name", "last_name", "email")) %>%
  collect()

rs <- dbGetQuery(
  con,
  "select c.first_name
                        ,c.last_name
                        ,c.email
                    from customer c
                         left outer join rental r
                              on c.customer_id = r.customer_id
                   where r.rental_id is null;
                 "
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-4b34001b371daf31fcf2" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-4b34001b371daf31fcf2">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["Sophie","Ian","Sophie","Ian","John","Ed"],["Yang","Frantz","Yang","Frantz","Smith","Borasky"],["sophie.yang@sakilacustomer.org","ian.frantz@sakilacustomer.org","sophie.yang@sakilacustomer.org","ian.frantz@sakilacustomer.org","john.smith@sakilacustomer.org","ed.borasky@sakilacustomer.org"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
sp_print_df(dplyr_tbl_loj)
```

<!--html_preserve--><div id="htmlwidget-b1bdbba72aec9089045d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b1bdbba72aec9089045d">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],["Sophie","Ian","Sophie","Ian","John","Ed","John"],["Yang","Frantz","Yang","Frantz","Smith","Borasky","Smith"],["sophie.yang@sakilacustomer.org","ian.frantz@sakilacustomer.org","sophie.yang@sakilacustomer.org","ian.frantz@sakilacustomer.org","john.smith@sakilacustomer.org","ed.borasky@sakilacustomer.org","john.smith@sakilacustomer.org"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<!--html_preserve--><div id="htmlwidget-af6ac1c69230c2179f6a" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-af6ac1c69230c2179f6a">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35"],["actor","address","address","category","city","city","country","customer","customer","film","film","film_actor","film_actor","film_actor","film_actor","film_category","film_category","film_category","film_category","inventory","inventory","language","payment","payment","payment","payment","rental","rental","rental","rental","staff","staff","store","store","store"],["actor_id","address_id","city_id","category_id","city_id","country_id","country_id","customer_id","address_id","film_id","language_id","actor_id","actor_id","film_id","film_id","category_id","film_id","category_id","film_id","film_id","inventory_id","language_id","staff_id","customer_id","rental_id","payment_id","customer_id","rental_id","staff_id","inventory_id","staff_id","address_id","store_id","address_id","manager_staff_id"],["actor_pkey","address_pkey","fk_address_city","category_pkey","city_pkey","fk_city","country_pkey","customer_pkey","customer_address_id_fkey","film_pkey","film_language_id_fkey","film_actor_actor_id_fkey","film_actor_pkey","film_actor_pkey","film_actor_film_id_fkey","film_category_category_id_fkey","film_category_pkey","film_category_pkey","film_category_film_id_fkey","inventory_film_id_fkey","inventory_pkey","language_pkey","payment_staff_id_fkey","payment_customer_id_fkey","payment_rental_id_fkey","payment_pkey","rental_customer_id_fkey","rental_pkey","rental_staff_id_key","rental_inventory_id_fkey","staff_pkey","staff_address_id_fkey","store_pkey","store_address_id_fkey","store_manager_staff_id_fkey"],["PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","PRIMARY KEY","FOREIGN KEY","FOREIGN KEY"],["","","city","","","country","","","address","","language","actor","","","film","category","","","film","film","","","staff","customer","rental","","customer","","staff","inventory","","address","","address","staff"],["","","city_id","","","country_id","","","address_id","","language_id","actor_id","","","film_id","category_id","","","film_id","film_id","","","staff_id","customer_id","rental_id","","customer_id","","staff_id","inventory_id","","address_id","","address_id","staff_id"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>constraint_name<\/th>\n      <th>constraint_type<\/th>\n      <th>ref_table<\/th>\n      <th>ref_table_col<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve--><!--html_preserve--><div id="htmlwidget-c6cef737dd6a83c62169" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c6cef737dd6a83c62169">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"],["actor","address","category","city","country","customer","film","film_actor","film_category","inventory","language","payment","rental","staff","store"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<!--html_preserve--><div id="htmlwidget-a9e8581aee330d6d5646" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a9e8581aee330d6d5646">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18"],["address","city","customer","film","film_actor","film_actor","film_category","film_category","inventory","payment","payment","payment","rental","rental","rental","staff","store","store"],["city_id","country_id","address_id","language_id","actor_id","film_id","category_id","film_id","film_id","staff_id","customer_id","rental_id","customer_id","staff_id","inventory_id","address_id","address_id","manager_staff_id"],["fk_address_city","fk_city","customer_address_id_fkey","film_language_id_fkey","film_actor_actor_id_fkey","film_actor_film_id_fkey","film_category_category_id_fkey","film_category_film_id_fkey","inventory_film_id_fkey","payment_staff_id_fkey","payment_customer_id_fkey","payment_rental_id_fkey","rental_customer_id_fkey","rental_staff_id_key","rental_inventory_id_fkey","staff_address_id_fkey","store_address_id_fkey","store_manager_staff_id_fkey"],["FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY","FOREIGN KEY"],["city","country","address","language","actor","film","category","film","film","staff","customer","rental","customer","staff","inventory","address","address","staff"],["city_id","country_id","address_id","language_id","actor_id","film_id","category_id","film_id","film_id","staff_id","customer_id","rental_id","customer_id","staff_id","inventory_id","address_id","address_id","staff_id"],[2,4,6,7,8,8,9,9,10,12,12,12,13,13,13,14,15,15],["table","table","table","table","table","table","table","table","table","table","table","table","table","table","table","table","table","table"],["rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle"],[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],[0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5],[18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18],[4,5,2,11,1,7,3,7,7,14,6,13,6,14,10,2,2,14],["table","table","table","table","table","table","table","table","table","table","table","table","table","table","table","table","table","table"],["rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle"],[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],[0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5],[18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>constraint_name<\/th>\n      <th>constraint_type<\/th>\n      <th>ref_table<\/th>\n      <th>ref_table_col<\/th>\n      <th>src_tbl_id<\/th>\n      <th>type.x<\/th>\n      <th>shape.x<\/th>\n      <th>width.x<\/th>\n      <th>height.x<\/th>\n      <th>fontsize.x<\/th>\n      <th>fk_tbl_id<\/th>\n      <th>type.y<\/th>\n      <th>shape.y<\/th>\n      <th>width.y<\/th>\n      <th>height.y<\/th>\n      <th>fontsize.y<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[7,10,11,12,13,16,17,18]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve--><!--html_preserve--><div id="htmlwidget-a9c870ee45a861efbc97" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a9c870ee45a861efbc97">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17"],["actor","address","category","city","country","customer","film","film_actor","film_actor","film_category","film_category","inventory","language","payment","rental","staff","store"],["actor_id","address_id","category_id","city_id","country_id","customer_id","film_id","actor_id","film_id","film_id","category_id","inventory_id","language_id","payment_id","rental_id","staff_id","store_id"],["actor_pkey","address_pkey","category_pkey","city_pkey","country_pkey","customer_pkey","film_pkey","film_actor_pkey","film_actor_pkey","film_category_pkey","film_category_pkey","inventory_pkey","language_pkey","payment_pkey","rental_pkey","staff_pkey","store_pkey"],["PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY","PRIMARY KEY"],["","","","","","","","","","","","","","","","",""],["","","","","","","","","","","","","","","","",""],[1,2,3,4,5,6,7,8,8,9,9,10,11,12,13,14,15],["table","table","table","table","table","table","table","table","table","table","table","table","table","table","table","table","table"],["rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle","rectangle"],[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],[0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5],[18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18],[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>column_name<\/th>\n      <th>constraint_name<\/th>\n      <th>constraint_type<\/th>\n      <th>ref_table<\/th>\n      <th>ref_table_col<\/th>\n      <th>src_tbl_id<\/th>\n      <th>type.x<\/th>\n      <th>shape.x<\/th>\n      <th>width.x<\/th>\n      <th>height.x<\/th>\n      <th>fontsize.x<\/th>\n      <th>fk_tbl_id<\/th>\n      <th>type.y<\/th>\n      <th>shape.y<\/th>\n      <th>width.y<\/th>\n      <th>height.y<\/th>\n      <th>fontsize.y<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[7,10,11,12,13,16,17,18]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<!--html_preserve--><div id="htmlwidget-d0e1be80fd8ee1a19c08" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d0e1be80fd8ee1a19c08">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18"],[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18],[2,4,6,7,8,8,9,9,10,12,12,12,13,13,13,14,15,15],[4,5,2,11,1,7,3,7,7,14,6,13,6,14,10,2,2,14],["fk","fk","fk","fk","fk","fk","fk","fk","fk","fk","fk","fk","fk","fk","fk","fk","fk","fk"],["fk_address_city","fk_city","customer_address_id_fkey","film_language_id_fkey","film_actor_actor_id_fkey","film_actor_film_id_fkey","film_category_category_id_fkey","film_category_film_id_fkey","inventory_film_id_fkey","payment_staff_id_fkey","payment_customer_id_fkey","payment_rental_id_fkey","rental_customer_id_fkey","rental_staff_id_key","rental_inventory_id_fkey","staff_address_id_fkey","store_address_id_fkey","store_manager_staff_id_fkey"],[15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>from<\/th>\n      <th>to<\/th>\n      <th>rel<\/th>\n      <th>label<\/th>\n      <th>fontsize<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<!--html_preserve--><div id="htmlwidget-41c6fff5c0ae3f9b920c" style="width:672px;height:3000px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-41c6fff5c0ae3f9b920c">{"x":{"diagram":"digraph {\n\ngraph [layout = \"neato\",\n       outputorder = \"edgesfirst\",\n       bgcolor = \"white\"]\n\nnode [fontname = \"Helvetica\",\n      fontsize = \"10\",\n      shape = \"circle\",\n      fixedsize = \"true\",\n      width = \"0.5\",\n      style = \"filled\",\n      fillcolor = \"aliceblue\",\n      color = \"gray70\",\n      fontcolor = \"gray50\"]\n\nedge [fontname = \"Helvetica\",\n     fontsize = \"8\",\n     len = \"1.5\",\n     color = \"gray80\",\n     arrowsize = \"0.5\"]\n\n  \"1\" [label = \"actor\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"2\" [label = \"address\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"3\" [label = \"category\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"4\" [label = \"city\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"5\" [label = \"country\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"6\" [label = \"customer\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"7\" [label = \"film\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"8\" [label = \"film_actor\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"9\" [label = \"film_category\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"10\" [label = \"inventory\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"11\" [label = \"language\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"12\" [label = \"payment\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"13\" [label = \"rental\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"14\" [label = \"staff\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"15\" [label = \"store\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n\"2\"->\"4\" [label = \"fk_address_city\", fontsize = \"15\"] \n\"4\"->\"5\" [label = \"fk_city\", fontsize = \"15\"] \n\"6\"->\"2\" [label = \"customer_address_id_fkey\", fontsize = \"15\"] \n\"7\"->\"11\" [label = \"film_language_id_fkey\", fontsize = \"15\"] \n\"8\"->\"1\" [label = \"film_actor_actor_id_fkey\", fontsize = \"15\"] \n\"8\"->\"7\" [label = \"film_actor_film_id_fkey\", fontsize = \"15\"] \n\"9\"->\"3\" [label = \"film_category_category_id_fkey\", fontsize = \"15\"] \n\"9\"->\"7\" [label = \"film_category_film_id_fkey\", fontsize = \"15\"] \n\"10\"->\"7\" [label = \"inventory_film_id_fkey\", fontsize = \"15\"] \n\"12\"->\"14\" [label = \"payment_staff_id_fkey\", fontsize = \"15\"] \n\"12\"->\"6\" [label = \"payment_customer_id_fkey\", fontsize = \"15\"] \n\"12\"->\"13\" [label = \"payment_rental_id_fkey\", fontsize = \"15\"] \n\"13\"->\"6\" [label = \"rental_customer_id_fkey\", fontsize = \"15\"] \n\"13\"->\"14\" [label = \"rental_staff_id_key\", fontsize = \"15\"] \n\"13\"->\"10\" [label = \"rental_inventory_id_fkey\", fontsize = \"15\"] \n\"14\"->\"2\" [label = \"staff_address_id_fkey\", fontsize = \"15\"] \n\"15\"->\"2\" [label = \"store_address_id_fkey\", fontsize = \"15\"] \n\"15\"->\"14\" [label = \"store_manager_staff_id_fkey\", fontsize = \"15\"] \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


```r
# diconnect from the db
dbDisconnect(con)

sp_docker_stop("sql-pet")
```


```r
knitr::knit_exit()
```









