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
<<<<<<< HEAD
## [1] "CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                     PORTS               NAMES"                  
## [2] "79707c17d50b        postgres-dvdrental   \"docker-entrypoint.s…\"   23 seconds ago      Exited (0) 2 seconds ago                       sql-pet"              
## [3] "424d4c3dfc89        rstats               \"/init\"                  5 days ago          Exited (0) 5 days ago                          containers_rstats_1"  
## [4] "4c3eb1dc5043        postgis              \"docker-entrypoint.s…\"   5 days ago          Exited (0) 5 days ago                          containers_postgis_1" 
## [5] "8da9d3a59732        dpage/pgadmin4       \"/entrypoint.sh\"         5 days ago          Exited (0) 5 days ago                          containers_pgadmin4_1"
## [6] "7030e81489b8        2feef91d6764         \"/bin/sh -c 'su - rs…\"   5 days ago          Exited (1) 5 days ago                          laughing_johnson"
=======
## [1] "CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                     PORTS               NAMES"    
## [2] "5168f9441a09        postgres-dvdrental   \"docker-entrypoint.s…\"   14 seconds ago      Exited (0) 2 seconds ago                       sql-pet"
>>>>>>> compile-book
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



<<<<<<< HEAD
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

<!--html_preserve--><div id="htmlwidget-e1f14d65f87a4bac06d0" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-e1f14d65f87a4bac06d0">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[524,1,2,3,4,5],[1,1,1,1,2,1],["Jared","Mary","Patricia","Linda","Barbara","Elizabeth"],["Ely","Smith","Johnson","Williams","Jones","Brown"],["jared.ely@sakilacustomer.org","mary.smith@sakilacustomer.org","patricia.johnson@sakilacustomer.org","linda.williams@sakilacustomer.org","barbara.jones@sakilacustomer.org","elizabeth.brown@sakilacustomer.org"],[530,5,6,7,8,9],[true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
pco <- dbSendQuery(con, 'select * from customer;')
rs2  <- dbFetch(pco)
dbClearResult(pco)
sp_print_df(head(rs2))
```

<!--html_preserve--><div id="htmlwidget-6417216b25c47479bf7f" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6417216b25c47479bf7f">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[524,1,2,3,4,5],[1,1,1,1,2,1],["Jared","Mary","Patricia","Linda","Barbara","Elizabeth"],["Ely","Smith","Johnson","Williams","Jones","Brown"],["jared.ely@sakilacustomer.org","mary.smith@sakilacustomer.org","patricia.johnson@sakilacustomer.org","linda.williams@sakilacustomer.org","barbara.jones@sakilacustomer.org","elizabeth.brown@sakilacustomer.org"],[530,5,6,7,8,9],[true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

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
=======
>>>>>>> compile-book
## Joins

Anti joins

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-f75d835d4e31fb720d60" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f75d835d4e31fb720d60">{"x":{"filter":"none","data":[["1"],["Sophie"],["Yang"],["dodreamdo@yahoo.com"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
>>>>>>> compile-book
### Union

#### how many films and languages exist in the DVD rental application

```r
rs <- dbGetQuery(con,
                "      select 'film' table_name,count(*) count from film 
                 union select 'language' table_name,count(*) count from language 
               ;
                "
                )
sp_print_df(head(rs))
```

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-f673079bf526b80a60c4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f673079bf526b80a60c4">{"x":{"filter":"none","data":[["1","2"],["film","language"],[1000,6]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-1d9f9b9fdca3023baa83" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1d9f9b9fdca3023baa83">{"x":{"filter":"none","data":[["1","2"],["film","language"],[1000,6]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>table_name<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book

#### what is the film distribution based on language

```r
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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-9e037b28e618f08dfd31" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-9e037b28e618f08dfd31">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,5,6,2,3,4],["English             ","French              ","German              ","Italian             ","Japanese            ","Mandarin            "],[1000,0,0,0,0,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>name<\/th>\n      <th>total<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-b18b48ec4ad649442f3b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b18b48ec4ad649442f3b">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,5,6,2,3,4],["English             ","French              ","German              ","Italian             ","Japanese            ","Mandarin            "],[1000,0,0,0,0,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>name<\/th>\n      <th>total<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book

## Store analysis
### which store has had more rentals and income


```r
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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-dd089404cbf409ba4af3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-dd089404cbf409ba4af3">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["actor","address","category","city","country","customer"],[200,603,16,600,109,600]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>tbl_name<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-514d280a38cf86ead40b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-514d280a38cf86ead40b">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["actor","address","category","city","country","customer"],[200,603,16,600,109,599]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>tbl_name<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book

## Store analysis

### which store has the largest income stream?

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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-448ea87e412b4db1ea1c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-448ea87e412b4db1ea1c">{"x":{"filter":"none","data":[["1","2"],[2,1],[31059.92,30252.12],[7304,7292]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>amt<\/th>\n      <th>cnt<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-74434d812ec23342fdce" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-74434d812ec23342fdce">{"x":{"filter":"none","data":[["1","2"],[2,1],[31059.92,30252.12],[7304,7292]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>amt<\/th>\n      <th>cnt<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book


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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-5f6f946c614a9f9f5949" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5f6f946c614a9f9f5949">{"x":{"filter":"none","data":[["1"],[1452],[14596],[61312.04],[16048],[4.2],[6098.4]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>missing<\/th>\n      <th>found<\/th>\n      <th>amt<\/th>\n      <th>cnt<\/th>\n      <th>avg_price<\/th>\n      <th>est_balance<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-8da54f9f5480ad7c3ec3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8da54f9f5480ad7c3ec3">{"x":{"filter":"none","data":[["1"],[1452],[14596],[61312.04],[16048],[4.2],[6098.4]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>missing<\/th>\n      <th>found<\/th>\n      <th>amt<\/th>\n      <th>cnt<\/th>\n      <th>avg_price<\/th>\n      <th>est_balance<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book

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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-afe62f23cd3051b52907" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-afe62f23cd3051b52907">{"x":{"filter":"none","data":[["1"],[4297.48],[1452]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-124fb78127817ec02cd9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-124fb78127817ec02cd9">{"x":{"filter":"none","data":[["1"],[4297.48],[1452]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book

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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-cc09f8ad6acdc0919459" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-cc09f8ad6acdc0919459">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[293,307,316,299,274,326],["Mae","Joseph","Steven","James","Naomi","Jose"],["Fletcher","Joy","Curley","Gannon","Jennings","Andrew"],[35.9,31.9,31.9,30.91,29.92,28.93],[10,10,10,9,8,7]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-dd0a51033db44e820d90" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-dd0a51033db44e820d90">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[293,307,316,299,274,326],["Mae","Joseph","Steven","James","Naomi","Jose"],["Fletcher","Joy","Curley","Gannon","Jennings","Andrew"],[35.9,31.9,31.9,30.91,29.92,28.93],[10,10,10,9,8,7]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book
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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-82463f881c24354c8a23" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-82463f881c24354c8a23">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[103,738,382,767,489,730],["Bucket Brotherhood","Rocketeer Mother","Grit Clockwork","Scalawag Duck","Juggler Hardly","Ridgemont Submarine"],[4.99,0.99,0.99,4.99,0.99,0.99],[169.66,32.67,31.68,159.68,31.68,31.68],[34,33,32,32,32,32]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>revenue<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-1fe403c81784621152ab" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1fe403c81784621152ab">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[103,738,382,767,489,730],["Bucket Brotherhood","Rocketeer Mother","Grit Clockwork","Scalawag Duck","Juggler Hardly","Ridgemont Submarine"],[4.99,0.99,0.99,4.99,0.99,0.99],[169.66,32.67,31.68,159.68,31.68,31.68],[34,33,32,32,32,32]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>revenue<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book

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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-87dee05b9c038333a572" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-87dee05b9c038333a572">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[103,767,973,31,369,1000],["Bucket Brotherhood","Scalawag Duck","Wife Turn","Apache Divine","Goodfellas Salute","Zorro Ark"],[4.99,4.99,4.99,4.99,4.99,4.99],[169.66,159.68,154.69,154.69,154.69,154.69],[34,32,31,31,31,31]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>revenue<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-ed78248b32e6634f28e5" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-ed78248b32e6634f28e5">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[103,767,973,31,369,1000],["Bucket Brotherhood","Scalawag Duck","Wife Turn","Apache Divine","Goodfellas Salute","Zorro Ark"],[4.99,4.99,4.99,4.99,4.99,4.99],[169.66,159.68,154.69,154.69,154.69,154.69],[34,32,31,31,31,31]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>revenue<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book

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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-d368e112eb33ac250351" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d368e112eb33ac250351">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[2,3,5,8,13,20],["Ace Goldfinger","Adaptation Holes","African Egg","Airport Pollock","Ali Forever","Amelie Hellfighters"],[4.99,2.99,2.99,4.99,4.99,4.99],[null,null,null,null,null,1],[null,null,null,null,null,3],[2,2,2,2,2,null],[3,4,3,4,4,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n      <th>store_id..6<\/th>\n      <th>count..7<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-2ae622211a824c064fbd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-2ae622211a824c064fbd">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[2,3,5,8,13,20],["Ace Goldfinger","Adaptation Holes","African Egg","Airport Pollock","Ali Forever","Amelie Hellfighters"],[4.99,2.99,2.99,4.99,4.99,4.99],[null,null,null,null,null,1],[null,null,null,null,null,3],[2,2,2,2,2,null],[3,4,3,4,4,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n      <th>store_id..6<\/th>\n      <th>count..7<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book

### Compute the outstanding balance.

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

<<<<<<< HEAD
<!--html_preserve--><div id="htmlwidget-058b60e3e9fe7548571e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-058b60e3e9fe7548571e">{"x":{"filter":"none","data":[["1"],[4297.48],[1452]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
=======
<!--html_preserve--><div id="htmlwidget-09904734225327216f09" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-09904734225327216f09">{"x":{"filter":"none","data":[["1"],[4297.48],[1452]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


## Different strategies for interacting with the database


select examples
    dbGetQuery returns the entire result set as a data frame.  
        For large returned datasets, complex or inefficient SQL statements, this may take a 
        long time.

      dbSendQuery: parses, compiles, creates the optimized execution plan.  
          dbFetch: Execute optimzed execution plan and return the dataset.
    dbClearResult: remove pending query results from the database to your R environment

### Use dbGetQuery

How many customers are there in the DVD Rental System

```r
rs1 <- dbGetQuery(con, 'select * from customer;')
sp_print_df(head(rs1))
```

<!--html_preserve--><div id="htmlwidget-b619f31f38e9f2471fcc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b619f31f38e9f2471fcc">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[524,1,2,3,4,5],[1,1,1,1,2,1],["Jared","Mary","Patricia","Linda","Barbara","Elizabeth"],["Ely","Smith","Johnson","Williams","Jones","Brown"],["jared.ely@sakilacustomer.org","mary.smith@sakilacustomer.org","patricia.johnson@sakilacustomer.org","linda.williams@sakilacustomer.org","barbara.jones@sakilacustomer.org","elizabeth.brown@sakilacustomer.org"],[530,5,6,7,8,9],[true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
pco <- dbSendQuery(con, 'select * from customer;')
rs2  <- dbFetch(pco)
dbClearResult(pco)
sp_print_df(head(rs2))
```

<!--html_preserve--><div id="htmlwidget-beeafef17c4840807f51" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-beeafef17c4840807f51">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[524,1,2,3,4,5],[1,1,1,1,2,1],["Jared","Mary","Patricia","Linda","Barbara","Elizabeth"],["Ely","Smith","Johnson","Williams","Jones","Brown"],["jared.ely@sakilacustomer.org","mary.smith@sakilacustomer.org","patricia.johnson@sakilacustomer.org","linda.williams@sakilacustomer.org","barbara.jones@sakilacustomer.org","elizabeth.brown@sakilacustomer.org"],[530,5,6,7,8,9],[true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Use dbExecute

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

### anti join -- Find sophie who have never rented a movie.

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

<!--html_preserve--><div id="htmlwidget-f6a2206cea77e899a1de" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f6a2206cea77e899a1de">{"x":{"filter":"none","data":[["1"],["Sophie"],["Yang"],["dodreamdo@yahoo.com"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
>>>>>>> compile-book



```r
# diconnect from the db
dbDisconnect(con)

sp_docker_stop("sql-pet")
```

```
## [1] "sql-pet"
```


```r
knitr::knit_exit()
```



