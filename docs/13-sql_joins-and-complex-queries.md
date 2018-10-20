# Joins and complex queries (13)



Verify Docker is up and running:

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
## [1] "CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                     PORTS               NAMES"    
## [2] "55ba7582259a        postgres-dvdrental   \"docker-entrypoint.s…\"   24 seconds ago      Exited (0) 2 seconds ago                       sql-pet"
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
discuss this simple example? http://www.postgresqltutorial.com/postgresql-left-join/ 

* `dplyr` joins on the server side
* Where you put `(collect(n = Inf))` really matters



## Different strategies for interacting with the database


select examples
    dbGetQuery returns the entire result set as a data frame.  
        For large returned datasets, complex or inefficient SQL statements, this may take a 
        long time.

      dbSendQuery: parses, compiles, creates the optimized execution plan.  
          dbFetch: Execute optimzed execution plan and return the dataset.
    dbClearResult: remove pending query results from the database to your R environment

## Use dbGetQuery

How many customers are there in the DVD Rental System

```r
rs1 <- dbGetQuery(con, 'select * from customer;')
sp_print_df(head(rs1))
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
pco <- dbSendQuery(con, 'select * from customer;')
rs2  <- dbFetch(pco)
dbClearResult(pco)
sp_print_df(head(rs2))
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

## Use dbExecute

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
## Joins
### anti join -- Find customers who have never rented a movie.

```r
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
sp_print_df(head(rs))
```


\begin{tabular}{l|l|l}
\hline
first\_name & last\_name & email\\
\hline
Sophie & Yang & dodreamdo@yahoo.com\\
\hline
\end{tabular}
### Union

how many films and languages exist in the DVD rental application

```r
rs <- dbGetQuery(con,
                "      select 'film' table_name,count(*) count from film 
                 union select 'language' table_name,count(*) count from language 
               ;
                "
                )
sp_print_df(head(rs))
```


\begin{tabular}{l|r}
\hline
table\_name & count\\
\hline
film & 1000\\
\hline
language & 6\\
\hline
\end{tabular}

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
sp_print_df(head(rs))
```


\begin{tabular}{r|l|r}
\hline
id & name & total\\
\hline
1 & English & 1000\\
\hline
5 & French & 0\\
\hline
6 & German & 0\\
\hline
2 & Italian & 0\\
\hline
3 & Japanese & 0\\
\hline
4 & Mandarin & 0\\
\hline
\end{tabular}



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
sp_print_df(head(rs))
```


\begin{tabular}{l|r}
\hline
tbl\_name & count\\
\hline
actor & 200\\
\hline
address & 603\\
\hline
category & 16\\
\hline
city & 600\\
\hline
country & 109\\
\hline
customer & 600\\
\hline
\end{tabular}

## Store analysis

### which store has the largest income stream

```r
rs <- dbGetQuery(con,
                "select store_id,sum(amount) amt,count(*) cnt 
                   from payment p 
                        join staff s 
                          on p.staff_id = s.staff_id  
                 group by store_id order by 2 desc
                 ;
                "
                )
sp_print_df(head(rs))
```


\begin{tabular}{r|r|r}
\hline
store\_id & amt & cnt\\
\hline
2 & 31059.92 & 7304\\
\hline
1 & 30252.12 & 7292\\
\hline
\end{tabular}


### How many rentals have not been paid
### How many rentals have been paid
### How much has been paid
### What is the average price/movie
### Estimate the outstanding balance


```r
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
sp_print_df(head(rs))
```


\begin{tabular}{r|r|r|r|r|r}
\hline
missing & found & amt & cnt & avg\_price & est\_balance\\
\hline
1452 & 14596 & 61312.04 & 16048 & 4.2 & 6098.4\\
\hline
\end{tabular}

### what is the actual outstanding balance

```r
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
sp_print_df(head(rs))
```


\begin{tabular}{r|r}
\hline
open\_amt & count\\
\hline
4297.48 & 1452\\
\hline
\end{tabular}

### Rank customers with highest open amounts


```r
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
sp_print_df(head(rs))
```


\begin{tabular}{r|l|l|r|r}
\hline
customer\_id & first\_name & last\_name & open\_amt & count\\
\hline
293 & Mae & Fletcher & 35.90 & 10\\
\hline
307 & Joseph & Joy & 31.90 & 10\\
\hline
316 & Steven & Curley & 31.90 & 10\\
\hline
299 & James & Gannon & 30.91 & 9\\
\hline
274 & Naomi & Jennings & 29.92 & 8\\
\hline
326 & Jose & Andrew & 28.93 & 7\\
\hline
\end{tabular}
### what film has been rented the most

```r
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
sp_print_df(head(rs))
```


\begin{tabular}{r|l|r|r|r}
\hline
film\_id & title & rental\_rate & revenue & count\\
\hline
103 & Bucket Brotherhood & 4.99 & 169.66 & 34\\
\hline
738 & Rocketeer Mother & 0.99 & 32.67 & 33\\
\hline
382 & Grit Clockwork & 0.99 & 31.68 & 32\\
\hline
767 & Scalawag Duck & 4.99 & 159.68 & 32\\
\hline
489 & Juggler Hardly & 0.99 & 31.68 & 32\\
\hline
730 & Ridgemont Submarine & 0.99 & 31.68 & 32\\
\hline
\end{tabular}

### what film has been generated the most revenue assuming all amounts are collected

```r
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
sp_print_df(head(rs))
```


\begin{tabular}{r|l|r|r|r}
\hline
film\_id & title & rental\_rate & revenue & count\\
\hline
103 & Bucket Brotherhood & 4.99 & 169.66 & 34\\
\hline
767 & Scalawag Duck & 4.99 & 159.68 & 32\\
\hline
973 & Wife Turn & 4.99 & 154.69 & 31\\
\hline
31 & Apache Divine & 4.99 & 154.69 & 31\\
\hline
369 & Goodfellas Salute & 4.99 & 154.69 & 31\\
\hline
1000 & Zorro Ark & 4.99 & 154.69 & 31\\
\hline
\end{tabular}

### which films are in one store but not the other.

```r
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
sp_print_df(head(rs))
```


\begin{tabular}{r|l|r|r|r|r|r}
\hline
film\_id & title & rental\_rate & store\_id & count & store\_id..6 & count..7\\
\hline
2 & Ace Goldfinger & 4.99 & NA & NA & 2 & 3\\
\hline
3 & Adaptation Holes & 2.99 & NA & NA & 2 & 4\\
\hline
5 & African Egg & 2.99 & NA & NA & 2 & 3\\
\hline
8 & Airport Pollock & 4.99 & NA & NA & 2 & 4\\
\hline
13 & Ali Forever & 4.99 & NA & NA & 2 & 4\\
\hline
20 & Amelie Hellfighters & 4.99 & 1 & 3 & NA & NA\\
\hline
\end{tabular}

## Compute the outstanding balance.

```r
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
sp_print_df(head(rs))
```


\begin{tabular}{r|r}
\hline
open\_amt & count\\
\hline
4297.48 & 1452\\
\hline
\end{tabular}



```r
# diconnect from the db
dbDisconnect(con)

sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```

