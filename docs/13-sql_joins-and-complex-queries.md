# Joins and complex queries (13)


## Verify Docker is up and running:

```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```
verify pet DB is available, it may be stopped.

```r
sp_show_all_docker_containers()
```

```
## [1] "CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                       PORTS               NAMES"    
## [2] "fea37155e415        postgres-dvdrental   \"docker-entrypoint.s…\"   25 seconds ago      Exited (137) 2 seconds ago                       sql-pet"
```
Start up the `docker-pet` container

```r
sp_docker_start("sql-pet")
```


now connect to the database with R

```r
# need to wait for Docker & Postgres to come up before connecting.

con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```


```r
## select examples
##    dbGetQuery returns the entire result set as a data frame.  
##        For large returned datasets, complex or inefficient SQL statements, this may take a 
##        long time.

##      dbSendQuery: parses, compiles, creates the optimized execution plan.  
##          dbFetch: Execute optimzed execution plan and return the dataset.
##    dbClearResult:remove pending query results from the database to your R environment
```

How many customers are there in the DVD Rental System

```r
rs1 <- dbGetQuery(con, 'select * from customer;')
kable(head(rs1))
```



 customer_id   store_id  first_name   last_name   email                                  address_id  activebool   create_date   last_update            active
------------  ---------  -----------  ----------  ------------------------------------  -----------  -----------  ------------  --------------------  -------
         524          1  Jared        Ely         jared.ely@sakilacustomer.org                  530  TRUE         2006-02-14    2013-05-26 14:49:45         1
           1          1  Mary         Smith       mary.smith@sakilacustomer.org                   5  TRUE         2006-02-14    2013-05-26 14:49:45         1
           2          1  Patricia     Johnson     patricia.johnson@sakilacustomer.org             6  TRUE         2006-02-14    2013-05-26 14:49:45         1
           3          1  Linda        Williams    linda.williams@sakilacustomer.org               7  TRUE         2006-02-14    2013-05-26 14:49:45         1
           4          2  Barbara      Jones       barbara.jones@sakilacustomer.org                8  TRUE         2006-02-14    2013-05-26 14:49:45         1
           5          1  Elizabeth    Brown       elizabeth.brown@sakilacustomer.org              9  TRUE         2006-02-14    2013-05-26 14:49:45         1

```r
pco <- dbSendQuery(con, 'select * from customer;')
rs2  <- dbFetch(pco)
dbClearResult(pco)
kable(head(rs2))
```



 customer_id   store_id  first_name   last_name   email                                  address_id  activebool   create_date   last_update            active
------------  ---------  -----------  ----------  ------------------------------------  -----------  -----------  ------------  --------------------  -------
         524          1  Jared        Ely         jared.ely@sakilacustomer.org                  530  TRUE         2006-02-14    2013-05-26 14:49:45         1
           1          1  Mary         Smith       mary.smith@sakilacustomer.org                   5  TRUE         2006-02-14    2013-05-26 14:49:45         1
           2          1  Patricia     Johnson     patricia.johnson@sakilacustomer.org             6  TRUE         2006-02-14    2013-05-26 14:49:45         1
           3          1  Linda        Williams    linda.williams@sakilacustomer.org               7  TRUE         2006-02-14    2013-05-26 14:49:45         1
           4          2  Barbara      Jones       barbara.jones@sakilacustomer.org                8  TRUE         2006-02-14    2013-05-26 14:49:45         1
           5          1  Elizabeth    Brown       elizabeth.brown@sakilacustomer.org              9  TRUE         2006-02-14    2013-05-26 14:49:45         1


```r
# insert yourself as a new customer
dbExecute(con,
  "insert into customer 
  (store_id,first_name,last_name,email,address_id
  ,activebool,create_date,last_update,active)
  values(2,'Sophie','Yang','dodreamdo@yahoo.com',1,TRUE,'2018-09-13','2018-09-13',1)
  returning customer_id;
  "
  )
```

```
## [1] 0
```


```r
## anti join -- Find customers who have never rented a movie.

rs <- dbGetQuery(con,
                 "select c.first_name
                        ,c.last_name
                        ,c.email
                    from customer c 
                         left outer join rental r
                              on c.customer_id = r.customer_id 
                   where r.rental_id is null;
                 "
                 )
head(rs)
```

```
##   first_name last_name               email
## 1     Sophie      Yang dodreamdo@yahoo.com
```


```r
## how many films and languages exist in the DVD rental application
rs <- dbGetQuery(con,
                "      select 'film' table_name,count(*) count from film 
                 union select 'language' table_name,count(*) count from language 
               ;
                "
                )
head(rs)
```

```
##   table_name count
## 1       film  1000
## 2   language     6
```

```r
## what is the film distribution based on language

rs <- dbGetQuery(con,
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
head(rs)
```

```
##   id                 name total
## 1  1 English               1000
## 2  5 French                   0
## 3  6 German                   0
## 4  2 Italian                  0
## 5  3 Japanese                 0
## 6  4 Mandarin                 0
```


```r
## Store analysis
### which store has had more rentals and income
rs <- dbGetQuery(con,
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
head(rs)
```

```
##   tbl_name count
## 1    actor   200
## 2  address   603
## 3 category    16
## 4     city   600
## 5  country   109
## 6 customer   600
```


```r
## Store analysis
### which store has the largest income stream
rs <- dbGetQuery(con,
                "select store_id,sum(amount) amt,count(*) cnt 
                   from payment p 
                        join staff s 
                          on p.staff_id = s.staff_id  
                 group by store_id order by 2 desc
                 ;
                "
                )
head(rs)
```

```
##   store_id      amt  cnt
## 1        2 31059.92 7304
## 2        1 30252.12 7292
```


```r
## Store analysis
### How many rentals have not been paid
### How many rentals have been paid
### How much has been paid
### What is the average price/movie
### Estimate the outstanding balance
rs <- dbGetQuery(con,
                "select sum(case when payment_id is null then 1 else 0 end) missing
                       ,sum(case when payment_id is not null then 1 else 0 end) found
                       ,sum(p.amount) amt
                       ,count(*) cnt 
                       ,round(sum(p.amount)/sum(case when payment_id is not null then 1 else 0 end),2) avg_price
                       ,round(round(sum(p.amount)/sum(case when payment_id is not null then 1 else 0 end),2)
                                  * sum(case when payment_id is null then 1 else 0 end),2) est_balance
                   from rental r 
                        left outer join payment p 
                          on r.rental_id = p.rental_id  
                 ;
                "
                )
head(rs)
```

```
##   missing found      amt   cnt avg_price est_balance
## 1    1452 14596 61312.04 16048       4.2      6098.4
```


```r
### what is the actual outstanding balance

rs <- dbGetQuery(con,
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
head(rs)
```

```
##   open_amt count
## 1  4297.48  1452
```


```r
### Rank customers with highest open amounts

rs <- dbGetQuery(con,
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
head(rs)
```

```
##   customer_id first_name last_name open_amt count
## 1         293        Mae  Fletcher    35.90    10
## 2         307     Joseph       Joy    31.90    10
## 3         316     Steven    Curley    31.90    10
## 4         299      James    Gannon    30.91     9
## 5         274      Naomi  Jennings    29.92     8
## 6         326       Jose    Andrew    28.93     7
```


```r
### what film has been rented the most
rs <- dbGetQuery(con,
                "select i.film_id,f.title,rental_rate,sum(rental_rate) revenue,count(*) count  --16044
                   from rental r 
                        join inventory i
                          on r.inventory_id = i.inventory_id
                        join film f
                          on i.film_id = f.film_id
                 group by i.film_id,f.title,rental_rate
                 order by count desc
                 ;"
                )  
head(rs)
```

```
##   film_id               title rental_rate revenue count
## 1     103  Bucket Brotherhood        4.99  169.66    34
## 2     738    Rocketeer Mother        0.99   32.67    33
## 3     382      Grit Clockwork        0.99   31.68    32
## 4     767       Scalawag Duck        4.99  159.68    32
## 5     489      Juggler Hardly        0.99   31.68    32
## 6     730 Ridgemont Submarine        0.99   31.68    32
```


```r
### what film has been generated the most revenue assuming all amounts are collected
rs <- dbGetQuery(con,
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
head(rs)
```

```
##   film_id              title rental_rate revenue count
## 1     103 Bucket Brotherhood        4.99  169.66    34
## 2     767      Scalawag Duck        4.99  159.68    32
## 3     973          Wife Turn        4.99  154.69    31
## 4      31      Apache Divine        4.99  154.69    31
## 5     369  Goodfellas Salute        4.99  154.69    31
## 6    1000          Zorro Ark        4.99  154.69    31
```


```r
### which films are in one store but not the other.
rs <- dbGetQuery(con,
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
head(rs)
```

```
##   film_id               title rental_rate store_id count store_id..6
## 1       2      Ace Goldfinger        4.99       NA  <NA>           2
## 2       3    Adaptation Holes        2.99       NA  <NA>           2
## 3       5         African Egg        2.99       NA  <NA>           2
## 4       8     Airport Pollock        4.99       NA  <NA>           2
## 5      13         Ali Forever        4.99       NA  <NA>           2
## 6      20 Amelie Hellfighters        4.99        1     3          NA
##   count..7
## 1        3
## 2        4
## 3        3
## 4        4
## 5        4
## 6     <NA>
```


```r
# Compute the outstanding balance.
rs <- dbGetQuery(con,
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
head(rs)
```

```
##   open_amt count
## 1  4297.48  1452
```
list what's there

```r
dbListTables(con)
```

```
##  [1] "actor_info"                 "customer_list"             
##  [3] "film_list"                  "nicer_but_slower_film_list"
##  [5] "sales_by_film_category"     "staff"                     
##  [7] "sales_by_store"             "staff_list"                
##  [9] "category"                   "film_category"             
## [11] "country"                    "actor"                     
## [13] "language"                   "inventory"                 
## [15] "payment"                    "rental"                    
## [17] "city"                       "store"                     
## [19] "film"                       "address"                   
## [21] "film_actor"                 "customer"
```

Clean up

```r
# dbRemoveTable(con, "cars")
# dbRemoveTable(con, "mtcars")
# dbRemoveTable(con, "cust_movies")

# diconnect from the db
dbDisconnect(con)

sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```
