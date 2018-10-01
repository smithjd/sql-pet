# Writing to the DBMS (73)






Start up the `docker-pet` container

```r
result <- system2("docker", "start sql-pet", stdout = TRUE, stderr = TRUE)
result
```

```
## [1] "sql-pet"
```


now connect to the database with R

```r
con <- wait_for_postgres(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```
## create a new table

This is an example from the DBI help file

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

## Clean up

```r
dbRemoveTable(con, "cars")

# diconnect from the db
dbDisconnect(con)

result <- system2("docker", "stop sql-pet", stdout = TRUE, stderr = TRUE)
result
```

```
## [1] "sql-pet"
```

