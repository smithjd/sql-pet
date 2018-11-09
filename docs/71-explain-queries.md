# Explain queries (71)



* examining `dplyr` queries (`dplyr::show_query` on the R side v EXPLAIN on the PostgreSQL side)

Start up the `docker-pet` container

```r
sp_docker_start("sql-pet")
```


now connect to the database with R

```r
con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```

## Performance considerations


```r
## Explain a `dplyr::join`

## Explain the quivalent SQL join
rs1 <- DBI::dbGetQuery(con
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

This came from 14-sql_pet-examples-part-b.Rmd

```r
rs1 <- DBI::dbGetQuery(con,
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
rs2 <- DBI::dbGetQuery(con,
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
rs3 <- DBI::dbGetQuery(con,
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
rs4 <- DBI::dbGetQuery(con,
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

## Clean up

```r
# dbRemoveTable(con, "cars")
# dbRemoveTable(con, "mtcars")
# dbRemoveTable(con, "cust_movies")

# diconnect from the db
dbDisconnect(con)

sp_docker_stop("sql-pet")
```

