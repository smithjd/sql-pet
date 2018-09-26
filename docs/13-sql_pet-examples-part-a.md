# Postgres Examples, part A

Libraries loaded and functions are loaded




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
## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES"    
## [2] "e154b06bdc5a        postgres:10         \"docker-entrypoint.s…\"   26 seconds ago      Up 5 seconds        0.0.0.0:5432->5432/tcp   sql-pet"
```

```r
any(grepl('Up .+pet$',result))
```

```
## [1] TRUE
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
# need to wait for Docker & Postgres to come up before connecting.

con <- wait_for_postgres(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "dvdrental",
                         seconds_to_test = 10)
```


```r
## Get list of database objects
rs <- dbGetQuery(con
                 ,"select table_catalog,table_schema,table_name,table_type 
                     from information_schema.tables 
                    where table_schema not in ('pg_catalog','information_schema')
                   order by table_name
                  ;"
                  )
# Get list of tables 
kable(dbListTables(con))
```


\begin{tabular}{l}
\hline
x\\
\hline
actor\_info\\
\hline
customer\_list\\
\hline
film\_list\\
\hline
nicer\_but\_slower\_film\_list\\
\hline
sales\_by\_film\_category\\
\hline
staff\\
\hline
sales\_by\_store\\
\hline
staff\_list\\
\hline
category\\
\hline
film\_category\\
\hline
country\\
\hline
actor\\
\hline
language\\
\hline
inventory\\
\hline
payment\\
\hline
rental\\
\hline
city\\
\hline
store\\
\hline
film\\
\hline
address\\
\hline
film\_actor\\
\hline
customer\\
\hline
\end{tabular}


```r
rs <- dbGetQuery(con
                 ,"select table_catalog||'.'||table_schema||'.'||table_name table_name
                         ,column_name,ordinal_position seq --,data_type
                         ,case when data_type = 'character varying' 
                               then data_type || '('|| character_maximum_length||')'
                               when data_type = 'real'
                               then data_type || '(' || numeric_precision ||','||numeric_precision_radix||')'
                               else data_type
                          end data_type
--                         ,character_maximum_length,numeric_precision,numeric_precision_radix
                     from information_schema.columns
                    where table_name in (select table_name
                                           from information_schema.tables
                                         where table_schema not in ('pg_catalog','information_schema')
                                         )
                   order by table_name,ordinal_position;

                  ;"
                  )
kable(head(rs, n = 20))
```


\begin{tabular}{l|l|r|l}
\hline
table\_name & column\_name & seq & data\_type\\
\hline
dvdrental.public.actor & actor\_id & 1 & integer\\
\hline
dvdrental.public.actor & first\_name & 2 & character varying(45)\\
\hline
dvdrental.public.actor & last\_name & 3 & character varying(45)\\
\hline
dvdrental.public.actor & last\_update & 4 & timestamp without time zone\\
\hline
dvdrental.public.actor\_info & actor\_id & 1 & integer\\
\hline
dvdrental.public.actor\_info & first\_name & 2 & character varying(45)\\
\hline
dvdrental.public.actor\_info & last\_name & 3 & character varying(45)\\
\hline
dvdrental.public.actor\_info & film\_info & 4 & text\\
\hline
dvdrental.public.address & address\_id & 1 & integer\\
\hline
dvdrental.public.address & address & 2 & character varying(50)\\
\hline
dvdrental.public.address & address2 & 3 & character varying(50)\\
\hline
dvdrental.public.address & district & 4 & character varying(20)\\
\hline
dvdrental.public.address & city\_id & 5 & smallint\\
\hline
dvdrental.public.address & postal\_code & 6 & character varying(10)\\
\hline
dvdrental.public.address & phone & 7 & character varying(20)\\
\hline
dvdrental.public.address & last\_update & 8 & timestamp without time zone\\
\hline
dvdrental.public.category & category\_id & 1 & integer\\
\hline
dvdrental.public.category & name & 2 & character varying(25)\\
\hline
dvdrental.public.category & last\_update & 3 & timestamp without time zone\\
\hline
dvdrental.public.city & city\_id & 1 & integer\\
\hline
\end{tabular}
There are {r dim(rs)[1]} rows in the catalog.


```r
rs <- dbGetQuery(con,
"
--SELECT conrelid::regclass as table_from
select table_catalog||'.'||table_schema||'.'||table_name table_name
,conname,pg_catalog.pg_get_constraintdef(r.oid, true) as condef
FROM information_schema.columns c,pg_catalog.pg_constraint r
WHERE 1 = 1 --r.conrelid = '16485' 
  AND r.contype  in ('f','p') ORDER BY 1
;"
)


kable(head(rs))
```


\begin{tabular}{l|l|l}
\hline
table\_name & conname & condef\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & actor\_pkey & PRIMARY KEY (actor\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & actor\_pkey & PRIMARY KEY (actor\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & actor\_pkey & PRIMARY KEY (actor\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & country\_pkey & PRIMARY KEY (country\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & country\_pkey & PRIMARY KEY (country\_id)\\
\hline
dvdrental.information\_schema.administrable\_role\_authorizations & country\_pkey & PRIMARY KEY (country\_id)\\
\hline
\end{tabular}


```r
rs <- dbGetQuery(con,
"select conrelid::regclass as table_from
      ,c.conname
      ,pg_get_constraintdef(c.oid)
  from pg_constraint c
  join pg_namespace n on n.oid = c.connamespace
 where c.contype in ('f','p')
   and n.nspname = 'public'
order by conrelid::regclass::text, contype DESC;
")
kable(head(rs))
```


\begin{tabular}{l|l|l}
\hline
table\_from & conname & pg\_get\_constraintdef\\
\hline
actor & actor\_pkey & PRIMARY KEY (actor\_id)\\
\hline
address & address\_pkey & PRIMARY KEY (address\_id)\\
\hline
address & fk\_address\_city & FOREIGN KEY (city\_id) REFERENCES city(city\_id)\\
\hline
category & category\_pkey & PRIMARY KEY (category\_id)\\
\hline
city & city\_pkey & PRIMARY KEY (city\_id)\\
\hline
city & fk\_city & FOREIGN KEY (country\_id) REFERENCES country(country\_id)\\
\hline
\end{tabular}

```r
dim(rs)[1]
```

```
## [1] 33
```


```r
rs <- dbGetQuery(con,
"SELECT r.*,
  pg_catalog.pg_get_constraintdef(r.oid, true) as condef
FROM pg_catalog.pg_constraint r
WHERE 1=1 --r.conrelid = '16485' AND r.contype = 'f' ORDER BY 1;
")

head(rs)
```

```
##                        conname connamespace contype condeferrable
## 1 cardinal_number_domain_check        12703       c         FALSE
## 2              yes_or_no_check        12703       c         FALSE
## 3                   year_check         2200       c         FALSE
## 4                   actor_pkey         2200       p         FALSE
## 5                 address_pkey         2200       p         FALSE
## 6                category_pkey         2200       p         FALSE
##   condeferred convalidated conrelid contypid conindid confrelid
## 1       FALSE         TRUE        0    12716        0         0
## 2       FALSE         TRUE        0    12724        0         0
## 3       FALSE         TRUE        0    16397        0         0
## 4       FALSE         TRUE    16420        0    16555         0
## 5       FALSE         TRUE    16461        0    16557         0
## 6       FALSE         TRUE    16427        0    16559         0
##   confupdtype confdeltype confmatchtype conislocal coninhcount
## 1                                             TRUE           0
## 2                                             TRUE           0
## 3                                             TRUE           0
## 4                                             TRUE           0
## 5                                             TRUE           0
## 6                                             TRUE           0
##   connoinherit conkey confkey conpfeqop conppeqop conffeqop conexclop
## 1        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 2        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 3        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 4         TRUE    {1}    <NA>      <NA>      <NA>      <NA>      <NA>
## 5         TRUE    {1}    <NA>      <NA>      <NA>      <NA>      <NA>
## 6         TRUE    {1}    <NA>      <NA>      <NA>      <NA>      <NA>
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  conbin
## 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       {OPEXPR :opno 525 :opfuncid 150 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({COERCETODOMAINVALUE :typeId 23 :typeMod -1 :collation 0 :location 195} {CONST :consttype 23 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 204 :constvalue 4 [ 0 0 0 0 0 0 0 0 ]}) :location 201}
## 2 {SCALARARRAYOPEXPR :opno 98 :opfuncid 67 :useOr true :inputcollid 100 :args ({RELABELTYPE :arg {COERCETODOMAINVALUE :typeId 1043 :typeMod 7 :collation 100 :location 121} :resulttype 25 :resulttypmod -1 :resultcollid 100 :relabelformat 2 :location -1} {ARRAYCOERCEEXPR :arg {ARRAY :array_typeid 1015 :array_collid 100 :element_typeid 1043 :elements ({CONST :consttype 1043 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 131 :constvalue 7 [ 28 0 0 0 89 69 83 ]} {CONST :consttype 1043 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 138 :constvalue 6 [ 24 0 0 0 78 79 ]}) :multidims false :location -1} :elemfuncid 0 :resulttype 1009 :resulttypmod -1 :resultcollid 100 :isExplicit false :coerceformat 2 :location -1}) :location 127}
## 3                                                                                                             {BOOLEXPR :boolop and :args ({OPEXPR :opno 525 :opfuncid 150 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({COERCETODOMAINVALUE :typeId 23 :typeMod -1 :collation 0 :location 62} {CONST :consttype 23 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 71 :constvalue 4 [ 109 7 0 0 0 0 0 0 ]}) :location 68} {OPEXPR :opno 523 :opfuncid 149 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({COERCETODOMAINVALUE :typeId 23 :typeMod -1 :collation 0 :location 82} {CONST :consttype 23 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 91 :constvalue 4 [ 107 8 0 0 0 0 0 0 ]}) :location 88}) :location 77}
## 4                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  <NA>
## 5                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  <NA>
## 6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  <NA>
##                                                                                       consrc
## 1                                                                               (VALUE >= 0)
## 2 ((VALUE)::text = ANY ((ARRAY['YES'::character varying, 'NO'::character varying])::text[]))
## 3                                                      ((VALUE >= 1901) AND (VALUE <= 2155))
## 4                                                                                       <NA>
## 5                                                                                       <NA>
## 6                                                                                       <NA>
##                                                                                         condef
## 1                                                                           CHECK (VALUE >= 0)
## 2 CHECK (VALUE::text = ANY (ARRAY['YES'::character varying, 'NO'::character varying]::text[]))
## 3                                                      CHECK (VALUE >= 1901 AND VALUE <= 2155)
## 4                                                                       PRIMARY KEY (actor_id)
## 5                                                                     PRIMARY KEY (address_id)
## 6                                                                    PRIMARY KEY (category_id)
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
# insert yourself as a new customer
dbExecute(con
         ,"insert into customer 
                 (store_id,first_name,last_name,email,address_id
                 ,activebool,create_date,last_update,active)
           values(2,'Sophie','Yang','dodreamdo@yahoo.com',1,TRUE,'2018-09-13','2018-09-13',1)              returning customer_id;
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

result <- system2("docker", "stop sql-pet", stdout = TRUE, stderr = TRUE)
result
```

```
## [1] "sql-pet"
```

