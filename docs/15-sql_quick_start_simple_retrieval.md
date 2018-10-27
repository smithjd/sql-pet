# SQL Quick start - simple retrieval (15)


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
  seconds_to_test = 10)
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


## SQL Commands

SQL commands fall into four categories.  

SQL Category|Definition
------------|----------------------------------------------
DDL:Data Definition Language    |DBA's execute these commands to define objects in the database.
DML:Data Manipulation Language  |Users and developers execute these commands to investigate data.
DCL:Data Control Language       |DBA's execute these commands to grant/revoke access to 
TCL:Transaction Control Language|Developers execute these commands when developing applications. 

Data analysts use the SELECT DML command to learn interesting things about the data stored in the database.  Applications are used to control the insert, update, and deletion of data in the database.  Data users can update the database objects via the application which enforces referential integrity in the database, but not directly against the application database objects.  

DBA's can setup a sandbox within the database for a data analyst.  The application(s) do not maintain the data in the sandbox.  In addition to the SELECT command, data analysts may be granted any or all the commands in the DDL and DML sections in the table below.  The most common ones are the DML commands with a star, "*. "

|DDL     |DML         |DCL     |TCL
|--------|------------|--------|----------
|ALTER   |CALL        |GRANT   |COMMIT
|CREATE  |DELETE*     |REVOKE  |ROLLBACK
|DROP    |EXPLAIN PLAN|        |SAVEPOINT
|RENAME  |INSERT*     |        |SET TRANSACTION
|TRUNCATE|LOCK TABLE  |        |
|        |MERGE       |        |
|        |SELECT*     |        |
|        |UPDATE*     |        |

Most relational database applications are designed for speed, speedy on-line transactional processing, OLTP, and a lot of parent child relationships.  Such applications can have 100's or even 1000's of tables supporting the application.  The goal is to transform the application data model into a useful data analysis model using the DDL and DML SQL statements.  

The `sql-pet` database is tiny, but for the purposes of these exercises, we assume that data so large that it will not easily fit into the memory of your laptop.

A SQL SELECT statement consists of 1 to 6 clauses.  In the table below, `object` refers to either a database table or a view object.    

|SQL Clause | DPLYR Verb| SQL Description
|-----------|-----------|-------------------
|SELECT     | SELECT()  |Contains a list of column names from an object or a derived value.
|           | mutate()  |
|  FROM     |           |Contains a list of related objects from which the SELECT list of columns is derived.
| WHERE     | filter()  |Provides the filter conditions the objects in the FROM clause must meet.
|GROUP BY   | group_by()|Contains a list unique column values returned from the WHERE clause.
|HAVING     |           |Provides the filter condition on the the GROUP BY clause.
|ORDER BY   | arrange() |Contains a list of column names indicating the order of the column value.  Each column can be either ASCending or DEScending.

## Query statement structure

A SQL query statement consists of six distinct parts and each part is referred to as a clause.  The foundation of the SQL language is based set theory and the result of a SQL query is referred to as a result set.  A SQL query statement is "guaranteed" to return the same set of data, 
but not necessarily in the same order.  However, in practice, the result set is usually in the same order.

For this tutorial, a SQL query either returns a detailed row set or a summarized row set.  The detailed row set can show, but is not required to 
show every column.  A summarized row set requires one or more summary columns and the associated aggregated summary values. 

Sales reps may be interested a detailed sales report showing all their activity.  At the end of the month, the sales rep may be interested at a 
summary level based on product line dollars.  The sales manager may be more interest in territory dollars.

## SQL Clauses

1.  Select Clause
2.  From Clause
3.  Where Clause
4.  Group By Clause
5.  Having Clause
6.  Order By Clause

This section focuses on getting new SQL users familiar with the six SQL query clauses and a single table.   SQL queries from multiple tables are discussed
in the JOIN section of this tutorial.  

For lack of a better term, a SQL-QBE, a very simple SQL Query by example, is used to illustrate some SQL feature.  

    Side Note: This version of Postgres requires all SQL statments be terminated with a semi-colon.  
Some older flavors of SQL and GUI tools do not require the SQL statement to be terminated with a semi-colon, ';' for the command to be executed.  It is recommended that you always terminate your SQL commands with a semi-colon.

## SELECT Clause: Column Selection -- Vertical Partioning of Data 

### 1.  Simplest SQL query: All rows and all columns from a single table.  

    dvdrental=# select * from store;  
    
 store_id | manager_staff_id | address_id |     last_update
----------+------------------+------------+---------------------
    1 |                1 |          1 | 2006-02-15 09:57:12
    2 |                2 |          2 | 2006-02-15 09:57:12   
                
### 2.  Same Query as 1, but only show first two columns; 

    dvdrental=# select STORE_ID, manager_staff_id from store;                
    
 store_id | manager_staff_id                                             
----------+------------------                                            
        1 |                1                             
        2 |                2                             
                
### 3.  Same Query as 2, but reverse the column order               

    dvdrental=# select manager_staff_id,store_id from store;
    
 manager_staff_id | store_id                            
------------------+----------                           
                1 |        1                            
                        2 |        2          
                        
### 4.  Rename Columns -- SQL column alias in the result set

    dvdrental=# select manager_staff_id mgr_sid,store_id "store id" from store;  
    
 mgr_sid | store id
---------+----------
       1 |        1
       2 |        2
                        
    The manager_staff_id has changed to mgr_sid.
    store_id has changed to store id.  In practice, aliasing column names that have a space is not done.
    
    Note that the column names have changed in the result set only, not in the actual database table.  
    The DBA's will not allow a space or other special characters in a database table column name.  
    
    Some motivations for aliasing the result set column names are
    
      1.  Some database table column names are not user friendly.
      2.  When multiple tables are joined, the column names may be the same in one or more tables and one needs to distinguish between the column names from the different tables.
      
### 5.  Adding labels and Additional Columns to the Result Set

    dvdrental=# select 'derived column' showing
                       ,*
                       ,current_database() db
                       ,user
                       ,to_char(now(),'YYYY/MM/DD HH24:MI:SS') dtts 
                  from store; 
    
showing     | store_id | manager_staff_id | address_id |     last_update     |    db     |   user   |        dtts             
----------------+----------+------------------+------------+---------------------+-----------+----------+---------------------    
 derived column |        1 |                1 |          1 | 2006-02-15 09:57:12 | dvdrental | postgres | 2018/10/07 20:20:28    
 derived column |        2 |                2 |          2 | 2006-02-15 09:57:12 | dvdrental | postgres | 2018/10/07 20:20:28     
 
    All the previous examples easily fit on a single line.  This one is longer.  Each column is entered on its own line, indented past the select keyword, and preceeded by a comma.  
    
    1.  The showing column is a hard coded string surrounded by single quotes.  Note that single quotes are for hard coded values and double quotes are for column aliases.  
    2.  The db and dtts, date timestamp, are new columns generated from Postgres System Information Functions.
    3.  Note that `user` is not a function call, no parenthesis.  
    
## SQL Comments

https://pgexercises.com/questions/basic

SQL supports both a single line comment, preceed the line with two dashes, `--`, and a C like block comment, \\*  ... */.

### 6.  Single line comment --

    dvdrental=# select 'single line comment, dtts' showing       
                      ,*
                      ,current_database() db
                      ,user
    --                   ,to_char(now(),'YYYY/MM/DD HH24:MI:SS') dtts
                 from store;

showing          | store_id | manager_staff_id | address_id |     last_update     |    db     |   user
-----------------+----------+------------------+------------+---------------------+-----------+----------
 single line comment, dtts |        1 |                1 |          1 | 2006-02-15 09:57:12 | dvdrental | postgres
 single line comment, dtts |        2 |                2 |          2 | 2006-02-15 09:57:12 | dvdrental | postgres
 
    The dtts  line is commented out with the two dashes and is dropped from the end of the result set columns.
    
### 7.  Multi-line comment /\*...\*/

    dvdrental=# select 'block comment drop db, user, and dtts' showing
                      ,*
                /*
                      ,current_database() db
                      ,user
                      ,to_char(now(),'YYYY/MM/DD HH24:MI:SS') dtts
                */
                  from store;
                  
showing                                | store_id | manager_staff_id | address_id |     last_update
---------------------------------------+----------+------------------+------------+---------------------
 block comment drop db, user, and dtts |        1 |                1 |          1 | 2006-02-15 09:57:12
 block comment drop db, user, and dtts |        2 |                2 |          2 | 2006-02-15 09:57:12    

    The three columns db, user, and dtts, between the /\* and \*/ have been commented and no longer appear as the end columns of the result set.
    

## FROM Clause 

The `FROM` clause contains database tables/views from which the `SELECT` columns are derived.  For now, in the examples, we are only using a single table.  If the database reflects a relational model, your data is likely spread out over several tables.  The key take away when beginning your analysis is to pick the table that has most of the data that you need for your analysis.  This table becomes your main or driving table to build your SQL query statement around.  After identifying your driving table, potentially save yourself a lot of time and heart ache.  Review any view that is built on your driving table.  If one or more exist, especially if vendor built, may already have the additional information need for your analysis.

Insert SQL here or link to Views dependent on what

In this tutorial, there is only a single user hitting the database and row/table locking is not necessary and considered out of scope.

### Table Uses

  *  A table can be used more than once in a FROM clause.  These are self-referencing table.  An example is an EMPLOYEE table which contains a foriegn key to her manager.  Her manager also has a foriegn key to her manager, etc up the corporate ladder.  
  *  In the example above, the EMPLOYEE table plays two roles, employee and manager.  The next line shows the FROM clause showing both rows.  
    
     FROM EMPLOYEE EE, EMPLOYEE MGR
       
  *  The EE and MGR are role abbreviations for the EMPLOYEE table.  
  *  Since all the column names are exactly the same for the EE and MGR role, the column names need to be prefixed with their role alias, e.g., SELECT MGR.EE_NAME, EE.EE_NAME ... shows the manager name and her employee name who work for her.
  *  It is a good habit to always alias your tables and prefix your column names with the table alias to eliminate any ambiguity as to where the column came from.  This is critical where there is inconsistent table column naming convention.
  * Cover inline tables in future section
  
```
Side Note: Do not create an unintended Cartesian join.  If one has more than one table in the FROM clause, make sure that every table in the FROM clause joins to at least one other table.  If your result set has an unexpectantly high rowcount and long runtime, check for a missing join in the FROM clause.
```

## WHERE Clause: Row Selection -- Horizontal Partitioning of Data                                          

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

### Example Continued

We begin with `1`, our simplest SQL query.

    dvdrental=# select * from store;  
    
 store_id | manager_staff_id | address_id |     last_update
----------+------------------+------------+---------------------
    1 |                1 |          1 | 2006-02-15 09:57:12
    2 |                2 |          2 | 2006-02-15 09:57:12 

### 7 WHERE condition logically never TRUE.

    dvdrental=# select * from store where 1 = 0;
    
 store_id | manager_staff_id | address_id |     last_update
----------+------------------+------------+---------------------

    Since 1 = 0 is always false, no rows are ever returned.  Initially this construct seems useless, but actually is quite handy when debugging large scripts where a portion of the script needs to be turned off or when creating an empty table with the exact same column names and types as the FROM table(s).  

### 8 WHERE condition logically always TRUE.

    dvdrental=# select * from store where 1 = 1;
    
 store_id | manager_staff_id | address_id |     last_update
----------+------------------+------------+---------------------
    1 |                1 |          1 | 2006-02-15 09:57:12
    2 |                2 |          2 | 2006-02-15 09:57:12
    
    Since 1 = 1 is always true, all rows are always returned.  Initially this construct seems useless, but actually is also quite handy when debugging large scripts and creating a backup of table.
    
### 9 WHERE equality condition 

    dvdrental=# select * from store where store_id = 2;
    
 store_id | manager_staff_id | address_id |     last_update
----------+------------------+------------+---------------------
    2 |                2 |          2 | 2006-02-15 09:57:12        
        
        The only row where the store_id = 2 is row 2.  Only row 2 is kept and all others are dropped.
        
### 10 WHERE NOT equal conditions 

    dvdrental=# select * from store where store_id <> 2;  # <> syntactically the same as !=
    
 store_id | manager_staff_id | address_id |     last_update
----------+------------------+------------+---------------------
    1     |                1 |          1 | 2006-02-15 09:57:12       
        
        The only row where the store_id <> 2 is row 1.  Only row 1 is kept and all others are dropped.

### 10 WHERE OR condition

    dvdrental=# select * from store where manager_staff_id = 1 or store_id <> 2 or address_id = 3; 
    
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



    
## TO-DO's
 
 1.  inline tables
 2.  correlated subqueries
 3.  Binding order

      3.1  FROM
      3.2  ON
      3.3  JOIN
      3.4  WHERE
      3.5  GROUP BY
      3.6  WITH CUBE/ROLLUP
      3.7  HAVING
      3.8  SELECT
      3.9  DISTINCT
      3.10 ORDER BY
      3.11 TOP
      3.12 OFFSET/FETCH
      
  4.  dplyr comparison of select features
  5.  dplyr comparison of fetch versus where.
  6.  SQL for View table dependencies.
  7.  Add cartesian join exercise.
