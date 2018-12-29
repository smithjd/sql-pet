# SQL Quick start - simple retrieval (15)

> This chapter demonstrates:
> 
> * Several elementary SQL statements
> * SQL databases and 3rd normal form




## Intro

* Coverage in this book.  There are many SQL tutorials that are available.  For example, we are drawing some materials from  [a tutorial we recommend](http://www.postgresqltutorial.com/postgresql-sample-database/).  In particular, we will not replicate the lessons there, which you might want to complete.  Instead, we are showing strategies that are recommended for R users.  That will include some translations of queries that are discussed there.

* https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html  Very good intro.  How is ours different?

Start up the `docker-pet` container

```r
sp_docker_start("sql-pet")
```

Now connect to the `dvdrental` database with R

```r
con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password =  Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 30)
con
```

```
## <PqConnection> dvdrental@localhost:5432
```


```r
colFmt <- function(x,color)
{
  # x string
  # color 
  outputFormat = knitr::opts_knit$get("rmarkdown.pandoc.to")
  if(outputFormat == 'latex')
    paste("\\textcolor{",color,"}{",x,"}",sep="")
  else if(outputFormat == 'html')
    paste("<font color='",color,"'>",x,"</font>",sep="")
  else
    x
}

# sample call
# * `r colFmt('Cover inline tables in future section','red')`
```

Moved this from 11-elementary-queries

```r
dplyr_summary_df <-
    read.delim(
    '11-dplyr_sql_summary_table.tsv',
    header = TRUE,
    sep = '\t',
    as.is = TRUE
    )

head(dplyr_summary_df)
```

```
##   In          Dplyr_Function
## 1  Y               arrange()
## 2 Y?              distinct()
## 3  Y       select() rename()
## 4  N                  pull()
## 5  Y    mutate() transmute()
## 6  Y summarise() summarize()
##                                      description
## 1                      Arrange rows by variables
## 2           Return rows with matching conditions
## 3                Select/rename variables by name
## 4                     Pull out a single variable
## 5                              Add new variables
## 6 Reduces multiple values down to a single value
##                            SQL_Clause Notes                 Category
## 1                            ORDER BY    NA Basic single-table verbs
## 2                   SELECT distinct *    NA Basic single-table verbs
## 3       SELECT column_name alias_name    NA Basic single-table verbs
## 4                 SELECT column_name;    NA Basic single-table verbs
## 5 SELECT computed_value computed_name    NA Basic single-table verbs
## 6 SELECT aggregate_functions GROUP BY    NA Basic single-table verbs
```
## Databases and Third Normal Form - 3NF

Most relational database applications are designed to be third normal form "like", 3NF.  The key benefits of 3NF are 

1.  speedy on-line transactional processing, OLTP.
2.  improved referential integrity, reduce modification anomalies that can occur during an insert, update, or delete operation.
3.  reduced storage, elimination of redundant data.

3NF is great for database application input performance, but not so great for getting the data back out for the data analyst or report writer.  As a data analyst, you might get the ubiquitous Excel spreadsheet with all the information needed to start an Exploratory Data Analysis, EDA.  The spreadsheet may have provider, patient, diagnosis, procedure, and insurance information all "neatly" arranged on a single row.  At least "neatly" when compared to the same information stored in the database, in at least 5 tables.  

For this tutorial, the most important thing to know about 3NF is that the data you are looking for gets spread across many many tables.  Working in a relational database requires you to 

1.  find the many many different tables that contains your data.   
2.  Understand the relationships that tie the tables together correctly to ensure that data is not dropped or duplicated.  Data that is dropped or duplicated can either over or understate your aggregated numeric values.  

![hospital-billing-erd](ERD_Hospital_Billing_System.png)

https://www.smartdraw.com/entity-relationship-diagram/examples/hospital-billing-entity-relationship-diagram/

Real life applications have 100's or even 1000's of tables supporting the application.  The goal is to transform the application data model into a useful data analysis model using the DDL and DML SQL statements.  

## SQL Commands

SQL commands fall into four categories.  

SQL Category|Definition
------------|----------------------------------------------
DDL:Data Definition Language    |DBA's execute these commands to define objects in the database.
DML:Data Manipulation Language  |Users and developers execute these commands to investigate data.
DCL:Data Control Language       |DBA's execute these commands to grant/revoke access to 
TCL:Transaction Control Language|Developers execute these commands when developing applications. 

Data analysts use the SELECT DML command to learn interesting things about the data stored in the database.  Applications are used to control the insert, update, and deletion of data in the database.  Data users can update the database objects via the application which enforces referential integrity in the database.  Data users should never directly update data application database objects. Leave this task to the developers and DBA's. 

DBA's can setup a sandbox within the database for a data analyst.  The application(s) do not maintain the data in the sandbox.  


The `sql-pet` database is tiny, but for the purposes of these exercises, we assume that data so large that it will not easily fit into the memory of your laptop.

This tutorial focuses on the most frequently used SQL statement, the SQL SELECT statement.  

A SQL SELECT statement consists of 1 to 6 clauses.  

|SQL Clause | DPLYR Verb| SQL Description
|-----------|-----------|-------------------
|SELECT     | SELECT()  |Contains a list of column names from an object or a derived value.
|           | mutate()  |
|  FROM     |           |Contains a list of related tables from which the SELECT list of columns is derived.
| WHERE     | filter()  |Provides the filter conditions the objects in the FROM clause must meet.
|GROUP BY   | group_by()|Contains a list rollup aggregation columns.
|HAVING     |           |Provides the filter condition on the the GROUP BY clause.
|ORDER BY   | arrange() |Contains a list of column names indicating the order of the column value.  Each column can be either ASCending or DEScending.

The foundation of the SQL language is based set theory and the result of a SQL SELECT statement is referred to as a result set.  A SQL SELECT statement is "guaranteed" to return the same set of data, 
but not necessarily in the same order.  However, in practice, the result set is usually in the same order.

SQL SELECT statements can be broken up into two categories, SELECT detail statements and SELECT aggregate statements.

|SELECT DETAIL              | SELECT AGGREGATE
|---------------------------|-------------------------------
|select det_col1...det_coln | select det_agg1..., agg1,...,aggn
|  from same                |   from same
| where same                |  where same
|                           | group by det_agg1
|                           | having <aggregation condition>
|order by same              | order by same

The difference between the two statements is the AGGREGATE has 

1.  select clause has one or more detail columns, det_agg1..., on which values get aggregated against/rolled up to.
2.  select clause zero or more aggregated values, agg1, ..., aggn
3.  group by clause is required and matches the one or more detail columns, det_agg1.
4.  having clause is optional and adds a filter condition on one or more agg1 ... aggn values.
 
## SQL SELECT Quick Start

This section focuses on getting new SQL users familiar with the six SQL query clauses and a single table.   SQL queries from multiple tables are discussed in the JOIN section of this tutorial.  The JOIN section resolves the issue introduced with 3NF, the splitting of data into many many tables, back into a denormalaized format similar to the Excel spreadsheet.

The DBI::dbGetQuery function is used to submit SQL SELECT statements to the Postgres database.  At a minimum it requires two parameters, a connection object and a SQL SELECT statement.

In the following section we only look at SELECT DETAIL statements.

### SELECT Clause: Column Selection -- Vertical Partioning of Data 

#### 1.  Simplest SQL query: All rows and all columns from a single table.  


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select * from store;
  ")
kable(rs,caption = 'select all columns')  
```



Table: (\#tab:unnamed-chunk-5)select all columns

 store_id   manager_staff_id   address_id  last_update         
---------  -----------------  -----------  --------------------
        1                  1            1  2006-02-15 09:57:12 
        2                  2            2  2006-02-15 09:57:12 
                
#### 2.  Same Query as 1, but only show first two columns; 


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select STORE_ID, manager_staff_id from store;  
  ")
kable(rs,caption = 'select first two columns only') 
```



Table: (\#tab:unnamed-chunk-6)select first two columns only

 store_id   manager_staff_id
---------  -----------------
        1                  1
        2                  2

#### 3.  Same Query as 2, but reverse the column order               
dvdrental=# select manager_staff_id,store_id from store;

```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select manager_staff_id,store_id from store;  
  ")
kable(rs,caption = 'reverse the column order') 
```



Table: (\#tab:unnamed-chunk-7)reverse the column order

 manager_staff_id   store_id
-----------------  ---------
                1          1
                2          2
    
       
                        
#### 4.  Rename Columns -- SQL column alias in the result set


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select manager_staff_id mgr_sid,store_id st_id from store;    
  ")
kable(rs,caption = 'Rename Columns') 
```



Table: (\#tab:unnamed-chunk-8)Rename Columns

 mgr_sid   st_id
--------  ------
       1       1
       2       2


    The manager_staff_id has changed to mgr_sid.
    store_id has changed to st_id.  
    
    Note that the column names have changed in the result set only, not in the actual database table.  
    The DBA's will not allow a space or other special characters in a database table column name.  
    
    Some motivations for aliasing the result set column names are
    
      1.  Some database table column names are not user friendly.
      2.  When multiple tables are joined, the column names may be the same in one or more tables and one needs to distinguish between the column names from the different tables.
      
#### 5.  Adding Meta Data Columns to the Result Set


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select 'derived column' showing
        ,*
        ,current_database() db
        ,user
        ,to_char(now(),'YYYY/MM/DD HH24:MI:SS') dtts 
    from store;    
  ")
kable(rs,caption = 'Adding Meta Data Columns') 
```



Table: (\#tab:unnamed-chunk-9)Adding Meta Data Columns

showing           store_id   manager_staff_id   address_id  last_update           db          user       dtts                
---------------  ---------  -----------------  -----------  --------------------  ----------  ---------  --------------------
derived column           1                  1            1  2006-02-15 09:57:12   dvdrental   postgres   2018/12/29 05:05:59 
derived column           2                  2            2  2006-02-15 09:57:12   dvdrental   postgres   2018/12/29 05:05:59 
 
    All the previous examples easily fit on a single line.  This one is longer.  Each column is entered on its own line, indented past the select keyword, and preceeded by a comma.  
    
    1.  The showing column is a hard coded string surrounded by single quotes.  Note that single quotes are for hard coded values and double quotes are for column aliases.  
    2.  The db and dtts, date timestamp, are new columns generated from Postgres System Information Functions.
    3.  Note that `user` is not a function call, no parenthesis.  
    
### SQL Comments

SQL supports both a single line comment, preceed the line with two dashes, `--`, and a C like block comment, \\*  ... */.

#### 6.  Single line comment --


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select 'single line comment, dtts' showing       
        ,*
        ,current_database() db
        ,user
    --  ,to_char(now(),'YYYY/MM/DD HH24:MI:SS') dtts
    from store;    
  ")
kable(rs,caption = 'Sincle line comment') 
```



Table: (\#tab:unnamed-chunk-10)Sincle line comment

showing                      store_id   manager_staff_id   address_id  last_update           db          user     
--------------------------  ---------  -----------------  -----------  --------------------  ----------  ---------
single line comment, dtts           1                  1            1  2006-02-15 09:57:12   dvdrental   postgres 
single line comment, dtts           2                  2            2  2006-02-15 09:57:12   dvdrental   postgres 

    The dtts  line is commented out with the two dashes and is dropped from the end of the result set columns.
    
#### 7.  Multi-line comment /\*...\*/


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select 'block comment drop db, user, and dtts' showing
        ,*
        /*
        ,current_database() db
        ,user
        ,to_char(now(),'YYYY/MM/DD HH24:MI:SS') dtts
        */
    from store;    
  ")
kable(rs,caption = 'Multi-line comment') 
```



Table: (\#tab:unnamed-chunk-11)Multi-line comment

showing                                  store_id   manager_staff_id   address_id  last_update         
--------------------------------------  ---------  -----------------  -----------  --------------------
block comment drop db, user, and dtts           1                  1            1  2006-02-15 09:57:12 
block comment drop db, user, and dtts           2                  2            2  2006-02-15 09:57:12 

    The three columns db, user, and dtts, between the /\* and \*/ have been commented and no longer appear as the end columns of the result set.
    
### FROM Clause 

The `FROM` clause contains one or more datasets, usually database tables/views, from which the `SELECT` columns are derived.  For now, in the examples, we are only using a single table.  If the database reflects a relational model, your data is likely spread out over several tables.  The key take away when beginning your analysis is to pick the table that has most of the data that you need for your analysis.  This table becomes your main or driving table to build your SQL query statement around.  After identifying your driving table, potentially save yourself a lot of time and heart ache,  review any view that is built on your driving table.  If one or more exist, especially, if vendor built, may already have the additional information needed for your analysis.

<font color='red'>Insert SQL here or link to Views dependent on what</font>

In this tutorial, there is only a single user hitting the database and row/table locking is not necessary and considered out of scope.

#### Table Uses

  *  A table can be used more than once in a FROM clause.  These are self-referencing tables.  An example is an EMPLOYEE table which contains a foriegn key to her manager.  Her manager also has a foriegn key to her manager, etc up the corporate ladder.  
  *  In the example above, the EMPLOYEE table plays two roles, employee and manager.  The next line shows the FROM clause showing the same table used twice.  
    
     FROM EMPLOYEE EE, EMPLOYEE MGR
       
  *  The EE and MGR are aliases for the EMPLOYEE table and represent the different roles the EMPLOYEE table plays.  
  *  Since all the column names are exactly the same for the EE and MGR role, the column names need to be prefixed with their role alias, e.g., SELECT MGR.EE_NAME, EE.EE_NAME ... shows the manager name and her employee name(s) who work for her.
  *  It is a good habit to always alias your tables and prefix your column names with the table alias to eliminate any ambiguity as to where the column came from.  This is critical where there is inconsistent table column naming convention.  It also helps when debugging larger SQL queries.
  * <font color='red'>Cover inline tables in future section</font>
  
```
Side Note: Do not create an unintended Cartesian join.  If one has more than one table in the FROM clause, make sure that every table in the FROM clause joins to at least one other table in the WHERE clause.  If your result set has an unexpectantly high rowcount and long runtime, check for a missing join in the FROM clause.
```

### WHERE Clause: Row Selection -- Horizontal Partitioning of Data                                          

In the previous SELECT clause section, the SELECT statement either partitioned data vertically across the table columns or derived vertical column values.  This section provides examples that partitions the table data across rows in the table.

  

The WHERE clause defines all the conditions the data must meet to be included or excluded in the final result set.  If all the conditions are met data is returned or it is rejected.  This is commonly referred to as the data set filter condition.  

```
Side Note: For performance optimization reasons, the WHERE clause should reduce the dataset down to the smallest dataset as quickly as possible.  This is typically done using indexed columns, range conditions, and any other condition that rejects a lot of rows from being retrieved.
```

The WHERE condition(s) can be simple or complex, but in the end are the appliction of the logic rules shown in the table below.

p | q | p and q | p or q 
--|---|---------|--------
T | T |    T    |   T
T | F |    F    |   T
T | N |    N    |   T
F | F |    F    |   F
F | N |    F    |   T
N | N |    N    |   N

When the filter logic is complex, it is sometimes easier to represent the where clause symbollically and  apply a version of DeMorgan's law which is shown below.

1.  (A and B)' = A' or B'
2.  (A or B)'  = A' and B'

#### Examples Continued

We begin with `1`, our simplest SQL query.


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select * from store;
  ")
kable(rs,caption = 'select all columns')  
```



Table: (\#tab:unnamed-chunk-12)select all columns

 store_id   manager_staff_id   address_id  last_update         
---------  -----------------  -----------  --------------------
        1                  1            1  2006-02-15 09:57:12 
        2                  2            2  2006-02-15 09:57:12 

#### 8 WHERE condition logically never TRUE.


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select * from store where 1 = 0;
  ")
kable(rs,caption = 'WHERE always FALSE')  
```



Table: (\#tab:unnamed-chunk-13)WHERE always FALSE

 store_id   manager_staff_id   address_id  last_update 
---------  -----------------  -----------  ------------

    Since 1 = 0 is always false, no rows are ever returned.  Initially this construct seems useless, but actually is quite handy when debugging large scripts where a portion of the script needs to be turned off or when creating an empty table with the exact same column names and types as the FROM table(s).  

#### 9 WHERE condition logically always TRUE.


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select * from store where 1 = 1;
  ")
kable(rs,caption = 'WHERE always TRUE')  
```



Table: (\#tab:unnamed-chunk-14)WHERE always TRUE

 store_id   manager_staff_id   address_id  last_update         
---------  -----------------  -----------  --------------------
        1                  1            1  2006-02-15 09:57:12 
        2                  2            2  2006-02-15 09:57:12 
    
    Since 1 = 1 is always true, all rows are always returned.  Initially this construct seems useless, but actually is also quite handy when debugging large scripts and creating a backup of table.
    
#### 10 WHERE equality condition 


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select * from store where store_id = 2;
  ")
kable(rs,caption = 'WHERE EQUAL')  
```



Table: (\#tab:unnamed-chunk-15)WHERE EQUAL

 store_id   manager_staff_id   address_id  last_update         
---------  -----------------  -----------  --------------------
        2                  2            2  2006-02-15 09:57:12 
        
        The only row where the store_id = 2 is row 2 and it is the only row returned.
        
#### 11 WHERE NOT equal conditions 


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select * from store where store_id <> 2;
  ")
kable(rs,caption = 'WHERE NOT EQUAL')  
```



Table: (\#tab:unnamed-chunk-16)WHERE NOT EQUAL

 store_id   manager_staff_id   address_id  last_update         
---------  -----------------  -----------  --------------------
        1                  1            1  2006-02-15 09:57:12 

    <> is syntactically the same as !=
        
        The only row where the store_id <> 2 is row 1 and only row 1 is returned.  

#### 12 WHERE OR condition


```r
rs <-
  DBI::dbGetQuery(
  con,
  "
  select * from store where manager_staff_id = 1 or store_id < 3; 
  ")
kable(rs,caption = 'WHERE OR condition')  
```



Table: (\#tab:unnamed-chunk-17)WHERE OR condition

 store_id   manager_staff_id   address_id  last_update         
---------  -----------------  -----------  --------------------
        1                  1            1  2006-02-15 09:57:12 
        2                  2            2  2006-02-15 09:57:12 

    The first condition manager_staff_id = 1 returns a single row and the second condition store_id < 3 returns two rows.  
    
Following table is modified from http://www.tutorialspoint.com/sql/sql-operators

SQL Comparison Operators

Operator | Description | example
---------|--------------------------------------------------------------------|-------------
=	|Checks if the values of two operands are equal or not, if yes then condition becomes true.	|(a = b) is not true.
!= |	Checks if the values of two operands are equal or not, if values are not equal then condition becomes true.	| (a != b) is true.
<>	|Checks if the values of two operands are equal or not, if values are not equal then condition becomes true.	| (a <> b) is true.
> |	Checks if the value of left operand is greater than the value of right operand, if yes then condition becomes true.	|(a > b) is not true.
<	| Checks if the value of left operand is less than the value of right operand, if yes then condition becomes true.	| (a < b) is true.
>=|	Checks if the value of left operand is greater than or equal to the value of right operand, if yes then condition becomes true.	|(a >= b) is not true.
<=|	Checks if the value of left operand is less than or equal to the value of right operand, if yes then condition becomes true.	|(a <= b) is true.
!<|	Checks if the value of left operand is not less than the value of right operand, if yes then condition becomes true.	|(a !< b) is false.
!>|	Checks if the value of left operand is not greater than the value of right operand, if yes then condition becomes true.	|(a !> b) is true.

Operator|Description
--------|------------------------------------------------------------------------------------------
ALL|The ALL operator is used to compare a value to all values in another value set.
AND|The AND operator allows the existence of multiple conditions in an SQL statement's WHERE clause.
ANY|The ANY operator is used to compare a value to any applicable value in the list as per the condition.
BETWEEN|The BETWEEN operator is used to search for values that are within a set of values, given the minimum value and the maximum value.
EXISTS|The EXISTS operator is used to search for the presence of a row in a specified table that meets a certain criterion.
IN|The IN operator is used to compare a value to a list of literal values that have been specified.
LIKE|The LIKE operator is used to compare a value to similar values using wildcard operators.
NOT|The NOT operator reverses the meaning of the logical operator with which it is used. Eg: NOT EXISTS, NOT BETWEEN, NOT IN, etc. This is a negate operator.
OR|The OR operator is used to combine multiple conditions in an SQL statement's WHERE clause.
IS NULL|The NULL operator is used to compare a value with a NULL value.
UNIQUE|The UNIQUE operator searches every row of a specified table for uniqueness (no duplicates). 


https://pgexercises.com/questions/basic
    
 ## TO-DO's
 
 1.  inline tables
 2.  correlated subqueries
 
 

 

 
## Paradigm Shift from R-Dplyr to SQL
 
Paraphrasing what some have said with an R dplyr background and no SQL experience, "It is like working from the inside out."  This sentiment occurs because 

1.  The SQL SELECT statement begins at the end, the SELECT clause, and drills backwards, loosely speaking, to derive the desired result set.
2.  SQL SELECT statements are an all or nothing proposition.  One gets nothing if there is any kind of syntax error.  
3.  SQL SELECT result sets can be quite opaque.  The WHERE clause can be very dense and difficult to trace through.  It is rarely ever linear in nature.  
4.  Validating all the permutations in the where clause can be tough and tedious.

### Big bang versus piped incremental steps.

1.  Dplyr starts with one or more sources joined together in a conceptually similar way that SQL joins sources.
2.  The pipe and filter() function breaks down the filter conditions into small managable logical steps. This makes it much easier to understand what is happening in the derivation of the final tibble.  Adding  tees through out the pipe line gives one full trace back of all the data transformations at every pipe.

Helpful tidyverse functions that output tibbles: tbl_module function in https://github.com/nhemerson/tibbleColumns package; 

Mental picture: SQL approach: Imagine a data lake named Niagera Falls and drinking from it without drowning.  R-Dplyr approach: Imagine a resturant at the bottom of the Niagera Falls data lake and having a refreshing dring out of the water faucet.


### SQL Execution Order

The table below is derived from this site.  https://www.periscopedata.com/blog/sql-query-order-of-operations  It shows what goes on under the hood SQL SELECT hood.
 
 
SEQ|SQL             |Function                                | Dplyr
---|----------------|----------------------------------------|-------------------------
1  |WITH            |Common Table expression, CTE, one or more datasets/tables used FROM clause.|.data parameter in dplyr functions
2  |FROM            |Choose and join tables to get base data|.data parameter in dplyr functions
3  |ON              |Choose and join tables to get base data|dplyr join family of functions
4  |JOIN            |Choose and join tables to get base data|dplyr join family of functions
5  |WHERE           |filters the base data|dplyr filter()
6  |GROUP BY        |aggregates the base data|dplyr group_by family of functions
7  |WITH CUBE/ROLLUP|aggregates the base data|is this part of the dplyr grammar
8  |HAVING          |filters aggregated data|dplyr filter()
9  |SELECT          |Returns final data set|dplyr select()
10 |DISTINCT        |Dedupe the final data set|dplyr distinct()
11 |ORDER BY        |Sorts the final data set|arrange()
12 |TOP/LIMIT       |Limits the number of rows in data set
13 |OFFSET/FETCH    |Limits the number of rows in data set

The SEQ column shows the standard order of SQL execution.  One take away for this tutorial is that the SELECT clause actually executes late in the process, even though it is the first clause in the entire SELECT statement.  A second take away is that SQL execution order, or tweaked order, plays a critical role in SQL query tuning. 

      
  6.  SQL for View table dependencies.
  7.  Add cartesian join exercise.
