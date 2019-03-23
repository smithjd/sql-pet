# Writing to the DBMS {#chapter_writing-to-the-dbms}

This chapter demonstrates how to:

>
>  * Set up and connect to a `cattle` database
>  * Create, modify, and remove a database table
>

In a corporate setting, you may be creating your own tables or modifying existing tables less frequently than retrieving data. Nevertheless, in our sandbox you can easily do so.

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
require(knitr)
library(sqlpetr)
```

## Set up a `cattle` container

Check that Docker is up and running:


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```

### Remove previous containers if they exist
Remove the `cattle` and `sql-pet` containers if they exist (e.g., from prior experiments).  

```r
sp_docker_remove_container("cattle")
```

```
## [1] 0
```

```r
sp_docker_remove_container("sql-pet")
```

```
## [1] 0
```

Create a new `cattle` container:

```r
sp_make_simple_pg("cattle")
```

Show that we're ready to connect:

```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up, running these containers:"                                                                                                            
## [2] "CONTAINER ID        IMAGE               COMMAND                  CREATED                  STATUS                  PORTS                    NAMES"   
## [3] "4e79d844bf8d        postgres:10         \"docker-entrypoint.s…\"   Less than a second ago   Up Less than a second   0.0.0.0:5432->5432/tcp   cattle"
```

### Connect to PostgreSQL

Connect to PostgreSQL using the `sp_get_postgres_connection` function:

```r
con <- sp_get_postgres_connection(user = "postgres",
                         password = "postgres",
                         dbname = "postgres",
                         seconds_to_test = 30, connection_tab = TRUE
                         )
```

## Interact with PostgreSQL

Check on the contents of the database.


```r
DBI::dbListTables(con)
```

```
## character(0)
```
It does not contain any tables yet.
 
### Create a new table in the database

This is an example from the DBI help file using the "cars" built-in dataset, not to be confused with mtcars:

```r
dbWriteTable(con, "cars", head(cars, 3)) #
```

The `cars` table has 3 rows:

```r
dbReadTable(con, "cars")  
```

```
##   speed dist
## 1     4    2
## 2     4   10
## 3     7    4
```
### Modify an existing table

To add additional rows or instances to the "cars" table, we will use INSERT command with their values.

There are two different ways of adding values: list them or pass values using the param argument. 


```r
dbExecute(
  con,
  "INSERT INTO cars (speed, dist) VALUES (1, 1), (2, 2), (3, 3)"
)
```

```
## [1] 3
```

Now it has 6 rows:

```r
dbReadTable(con, "cars")
```

```
##   speed dist
## 1     4    2
## 2     4   10
## 3     7    4
## 4     1    1
## 5     2    2
## 6     3    3
```

Pass values using the param argument:

```r
dbExecute(
  con,
  "INSERT INTO cars (speed, dist) VALUES ($1, $2)",
  param = list(4:7, 5:8)
)
```

```
## [1] 4
```

Now there are 10 rows:

```r
dbReadTable(con, "cars")
```

```
##    speed dist
## 1      4    2
## 2      4   10
## 3      7    4
## 4      1    1
## 5      2    2
## 6      3    3
## 7      4    5
## 8      5    6
## 9      6    7
## 10     7    8
```

### Remove the table 

Remove the "cars"  table.


```r
dbRemoveTable(con, "cars")
```

## Clean up

Disconnect from the database:

```r
dbDisconnect(con)
```

Stop the `cattle` container, but leave it around for future use.

```r
sp_docker_stop("cattle")
```

