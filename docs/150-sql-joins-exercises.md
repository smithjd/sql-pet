# SQL Metadata exercises 
<!-- 
When vendors implement such changes, their QA team performs rigorous testing before releasing the new functionality to their client base.  Their clients' IT departments also test the new functionality in their own DEV/QA environments before promoting the new functionality into their production environments.

Sometimes the vendors application doesn't quite address a customers need or a new need arises say a new government regulation.  

*  Many database vendor applictions recognize that they cannot address of all their custommers requirements and build in special user defined columns.  The business can activate a column and use it to address some business need not designed into the application.

*  Sometimes business users will a column that doesn't make sense for their business and use it anyway to address a one time business need.  

3.  The business re-purposes a column in a table and the column definition changes.  Again there is a break in the meaning of the new columns between the existing records and new records.
-->

> This chapter demonstrates:
> 
> * Finding table column metadata for any specific table
> * Finding the primary and foreign keys for any specific table
> * Reusing SQL via parameterization 
> * Why understanding the contents of a database requires a team approach.





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
## CONTAINER ID        IMAGE                COMMAND                  CREATED              STATUS                     PORTS               NAMES
## 6f13a331bfbf        postgres-dvdrental   "docker-entrypoint.s…"   About a minute ago   Exited (0) 2 seconds ago                       sql-pet
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

## Table Structures

### Customer Columns

In an earlier chapter we used functions dbListTable and dbListFields from the DBI package to get a list of tables and the fields in a table.  Below we list out the columns from the customer table.


```r
dbListFields(con, "customer")
```

```
##  [1] "customer_id" "store_id"    "first_name"  "last_name"   "email"      
##  [6] "address_id"  "activebool"  "create_date" "last_update" "active"
```

A couple of things immediately jump out based on the column names:

1.  There are three *_id columns, customer_id, store_id, and address_id.  ID columns are typically an integer type.  It is common convention to have the table primary key column(s) at the beginning of the table or a set of columns at the beginning of the table that make the row unique.

  *  Just looking at the column names, one cannot tell if the customer is uniquely identified by just the customer_id or the customer_id + store_id.  Are there customers who visit both stores?
  
2.  Based on the column names, it looks like there are three string/character columns, first_name, last_name, and email.  

*  What are the sizes of these colums?

3.  There are two dates, create_date and last_update.
4.  There are two active columns, `activebool` and `active`.  The activebool looks like it is a boolean column.  What type of column is active, integer or text?

Databases maintains a data dictionary of metadata on all the database objects.  SQL databases have two useful tables for getting table and table column information, `information_schema.tables` and `information_schema.columns`.

AS an example, the following code block returns a summary of the number of tables and views in the differnt schemas.  The tables and views associated with DVD Rentals are in the public table_schema.  



The metadata of the tables and views in the public `table_schema` are contained in the `information_schema`.  The `information_schema` provides information about all of the tables, views, columns, and procedures in the entire database, not just DVD Rentals.  We are interested in the `tables` and `columns` views.


```r
info_schema <- dbGetQuery(con
         ,"Select t.table_catalog
                 ,t.table_schema
                 ,t.table_name
                 ,t.table_type
             from information_schema.tables t
            where t.table_schema = 'information_schema'
              and table_name in ('tables','columns')
          ")

sp_print_df(info_schema)
```

<!--html_preserve--><div id="htmlwidget-6d34d29cfc4ef4b3889c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6d34d29cfc4ef4b3889c">{"x":{"filter":"none","data":[["1","2"],["dvdrental","dvdrental"],["information_schema","information_schema"],["columns","tables"],["VIEW","VIEW"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_catalog<\/th>\n      <th>table_schema<\/th>\n      <th>table_name<\/th>\n      <th>table_type<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Table Column Metadata

The next code block uses the `information_schema.columns` to return column information from any table in the Dvdrental database.

*  This code block is an example of a parameterized R function, sp_tbl_descr, sql pet table description.
*  Sp_tbl_descr uses the `dvdrental.information_schema.columns` table to return some of the metadata on a dvdrental table.
*  The function is restricted to the dvdrenatal database, see the where clause `and c.table_catalog = 'dvdrental'`.  
*  The function has one parameter passed it, table_name.  Parameter substitution occurs in the where clause, `and c.table_name = $1`.  The paramter substituion variable syntax depends on the vendor.
*  The dbGetQuery documentation shows

```
con <- dbConnect(RSQLite::SQLite(), ":memory:")
dbGetQuery(con, "SELECT COUNT(*) FROM mtcars WHERE cyl = ?", param = list(1:8))
```

### sp_tbl_descr -- Parameterized Table Description Function


```r
sp_tbl_descr <- function (table_name) {
dbGetQuery(
       con,
       "select btrim(c.table_name) table_name, c.ordinal_position seq
             , c.column_name COL_NAME
             , case when c.udt_name = 'varchar' 
                    then c.udt_name ||
                         case when c.character_maximum_length is not null 
                              then '('||cast(c.character_maximum_length as varchar)||')'
                              else ''
                         end 
                    when c.udt_name like ('int%')
                    then c.udt_name ||'-'||cast(c.numeric_precision as varchar)
                    else c.udt_name 
               end COL_TYPE
             , c.is_nullable is_null
--             , c.column_default
--             , t.table_catalog
             ,t.table_schema
          from dvdrental.information_schema.columns c
               join information_schema.tables t on c.table_name = t.table_name
         where 1 = 1 
           and c.table_catalog = 'dvdrental' 
           and c.table_name = $1"
       ,table_name
       )
}    
```

The next code block returns the customer metadata via a call to the previous function.


```r
sp_tbl_descr('customer')
```

```
##    table_name seq    col_name    col_type is_null table_schema
## 1    customer   1 customer_id     int4-32      NO       public
## 2    customer   2    store_id     int2-16      NO       public
## 3    customer   3  first_name varchar(45)      NO       public
## 4    customer   4   last_name varchar(45)      NO       public
## 5    customer   5       email varchar(50)     YES       public
## 6    customer   6  address_id     int2-16      NO       public
## 7    customer   7  activebool        bool      NO       public
## 8    customer   8 create_date        date      NO       public
## 9    customer   9 last_update   timestamp     YES       public
## 10   customer  10      active     int4-32     YES       public
```

The metadata tells us the length of the three varchar, variable length, columns.  We can see that our two date columns are of different types, date and timestamp.  `is_null=NO` tells us the column is required to have a value non-null value.  `is_null=YES`otherwise it can be null. 
The `activebool` is either true or false.  Without a definitive description of the column, we will assume that the customer is active, `activebool=true` or inactive, `activebool=false.`  The active column, an int4 data type, can take on a large set of values. 

*  Why would an application need two active indicators?

## Primary and Foreign Key Constraints

The database or application designers implement constraints to help maintain referential integrity and improve database performance.  One is the implementation of a primary key which must be unique for each row in the table.  The primary key is usually defined as the first column.  On occasion the primary key consists of multiple columns and none of these columns can be null.

Looking back to the customer columns, what is the customer table primary key, customer_id or customer_id + store_id?  

The other constraint is a foreign key constraint which is one or more columns in one table that make up a primary key in another table.

From the DVD Rental ERD, [here](https://www.postgresqltutorial.com/postgresql-sample-database), one can see that out of the 15 tables in the ERD, all but two tables have a single column primary key, film_category and the film_actor tables have two columns that define the primary key. The primary key columns have an asterisk to the left of the column name.  For the single column keys, the primary key column is the name of the table suffixed with `_id.`  

The customer primary key is just customer_id column.  

Is the customer.store_id a foreign key to the store table?  Based on ERD, the customer.store_id is not a foreign key to the store table.

The next code block uses many `information_schema` objects to return a table's primary and foreign keys for any table in the Dvdrental database.

*  This code block is another example of a parameterized R function, sp_tbl_pk_fk, sql pet table primary key and foreign keys.
*  Not all tables are required to have a primary key.  If a table has one
    *  The function returns one or more columns that make up the table primary key.  
    *  The function also returns any other table that has a foreign key reference to the table.
*  The function is restricted to the Dvdrenatal database, see the where clause `and c.table_catalog = 'dvdrental'`.  
*  The function is restricted to the public schema where the Dvd rental table/views are kept, see the where clause c.table_schema = 'public'. 
*  The function has one parameter passed it, table_name.  Parameter substitution occurs in the where clause, `AND (c.table_name = $1 or coalesce(c2.table_name, '') = $1)`.  The paramter substituion occurs to see if the table_name passed has a primary key or refereced as a foreign table.

### sp_tbl_pk_fk -- Parameterized Table Primary Foreign Key(s) Function


```r
sp_tbl_pk_fk_sql <- function(table_name) {
    dbGetQuery(con
              ,"SELECT c.table_name
                      ,kcu.column_name
                      ,c.constraint_name
                      ,c.constraint_type
                      ,coalesce(c2.table_name, '') ref_table
                      ,coalesce(kcu2.column_name, '') ref_table_col
                  FROM information_schema.tables t
                       LEFT JOIN information_schema.table_constraints c
                         ON t.table_catalog = c.table_catalog
                        AND t.table_schema = c.table_schema
                        AND t.table_name = c.table_name
                       LEFT JOIN information_schema.key_column_usage kcu
                         ON c.constraint_schema = kcu.constraint_schema
                        AND c.constraint_name = kcu.constraint_name
                       LEFT JOIN information_schema.referential_constraints rc
                         ON c.constraint_schema = rc.constraint_schema
                        AND c.constraint_name = rc.constraint_name
                       LEFT JOIN information_schema.table_constraints c2
                         ON rc.unique_constraint_schema = c2.constraint_schema
                        AND rc.unique_constraint_name = c2.constraint_name
                       LEFT JOIN information_schema.key_column_usage kcu2
                         ON c2.constraint_schema = kcu2.constraint_schema
                        AND c2.constraint_name = kcu2.constraint_name
                        AND kcu.ordinal_position = kcu2.ordinal_position
                 WHERE c.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
                   AND c.table_catalog = 'dvdrental'
                   AND c.table_schema = 'public'
                   AND (c.table_name = $1 or coalesce(c2.table_name, '') = $1)
               ORDER BY c.table_name,c.constraint_type desc"
              ,param = list(table_name)
              )
}
```

### Customer primary and foreign key constraints

The next code block returns the customer primary and foreign key metadata via a call to the previous function.


```r
sp_tbl_pk_fk_sql('customer')
```

```
##   table_name column_name          constraint_name constraint_type
## 1   customer customer_id            customer_pkey     PRIMARY KEY
## 2   customer  address_id customer_address_id_fkey     FOREIGN KEY
## 3    payment customer_id payment_customer_id_fkey     FOREIGN KEY
## 4     rental customer_id  rental_customer_id_fkey     FOREIGN KEY
##   ref_table ref_table_col
## 1                        
## 2   address    address_id
## 3  customer   customer_id
## 4  customer   customer_id
```

The table above tells us:

1.  The customer has customer_id as the primary key which matches the ERD.
2.  The customer address_id is a foreign key to the address table, the ref_table column and joins on the ref_table_col, address_id.
3.  The payment and rental tables have customer_id as a foreign key back to the customer table.

The ERD matches the Primary and Foreign Key information in the table above.

## We need documentation and/or a DBA.

The output above shows that the store_id column is not part of the customer primary key and it isn't foreign key to the store table.

Some possible explanations are:

1.  The ERD is incomplete or it excluded some foreign keys to highlight other relationships.
2.  The SQL above is wrong.
3.  The customer-store foreign key constraint was just missed.  On large systems this is not out of the realm of possibilities.
4.  The customer-store foreign key constraint was diabled.
5.  The customer-store foreign key constraint was designed out of the system.

The DBA team or project documentation may help explain 

*  The true relation between the customer and store tables.  
*  Why there are two customer active columns, activebool and active.

Some possible explanation for the two active columns are:

1.  The application vendor adds new functionality resulting in 

*  new columns being added to a table
*  dropping a table and migrating the old data into one or more new tables
*  splitting a table into one or more tables
*  Sometimes applications are migrated from one vendor's RDBMS to a different vedor's RDBMS which usually introduces some kind of incompatability.

2.  A company has its own DBA's add columns to a table to reflect new business requirements.

*  All the existing records are updated to reconstruct the new data for the new columns or 
*  All the existing columns are defaulted to a single value.  There is a break in the meaning of the new columns between the existing records and new records.  

3.  The business DBA's add new columns are added to tables to reflect some new business requirements.  New columns are typically added to the end of the table.  If a table is wide and the new column is at the end, it is very easy to miss the new column when having to scroll across the screen to find it.

See figure 1 [here](https://dev.mysql.com/doc/sakila/en/sakila-structure.html) for another ERD.  What does this ERD tell us about the relationship between the customer and store tables?

See the customer table column description [here](https://dev.mysql.com/doc/sakila/en/sakila-structure-tables-customer.html).  What can we learn about the active column from this link?

### Other Table Column Metadata

In the next code block, change the function parameter to different table names to get the associated column metadata.  If necessary, uncomment the dbListTable line to get a list of table names.


```r
#dbListTables(con)
sp_tbl_descr('customer')
```

```
##    table_name seq    col_name    col_type is_null table_schema
## 1    customer   1 customer_id     int4-32      NO       public
## 2    customer   2    store_id     int2-16      NO       public
## 3    customer   3  first_name varchar(45)      NO       public
## 4    customer   4   last_name varchar(45)      NO       public
## 5    customer   5       email varchar(50)     YES       public
## 6    customer   6  address_id     int2-16      NO       public
## 7    customer   7  activebool        bool      NO       public
## 8    customer   8 create_date        date      NO       public
## 9    customer   9 last_update   timestamp     YES       public
## 10   customer  10      active     int4-32     YES       public
```

### Other Table PK FK 

In the next code block, change the function parameter to different table names to get the associated PK and FK associated wih the table.


```r
#dbListTables(con)
sp_tbl_pk_fk_sql('customer')
```

```
##   table_name column_name          constraint_name constraint_type
## 1   customer customer_id            customer_pkey     PRIMARY KEY
## 2   customer  address_id customer_address_id_fkey     FOREIGN KEY
## 3    payment customer_id payment_customer_id_fkey     FOREIGN KEY
## 4     rental customer_id  rental_customer_id_fkey     FOREIGN KEY
##   ref_table ref_table_col
## 1                        
## 2   address    address_id
## 3  customer   customer_id
## 4  customer   customer_id
```
