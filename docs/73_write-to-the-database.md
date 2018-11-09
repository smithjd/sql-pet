# Writing to the DBMS (73)

At the end of this chapter, you will be able to 

  * Write queries in R using docker container.
  * Start and connect to the database with R.
  * Create, Modify, and remove the table.


Start up the `docker-pet` container:


```r
sp_docker_start("sql-pet")
```


Now connect to the database with R using your login info:

```r
con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```
## Create a new table

This is an example from the DBI help file.


```r
dbWriteTable(con, "cars", head(cars, 3)) # "cars" is a built-in dataset, not to be confused with mtcars

dbReadTable(con, "cars")   # there are 3 rows
```

```
##   speed dist
## 1     4    2
## 2     4   10
## 3     7    4
```
## Modify an existing table

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

```r
dbReadTable(con, "cars")   # there are now 6 rows
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

```r
# Pass values using the param argument:
dbExecute(
  con,
  "INSERT INTO cars (speed, dist) VALUES ($1, $2)",
  param = list(4:7, 5:8)
)
```

```
## [1] 4
```

```r
dbReadTable(con, "cars")   # there are now 10 rows
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

## Remove table and Clean up

Here you will remove the table "cars", disconnect from the database and exit docker.


```r
dbRemoveTable(con, "cars")

# diconnect from the db
dbDisconnect(con)

sp_docker_stop("sql-pet")
```

