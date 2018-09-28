# Postgres Examples, part B (14)







## Verify Docker is up and running:

```r
result <- system2("docker", "version", stdout = TRUE, stderr = TRUE)
result
```

```
##  [1] "Client:"                                        
##  [2] " Version:           18.06.1-ce"                 
##  [3] " API version:       1.38"                       
##  [4] " Go version:        go1.10.3"                   
##  [5] " Git commit:        e68fc7a"                    
##  [6] " Built:             Tue Aug 21 17:21:31 2018"   
##  [7] " OS/Arch:           darwin/amd64"               
##  [8] " Experimental:      false"                      
##  [9] ""                                               
## [10] "Server:"                                        
## [11] " Engine:"                                       
## [12] "  Version:          18.06.1-ce"                 
## [13] "  API version:      1.38 (minimum version 1.12)"
## [14] "  Go version:       go1.10.3"                   
## [15] "  Git commit:       e68fc7a"                    
## [16] "  Built:            Tue Aug 21 17:29:02 2018"   
## [17] "  OS/Arch:          linux/amd64"                
## [18] "  Experimental:     true"
```
verify pet DB is available, it may be stopped.

```r
result <- system2("docker", "ps -a", stdout = TRUE, stderr = TRUE)
result
```

```
## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                     PORTS               NAMES"    
## [2] "df141df324e0        postgres:10         \"docker-entrypoint.s…\"   31 seconds ago      Exited (0) 2 seconds ago                       sql-pet"
```

```r
any(grepl('Up .+pet$',result))
```

```
## [1] FALSE
```
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


```r
## meta data: check existence of a table
rs1 <- dbGetQuery(con
                 ,"SELECT c.* 
                     FROM pg_catalog.pg_class c
                     JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                    WHERE  n.nspname = 'public'
                      AND  c.relname = 'cust_movies'
                      AND  c.relkind = 'r'
                   ;
                 "
                 )
head(rs1)
```

```
##  [1] relname             relnamespace        reltype            
##  [4] reloftype           relowner            relam              
##  [7] relfilenode         reltablespace       relpages           
## [10] reltuples           relallvisible       reltoastrelid      
## [13] relhasindex         relisshared         relpersistence     
## [16] relkind             relnatts            relchecks          
## [19] relhasoids          relhaspkey          relhasrules        
## [22] relhastriggers      relhassubclass      relrowsecurity     
## [25] relforcerowsecurity relispopulated      relreplident       
## [28] relispartition      relfrozenxid        relminmxid         
## [31] relacl              reloptions          relpartbound       
## <0 rows> (or 0-length row.names)
```



```r
## create table via SQL statement
rs <- dbGetQuery(con
                ,'CREATE TABLE cust_movies AS
                    select c.customer_id
                          ,first_name
                          ,last_name,title
                          ,description
                      from customer c join rental r on c.customer_id = r.customer_id
                        join inventory i on r.inventory_id = i.inventory_id 
                        join film f on i.film_id = f.film_id 
                    order by last_name,first_name;
                 '
                )
```

```
## Warning in result_fetch(res@ptr, n = n): Don't need to call dbFetch() for
## statements, only for queries
```

```r
head(rs)
```

```
## data frame with 0 columns and 0 rows
```
Moved the following lines from #13

```r
## how many customers are there in the DVD Rental System
rs1 <- dbGetQuery(con,'select * from customer;')
kable(head(rs1))
```


\begin{tabular}{r|r|l|l|l|r|l|l|l|r}
\hline
customer\_id & store\_id & first\_name & last\_name & email & address\_id & activebool & create\_date & last\_update & active\\
\hline
524 & 1 & Jared & Ely & jared.ely@sakilacustomer.org & 530 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
1 & 1 & Mary & Smith & mary.smith@sakilacustomer.org & 5 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
2 & 1 & Patricia & Johnson & patricia.johnson@sakilacustomer.org & 6 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
3 & 1 & Linda & Williams & linda.williams@sakilacustomer.org & 7 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
4 & 2 & Barbara & Jones & barbara.jones@sakilacustomer.org & 8 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
5 & 1 & Elizabeth & Brown & elizabeth.brown@sakilacustomer.org & 9 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
\end{tabular}

```r
pco <- dbSendQuery(con,'select * from customer;')
rs2  <- dbFetch(pco)
dbClearResult(pco)
kable(head(rs2))
```


\begin{tabular}{r|r|l|l|l|r|l|l|l|r}
\hline
customer\_id & store\_id & first\_name & last\_name & email & address\_id & activebool & create\_date & last\_update & active\\
\hline
524 & 1 & Jared & Ely & jared.ely@sakilacustomer.org & 530 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
1 & 1 & Mary & Smith & mary.smith@sakilacustomer.org & 5 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
2 & 1 & Patricia & Johnson & patricia.johnson@sakilacustomer.org & 6 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
3 & 1 & Linda & Williams & linda.williams@sakilacustomer.org & 7 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
4 & 2 & Barbara & Jones & barbara.jones@sakilacustomer.org & 8 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
5 & 1 & Elizabeth & Brown & elizabeth.brown@sakilacustomer.org & 9 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
\end{tabular}



```r
pco <- dbSendQuery(con,"select * from customer where customer_id between $1 and $2")
dbBind(pco,list(501,525))
rs2  <- dbFetch(pco)
dbClearResult(pco)
kable(head(rs2))
```


\begin{tabular}{r|r|l|l|l|r|l|l|l|r}
\hline
customer\_id & store\_id & first\_name & last\_name & email & address\_id & activebool & create\_date & last\_update & active\\
\hline
524 & 1 & Jared & Ely & jared.ely@sakilacustomer.org & 530 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
501 & 1 & Ruben & Geary & ruben.geary@sakilacustomer.org & 506 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
502 & 1 & Brett & Cornwell & brett.cornwell@sakilacustomer.org & 507 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
503 & 1 & Angel & Barclay & angel.barclay@sakilacustomer.org & 508 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
504 & 1 & Nathaniel & Adam & nathaniel.adam@sakilacustomer.org & 509 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
505 & 1 & Rafael & Abney & rafael.abney@sakilacustomer.org & 510 & TRUE & 2006-02-14 & 2013-05-26 14:49:45 & 1\\
\hline
\end{tabular}


```r
rs1 <- dbGetQuery(con,
                "explain select r.*
                   from rental r 
                 ;"
                )  
head(rs1)
```

```
##                                                      QUERY PLAN
## 1 Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=36)
```

```r
rs2 <- dbGetQuery(con,
                "explain select count(*) count
                   from rental r 
                        left outer join payment p 
                          on r.rental_id = p.rental_id  
                    where p.rental_id is null
                 ;")
head(rs2)
```

```
##                                                                                                QUERY PLAN
## 1                                                       Aggregate  (cost=2086.78..2086.80 rows=1 width=8)
## 2                                             ->  Merge Anti Join  (cost=0.57..2066.73 rows=8022 width=0)
## 3                                                                 Merge Cond: (r.rental_id = p.rental_id)
## 4              ->  Index Only Scan using rental_pkey on rental r  (cost=0.29..1024.95 rows=16044 width=4)
## 5         ->  Index Only Scan using idx_fk_rental_id on payment p  (cost=0.29..819.23 rows=14596 width=4)
```

```r
rs3 <- dbGetQuery(con,
                "explain select sum(f.rental_rate) open_amt,count(*) count
                   from rental r 
                        left outer join payment p 
                          on r.rental_id = p.rental_id 
                        join inventory i
                          on r.inventory_id = i.inventory_id
                        join film f
                          on i.film_id = f.film_id
                    where p.rental_id is null
                 ;")
head(rs3)
```

```
##                                                                  QUERY PLAN
## 1                        Aggregate  (cost=2353.64..2353.65 rows=1 width=40)
## 2                  ->  Hash Join  (cost=205.14..2313.53 rows=8022 width=12)
## 3                                        Hash Cond: (i.film_id = f.film_id)
## 4                   ->  Hash Join  (cost=128.64..2215.88 rows=8022 width=2)
## 5                              Hash Cond: (r.inventory_id = i.inventory_id)
## 6               ->  Merge Anti Join  (cost=0.57..2066.73 rows=8022 width=4)
```

```r
rs4 <- dbGetQuery(con,
                "explain select c.customer_id,c.first_name,c.last_name,sum(f.rental_rate) open_amt,count(*) count
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
                 ;"
                )  
head(rs4)
```

```
##                                                          QUERY PLAN
## 1                  Sort  (cost=2452.49..2453.99 rows=599 width=260)
## 2                               Sort Key: (sum(f.rental_rate)) DESC
## 3     ->  HashAggregate  (cost=2417.37..2424.86 rows=599 width=260)
## 4                                          Group Key: c.customer_id
## 5         ->  Hash Join  (cost=227.62..2357.21 rows=8022 width=232)
## 6                        Hash Cond: (r.customer_id = c.customer_id)
```

## SQL Execution Steps

*  Parse the incoming SQL query
*  Compile the SQL query
*  Plan/optimize the data acquisition path
*  Execute the optimized query / acquire and return data


```r
dbWriteTable(con, "mtcars", mtcars, overwrite = TRUE)
rs <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
dbFetch(rs)
```

```
##     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
## 1  22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
## 2  24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
## 3  22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
## 4  32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
## 5  30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
## 6  33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
## 7  21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
## 8  27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
## 9  26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
## 10 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
## 11 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2
```

```r
dbClearResult(rs)
```


```r
#Pass one set of values with the param argument:
rs <- dbSendQuery(con,"SELECT * FROM mtcars WHERE cyl = 4")
dbFetch(rs)
```

```
##     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
## 1  22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
## 2  24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
## 3  22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
## 4  32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
## 5  30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
## 6  33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
## 7  21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
## 8  27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
## 9  26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
## 10 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
## 11 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2
```

```r
dbClearResult(rs)

# Pass multiple sets of values with dbBind():
rs <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = $1")
dbBind(rs, list(6L)) # cyl = 6
dbFetch(rs)
```

```
##    mpg cyl  disp  hp drat    wt  qsec vs am gear carb
## 1 21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
## 2 21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
## 3 21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
## 4 18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
## 5 19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
## 6 17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
## 7 19.7   6 145.0 175 3.62 2.770 15.50  0  1    5    6
```

```r
dbBind(rs, list(8L)) # cyl = 8
dbFetch(rs)
```

```
##     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
## 1  18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
## 2  14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
## 3  16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
## 4  17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
## 5  15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
## 6  10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
## 7  10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
## 8  14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
## 9  15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
## 10 15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
## 11 13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
## 12 19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
## 13 15.8   8 351.0 264 4.22 3.170 14.50  0  1    5    4
## 14 15.0   8 301.0 335 3.54 3.570 14.60  0  1    5    8
```

```r
dbClearResult(rs)
```

This is an example from the DBI help file

```r
dbWriteTable(con, "cars", head(cars, 3)) # not to be confused with mtcars
dbReadTable(con, "cars")   # there are 3 rows
```

```
##   speed dist
## 1     4    2
## 2     4   10
## 3     7    4
```

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
 
Clean up

```r
dbRemoveTable(con, "cars")
dbRemoveTable(con, "mtcars")
dbRemoveTable(con, "cust_movies")

# diconnect from the db
dbDisconnect(con)

result <- system2("docker", "stop sql-pet", stdout = TRUE, stderr = TRUE)
result
```

```
## [1] "sql-pet"
```

