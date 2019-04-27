---
output:
  html_document:
    code_folding: "show"
---

# SQL Joins Exercises {#chapter_sql-joins-exercises}

> This chapter contains questions one may be curious about or asked about the DVD Rental business.  
> The goal of the exercises is extracting useful or questionable insights from one or more tables.   Each exercise has has some or all of the following parts.
>
>  1.  The question.
>  2.  The tables used to answer the question.
>  3.  A hidden SQL code block showing the desired output. Click the code button to see the SQL code.   
>  4.  A table of derived values or renamed columns shown in the SQL block to facilitate replicating the desired dplyr solution.  Abbreviated column names are used to squeeze in more columns into the answer to reduce scrolling across the screen.
>  5.  A replication section where you recreate the desired output using dplyr syntax.  Most columns come directly out of the tables.  Each replication code block has three commented function calls 
>    *  sp_tbl_descr('store')        --describes a table, store
>    *  sp_tbl_pk_fk('table_name')   --shows a table's primary and foreign keys
>    *  sp_print_df(table_rows_sql)  --shows table row counts.
>    
> 6. To keep the exercises concentrated on the joins, all derived dates drop their timestamp.
>    *  SQL syntax:   date_column::DATE
>    *  Dplyr syntax: as.date(date_column)
>



##  Exercise Instructions

1.  Manually execute all the code blocks up-to the "SQL Union Exercise."  
2.  Most of the exercises can be performed in any order.  
*  There are function exercises that create a function followed by another code block to call the function in the previous exercise.
3.  Use the Show Document Outline, CTL-Shift-O, to navigate to the different exercises.




Verify Docker is up and running:


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up, running these containers:"                                                                                                               
## [2] "CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS              PORTS                              NAMES"    
## [3] "c12077eaade2        postgres-dvdrental   \"docker-entrypoint.s…\"   49 seconds ago      Up 2 seconds        5432/tcp, 0.0.0.0:5439->5439/tcp   sql-pet"
```

Verify pet DB is available, it may be stopped.


```r
sp_show_all_docker_containers()
```

```
## CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS                     PORTS                              NAMES
## c12077eaade2        postgres-dvdrental   "docker-entrypoint.s…"   49 seconds ago      Up 2 seconds               5432/tcp, 0.0.0.0:5439->5439/tcp   sql-pet
## 08cfc88c882c        postgres:10          "docker-entrypoint.s…"   2 weeks ago         Exited (255) 2 weeks ago   0.0.0.0:5432->5432/tcp             hr-sample
```

Start up the `docker-pet` container


```r
sp_docker_start("sql-pet")
```

Now connect to the database with R


```r
# need to wait for Docker & Postgres to come up before connecting.

con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 30, connection_tab = TRUE
)
```

## Dplyr tables

All the tables defined in the DVD Rental System will fit into memory which is rarely the case when working with a database.  Instead of loading all the DVD Rental System tables into memory via a DBI::dbReadTable, each table is loaded into an R object named TableName_table, via a dplyr::tbl call.

*  actor_table <- dplyr::tbl(con,"actor")


```r
source(here::here('book-src','dvdrental-table-declarations.R'),echo=FALSE)
```

The following code block deletes and inserts records into the different tables used in the exercises in this chpater.  The techniques used in this code block are discussed in detail in the appendix, ??add link here.??  


```r
source(file=here('book-src/sql_pet_data.R'),echo=FALSE)
```

## Overview Exercise

When joining many tables, it is helpful to have the number of rows from each table as an initial sanity check that the joins are returning a reasonable number of rows.

### 1.  How many rows are in each table?


```r
table_rows_sql <- dbGetQuery(
  con,
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
sp_print_df(table_rows_sql)
```

<!--html_preserve--><div id="htmlwidget-1d9f9b9fdca3023baa83" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1d9f9b9fdca3023baa83">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"],["actor","address","category","city","country","customer","film","film_actor","film_category","inventory","language","payment","rental","staff","store"],[200,603,16,600,109,604,1001,5462,1002,4583,6,14596,16045,2,3]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>tbl_name<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('table_name')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

table_rows_dplyr <- 
  as.data.frame(actor_table %>% mutate(name = "actor") %>% group_by(name) %>% 
                  summarize(rows = n())) %>% 
  union(as.data.frame(address_table %>% mutate(name = "address") %>% group_by(name) %>% 
                        summarize(rows = n()))) %>% 
  arrange(name)

sp_print_df(table_rows_dplyr)
```

<!--html_preserve--><div id="htmlwidget-b18b48ec4ad649442f3b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b18b48ec4ad649442f3b">{"x":{"filter":"none","data":[["1","2"],["actor","address"],[200,603]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>name<\/th>\n      <th>rows<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Exercises

### 1. Where is the DVD Rental Business located?

To answer this question we look at the `store`, `address`, `city`, and `country` tables to answer this question.


```r
store_locations_sql <- dbGetQuery(con,
"select s.store_id
       ,a.address
       ,c.city
       ,a.district
       ,a.postal_code
       ,c2.country
       ,s.last_update
   from store s 
         join address a on s.address_id = a.address_id
         join city c on a.city_id = c.city_id
         join country c2 on c.country_id = c2.country_id
")
sp_print_df(store_locations_sql)
```

<!--html_preserve--><div id="htmlwidget-514d280a38cf86ead40b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-514d280a38cf86ead40b">{"x":{"filter":"none","data":[["1","2","3"],[1,2,10],["47 MySakila Drive","28 MySQL Boulevard","1795 Santiago de Compostela Way"],["Lethbridge","Woodridge","Laredo"],["Alberta","QLD","Texas"],["","","18743"],["Canada","Australia","United States"],["2006-02-15T17:57:12Z","2006-02-15T17:57:12Z","2019-04-27T00:17:12Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>address<\/th>\n      <th>city<\/th>\n      <th>district<\/th>\n      <th>postal_code<\/th>\n      <th>country<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":1},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>Our DVD Rental business is international and operates in three countries, Canada, Austraila, and the United States.  Each country has one store.</font> 

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

store_locations_dplyr <- as.data.frame("code me")

sp_print_df(store_locations_dplyr)
```

<!--html_preserve--><div id="htmlwidget-74434d812ec23342fdce" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-74434d812ec23342fdce">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 2. List Each Store and the Staff Contact Information?

To answer this question we look at the `store`, `staff`, `address`, `city`, and `country` tables.


```r
store_employees_sql <- dbGetQuery(con,
"select st.store_id
       ,s.first_name
       ,s.last_name
       ,s.email
       ,a.phone
       ,a.address
       ,c.city
       ,a.district
       ,a.postal_code
       ,c2.country
   from store st left join staff s on st.manager_staff_id = s.staff_id 
         left join address a on s.address_id = a.address_id
         left join city c on a.city_id = c.city_id
         left join country c2 on c.country_id = c2.country_id
")
sp_print_df(store_employees_sql)
```

<!--html_preserve--><div id="htmlwidget-8da54f9f5480ad7c3ec3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8da54f9f5480ad7c3ec3">{"x":{"filter":"none","data":[["1","2","3"],[1,2,10],["Mike","Jon",null],["Hillyer","Stephens",null],["Mike.Hillyer@sakilastaff.com","Jon.Stephens@sakilastaff.com",null],["14033335568","6172235589",null],["23 Workhaven Lane","1411 Lillydale Drive",null],["Lethbridge","Woodridge",null],["Alberta","QLD",null],["","",null],["Canada","Australia",null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>phone<\/th>\n      <th>address<\/th>\n      <th>city<\/th>\n      <th>district<\/th>\n      <th>postal_code<\/th>\n      <th>country<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":1},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>Our DVD Rental business is international and operates in three countries, Canada, Austraila, and the United States.  Each country has one store.  The stores in Canada and Austrailia have one employee each, Mike Hillyer and Jon Stephens respectively.  The store in the United States has no employees yet.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

store_employees_dplyr <- as.data.frame("code me")

sp_print_df(store_employees_dplyr)
```

<!--html_preserve--><div id="htmlwidget-124fb78127817ec02cd9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-124fb78127817ec02cd9">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


### 3. How Many Active, Inactive, and Total Customers Does the DVD Rental Business Have?

To answer this question we look at the `customer` table.  In a previous chapter we observed that there are two columns, `activebool` and `active`.  We consider `active = 1` as active.


```r
customer_cnt_sql <- dbGetQuery(con,
"SELECT sum(case when active = 1 then 1 else 0 end) active
       ,sum(case when active = 0 then 1 else 0 end) inactive
       ,count(*) total
   from customer
")

sp_print_df(customer_cnt_sql)
```

<!--html_preserve--><div id="htmlwidget-dd0a51033db44e820d90" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-dd0a51033db44e820d90">{"x":{"filter":"none","data":[["1"],[589],[15],[604]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>active<\/th>\n      <th>inactive<\/th>\n      <th>total<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>
Our DVD Rental business is international and operates in three countries, Canada, Austraila, and the United States.  Each country has one store.  The stores in Canada and Austrailia have one employee each.  The store in the United States has no employees yet.  

The business has 604 international customers, 589 are active and 15 inactive.</font>


#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customer_cnt_dplyr <- as.data.frame("code me")

sp_print_df(customer_cnt_dplyr)
```

<!--html_preserve--><div id="htmlwidget-1fe403c81784621152ab" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1fe403c81784621152ab">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 4. How Many and What Percent of Customers Are From Each Country?

To answer this question we look at the `customer`, `address`, `city`, and `country` tables. 


```r
customers_sql <- dbGetQuery(con,
"select c.active,country.country,count(*) count
              ,round(100 * count(*) / sum(count(*)) over(),4) as pct
         from customer c
              join address a on c.address_id = a.address_id
              join city  on a.city_id = city.city_id
              join country on city.country_id = country.country_id
         group by c.active,country
order by count(*) desc
")
sp_print_df(customers_sql)
```

<!--html_preserve--><div id="htmlwidget-ed78248b32e6634f28e5" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-ed78248b32e6634f28e5">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118"],[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0,0,1,1,0,1,1,1,0,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0],["India","China","United States","Japan","Mexico","Brazil","Russian Federation","Philippines","Indonesia","Turkey","Argentina","Nigeria","South Africa","Taiwan","United Kingdom","Canada","Poland","Germany","Venezuela","Italy","Iran","Ukraine","Colombia","Egypt","Vietnam","Pakistan","Spain","Netherlands","Saudi Arabia","South Korea","Peru","France","Yemen","Malaysia","Morocco","Austria","China","India","Dominican Republic","Chile","United Arab Emirates","Thailand","Algeria","Bangladesh","Israel","Mozambique","Paraguay","Ecuador","Switzerland","Tanzania","Angola","Cambodia","Bolivia","Australia","Romania","Yugoslavia","Bulgaria","Latvia","Oman","Puerto Rico","Congo, The Democratic Republic of the","Kenya","Belarus","Sudan","Cameroon","Kazakstan","Azerbaijan","Myanmar","Greece","French Polynesia","Madagascar","Turkey","Saint Vincent and the Grenadines","Armenia","Gambia","Slovakia","North Korea","Malawi","Sri Lanka","Bahrain","Nauru","Moldova","Finland","Kuwait","Estonia","Hong Kong","Lithuania","Tonga","United Kingdom","Tunisia","American Samoa","Israel","Mexico","Sweden","New Zealand","Iran","Brunei","Greenland","Runion","Virgin Islands, U.S.","Nepal","Zambia","Ethiopia","Hungary","Poland","Chad","French Guiana","Faroe Islands","Turkmenistan","Czech Republic","Anguilla","Iraq","Holy See (Vatican City State)","Senegal","Tuvalu","Liechtenstein","Afghanistan","Russian Federation"],[57,50,36,31,29,28,27,20,14,14,13,13,11,10,8,8,7,7,7,7,7,6,6,6,6,5,5,5,5,5,4,4,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],[9.4371,8.2781,5.9603,5.1325,4.8013,4.6358,4.4702,3.3113,2.3179,2.3179,2.1523,2.1523,1.8212,1.6556,1.3245,1.3245,1.1589,1.1589,1.1589,1.1589,1.1589,0.9934,0.9934,0.9934,0.9934,0.8278,0.8278,0.8278,0.8278,0.8278,0.6623,0.6623,0.6623,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>active<\/th>\n      <th>country<\/th>\n      <th>count<\/th>\n      <th>pct<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>
Based on the table above, the DVD Rental business has customers in 118 countries.  The DVD Rental business cannot have many walk in customers.  It may possibly use a mail order distribution model.

For an international company, how are the different currencies converted to a standard currency?  Looking at the ERD, there is no currency conversion rate.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customers_dplyr <- as.data.frame("code me")

sp_print_df(customers_dplyr)
```

<!--html_preserve--><div id="htmlwidget-2ae622211a824c064fbd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-2ae622211a824c064fbd">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 5 What Countries Constitute the Top 25% of the Customer Base?

Using the previous code, add two new columns.  One column shows a running total and the second column shows a running percentage.  Order the data by count then by country.

To answer this question we look at the `customer`, `address`, `city`, and `country` tables again.


```r
country_sql <- dbGetQuery(con,
                            
"select active,country,count
       ,sum(count) over (order by count desc,country rows between unbounded preceding and current row) running_total
       , pct
       ,sum(pct) over (order by pct desc,country rows between unbounded preceding and current row) running_pct
  from (-- Start of inner SQL Block
        select c.active,country.country,count(*) count
              ,round(100 * count(*) / sum(count(*)) over(),4) as pct
         from customer c
              join address a on c.address_id = a.address_id
              join city  on a.city_id = city.city_id
              join country on city.country_id = country.country_id
         group by c.active,country
       ) ctry  -- End of inner SQL Block
 order by count desc,country
")
sp_print_df(country_sql)
```

<!--html_preserve--><div id="htmlwidget-09904734225327216f09" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-09904734225327216f09">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118"],[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,0,1,1,0,0,1],["India","China","United States","Japan","Mexico","Brazil","Russian Federation","Philippines","Indonesia","Turkey","Argentina","Nigeria","South Africa","Taiwan","Canada","United Kingdom","Germany","Iran","Italy","Poland","Venezuela","Colombia","Egypt","Ukraine","Vietnam","Netherlands","Pakistan","Saudi Arabia","South Korea","Spain","France","Peru","Yemen","Algeria","Austria","Bangladesh","Chile","China","Dominican Republic","Ecuador","India","Israel","Malaysia","Morocco","Mozambique","Paraguay","Switzerland","Tanzania","Thailand","United Arab Emirates","Angola","Australia","Azerbaijan","Belarus","Bolivia","Bulgaria","Cambodia","Cameroon","Congo, The Democratic Republic of the","French Polynesia","Greece","Kazakstan","Kenya","Latvia","Myanmar","Oman","Puerto Rico","Romania","Sudan","Yugoslavia","Afghanistan","American Samoa","Anguilla","Armenia","Bahrain","Brunei","Chad","Czech Republic","Estonia","Ethiopia","Faroe Islands","Finland","French Guiana","Gambia","Greenland","Holy See (Vatican City State)","Hong Kong","Hungary","Iran","Iraq","Israel","Kuwait","Liechtenstein","Lithuania","Madagascar","Malawi","Mexico","Moldova","Nauru","Nepal","New Zealand","North Korea","Poland","Runion","Russian Federation","Saint Vincent and the Grenadines","Senegal","Slovakia","Sri Lanka","Sweden","Tonga","Tunisia","Turkey","Turkmenistan","Tuvalu","United Kingdom","Virgin Islands, U.S.","Zambia"],[57,50,36,31,29,28,27,20,14,14,13,13,11,10,8,8,7,7,7,7,7,6,6,6,6,5,5,5,5,5,4,4,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],[57,107,143,174,203,231,258,278,292,306,319,332,343,353,361,369,376,383,390,397,404,410,416,422,428,433,438,443,448,453,457,461,465,468,471,474,477,480,483,486,489,492,495,498,501,504,507,510,513,516,518,520,522,524,526,528,530,532,534,536,538,540,542,544,546,548,550,552,554,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,571,572,573,574,575,576,577,578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604],[9.4371,8.2781,5.9603,5.1325,4.8013,4.6358,4.4702,3.3113,2.3179,2.3179,2.1523,2.1523,1.8212,1.6556,1.3245,1.3245,1.1589,1.1589,1.1589,1.1589,1.1589,0.9934,0.9934,0.9934,0.9934,0.8278,0.8278,0.8278,0.8278,0.8278,0.6623,0.6623,0.6623,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.4967,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.3311,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656,0.1656],[9.4371,17.7152,23.6755,28.808,33.6093,38.2451,42.7153,46.0266,48.3445,50.6624,52.8147,54.967,56.7882,58.4438,59.7683,61.0928,62.2517,63.4106,64.5695,65.7284,66.8873,67.8807,68.8741,69.8675,70.8609,71.6887,72.5165,73.3443,74.1721,74.9999,75.6622,76.3245,76.9868,77.4835,77.9802,78.4769,78.9736,79.4703,79.967,80.4637,80.9604,81.4571,81.9538,82.4505,82.9472,83.4439,83.9406,84.4373,84.934,85.4307,85.7618,86.0929,86.424,86.7551,87.0862,87.4173,87.7484,88.0795,88.4106,88.7417,89.0728,89.4039,89.735,90.0661,90.3972,90.7283,91.0594,91.3905,91.7216,92.0527,92.2183,92.3839,92.5495,92.7151,92.8807,93.0463,93.2119,93.3775,93.5431,93.7087,93.8743,94.0399,94.2055,94.3711,94.5367,94.7023,94.8679,95.0335,95.1991,95.3647,95.5303,95.6959,95.8615,96.0271,96.1927,96.3583,96.5239,96.6895,96.8551,97.0207,97.1863,97.3519,97.5175,97.6831,97.8487,98.0143,98.1799,98.3455,98.5111,98.6767,98.8423,99.0079,99.1735,99.3391,99.5047,99.6703,99.8359,100.0015]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>active<\/th>\n      <th>country<\/th>\n      <th>count<\/th>\n      <th>running_total<\/th>\n      <th>pct<\/th>\n      <th>running_pct<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>
The top 25% of the customer base are from India, China, the United States, and Japan.  The next six countries, the top 10, Mexico, Brazil, Russian Federation, Philipines, Indonesia, and Turkey round out the top 50% of the businesses customer base.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

country_dplyr <- as.data.frame("code me")

sp_print_df(country_dplyr)
```

<!--html_preserve--><div id="htmlwidget-b619f31f38e9f2471fcc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b619f31f38e9f2471fcc">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 6. How many customers are in Australia and Canada?

To answer this question we use the results from the previous exercise.


```r
country_au_ca_sql <- country_sql %>% filter(country == 'Australia' | country == 'Canada')
sp_print_df(country_au_ca_sql)
```

<!--html_preserve--><div id="htmlwidget-beeafef17c4840807f51" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-beeafef17c4840807f51">{"x":{"filter":"none","data":[["1","2"],[1,1],["Canada","Australia"],[8,2],[361,520],[1.3245,0.3311],[59.7683,86.0929]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>active<\/th>\n      <th>country<\/th>\n      <th>count<\/th>\n      <th>running_total<\/th>\n      <th>pct<\/th>\n      <th>running_pct<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>There are 10 customers in Austrailia and Canada where the brick and mortar stores are located.  The 20 customers are less than 2% of the world wide customer base.  </font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

country_au_ca_dplyr <- as.data.frame("code me")

sp_print_df(country_au_ca_dplyr)
```

<!--html_preserve--><div id="htmlwidget-f6a2206cea77e899a1de" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f6a2206cea77e899a1de">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 7. How Many Languages?

With an international customer base, how many languages does the DVD Rental business distribute DVD's in.

To answer this question we look at the `language` table.


```r
languages_sql <- dbGetQuery(con,
"
select * from language
")

sp_print_df(languages_sql)
```

<!--html_preserve--><div id="htmlwidget-80fb537b5ba0bd90fb93" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-80fb537b5ba0bd90fb93">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,2,3,4,5,6],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              "],["2006-02-15T18:02:19Z","2006-02-15T18:02:19Z","2006-02-15T18:02:19Z","2006-02-15T18:02:19Z","2006-02-15T18:02:19Z","2006-02-15T18:02:19Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":1},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>DVD's are distributed in six languages.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

# languages_dplyr <- as.data.frame("code me")
# 
# sp_print_df(language_table)
```

### 8.  What is the distribution of DVD's by Language 

To answer this question we look at the `language` and `film` tables.


```r
language_distribution_sql <- dbGetQuery(con,
'
select l.language_id,name "language",count(f.film_id)
  from language l left join film f on l.language_id = f.language_id
group by l.language_id,name
order by l.language_id
')

sp_print_df(language_distribution_sql)
```

<!--html_preserve--><div id="htmlwidget-703a15d93cfc9aff608e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-703a15d93cfc9aff608e">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,2,3,4,5,6],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1001,0,0,0,0,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>language<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>This is a surprise.  For an international customer base, the entire stock of 1001 DVD's are in English only.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

language_distribution_dplyr <- as.data.frame("code me")

sp_print_df(language_distribution_dplyr)
```

<!--html_preserve--><div id="htmlwidget-6d936e3915a36e12cd53" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6d936e3915a36e12cd53">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 9.  What are the number of rentals and rented amount by store, by month?

To answer this question we look at the `rental`, `inventory`, and `film` tables to answer this question. 


```r
store_rentals_by_mth_sql <- dbGetQuery(con,
"select *
       ,sum(rental_amt) over (order by yyyy_mm,store_id rows 
                              between unbounded preceding and current row) running_rental_amt
   from (select yyyy_mm,store_id,rentals,rental_amt
               ,sum(rentals) over(partition by yyyy_mm order by store_id) mo_rentals
               ,sum(rental_amt) over (partition by yyyy_mm order by store_id) mo_rental_amt
           from (select to_char(rental_date,'yyyy-mm') yyyy_mm
                       ,i.store_id,count(*) rentals, sum(f.rental_rate) rental_amt
                   from rental r join inventory i on r.inventory_id = i.inventory_id 
                        join film f on i.film_id = f.film_id
                 group by to_char(rental_date,'yyyy-mm'),i.store_id
                ) as details
        ) as mo_running
order by yyyy_mm,store_id
")
sp_print_df(store_rentals_by_mth_sql)
```

<!--html_preserve--><div id="htmlwidget-c195b56d57c26c8f1d4d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c195b56d57c26c8f1d4d">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11"],["2005-05","2005-05","2005-06","2005-06","2005-07","2005-07","2005-08","2005-08","2006-02","2006-02","2019-04"],[1,2,1,2,1,2,1,2,1,2,1],[575,581,1121,1190,3334,3375,2801,2885,92,90,1],[1721.25,1667.19,3331.79,3444.1,9914.66,9861.25,8292.99,8464.15,249.08,265.1,4.99],[575,1156,1121,2311,3334,6709,2801,5686,92,182,1],[1721.25,3388.44,3331.79,6775.89,9914.66,19775.91,8292.99,16757.14,249.08,514.18,4.99],[1721.25,3388.44,6720.23,10164.33,20078.99,29940.24,38233.23,46697.38,46946.46,47211.56,47216.55]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>yyyy_mm<\/th>\n      <th>store_id<\/th>\n      <th>rentals<\/th>\n      <th>rental_amt<\/th>\n      <th>mo_rentals<\/th>\n      <th>mo_rental_amt<\/th>\n      <th>running_rental_amt<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


<font color='blue'>The current entry, row 11, is our new rental row we added to show the different joins in a previous chapter.
</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

store_rentals_by_mth_dplyr <- as.data.frame("code me")
    
sp_print_df(head(store_rentals_by_mth_dplyr, n=25))
```

<!--html_preserve--><div id="htmlwidget-7a589913f405d7a14fbe" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-7a589913f405d7a14fbe">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 10.  Rank Films Based on the Number of Times Rented and Associated Revenue

To answer this question we look at the `rental`, `inventory`, and `film` tables.


```r
film_rank_sql <- dbGetQuery(con,
"select f.film_id,f.title,f.rental_rate,count(*) count,f.rental_rate * count(*) rental_amt
   from rental r join inventory i on r.inventory_id = i.inventory_id 
        join film f on i.film_id = f.film_id
 group by f.film_id,f.title,f.rental_rate
 order by count(*) desc")
  
sp_print_df(film_rank_sql)
```

<!--html_preserve--><div id="htmlwidget-a3fe20e2cfd2d5bbfba3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a3fe20e2cfd2d5bbfba3">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200","201","202","203","204","205","206","207","208","209","210","211","212","213","214","215","216","217","218","219","220","221","222","223","224","225","226","227","228","229","230","231","232","233","234","235","236","237","238","239","240","241","242","243","244","245","246","247","248","249","250","251","252","253","254","255","256","257","258","259","260","261","262","263","264","265","266","267","268","269","270","271","272","273","274","275","276","277","278","279","280","281","282","283","284","285","286","287","288","289","290","291","292","293","294","295","296","297","298","299","300","301","302","303","304","305","306","307","308","309","310","311","312","313","314","315","316","317","318","319","320","321","322","323","324","325","326","327","328","329","330","331","332","333","334","335","336","337","338","339","340","341","342","343","344","345","346","347","348","349","350","351","352","353","354","355","356","357","358","359","360","361","362","363","364","365","366","367","368","369","370","371","372","373","374","375","376","377","378","379","380","381","382","383","384","385","386","387","388","389","390","391","392","393","394","395","396","397","398","399","400","401","402","403","404","405","406","407","408","409","410","411","412","413","414","415","416","417","418","419","420","421","422","423","424","425","426","427","428","429","430","431","432","433","434","435","436","437","438","439","440","441","442","443","444","445","446","447","448","449","450","451","452","453","454","455","456","457","458","459","460","461","462","463","464","465","466","467","468","469","470","471","472","473","474","475","476","477","478","479","480","481","482","483","484","485","486","487","488","489","490","491","492","493","494","495","496","497","498","499","500","501","502","503","504","505","506","507","508","509","510","511","512","513","514","515","516","517","518","519","520","521","522","523","524","525","526","527","528","529","530","531","532","533","534","535","536","537","538","539","540","541","542","543","544","545","546","547","548","549","550","551","552","553","554","555","556","557","558","559","560","561","562","563","564","565","566","567","568","569","570","571","572","573","574","575","576","577","578","579","580","581","582","583","584","585","586","587","588","589","590","591","592","593","594","595","596","597","598","599","600","601","602","603","604","605","606","607","608","609","610","611","612","613","614","615","616","617","618","619","620","621","622","623","624","625","626","627","628","629","630","631","632","633","634","635","636","637","638","639","640","641","642","643","644","645","646","647","648","649","650","651","652","653","654","655","656","657","658","659","660","661","662","663","664","665","666","667","668","669","670","671","672","673","674","675","676","677","678","679","680","681","682","683","684","685","686","687","688","689","690","691","692","693","694","695","696","697","698","699","700","701","702","703","704","705","706","707","708","709","710","711","712","713","714","715","716","717","718","719","720","721","722","723","724","725","726","727","728","729","730","731","732","733","734","735","736","737","738","739","740","741","742","743","744","745","746","747","748","749","750","751","752","753","754","755","756","757","758","759","760","761","762","763","764","765","766","767","768","769","770","771","772","773","774","775","776","777","778","779","780","781","782","783","784","785","786","787","788","789","790","791","792","793","794","795","796","797","798","799","800","801","802","803","804","805","806","807","808","809","810","811","812","813","814","815","816","817","818","819","820","821","822","823","824","825","826","827","828","829","830","831","832","833","834","835","836","837","838","839","840","841","842","843","844","845","846","847","848","849","850","851","852","853","854","855","856","857","858","859","860","861","862","863","864","865","866","867","868","869","870","871","872","873","874","875","876","877","878","879","880","881","882","883","884","885","886","887","888","889","890","891","892","893","894","895","896","897","898","899","900","901","902","903","904","905","906","907","908","909","910","911","912","913","914","915","916","917","918","919","920","921","922","923","924","925","926","927","928","929","930","931","932","933","934","935","936","937","938","939","940","941","942","943","944","945","946","947","948","949","950","951","952","953","954","955","956","957","958","959"],[103,738,382,331,730,489,767,1000,621,369,418,753,31,891,735,973,563,109,748,239,869,979,559,789,609,450,285,127,403,374,702,341,220,945,86,174,301,873,941,875,361,849,595,73,284,893,378,358,295,395,356,305,951,745,764,159,911,850,625,638,715,521,200,698,603,367,958,135,835,206,525,468,330,78,697,879,114,897,434,228,531,244,870,349,445,181,303,471,687,460,391,773,938,890,970,554,234,901,838,670,12,101,263,397,572,307,167,683,880,856,895,309,266,624,162,555,791,288,387,760,571,247,786,273,172,989,863,545,55,417,245,644,319,902,154,586,741,775,476,11,649,810,304,45,366,91,865,35,966,119,131,790,447,527,253,650,804,641,502,43,551,852,433,130,491,443,388,166,914,676,816,494,122,117,320,270,646,961,645,327,412,771,843,857,1,504,10,191,982,614,51,995,271,334,915,199,353,976,608,437,665,759,4,892,26,376,518,322,556,706,79,54,823,267,428,18,772,143,814,61,59,15,500,949,314,972,300,21,575,782,408,415,176,985,651,898,142,406,25,800,444,89,252,930,317,67,23,6,981,677,242,149,280,755,602,776,37,132,377,922,164,514,637,846,129,49,807,218,861,596,112,681,841,22,313,235,19,57,83,274,833,806,953,416,69,727,354,193,100,39,138,292,920,255,249,484,414,326,439,140,462,139,628,231,647,363,204,851,906,720,680,805,486,535,409,993,707,147,728,778,845,578,694,465,350,733,590,562,402,467,668,723,496,743,99,501,827,579,345,663,160,344,747,222,115,97,948,690,118,479,734,436,710,48,298,785,233,243,370,396,72,725,158,580,912,282,269,631,457,281,302,864,887,227,311,619,451,560,818,610,616,150,429,812,17,212,967,768,90,461,688,184,871,456,385,329,724,746,524,383,56,8,254,936,432,121,986,777,346,286,215,463,689,473,657,474,251,971,583,155,77,709,410,924,116,294,877,299,169,561,999,95,944,574,854,333,611,448,70,925,308,643,183,424,763,265,717,506,626,512,510,744,803,964,623,737,175,878,348,534,488,398,693,464,58,481,336,275,672,483,380,691,324,552,859,739,855,716,427,105,85,708,679,458,480,526,606,226,600,975,351,678,111,373,797,50,141,956,123,862,963,42,969,179,601,908,44,696,165,704,189,809,757,666,686,927,392,186,980,570,170,260,203,749,937,664,991,40,987,598,152,84,442,68,858,655,137,529,505,421,618,634,942,272,542,544,201,844,438,446,932,907,588,28,236,770,654,287,796,732,795,872,420,792,896,7,820,988,830,110,589,557,452,229,232,788,532,615,592,962,453,648,658,478,347,216,913,599,784,219,381,455,900,241,756,916,629,536,847,360,946,81,493,921,793,774,652,620,992,894,205,673,783,426,277,832,667,840,379,365,24,173,546,16,394,968,190,882,296,929,133,290,661,27,65,328,917,617,765,34,842,604,63,423,440,96,711,98,487,577,511,71,593,762,449,209,639,736,153,660,293,828,321,573,258,145,829,705,177,151,202,568,213,867,597,134,994,540,430,207,585,798,291,931,766,9,881,794,93,533,413,813,80,113,5,3,567,919,564,519,977,538,821,957,928,88,315,825,389,576,194,682,323,581,933,627,306,250,722,831,918,848,283,210,509,888,257,700,587,187,640,886,899,633,729,469,342,761,46,74,549,819,92,530,104,853,889,692,75,337,64,905,352,60,731,726,368,422,960,375,82,613,157,537,636,740,477,868,811,662,339,528,780,393,312,29,750,508,539,952,553,276,482,20,543,279,246,630,66,837,834,522,126,240,632,188,826,120,214,565,582,591,435,355,264,492,815,503,934,983,685,230,466,338,516,256,984,515,13,940,425,824,211,208,998,30,390,454,76,357,714,550,978,721,499,594,223,364,817,136,926,866,787,923,566,659,401,146,674,751,758,719,124,52,718,47,822,990,548,490,384,523,431,163,752,876,703,371,656,225,939,197,569,513,278,268,839,407,156,622,161,996,947,238,836,547,237,910,196,53,411,248,316,182,605,2,684,520,470,185,289,695,935,178,261,517,653,779,541,106,399,262,224,754,883,799,340,769,997,635,498,808,125,372,168,507,475,959,259,62,32,297,974,472,885,102,405,884,485,965,675,310,612,107,362,343,180,903,441,459,335,94,781,558,699,904,400,584,1001],["Bucket Brotherhood","Rocketeer Mother","Grit Clockwork","Forward Temple","Ridgemont Submarine","Juggler Hardly","Scalawag Duck","Zorro Ark","Network Peak","Goodfellas Salute","Hobbit Alien","Rush Goodfellas","Apache Divine","Timberland Sky","Robbers Joon","Wife Turn","Massacre Usual","Butterfly Chocolat","Rugrats Shakespeare","Dogma Family","Suspects Quills","Witches Panic","Married Go","Shock Cabin","Muscle Bright","Idols Snatchers","English Bulworth","Cat Coneheads","Harry Idaho","Graffiti Love","Pulp Beverly","Frost Head","Deer Virginian","Virginian Pluto","Boogie Amelie","Confidential Interview","Family Sweet","Sweethearts Suspects","Videotape Arsenic","Talented Homicide","Gleaming Jawbreaker","Storm Happiness","Moon Bunch","Bingo Talented","Enemy Odds","Titans Jerk","Greatest North","Gilmore Boiled","Expendable Stallion","Handicap Boondock","Giant Troopers","Fatal Haunted","Voyage Legally","Roses Treasure","Saturday Lambs","Closer Bang","Trip Newton","Story Side","None Spiking","Operation Operation","Range Moonwalker","Lies Treatment","Curtain Videotape","Princess Giant","Movie Shakespeare","Goldmine Tycoon","Wardrobe Phantom","Chance Resurrection","Spy Mile","Dancing Fever","Loathing Legally","Invasion Cyclone","Forrester Comancheros","Blackout Private","Primary Glass","Telegraph Voyage","Camelot Vacation","Torque Bound","Horror Reign","Detective Vision","Lose Inch","Dorado Notting","Swarm Gold","Gangs Pride","Hyde Doctor","Contact Anonymous","Fantasy Troopers","Island Exorcist","Pocus Pulp","Innocent Usual","Half Outfield","Seabiscuit Punk","Velvet Terminator","Tights Dawn","Westward Seabiscuit","Malkovich Pet","Disturbing Scarface","Tracy Cider","Stagecoach Armageddon","Pelican Comforts","Alaska Phantom","Brotherhood Blanket","Durham Panky","Hanky October","Metropolis Coma","Fellowship Autumn","Coma Head","Pity Bound","Telemark Heartbreakers","Streetcar Intentions","Tomorrow Hustler","Feud Frogmen","Dynamite Tarzan","Nightmare Chill","Clueless Bucket","Mallrats United","Show Lord","Escape Metropolis","Gun Bonnie","Samurai Lion","Metal Armageddon","Downhill Enough","Shepherd Midsummer","Effect Gladiator","Coneheads Smoochy","Working Microcosmos","Sun Confessions","Madness Attacks","Barbarella Streetcar","Hills Neighbors","Double Wrath","Oscar Gold","Fish Opus","Trading Pinocchio","Clash Freddy","Mockingbird Hollywood","Roman Punk","Seattle Expecations","Jason Trap","Alamo Videotape","Oz Liaisons","Slums Duck","Fargo Gandhi","Attraction Newton","Goldfinger Sensibility","Bound Cheaper","Sunrise League","Arachnophobia Rollercoaster","Wedding Apollo","Caper Motions","Center Dinosaur","Shootist Superfly","Ice Crossing","Lola Agent","Drifter Commandments","Pacific Amistad","Sleeping Suspects","Orange Grapes","Knock Warlock","Atlantis Cause","Maiden Home","Strangelove Desire","Horn Working","Celebrity Horn","Jumping Wrath","Hurricane Affair","Gunfight Moon","Color Philadelphia","Trouble Date","Philadelphia Wife","Snowman Rollercoaster","Karate Moon","Carrie Bunch","Candles Grapes","Flamingos Connecticut","Earth Vision","Outbreak Divine","Wash Heavenly","Others Soup","Fool Mockingbird","Heavyweights Beast","Scorpion Apollo","Steel Santa","Strictly Scarface","Academy Dinosaur","Kwai Homeward","Aladdin Calendar","Crooked Frogmen","Women Dorado","Name Detective","Balloon Homeward","Yentl Idaho","Easy Gladiator","Freddy Storm","Truman Crazy","Cupboard Sinners","Gentlemen Stage","Wind Phantom","Murder Antitrust","House Dynamite","Patton Interview","Salute Apollo","Affair Prejudice","Titanic Boondock","Annie Identity","Grapes Fury","Liaisons Sweet","Flatliners Killer","Maltese Hope","Queen Luke","Blade Polish","Banger Pinocchio","South Wait","Eagles Panky","Homicide Peach","Alter Victory","Sea Virgin","Chill Luck","Snatch Slipper","Beauty Grease","Bear Graceland","Alien Center","Kiss Glory","Volcano Texas","Fight Jawbreaker","Whisperer Giant","Falcon Volume","American Circus","Midsummer Groundhog","Shakespeare Saddle","Head Stranger","High Encino","Congeniality Quest","Wonderland Christmas","Packer Madigan","Tourist Pelican","Chicken Hellfighters","Haunting Pianist","Angels Life","Sinners Atlantis","Hustler Party","Borrowers Bedazzled","Dream Pickup","Vacation Boondock","Fireball Philadelphia","Berets Agent","Anaconda Confessions","Agent Truman","Wolves Desire","Pianist Outfield","Doom Dancing","Christmas Moonshine","Empire Malkovich","Sabrina Midnight","Mourning Purple","Secret Groundhog","Arizona Bang","Chainsaw Uptown","Grease Youth","Undefeated Dalmations","Coast Rainbow","Lebowski Soldiers","Open African","Sting Personal","Cause Date","Badman Dawn","Sleuth Orient","Deceiver Betrayed","Suit Walls","Moonshine Cabin","Calendar Gunfight","Pirates Roxanne","Star Operation","Amistad Midsummer","Fidelity Devil","Divide Monster","Amadeus Holy","Basic Easy","Blues Instinct","Egg Igby","Splendor Patton","Sleepy Japanese","Wait Cider","Highball Potter","Beverly Outlaw","Resurrection Silverado","Ghost Groundhog","Crossroads Casualties","Brooklyn Desert","Armageddon Lost","Chariots Conspiracy","Excitement Eve","Unbreakable Karate","Driving Polish","Dracula Crystal","Jerk Paycheck","Hellfighters Sierra","Flying Hook","Hunchback Impossible","Cheaper Clyde","Insider Arizona","Chasing Fight","Northwest Polish","Dinosaur Secretary","Outfield Massacre","Go Purple","Dalmations Sweden","Straight Hours","Tramp Others","Redemption Comforts","Pinocchio Simon","Sleepless Monsoon","Jet Neighbors","Love Suicides","Heartbreakers Bright","Wrong Behavior","Quest Mussolini","Chocolat Harry","Reunion Witches","Secrets Paradise","Stepmom Dream","Million Ace","Prejudice Oleander","Interview Liaisons","Garden Island","River Outlaw","Money Harold","Masked Bubble","Harper Dying","Intrigue Worst","Peak Forever","Reign Gentlemen","Kick Savannah","Room Roman","Bringing Hysterical","Kissing Dolls","Spice Sorority","Minds Truman","Gables Metropolis","Patient Sister","Club Graffiti","Fury Murder","Roxanne Rebel","Desert Poseidon","Campus Remember","Bride Intrigue","Voice Peach","Pond Seattle","Canyon Stock","Jedi Beneath","Road Roxanne","Hours Rage","Rage Games","Backlash Undefeated","Eyes Driving","Shawshank Bubble","Disciple Mother","Doors President","Gorgeous Bingo","Hanging Deep","Bill Others","Requiem Tycoon","Clones Pinocchio","Mine Titans","Trojan Tomorrow","Encounters Curtain","Earring Instinct","Novocaine Flight","Independence Hotel","Encino Elf","Fantasia Park","Sundance Invasion","Thief Pelican","Details Packer","Fiction Christmas","Neighbors Charade","Igby Maker","Mars Roman","Something Duck","Music Boondock","National Story","Cider Desire","Honey Ties","Smoking Barbarella","Alone Trip","Darn Forrester","Weekend Personal","Scarface Bang","Boulevard Mob","Insects Stone","Polish Brooklyn","Core Suit","Sweden Shining","Inch Jet","Groundhog Uncut","Forrest Sons","Remember Diary","Rouge Squad","Lion Uncut","Groove Fiction","Barefoot Manchurian","Airport Pollock","Driver Annie","Vanishing Rocky","Hope Tootsie","Carol Texas","Wonka Sea","Secretary Rouge","Galaxy Sweethearts","Enough Raging","Dawn Pond","Instinct Airport","Pollock Deliverance","Jacket Frisco","Paradise Sabrina","Jade Bunch","Dragonfly Strangers","Whale Bikini","Mission Zoolander","Cleopatra Devil","Birds Perdition","Racer Egg","Heaven Freedom","Unforgiven Zoolander","Candidate Perdition","Expecations Natural","Taxi Kick","Factory Dragon","Comforts Rush","Mask Peach","Zoolander Fiction","Breakfast Goldfinger","Virgin Daisy","Midnight Westward","Strangers Graffiti","Freaky Pocus","Musketeers Wait","Idaho Love","Bikini Borrowers","United Pilot","Ferris Mother","Orient Closer","Conversation Downhill","Holocaust Highball","Satisfaction Confidential","Dying Maker","Rear Trading","Lady Stage","Noon Papi","League Hellfighters","Lawless Vision","Roots Remember","Slacker Liaisons","Waterfront Deliverance","Newton Labyrinth","Rock Instinct","Confused Candles","Teen Apollo","Gandhi Kwai","Louisiana Harry","Joon Northwest","Hanover Galaxy","Potter Connecticut","Intentions Empire","Beach Heartbreakers","Jekyll Frogmen","French Holiday","Egypt Tenenbaums","Perfect Groove","Jericho Mulan","Greek Everyone","Poseidon Forever","Flintstones Happiness","Majestic Floats","Sugar Wonka","Rocky War","Streak Ridgemont","Reap Unfaithful","Homeward Cider","Bull Shawshank","Bonnie Holocaust","Quills Bull","Pilot Hoosiers","Indian Love","Jeepers Wedding","Lock Rear","Mummy Creatures","Destiny Saturday","Motions Details","Willow Tracy","Gaslight Crusade","Pickup Driving","Caddyshack Jedi","Graduate Lord","Silence Kane","Baked Cleopatra","Chicago North","Wanda Chamber","Casablanca Super","Summer Scarface","Watch Tracy","Artist Coldblooded","West Lion","Conquerer Nuts","Moulin Wake","Trap Guys","Attacks Hate","Pride Alamo","Coldblooded Darling","Pure Runner","Creatures Shakespeare","Slipper Fidelity","Sagebrush Clueless","Paycheck Wait","Pluto Oleander","Uprising Uptown","Hall Cassidy","Craft Outfield","Wizard Coldblooded","Mermaid Insects","Command Darling","Dude Blindness","Daisy Menagerie","Rules Human","Varsity Trip","Patriot Roman","Worst Banger","Army Flintstones","Words Hunter","Mosquito Armageddon","Circus Youth","Boiled Dares","Hunting Musketeers","Betrayed Rear","Submarine Bed","Panther Reds","Charade Duffel","Lonely Elephant","Labyrinth League","Holiday Games","Necklace Outbreak","Odds Boogie","Vietnam Smoochy","Edge Kissing","Lust Lock","Madison Trap","Cyclone Family","Steers Armageddon","Human Graffiti","Hysterical Grail","Valley Packer","Translation Summer","Model Fish","Anthem Luke","Divine Resurrection","Scissorhands Slums","Panky Submarine","Entrapment Satisfaction","Sierra Divide","Rings Heartbreakers","Siege Madre","Sweet Brotherhood","Holes Brannigan","Shrek License","Tootsie Pilot","Airplane Sierra","Sons Interview","Worker Tarzan","Spirit Flintstones","Cabin Flash","Modern Dorado","Manchurian Curtain","Illusion Amelie","Devil Desire","Dirty Ace","Ship Wonderland","Loser Hustler","Nash Chocolat","Monster Spartacus","Wasteland Divine","Image Princess","Outlaw Hanky","Paris Weekend","Jaws Harry","Games Bowfinger","Day Unfaithful","Troopers Metal","Mother Oleander","Shanghai Tycoon","Deep Crusade","Grinch Massage","Impossible Prejudice","Town Ark","Donnie Alley","Saddle Antitrust","Turn Star","Notorious Reunion","Lovely Jingle","Stock Glass","Glass Dying","Virtual Spoilers","Blindness Gun","Kane Exorcist","Uncut Suicides","Shrunk Divine","Searchers Wait","Pajama Jawbreaker","Nemo Campus","Wrath Mile","Tomatoes Hellfighters","Dances None","Personal Ladybugs","Shane Darkness","Home Pity","Elephant Trojan","Splash Gump","Peach Innocent","Stampede Disturbing","Greedy Roots","Gold River","Analyze Hoosiers","Confessions Maguire","Madre Gables","Alley Evolution","Hamlet Wisdom","Werewolf Lola","Creepers Kane","Tenenbaums Command","Express Lonely","Usual Untouchables","Chamber Italian","Everyone Craft","Past Suicides","Anonymous Human","Behavior Runaway","Forever Candidate","Tuxedo Mile","Natural Stock","Saturn Name","Arabia Dogma","State Wasteland","Mulan Moon","Bedazzled Married","Hollywood Anonymous","Hunger Roof","Breaking Home","Raging Airplane","Bright Encounters","Jingle Sagebrush","Mile Mulan","Lawrence Love","Bilko Anonymous","Monterey Labyrinth","Sassy Packer","Identity Lover","Darkness War","Opposite Necklace","Robbery Bright","Citizen Shrek","Party Knock","Exorcist Sting","Spiking Element","Flash Wars","Microcosmos Paradise","Drums Dynamite","Chisum Behavior","Spinal Rocky","Purple Movie","Connecticut Tramp","Cincinatti Whisperer","Daddy Pittsburgh","Memento Zoolander","Date Speed","Super Wyoming","Moonwalker Fool","Champion Flatliners","Wyoming Storm","Lucky Flying","Hook Chariots","Dangerous Uptown","Mob Duffel","Silverado Goldfinger","Evolution Alter","Valentine Vanishing","Savannah Town","Alabama Devil","Temple Attraction","Side Ark","Brannigan Sunrise","Lost Bird","Hedwig Alter","Smoochy Control","Blanket Beverly","California Birds","African Egg","Adaptation Holes","Meet Chocolate","Tycoon Gathering","Massage Image","Liberty Magnificent","Window Side","Loverboy Attacks","Sorority Queen","War Notting","Uptown Young","Born Spinal","Finding Anaconda","Speakeasy Date","Gunfighter Mussolini","Mighty Luck","Crow Grease","Pittsburgh Hunchback","Flight Lies","Minority Kiss","Vampire Whale","North Tequila","Feathers Metal","Dragon Squad","Reef Salute","Spirited Casualties","Twisted Pirates","Stone Fire","Ending Crowds","Darko Dorado","Language Cowboy","Thin Sagebrush","Drumline Cyclone","Prix Undefeated","Mod Secretary","Cranes Reservoir","Opus Ice","Theory Mermaid","Towers Hurricane","October Submarine","Rider Caddyshack","Iron Moon","Fugitive Maguire","Santa Paris","Autumn Crow","Birch Antitrust","Magnolia Forrester","Song Hedwig","Bowfinger Gables","Lord Arizona","Bugsy Song","Stranger Strangers","Ties Hunger","Potluck Mixed","Bird Independence","Frida Slipper","Beethoven Exorcist","Trainspotting Strangers","Gathering Calendar","Beast Hunchback","Right Cranes","Reservoir Adaptation","Gone Trouble","Hollow Jeopardy","Wars Pluto","Grail Frankenstein","Blood Argonauts","Mystic Truman","Clockwork Paradise","Lover Truman","Oleander Clue","Rollercoaster Bringing","Jawbreaker Brooklyn","Superfly Trip","Smile Earring","Paths Control","Frogmen Breaking","Lolita World","Sensibility Rear","Halloween Nuts","Fiddler Lost","Antitrust Tomatoes","Run Pacific","Lambs Cincinatti","Luck Opus","Wagon Jaws","Maker Gables","Element Freddy","Jeopardy Encino","Amelie Hellfighters","Madigan Dorado","Elizabeth Shane","Doubtfire Labyrinth","Notting Speakeasy","Beneath Rush","Stage World","Spoilers Hellfighters","Life Twisted","Casualties Encino","Dolls Rage","Nuts Ties","Crazy Home","Speed Suit","Caribbean Liberty","Daughter Madigan","Matrix Snowman","Miracle Virtual","Monsoon Cause","Hotel Happiness","Ghostbusters Elf","Dwarfs Alter","Jungle Closer","Snatchers Montezuma","Kramer Chocolate","Vanilla Day","Won Dares","Platoon Instinct","Diary Panic","Intolerable Intentions","Frisco Forrest","Legend Jedi","Drop Waterfront","Wonderful Drop","Legally Secretary","Ali Forever","Victory Academy","Holy Tadpole","Spartacus Cheaper","Darling Breaking","Dares Pluto","Zhivago Core","Anything Savannah","Guys Falcon","Impact Aladdin","Birdcage Casper","Gilbert Pelican","Random Go","Maguire Apache","Wisdom Worker","Reds Pocus","King Evolution","Montezuma Command","Desire Alien","Godfather Diary","Soldiers Evolution","Chaplin License","Untouchables Sunrise","Sunset Racer","Shining Roses","Unfaithful Kill","Maude Mod","Park Citizen","Harold French","Chitty Lock","Pet Haunting","Runaway Tenenbaums","Saints Bride","Records Zorro","Casper Dragonfly","Ballroom Mockingbird","Rebel Airport","Baby Hall","Soup Wisdom","World Leathernecks","Magnificent Chitty","Jumanji Blade","Grosse Wonderful","Lights Deer","Hoosiers Birdcage","Clyde Theory","Runner Madigan","Tarzan Videotape","Punk Divorce","Gosford Donnie","Papi Necklace","Destination Jerk","Vertigo Northwest","Crusade Honey","Menagerie Rushmore","Leathernecks Dwarfs","Elf Murder","Early Home","Stallion Sundance","Hawk Chill","Clerks Angels","Newsies Story","Clue Grail","Young Language","Vision Torque","Doctor Grail","Squad Fish","Magic Mallrats","Divorce Shining","Treatment Jekyll","Cruelty Unforgiven","Bang Kwai","Heavenly Gun","Dozen Lion","Fire Wolves","Control Anthem","Mulholland Beast","Ace Goldfinger","Pizza Jumanji","License Weekend","Ishtar Rocketeer","Cowboy Doom","Eve Resurrection","President Bang","Vanished Garden","Connection Microcosmos","Duffel Apocalypse","Lesson Cleopatra","Panic Club","Sense Greek","Luke Mummy","Bulworth Commandments","Happiness United","Dumbo Lust","Desperate Trainspotting","Rushmore Mermaid","Tequila Past","Simon North","Frontier Cabin","School Jacket","Youth Kick","Oklahoma Jumanji","Killer Innocent","Sling Luke","Cassidy Wyoming","Graceland Dynamite","Comancheros Enemy","Ladybugs Armageddon","Japanese Run","Warlock Werewolf","Duck Racer","Bed Highball","Apocalypse Flamingos","Extraordinary Conquerer","Wild Apollo","Italian African","Texas Watch","Bubble Grosse","Haunted Antitrust","Terminator Club","Jersey Sassy","Watership Frontier","Phantom Glory","Fever Empire","Mussolini Spoilers","Bunch Minds","Glory Tracy","Full Flatliners","Conspiracy Spirit","Traffic Hobbit","Hunter Alter","Informer Double","Freedom Cleopatra","Braveheart Human","Seven Swarm","Mannequin Worst","Private Drop","Train Bunch","Hardly Robbers","Mixed Doors","Sophie's Choice"],[4.99,0.99,0.99,2.99,0.99,0.99,4.99,4.99,2.99,4.99,0.99,0.99,4.99,0.99,2.99,4.99,4.99,0.99,0.99,4.99,2.99,4.99,2.99,2.99,2.99,2.99,0.99,4.99,4.99,0.99,2.99,0.99,2.99,0.99,4.99,4.99,0.99,0.99,4.99,0.99,2.99,0.99,0.99,2.99,4.99,4.99,2.99,0.99,0.99,0.99,2.99,2.99,0.99,4.99,4.99,4.99,4.99,0.99,0.99,2.99,4.99,4.99,0.99,2.99,4.99,0.99,2.99,2.99,2.99,0.99,0.99,2.99,4.99,2.99,0.99,4.99,0.99,4.99,0.99,0.99,0.99,4.99,0.99,2.99,2.99,2.99,0.99,2.99,0.99,4.99,2.99,2.99,4.99,0.99,0.99,2.99,2.99,0.99,4.99,4.99,0.99,0.99,4.99,2.99,2.99,4.99,4.99,4.99,2.99,4.99,2.99,0.99,0.99,4.99,2.99,0.99,4.99,2.99,0.99,2.99,2.99,0.99,0.99,0.99,4.99,4.99,0.99,0.99,2.99,0.99,0.99,2.99,2.99,4.99,2.99,0.99,0.99,4.99,2.99,0.99,2.99,0.99,2.99,4.99,0.99,0.99,4.99,2.99,0.99,0.99,4.99,0.99,2.99,4.99,4.99,0.99,4.99,0.99,2.99,2.99,4.99,0.99,2.99,0.99,0.99,2.99,0.99,2.99,2.99,4.99,0.99,0.99,0.99,4.99,4.99,0.99,0.99,4.99,2.99,4.99,4.99,4.99,4.99,2.99,0.99,0.99,4.99,0.99,0.99,4.99,2.99,4.99,4.99,4.99,4.99,2.99,2.99,0.99,2.99,2.99,2.99,2.99,2.99,4.99,0.99,0.99,4.99,2.99,4.99,4.99,0.99,0.99,2.99,4.99,2.99,0.99,2.99,0.99,4.99,4.99,2.99,2.99,4.99,0.99,0.99,4.99,4.99,4.99,4.99,2.99,4.99,2.99,0.99,4.99,0.99,4.99,0.99,0.99,2.99,2.99,4.99,0.99,2.99,2.99,0.99,2.99,0.99,2.99,0.99,0.99,0.99,0.99,0.99,4.99,0.99,4.99,2.99,0.99,0.99,4.99,0.99,2.99,4.99,4.99,2.99,2.99,0.99,0.99,4.99,4.99,4.99,0.99,2.99,2.99,4.99,2.99,0.99,2.99,2.99,2.99,0.99,2.99,0.99,0.99,2.99,0.99,4.99,2.99,4.99,0.99,2.99,0.99,0.99,4.99,0.99,2.99,2.99,2.99,4.99,0.99,2.99,4.99,2.99,2.99,0.99,0.99,0.99,0.99,0.99,2.99,4.99,4.99,4.99,0.99,4.99,2.99,2.99,0.99,0.99,4.99,4.99,4.99,4.99,4.99,4.99,0.99,2.99,0.99,0.99,0.99,4.99,2.99,0.99,0.99,2.99,4.99,4.99,4.99,0.99,0.99,0.99,0.99,0.99,4.99,2.99,0.99,0.99,2.99,0.99,0.99,4.99,0.99,4.99,4.99,2.99,4.99,0.99,4.99,2.99,4.99,2.99,4.99,2.99,4.99,2.99,0.99,0.99,0.99,0.99,0.99,2.99,0.99,4.99,4.99,0.99,0.99,4.99,0.99,4.99,0.99,2.99,2.99,0.99,0.99,0.99,4.99,2.99,4.99,0.99,0.99,0.99,2.99,4.99,4.99,4.99,2.99,2.99,0.99,0.99,0.99,2.99,4.99,2.99,2.99,2.99,2.99,2.99,4.99,4.99,2.99,4.99,2.99,2.99,2.99,2.99,2.99,4.99,4.99,4.99,0.99,4.99,2.99,2.99,0.99,2.99,4.99,0.99,0.99,2.99,2.99,2.99,4.99,4.99,0.99,4.99,2.99,4.99,2.99,4.99,0.99,2.99,2.99,4.99,0.99,4.99,4.99,0.99,4.99,2.99,4.99,4.99,0.99,4.99,4.99,0.99,0.99,2.99,4.99,0.99,0.99,0.99,4.99,2.99,2.99,2.99,2.99,4.99,0.99,2.99,2.99,2.99,4.99,4.99,0.99,4.99,4.99,0.99,2.99,0.99,0.99,0.99,4.99,2.99,0.99,2.99,2.99,0.99,4.99,0.99,2.99,2.99,2.99,0.99,2.99,0.99,2.99,4.99,4.99,4.99,0.99,0.99,2.99,4.99,4.99,0.99,4.99,4.99,0.99,4.99,2.99,0.99,0.99,2.99,4.99,4.99,2.99,4.99,0.99,4.99,4.99,4.99,4.99,4.99,4.99,2.99,2.99,2.99,0.99,2.99,0.99,2.99,4.99,2.99,4.99,4.99,4.99,2.99,2.99,2.99,4.99,0.99,0.99,0.99,4.99,2.99,2.99,2.99,4.99,2.99,4.99,0.99,0.99,4.99,4.99,2.99,2.99,4.99,0.99,0.99,0.99,0.99,2.99,4.99,2.99,0.99,4.99,2.99,2.99,0.99,0.99,0.99,2.99,0.99,4.99,2.99,2.99,4.99,2.99,2.99,2.99,2.99,4.99,2.99,2.99,4.99,4.99,0.99,0.99,2.99,4.99,4.99,4.99,2.99,0.99,2.99,2.99,0.99,2.99,2.99,0.99,4.99,4.99,0.99,2.99,2.99,2.99,0.99,2.99,0.99,0.99,0.99,0.99,2.99,4.99,4.99,0.99,2.99,0.99,0.99,4.99,2.99,4.99,2.99,2.99,2.99,4.99,4.99,0.99,2.99,4.99,4.99,0.99,4.99,0.99,4.99,2.99,2.99,0.99,4.99,0.99,2.99,0.99,0.99,0.99,0.99,2.99,4.99,4.99,4.99,0.99,0.99,4.99,0.99,0.99,2.99,2.99,4.99,0.99,0.99,2.99,2.99,2.99,4.99,2.99,0.99,4.99,2.99,2.99,4.99,4.99,4.99,4.99,0.99,4.99,4.99,4.99,4.99,2.99,0.99,4.99,0.99,4.99,0.99,0.99,0.99,2.99,4.99,0.99,4.99,2.99,2.99,0.99,2.99,4.99,2.99,2.99,2.99,4.99,2.99,2.99,2.99,0.99,0.99,4.99,2.99,4.99,0.99,2.99,2.99,2.99,0.99,4.99,4.99,0.99,4.99,4.99,0.99,0.99,0.99,0.99,4.99,0.99,0.99,4.99,0.99,4.99,0.99,2.99,4.99,2.99,4.99,0.99,0.99,4.99,2.99,4.99,4.99,2.99,4.99,4.99,0.99,0.99,4.99,2.99,2.99,4.99,4.99,2.99,4.99,2.99,0.99,4.99,0.99,4.99,4.99,2.99,2.99,4.99,2.99,2.99,0.99,0.99,0.99,2.99,0.99,2.99,0.99,0.99,2.99,4.99,0.99,2.99,4.99,2.99,4.99,2.99,0.99,4.99,2.99,2.99,0.99,4.99,0.99,4.99,4.99,4.99,4.99,0.99,0.99,2.99,0.99,2.99,4.99,2.99,4.99,2.99,4.99,4.99,4.99,4.99,2.99,4.99,4.99,0.99,2.99,0.99,2.99,2.99,4.99,2.99,4.99,2.99,4.99,4.99,0.99,4.99,2.99,4.99,4.99,0.99,0.99,4.99,4.99,2.99,0.99,2.99,4.99,0.99,0.99,0.99,2.99,2.99,0.99,4.99,4.99,0.99,2.99,2.99,4.99,2.99,2.99,0.99,0.99,2.99,0.99,4.99,0.99,2.99,0.99,0.99,2.99,4.99,4.99,0.99,0.99,4.99,0.99,0.99,2.99,2.99,4.99,0.99,2.99,0.99,0.99,2.99,4.99,4.99,0.99,0.99,2.99,2.99,2.99,2.99,4.99,4.99,0.99,0.99,4.99,0.99,4.99,0.99,0.99,2.99,2.99,0.99,2.99,0.99,0.99,2.99,4.99,4.99,4.99,4.99,2.99,4.99,2.99,2.99,4.99,2.99,4.99,4.99,0.99,0.99,0.99,0.99,4.99,4.99,2.99,2.99,2.99,0.99,4.99,2.99,4.99,0.99,4.99,4.99,0.99,0.99,2.99,0.99,2.99,4.99,0.99,0.99,0.99,2.99,2.99,2.99,4.99,2.99,0.99,4.99,0.99,4.99,4.99,4.99,4.99,0.99,2.99,4.99,2.99,2.99,2.99,2.99,2.99,4.99,2.99,4.99,0.99,2.99,4.99,2.99,4.99,4.99,2.99,2.99,4.99],[34,33,32,32,32,32,32,31,31,31,31,31,31,31,31,31,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,28,28,28,28,28,28,28,28,28,28,28,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,5,5,5,5,5,5,5,5,5,5,5,5,5,5,4,4,4,1],[169.66,32.67,31.68,95.68,31.68,31.68,159.68,154.69,92.69,154.69,30.69,30.69,154.69,30.69,92.69,154.69,149.7,29.7,29.7,149.7,89.7,149.7,89.7,89.7,89.7,89.7,29.7,149.7,149.7,29.7,89.7,29.7,86.71,28.71,144.71,144.71,28.71,28.71,144.71,28.71,86.71,28.71,28.71,86.71,144.71,144.71,86.71,27.72,27.72,27.72,83.72,83.72,27.72,139.72,139.72,139.72,139.72,27.72,26.73,80.73,134.73,134.73,26.73,80.73,134.73,26.73,80.73,80.73,80.73,26.73,26.73,80.73,134.73,80.73,26.73,134.73,26.73,134.73,26.73,26.73,26.73,134.73,26.73,80.73,77.74,77.74,25.74,77.74,25.74,129.74,77.74,77.74,129.74,25.74,25.74,77.74,77.74,25.74,129.74,129.74,25.74,25.74,129.74,77.74,77.74,129.74,129.74,129.74,74.75,124.75,74.75,24.75,24.75,124.75,74.75,24.75,124.75,74.75,24.75,74.75,74.75,24.75,24.75,24.75,124.75,124.75,24.75,24.75,74.75,24.75,24.75,74.75,74.75,124.75,74.75,23.76,23.76,119.76,71.76,23.76,71.76,23.76,71.76,119.76,23.76,23.76,119.76,71.76,23.76,23.76,119.76,23.76,71.76,119.76,119.76,23.76,119.76,23.76,71.76,71.76,119.76,23.76,71.76,23.76,23.76,71.76,23.76,71.76,68.77,114.77,22.77,22.77,22.77,114.77,114.77,22.77,22.77,114.77,68.77,114.77,114.77,114.77,114.77,68.77,22.77,22.77,114.77,22.77,22.77,114.77,68.77,114.77,114.77,114.77,114.77,68.77,68.77,22.77,68.77,68.77,68.77,68.77,68.77,114.77,21.78,21.78,109.78,65.78,109.78,109.78,21.78,21.78,65.78,109.78,65.78,21.78,65.78,21.78,109.78,109.78,65.78,65.78,109.78,21.78,21.78,109.78,109.78,109.78,109.78,65.78,109.78,65.78,21.78,109.78,21.78,109.78,21.78,21.78,65.78,65.78,109.78,21.78,65.78,62.79,20.79,62.79,20.79,62.79,20.79,20.79,20.79,20.79,20.79,104.79,20.79,104.79,62.79,20.79,20.79,104.79,20.79,62.79,104.79,104.79,62.79,62.79,20.79,20.79,104.79,104.79,104.79,20.79,62.79,62.79,104.79,62.79,20.79,62.79,62.79,62.79,20.79,62.79,20.79,20.79,62.79,20.79,104.79,62.79,104.79,20.79,62.79,20.79,20.79,104.79,20.79,59.8,59.8,59.8,99.8,19.8,59.8,99.8,59.8,59.8,19.8,19.8,19.8,19.8,19.8,59.8,99.8,99.8,99.8,19.8,99.8,59.8,59.8,19.8,19.8,99.8,99.8,99.8,99.8,99.8,99.8,19.8,59.8,19.8,19.8,19.8,99.8,59.8,19.8,19.8,59.8,99.8,99.8,99.8,18.81,18.81,18.81,18.81,18.81,94.81,56.81,18.81,18.81,56.81,18.81,18.81,94.81,18.81,94.81,94.81,56.81,94.81,18.81,94.81,56.81,94.81,56.81,94.81,56.81,94.81,56.81,18.81,18.81,18.81,18.81,18.81,56.81,18.81,94.81,94.81,18.81,18.81,94.81,18.81,94.81,18.81,56.81,56.81,18.81,17.82,17.82,89.82,53.82,89.82,17.82,17.82,17.82,53.82,89.82,89.82,89.82,53.82,53.82,17.82,17.82,17.82,53.82,89.82,53.82,53.82,53.82,53.82,53.82,89.82,89.82,53.82,89.82,53.82,53.82,53.82,53.82,53.82,89.82,89.82,89.82,17.82,89.82,53.82,53.82,17.82,53.82,89.82,16.83,16.83,50.83,50.83,50.83,84.83,84.83,16.83,84.83,50.83,84.83,50.83,84.83,16.83,50.83,50.83,84.83,16.83,84.83,84.83,16.83,84.83,50.83,84.83,84.83,16.83,84.83,84.83,16.83,16.83,50.83,84.83,16.83,16.83,16.83,84.83,50.83,50.83,50.83,50.83,84.83,16.83,50.83,50.83,50.83,84.83,84.83,16.83,84.83,79.84,15.84,47.84,15.84,15.84,15.84,79.84,47.84,15.84,47.84,47.84,15.84,79.84,15.84,47.84,47.84,47.84,15.84,47.84,15.84,47.84,79.84,79.84,79.84,15.84,15.84,47.84,79.84,79.84,15.84,79.84,79.84,15.84,79.84,47.84,15.84,15.84,47.84,79.84,79.84,47.84,79.84,15.84,79.84,79.84,79.84,79.84,79.84,79.84,47.84,47.84,47.84,15.84,47.84,14.85,44.85,74.85,44.85,74.85,74.85,74.85,44.85,44.85,44.85,74.85,14.85,14.85,14.85,74.85,44.85,44.85,44.85,74.85,44.85,74.85,14.85,14.85,74.85,74.85,44.85,44.85,74.85,14.85,14.85,14.85,14.85,44.85,74.85,44.85,14.85,74.85,44.85,44.85,14.85,14.85,14.85,44.85,14.85,74.85,44.85,44.85,74.85,44.85,44.85,44.85,41.86,69.86,41.86,41.86,69.86,69.86,13.86,13.86,41.86,69.86,69.86,69.86,41.86,13.86,41.86,41.86,13.86,41.86,41.86,13.86,69.86,69.86,13.86,41.86,41.86,41.86,13.86,41.86,13.86,13.86,13.86,13.86,41.86,69.86,69.86,13.86,41.86,13.86,13.86,69.86,41.86,69.86,41.86,41.86,41.86,69.86,69.86,12.87,38.87,64.87,64.87,12.87,64.87,12.87,64.87,38.87,38.87,12.87,64.87,12.87,38.87,12.87,12.87,12.87,12.87,38.87,64.87,64.87,64.87,12.87,12.87,64.87,12.87,12.87,38.87,38.87,64.87,12.87,12.87,38.87,38.87,38.87,64.87,38.87,12.87,64.87,38.87,38.87,64.87,64.87,64.87,64.87,12.87,64.87,64.87,64.87,64.87,38.87,12.87,59.88,11.88,59.88,11.88,11.88,11.88,35.88,59.88,11.88,59.88,35.88,35.88,11.88,35.88,59.88,35.88,35.88,35.88,59.88,35.88,35.88,35.88,11.88,11.88,59.88,35.88,59.88,11.88,35.88,35.88,35.88,11.88,59.88,59.88,11.88,59.88,54.89,10.89,10.89,10.89,10.89,54.89,10.89,10.89,54.89,10.89,54.89,10.89,32.89,54.89,32.89,54.89,10.89,10.89,54.89,32.89,54.89,54.89,32.89,54.89,54.89,10.89,10.89,54.89,32.89,32.89,54.89,54.89,32.89,54.89,32.89,10.89,54.89,10.89,54.89,49.9,29.9,29.9,49.9,29.9,29.9,9.9,9.9,9.9,29.9,9.9,29.9,9.9,9.9,29.9,49.9,9.9,29.9,49.9,29.9,49.9,29.9,9.9,49.9,29.9,29.9,9.9,49.9,9.9,49.9,49.9,49.9,49.9,9.9,9.9,29.9,9.9,29.9,44.91,26.91,44.91,26.91,44.91,44.91,44.91,44.91,26.91,44.91,44.91,8.91,26.91,8.91,26.91,26.91,44.91,26.91,44.91,26.91,44.91,44.91,8.91,44.91,26.91,44.91,44.91,8.91,8.91,44.91,44.91,26.91,8.91,26.91,44.91,8.91,8.91,8.91,26.91,26.91,8.91,44.91,44.91,8.91,23.92,23.92,39.92,23.92,23.92,7.92,7.92,23.92,7.92,39.92,7.92,23.92,7.92,7.92,23.92,39.92,39.92,7.92,7.92,39.92,7.92,7.92,23.92,23.92,39.92,7.92,23.92,7.92,7.92,23.92,39.92,39.92,7.92,7.92,23.92,23.92,20.93,20.93,34.93,34.93,6.93,6.93,34.93,6.93,34.93,6.93,6.93,20.93,20.93,6.93,20.93,6.93,6.93,20.93,34.93,34.93,34.93,34.93,20.93,34.93,20.93,20.93,34.93,20.93,34.93,34.93,6.93,6.93,6.93,6.93,34.93,34.93,20.93,20.93,17.94,5.94,29.94,17.94,29.94,5.94,29.94,29.94,5.94,5.94,17.94,5.94,17.94,29.94,5.94,5.94,5.94,17.94,17.94,17.94,29.94,17.94,5.94,29.94,5.94,29.94,29.94,29.94,29.94,5.94,17.94,24.95,14.95,14.95,14.95,14.95,14.95,24.95,14.95,24.95,4.95,14.95,24.95,14.95,24.95,19.96,11.96,11.96,4.99]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>count<\/th>\n      <th>rental_amt<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>The most frequently rented movie, 34 times, is 'Bucket Brotherhood' followed by Rocketeer Mother, 33 times.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

film_rank_dplyr <- as.data.frame("code me")

sp_print_df(film_rank_dplyr)
```

<!--html_preserve--><div id="htmlwidget-a98751c486bb4e6734fc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a98751c486bb4e6734fc">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 11 What is the rental distribution/DVD for the top two rented films?

From the previous exercise we know that the top two films are `Bucket Brotherhood` and `Rocketeer Mother`.  

To answer this question we look at the `rental`, `inventory`, and `film` tables again.  

Instead of looking at the film level, we need to drill down to the individual dvd's for each film to answer this question.



```r
film_rank2_sql <- dbGetQuery(con,
"select i.store_id,i.film_id,f.title,i.inventory_id,count(*) 
   from rental r join inventory i on r.inventory_id = i.inventory_id 
        join film f on i.film_id = f.film_id
  where i.film_id in (103,738)
group by i.store_id,i.film_id,f.title,i.inventory_id")

sp_print_df(film_rank2_sql)
```

<!--html_preserve--><div id="htmlwidget-90472fc291eea3b37ad9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-90472fc291eea3b37ad9">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16"],[2,2,1,1,1,2,1,2,2,1,1,1,1,2,2,2],[738,738,738,738,103,738,738,103,103,103,738,103,103,738,103,103],["Rocketeer Mother","Rocketeer Mother","Rocketeer Mother","Rocketeer Mother","Bucket Brotherhood","Rocketeer Mother","Rocketeer Mother","Bucket Brotherhood","Bucket Brotherhood","Bucket Brotherhood","Rocketeer Mother","Bucket Brotherhood","Bucket Brotherhood","Rocketeer Mother","Bucket Brotherhood","Bucket Brotherhood"],[3367,3364,3361,3362,465,3365,3363,472,470,468,3360,467,466,3366,469,471],[5,5,3,2,3,4,5,2,5,5,5,4,5,4,5,5]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>inventory_id<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>The 'Bucket Brotherhood' and 'Rocketeer Mother' DVD's are equally distributed between the two stores, 4 dvd's each per film.  The 'Bucket Brotherhood' was rented 17 times from both stores.  The 'Rocketeer Mother' was rented 15 times from store 1 and 18 times from store 2.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

film_rank2_dplyr <- as.data.frame("code me")

sp_print_df(film_rank2_dplyr)
```

<!--html_preserve--><div id="htmlwidget-6c084255227fcd56827e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6c084255227fcd56827e">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


### 12.  List staffing information for store 1 associated with the `Bucket Brother` rentals? 

To answer this question we look at the `rental`, `inventory`, `film`, `staff`, `address`, `city`, and `country` tables.  


```r
film_103_details_sql <- dbGetQuery(con,
"select i.store_id,i.film_id,f.title,i.inventory_id inv_id,i.store_id inv_store_id
       ,r.rental_date::date rented,r.return_date::date returned
       ,s.staff_id,s.store_id staff_store_id,concat(s.first_name,' ',s.last_name) staff,ctry.country
   from rental r join inventory i on r.inventory_id = i.inventory_id 
        join film f on i.film_id = f.film_id
        join staff s on r.staff_id = s.staff_id
        join address a on s.address_id = a.address_id
        join city c on a.city_id = c.city_id
        join country ctry on c.country_id = ctry.country_id
  where i.film_id in (103)
    and r.rental_date::date between '2005-05-01'::date and '2005-06-01'::date
order by r.rental_date
")
sp_print_df(film_103_details_sql)
```

<!--html_preserve--><div id="htmlwidget-cc911bce9136bf4e7dfd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-cc911bce9136bf4e7dfd">{"x":{"filter":"none","data":[["1","2","3","4","5"],[1,2,2,1,2],[103,103,103,103,103],["Bucket Brotherhood","Bucket Brotherhood","Bucket Brotherhood","Bucket Brotherhood","Bucket Brotherhood"],[466,470,471,468,469],[1,2,2,1,2],["2005-05-25","2005-05-25","2005-05-30","2005-05-31","2005-05-31"],["2005-05-27","2005-05-29","2005-06-05","2005-06-03","2005-06-02"],[1,1,1,2,2],[1,1,1,2,2],["Mike Hillyer","Mike Hillyer","Mike Hillyer","Jon Stephens","Jon Stephens"],["Canada","Canada","Canada","Australia","Australia"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>inv_id<\/th>\n      <th>inv_store_id<\/th>\n      <th>rented<\/th>\n      <th>returned<\/th>\n      <th>staff_id<\/th>\n      <th>staff_store_id<\/th>\n      <th>staff<\/th>\n      <th>country<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,4,5,8,9]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>In a previous exercise we saw that store 1 based in Canada and store 2 based in Austrailia each had one employee, staff_id 1 and 2 respectively.  We see that Mike from store 1, Canada, had transactions in store 1 and store 2 on 5/25/2005.  Similarly Jon from store 2, Australia, had transaction in store 2 and store 1 on 5/31/2005.  Is this phsically possible, or a key in error?</font>

#### Replicate the output above using dplyr syntax.

column         | mapping               |definition
---------------|-----------------------|-----------
inv_id         |inventory.inventory_id |
inv_store_id   |inventory.store_id     |
rented         |rental.rental_date     |
returned       |rental.return_date     |
staff_store_id |store.store_id         |
staff          |first_name+last_name   |


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

film_103_details_dplyr <- as.data.frame("code me")

sp_print_df(film_103_details_dplyr)
```

<!--html_preserve--><div id="htmlwidget-6c3e37b0fa7ac693f7cc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6c3e37b0fa7ac693f7cc">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->



### 13.  Which film(s) have never been rented

To answer this question we look at the `film`, `inventory` and `rental` tables.


```r
never_rented_dvds_sql <- dbGetQuery(con,
'select i.store_id,f.film_id, f.title,f.description, i.inventory_id
   from film f join inventory i on f.film_id = i.film_id
        left join rental r on i.inventory_id = r.inventory_id 
  where r.inventory_id is null 
'
)

sp_print_df(never_rented_dvds_sql)
```

<!--html_preserve--><div id="htmlwidget-88984347109043009685" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-88984347109043009685">{"x":{"filter":"none","data":[["1","2"],[2,2],[1,1001],["Academy Dinosaur","Sophie's Choice"],["A Epic Drama of a Feminist And a Mad Scientist who must Battle a Teacher in The Canadian Rockies","orphaned language_id=10"],[5,4583]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>description<\/th>\n      <th>inventory_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>There are only two movies that have not been rented, Academy Dinousaur and Sophie's Choice.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

never_rented_dvds_dplyr <- as.data.frame("code me")

sp_print_df(never_rented_dvds_dplyr)
```

<!--html_preserve--><div id="htmlwidget-d80799441e19bf040cbf" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d80799441e19bf040cbf">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 14.  How many films are in each film rating?

To answer this question we look at the `film` table to answer this question.


```r
film_ratings_sql <- dbGetQuery(con,
'select f.rating,count(*)
   from film f 
group by f.rating
order by count(*) desc
'
)

sp_print_df(film_ratings_sql)
```

<!--html_preserve--><div id="htmlwidget-5bc260cc0681d28b4458" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5bc260cc0681d28b4458">{"x":{"filter":"none","data":[["1","2","3","4","5"],["PG-13","NC-17","R","PG","G"],[223,210,195,195,178]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>rating<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>There are 5 ratings and all 5 have roughly 200  movies.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

film_ratings_dplyr <- as.data.frame("code me")

sp_print_df(film_ratings_dplyr)
```

<!--html_preserve--><div id="htmlwidget-5e6debc8bc477449b2d2" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5e6debc8bc477449b2d2">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 15.  What are the different film categories?

To answer this question we look at the `category` table to answer this question.


```r
film_categories_sql <- dbGetQuery(con,
'select * from category'
)

sp_print_df(film_categories_sql)
```

<!--html_preserve--><div id="htmlwidget-a769f33e9bc2b11da24f" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a769f33e9bc2b11da24f">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16"],[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],["Action","Animation","Children","Classics","Comedy","Documentary","Drama","Family","Foreign","Games","Horror","Music","New","Sci-Fi","Sports","Travel"],["2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z","2006-02-15T17:46:27Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>category_id<\/th>\n      <th>name<\/th>\n      <th>last_update<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":1},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>There are 16 different categories</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

film_categories_dplyr <- as.data.frame("code me")

sp_print_df(film_categories_dplyr)
```

<!--html_preserve--><div id="htmlwidget-5afb8971f37330fd8cc4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5afb8971f37330fd8cc4">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 16. How many DVD's are in each film categeory?

To answer this question we look at the `category` table again.


```r
film_categories2_sql <- dbGetQuery(con,
'select c.name,count(*) count
   from category c join film_category fc on c.category_id = fc.category_id
group by c.name
order by count(*) desc
'
)

sp_print_df(film_categories2_sql)
```

<!--html_preserve--><div id="htmlwidget-e9ae68682532316859d5" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-e9ae68682532316859d5">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16"],["Sports","Foreign","Family","Documentary","Animation","Action","New","Drama","Sci-Fi","Games","Children","Comedy","Travel","Classics","Horror","Music"],[74,73,69,69,66,64,63,63,61,61,60,58,57,57,56,51]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>name<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>There are 16 film categories.  The highest category, Sports, has 77 films followed by the International category which has 76 film.  What is an example of an international category film where all films are currently in English?</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

film_categories2_dplyr <- as.data.frame("code me")

sp_print_df(film_categories2_dplyr)
```

<!--html_preserve--><div id="htmlwidget-32dc6527565d6d2fa8eb" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-32dc6527565d6d2fa8eb">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 17.  Which films are listed in multiple categories?

To answer this question we look at the `film`, `film_category` and `category` tables.


```r
multiple_categories_sql <- dbGetQuery(con,
'select f.film_id, f.title,c.name
   from film_category fc join film f on fc.film_id = f.film_id
        join category c on fc.category_id = c.category_id
  where fc.film_id in (select fc.film_id
                         from film f join film_category fc on f.film_id = fc.film_id
                       group by fc.film_id
                       having count(*) > 1
                       ) 
'
)

sp_print_df(multiple_categories_sql)
```

<!--html_preserve--><div id="htmlwidget-bbe1f43178625f07ed69" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-bbe1f43178625f07ed69">{"x":{"filter":"none","data":[["1","2"],[1001,1001],["Sophie's Choice","Sophie's Choice"],["Documentary","Drama"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>name<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":1},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>There is only one film which has two categories, Sophie's Choice.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

multiple_categories_dplyr <- as.data.frame("code me")

sp_print_df(multiple_categories_dplyr)
```

<!--html_preserve--><div id="htmlwidget-f44584fa5e4f08aaeb0b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f44584fa5e4f08aaeb0b">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 18.  Which DVD's are in one store's inventory but not the other

In the table below we show the first 10 rows.  

To answer this question we look at the `inventory` and `film` tables.


```r
dvd_in_1_store_sql <- dbGetQuery(
  con,
  "
--   select store1,count(count1) films_not_in_store_2,sum(coalesce(count1,0)) dvds_not_in_store_1
--         ,store2,count(count2) films_not_in_store_1,sum(coalesce(count2,0)) dvds_not_in_store_2
--     from (
             select coalesce(i1.film_id,i2.film_id) film_id,f.title,f.rental_rate
                   ,1 store1,coalesce(i1.count,0) count1
                   ,2 store2,coalesce(i2.count,0) count2
                  -- dvd inventory in store 1
               from (select film_id,store_id,count(*) count 
                       from inventory where store_id = 1 
                      group by film_id,store_id
                    ) as i1
                    full outer join 
                  -- dvd inventory in store 2
                    (select film_id,store_id,count(*) count
                       from inventory where store_id = 2 
                     group by film_id,store_id
                    ) as i2
                 on i1.film_id = i2.film_id 
               join film f 
                 on coalesce(i1.film_id,i2.film_id) = f.film_id
             where i1.film_id is null or i2.film_id is null
             order by f.title  
--          ) as src
--    group by store1,store2
"
)
if(HEAD_N > 0) {
    sp_print_df(head(dvd_in_1_store_sql,n=HEAD_N))
} else {
    sp_print_df(dvd_in_1_store_sql)
}
```

<!--html_preserve--><div id="htmlwidget-33be21b5fff197bb7cc4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-33be21b5fff197bb7cc4">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],[2,3,5,8,13,20,24,27,28,29],["Ace Goldfinger","Adaptation Holes","African Egg","Airport Pollock","Ali Forever","Amelie Hellfighters","Analyze Hoosiers","Anonymous Human","Anthem Luke","Antitrust Tomatoes"],[4.99,2.99,2.99,4.99,4.99,4.99,2.99,0.99,4.99,2.99],[1,1,1,1,1,1,1,1,1,1],[0,0,0,0,0,3,4,4,3,2],[2,2,2,2,2,2,2,2,2,2],[3,4,3,4,4,0,0,0,0,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>store1<\/th>\n      <th>count1<\/th>\n      <th>store2<\/th>\n      <th>count2<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


<font color='blue'>Store 1 has 196 films, (576 dvd's), that are not in store 2.  Store 2 has 199 films, (607 dvd's), that are not in store 1.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

inv_tbl1 <- inventory_table %>% 
    filter(store_id == 1 ) %>% 
    group_by(film_id) %>% 
    summarise(count=n())
inv_tbl2 <- inventory_table %>% 
    filter(store_id == 2 ) %>% 
    group_by(film_id) %>% 
    summarise(count=n())

dvd_in_1_store_dplyr <- as.data.frame("code me")

if(HEAD_N > 0) {
    sp_print_df(head(dvd_in_1_store_dplyr,n=HEAD_N))
} else {
    sp_print_df(dvd_in_1_store_dplyr)
}
```

<!--html_preserve--><div id="htmlwidget-008e7554d5faa93bd1b9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-008e7554d5faa93bd1b9">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 19.  Which films are not tracked in inventory?

To answer this question we look at the `film` and `rental` tables.


```r
films_no_inventory_sql <- dbGetQuery(con,
"
select f.film_id,title,rating,rental_rate,replacement_cost
  from film f left outer join inventory i on f.film_id = i.film_id
 where i.film_id is null;
")

if(HEAD_N > 0) {
    sp_print_df(head(films_no_inventory_sql,n=HEAD_N))
} else {
    sp_print_df(films_no_inventory_sql)
}
```

<!--html_preserve--><div id="htmlwidget-f943e07c4e65c2196ba8" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f943e07c4e65c2196ba8">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],[14,33,36,38,41,87,108,128,144,148],["Alice Fantasia","Apollo Teen","Argonauts Town","Ark Ridgemont","Arsenic Independence","Boondock Ballroom","Butch Panther","Catch Amistad","Chinatown Gladiator","Chocolate Duck"],["NC-17","PG-13","PG-13","NC-17","PG","NC-17","PG-13","G","PG","R"],[0.99,2.99,0.99,0.99,0.99,0.99,0.99,0.99,4.99,2.99],[23.99,15.99,12.99,25.99,17.99,14.99,19.99,10.99,24.99,13.99]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rating<\/th>\n      <th>rental_rate<\/th>\n      <th>replacement_cost<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


<font color='blue'>There are 42 films that do not exist in inventory or in either store.  These may be DVD's that have been ordered but the business has not received them.  Looking at the price and the replacement cost, it doesn't look like there is any rhyme or reason to the setting of the price.</font>

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

films_no_inventory_dplyr <- as.data.frame("code me")

if(HEAD_N > 0) {
    sp_print_df(head(films_no_inventory_dplyr,n=HEAD_N))
} else {
    sp_print_df(films_no_inventory_dplyr)
}
```

<!--html_preserve--><div id="htmlwidget-4b34001b371daf31fcf2" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-4b34001b371daf31fcf2">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 20 List film categories in descending accounts receivable.

To answer this question we look at the `rental`, `inventory`, `film`, `film_category` and `category`  tables.



```r
film_category_AR_rank_sql <- dbGetQuery(con,
"
select category,AR
       ,sum(AR) over (order by AR desc rows between unbounded preceding and current row) running_AR
       ,rentals
       ,sum(rentals) over (order by AR desc rows between unbounded preceding and current row) running_rentals
  from (select c.name category, sum(f.rental_rate) AR, count(*) rentals
          from rental r join inventory i on r.inventory_id = i.inventory_id 
               join film f on i.film_id = f.film_id
               join film_category fc on f.film_id = fc.film_id
               join category c on fc.category_id = c.category_id
       group by c.name
      ) src
")
  
sp_print_df(film_category_AR_rank_sql)
```

<!--html_preserve--><div id="htmlwidget-b1bdbba72aec9089045d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b1bdbba72aec9089045d">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16"],["Sports","Drama","Sci-Fi","Animation","Comedy","Foreign","Games","Action","Family","New","Travel","Documentary","Horror","Music","Children","Classics"],[3617.21,3378.39,3289.99,3218.34,3089.59,3050.67,3033.31,2966.88,2959.04,2904.6,2776.63,2752.49,2623.54,2541.7,2541.55,2477.61],[3617.21,6995.6,10285.59,13503.93,16593.52,19644.19,22677.5,25644.38,28603.42,31508.02,34284.65,37037.14,39660.68,42202.38,44743.93,47221.54],[1179,1061,1101,1166,941,1033,969,1112,1096,940,837,1051,846,830,945,939],[1179,2240,3341,4507,5448,6481,7450,8562,9658,10598,11435,12486,13332,14162,15107,16046]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>category<\/th>\n      <th>ar<\/th>\n      <th>running_ar<\/th>\n      <th>rentals<\/th>\n      <th>running_rentals<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>There are 16 film categories.  The top three categories based on highest AR amounts are Sports, Drama, and Sci-Fi.  The total number of rentals are 16046 with an AR amount of 47221.54.</font>

#### Replicate the output above using dplyr syntax.

column         | mapping          |definition
---------------|------------------|-----------
category       | category.name    |
ar             | f.rental_rate    |
running_ar     |                  | accumulated ar amounts based on ratings
rentals        |                  | number of rentals associated with the rating
running_rentals|                  | running rating rentals


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

film_category_AR_rank_dplyr <- as.data.frame("code me")
    
    
sp_print_df(film_category_AR_rank_dplyr)
```

<!--html_preserve--><div id="htmlwidget-af6ac1c69230c2179f6a" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-af6ac1c69230c2179f6a">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 21. List film ratings in descending accounts receivable order.

To answer this question we look at the `rental`, `inventory`, and `film` tables.


```r
film_rating_rank_sql <- dbGetQuery(con,
"select rating,AR
       ,sum(AR) over (order by AR desc rows 
        between unbounded preceding and current row) running_AR
       ,rentals
       ,sum(rentals) over (order by AR desc rows 
        between unbounded preceding and current row) running_rentals
from (select f.rating, sum(f.rental_rate) AR, count(*) rentals
        from rental r join inventory i on r.inventory_id = i.inventory_id 
        join film f on i.film_id = f.film_id
      group by f.rating
     ) as src 
")
  
sp_print_df(film_rating_rank_sql)
```

<!--html_preserve--><div id="htmlwidget-c6cef737dd6a83c62169" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c6cef737dd6a83c62169">{"x":{"filter":"none","data":[["1","2","3","4","5"],["PG-13","NC-17","PG","R","G"],[10797.15,10062.07,9470.87,9011.19,7875.27],[10797.15,20859.22,30330.09,39341.28,47216.55],[3585,3293,3213,3181,2773],[3585,6878,10091,13272,16045]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>rating<\/th>\n      <th>ar<\/th>\n      <th>running_ar<\/th>\n      <th>rentals<\/th>\n      <th>running_rentals<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>There are 5 film ratings.  The total number of rentals are 16045 with an AR amount of 47216.55.

Why do the film categories revenue and film rating revenue amounts and counts differ, 16046 and 47221.54?</font>  

#### Replicate the output above using dplyr syntax.

column         | mapping          |definition
---------------|------------------|-----------
rating         | film.rating      |
ar             | f.rental_rate    |
running_ar     |                  | accumulated ar amounts based on ratings
rentals        |                  | number of rentals associated with the rating
running_rentals|                  | running rating rentals



```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

film_rating_rank_dplyr <- as.data.frame("code me")

sp_print_df(film_rating_rank_dplyr)
```

<!--html_preserve--><div id="htmlwidget-a9e8581aee330d6d5646" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a9e8581aee330d6d5646">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->



### 22.  How many rentals were returned on time, returned late, never returned?

To answer this question we look at the `rental`, `inventory`, and `film` tables.


```r
returned_sql <- dbGetQuery(con,
"with details as
    (select case when r.return_date is null
                 then null
                 else r.return_date::date  - (r.rental_date + INTERVAL '1 day'  * f.rental_duration)::date
            end rtn_days
           ,case when r.return_date is null
                 then 1
                 else 0
            end not_rtn
       from rental r join inventory i on r.inventory_id = i.inventory_id
                     join film f on i.film_id = f.film_id
    )
 select sum(case when rtn_days <= 0 then 1 else 0 end) on_time
       ,sum(case when rtn_days >  0 then 1 else 0 end) late
       ,sum(not_rtn) not_rtn
       ,count(*) rented
       ,round(100. * sum(case when rtn_days <= 0 then 1 else 0 end)/count(*),2) on_time_pct
       ,round(100. * sum(case when rtn_days >  0 then 1 else 0 end)/count(*),2) late_pct
       ,round(100. * sum(not_rtn)/count(*),2)  not_rtn_pct
   from details
")

sp_print_df(returned_sql)
```

<!--html_preserve--><div id="htmlwidget-a9c870ee45a861efbc97" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a9c870ee45a861efbc97">{"x":{"filter":"none","data":[["1"],[8593],[7269],[183],[16045],[53.56],[45.3],[1.14]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>on_time<\/th>\n      <th>late<\/th>\n      <th>not_rtn<\/th>\n      <th>rented<\/th>\n      <th>on_time_pct<\/th>\n      <th>late_pct<\/th>\n      <th>not_rtn_pct<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>To date 53.56% of the rented DVD's were returned on time, 45.30% were returned late, and 1.14% were never returned.</font>

#### Replicate the output above using dplyr syntax.

column         | mapping          |definition
---------------|------------------|-----------
on_time        |                  |number of DVD's where rental.return_date <= rental.rental_date + film.rental_duration
late           |                  |number of DVD's where rental.return_date > rental.rental_date + film.rental_duration
not_rtn        |                  |number of DVD's not returned; rental.return_date is null
rented         |                  |number of DVD's rented.
on_time_pct    |                  |Percent of DVD's returned on time
late_pct       |                  |Percent of DVD's returned late
not_rtn_pct    |                  |Percent of DVD's not returned.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

returned_dplyr <- as.data.frame("code me")

sp_print_df(returned_dplyr)
```

<!--html_preserve--><div id="htmlwidget-d0e1be80fd8ee1a19c08" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d0e1be80fd8ee1a19c08">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 23.  Are there duplicate customers?

To answer this question we look at the `customer`, `address`, `city`, and `country` tables.

We assume that if the customer first and last name match in two different rows, then it is a duplicate customer. 


```r
customer_dupes_sql <- dbGetQuery(
  con,
  "select cust.customer_id id
         ,cust.store_id store
         ,concat(cust.first_name,' ',cust.last_name) customer
         ,cust.email
--         ,a.phone
         ,a.address
         ,c.city
         ,a.postal_code zip
         ,a.district
         ,ctry.country
     from customer cust join address a on cust.address_id = a.address_id
                     join city c on a.city_id = c.city_id
                     join country ctry on c.country_id = ctry.country_id
    where concat(cust.first_name,cust.last_name)
          in (select concat(first_name,last_name)
                from customer
              group by concat(first_name,last_name)
             having count(*) >1
             )
  ")
sp_print_df(customer_dupes_sql)
```

<!--html_preserve--><div id="htmlwidget-41c6fff5c0ae3f9b920c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-41c6fff5c0ae3f9b920c">{"x":{"filter":"none","data":[["1","2"],[600,601],[3,2],["Sophie Yang","Sophie Yang"],["sophie.yang@sakilacustomer.org","sophie.yang@sakilacustomer.org"],["47 MySakila Drive","47 MySakila Drive"],["Lethbridge","Lethbridge"],["",""],["Alberta","Alberta"],["Canada","Canada"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>store<\/th>\n      <th>customer<\/th>\n      <th>email<\/th>\n      <th>address<\/th>\n      <th>city<\/th>\n      <th>zip<\/th>\n      <th>district<\/th>\n      <th>country<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>Sophie is the only duplicate customer.  The only difference between the two records is the store.  Record 600 is associated with store 3, which has no employees, and 601 is associated with store 2</font>

#### Replicate the output above using dplyr syntax.

column         | mapping              |definition
---------------|----------------------|-----------
id             |customer.customer_id  |
store          |customer.store_id     |
customer       |first_name + last_name|
zip            |address.postal_code   |


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customer_dupes_dplyr <- as.data.frame("code me")
    
sp_print_df(customer_dupes_dplyr)
```

<!--html_preserve--><div id="htmlwidget-5fe564842c318b64a092" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5fe564842c318b64a092">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


### 24.  Which customers have never rented a movie?

To answer this question we look at the `customer` and `rental` tables.


```r
customer_no_rentals_sql <- dbGetQuery(
  con,
  "select c.customer_id id
         ,c.first_name
         ,c.last_name
         ,c.email
         ,a.phone
         ,city.city
         ,ctry.country
         ,c.active 
         ,c.create_date
--         ,c.last_update
     from customer c left join rental r on c.customer_id = r.customer_id
                     left join address a on c.address_id = a.address_id
                     left join city on a.city_id = city.city_id
                     left join country ctry on city.country_id = ctry.country_id
    where r.rental_id is null
  order by c.customer_id

  "
)
sp_print_df(customer_no_rentals_sql)
```

<!--html_preserve--><div id="htmlwidget-234a00f466fa8377b924" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-234a00f466fa8377b924">{"x":{"filter":"none","data":[["1","2","3","4"],[601,602,603,604],["Sophie","John","Ian","Ed"],["Yang","Smith","Frantz","Borasky"],["sophie.yang@sakilacustomer.org","john.smith@sakilacustomer.org","ian.frantz@sakilacustomer.org","ed.borasky@sakilacustomer.org"],["","","14033335568","6172235589"],["Lethbridge","Woodridge","Lethbridge","Woodridge"],["Canada","Australia","Canada","Australia"],[1,1,1,1],["2019-04-27","2019-04-27","2019-04-27","2019-04-27"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>phone<\/th>\n      <th>city<\/th>\n      <th>country<\/th>\n      <th>active<\/th>\n      <th>create_date<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>We see that there are four new customers who have never rented a movie.  These four customers are in the countries that have a manned store.</font>

column         | mapping              |definition
---------------|----------------------|-----------
id             |customer.customer_id  |

#### Replicate the output above using dplyr syntax.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customer_no_rentals_dplyr <- as.data.frame("code me")

sp_print_df(customer_no_rentals_dplyr)
```

<!--html_preserve--><div id="htmlwidget-868fa95f2212c2b3c328" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-868fa95f2212c2b3c328">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


### 25. Who are the top 5 customers with the most rentals and associated payments?

This exercise uses the `customer`, `rental`, and `payment` tables.


```r
customer_top_rentals_sql <- dbGetQuery(
  con,
  "select c.customer_id id,c.store_id
         ,concat(c.first_name,' ',c.last_name) customer
         ,min(rental_date)::date mn_rental_dt
         ,max(rental_date)::date mx_rental_dt
         ,sum(COALESCE(p.amount,0.)) paid
         ,count(r.rental_id) rentals
     from customer c
          left join rental r on c.customer_id = r.customer_id
          left join payment p on r.rental_id = p.rental_id 
   group by  c.customer_id
            ,c.first_name
            ,c.last_name
            ,c.store_id
   order by count(r.rental_id) desc
limit 5
  "
)
sp_print_df(customer_top_rentals_sql)
```

<!--html_preserve--><div id="htmlwidget-99c3e94ea8569a159b98" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-99c3e94ea8569a159b98">{"x":{"filter":"none","data":[["1","2","3","4","5"],[148,526,236,144,75],[1,2,1,1,2],["Eleanor Hunt","Karl Seal","Marcia Dean","Clara Shaw","Tammy Sanders"],["2005-05-28","2005-05-28","2005-05-26","2005-05-27","2005-05-26"],["2005-08-23","2005-08-23","2006-02-14","2005-08-23","2006-02-14"],[211.55,208.58,166.61,189.6,149.61],[46,45,42,42,41]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>store_id<\/th>\n      <th>customer<\/th>\n      <th>mn_rental_dt<\/th>\n      <th>mx_rental_dt<\/th>\n      <th>paid<\/th>\n      <th>rentals<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>The top 5 customers all rented between 41 to 46 DVD's.  Three of the top 5 rented about 14 DVD's per month over a three month period.  The other two customers 41 and 42 DVD's per 12 months.</font>

#### Replicate the output above using dplyr 

column         | mapping              |definition
---------------|----------------------|-----------
id             |customer.customer_id  |
customer       |first_name + last_name|
mn_rental_dt   |                      |minimum renal date
mx_rental_dt   |                      |maximum rental date
paid           |                      |paid amount
rentals        |                      |customer rentals

Use the dplyr inner_join verb to find the top 5 customers who have rented the most movies.


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customer_top_rentals_dplyr <- as.data.frame("code me")    

sp_print_df(head(customer_top_rentals_dplyr,n=5))
```

<!--html_preserve--><div id="htmlwidget-abcdda0cacd8bfd420cb" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-abcdda0cacd8bfd420cb">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 26. Combine the top 5 rental customers, (40 or more rentals), and zero rental customers

To answer this question we look at the `customer`, `rental`, and `payments` tables again.


```r
customer_rental_high_low_sql <- dbGetQuery(
  con,
  "select c.customer_id id
         ,concat(c.first_name,' ',c.last_name) customer
         ,count(*) cust_cnt
         ,count(r.rental_id) rentals
         ,count(p.payment_id) payments
         ,sum(coalesce(p.amount,0)) paid
     from customer c
          left outer join rental r on c.customer_id = r.customer_id
          left outer join payment p on r.rental_id = p.rental_id
   group by  c.customer_id
            ,c.first_name
            ,c.last_name
   having count(r.rental_id) = 0 or count(r.rental_id) > 40
   order by count(r.rental_id) desc
  "
)
sp_print_df(customer_rental_high_low_sql)
```

<!--html_preserve--><div id="htmlwidget-5bf2ee971cc89a16a855" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5bf2ee971cc89a16a855">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9"],[148,526,144,236,75,604,603,601,602],["Eleanor Hunt","Karl Seal","Clara Shaw","Marcia Dean","Tammy Sanders","Ed Borasky","Ian Frantz","Sophie Yang","John Smith"],[46,45,42,42,41,1,1,1,1],[46,45,42,42,41,0,0,0,0],[45,42,40,39,39,0,0,0,0],[211.55,208.58,189.6,166.61,149.61,0,0,0,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>customer<\/th>\n      <th>cust_cnt<\/th>\n      <th>rentals<\/th>\n      <th>payments<\/th>\n      <th>paid<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>We see that there are four new customers who have never rented a movie.  These four customers are in the countries that have a manned store.

We see that there are four new customers who have never rented a movie.  These four customers are in the countries that have a manned store.</font>

#### Replicate the output above using dplyr syntax.

Column          | Mapping             |Definition
----------------|---------------------|-----------------------------------
id              |customer.customer_id |
customer        |first_name + last_name|
rentals         |                     |customer rentals
payments        |                     |customer payments
paid_amt        |payment.amount       |aggregated payment amount 


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customer_rental_high_low_dplyr <- as.data.frame("code me")

sp_print_df(customer_rental_high_low_dplyr)
```

<!--html_preserve--><div id="htmlwidget-d53f5dec90ce090aa13d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d53f5dec90ce090aa13d">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 27.  Who are the top-n1 and bottom-n2 customers?

The issue with the two previous reports is that the top end is hardcoded, rentals  > 40.  Over time, the current customers will always be in the top section and new customers will get added.  Another way of looking at the previous report is to show just the top and bottom 5 customers.  

Parameterize the previous exercise to show the top 5 and bottom 5 customers. 

To answer this question we look at the `customer`, `rental`, and `payments` tables again.


```r
customer_rentals_hi_low_sql <- function(high_n,low_n) {
    customer_rental_high_low_sql <- dbGetQuery(con,
        "select *
           from (     select *
                            ,ROW_NUMBER() OVER(ORDER BY rentals desc) rent_hi_low
                            ,ROW_NUMBER() OVER(ORDER BY rentals ) rent_low_hi
                       FROM (    
                                 select c.customer_id id
                                       ,concat(c.first_name,' ',c.last_name) customer
                                       ,count(*) cust_cnt
                                       ,count(r.rental_id) rentals
                                       ,count(p.payment_id) payments
                                       ,sum(coalesce(p.amount,0)) paid_amt
                                  from customer c 
                                       left outer join rental r on c.customer_id = r.customer_id
                                       left outer join payment p on r.rental_id = p.rental_id
                                 group by c.customer_id
                                        ,c.first_name
                                        ,c.last_name
                            ) as summary
                ) row_nums
           where rent_hi_low <= $1 or rent_low_hi <= $2
          order by rent_hi_low
        "
           ,c(high_n,low_n)
        )
    return (customer_rental_high_low_sql)
}
```

The next code block executes a sql version of such a function.  With top_n = 5 and bot_n = 5, it replicates the hard coded version of the previous exercise. With top_n = 5 and bot_n = 0, it gives a top 5 report.  With top_n = 0 and bot_n = 5, the report returns the bottom 5.  Change the two parameters to see the output from the different combinations.


```r
top_n = 5
bot_n = 5
sp_print_df(customer_rentals_hi_low_sql(top_n,bot_n))
```

<!--html_preserve--><div id="htmlwidget-409f67cc1efea6a7bf83" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-409f67cc1efea6a7bf83">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],[148,526,236,144,75,600,602,604,601,603],["Eleanor Hunt","Karl Seal","Marcia Dean","Clara Shaw","Tammy Sanders","Sophie Yang","John Smith","Ed Borasky","Sophie Yang","Ian Frantz"],[46,45,42,42,41,1,1,1,1,1],[46,45,42,42,41,1,0,0,0,0],[45,42,39,40,39,0,0,0,0,0],[211.55,208.58,166.61,189.6,149.61,0,0,0,0,0],[1,2,3,4,5,600,601,602,603,604],[604,603,602,601,600,5,4,3,2,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>customer<\/th>\n      <th>cust_cnt<\/th>\n      <th>rentals<\/th>\n      <th>payments<\/th>\n      <th>paid_amt<\/th>\n      <th>rent_hi_low<\/th>\n      <th>rent_low_hi<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### Replicate the function above use dplyr syntax.

Column          | Mapping             |Definition
----------------|---------------------|-----------------------------------
id              |customer.customer_id |
cust_cnt        |                     |customer count
rentals         |                     |customer rentals
payments        |                     |customer payments
paid_amt        |payment.amount       |aggregated payment amount 
rent_hi_low     |                     |sequence with 1 = customer with highest rentals
rent_low_hi     |                     |sequence with 1 = customer with the lowest rentals



```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customer_rentals_hi_low_dplr <- function(high_n,low_n) {
     return(as.data.frame("code me"))
}
```


```r
top_n = 5
bot_n = 5
sp_print_df(customer_rentals_hi_low_dplr(top_n,bot_n))
```

<!--html_preserve--><div id="htmlwidget-619cf737bf6ed4e2fae9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-619cf737bf6ed4e2fae9">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 28.  How much has each store collected?

How are the stores performing?  The SQL code shows the payments made to each store in the business.


```r
store_payments_sql <- dbGetQuery(
  con,
  "select s.store_id,sum(p.amount) amount,count(*) cnt 
                   from payment p 
                        join staff s 
                          on p.staff_id = s.staff_id  
                 group by store_id order by 2 desc
                 ;
                "
)
sp_print_df(store_payments_sql)
```

<!--html_preserve--><div id="htmlwidget-4139ca2ad6f87f0aa0d4" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-4139ca2ad6f87f0aa0d4">{"x":{"filter":"none","data":[["1","2"],[2,1],[31059.92,30252.12],[7304,7292]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>amount<\/th>\n      <th>cnt<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>Each store collected just over 30,000 in revenue and each store had about 7300 rentals.</font>

#### Replicate the output above using dplyr syntax.



```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

store_payments_dplyr <- as.data.frame("code me")

sp_print_df(store_payments_dplyr)
```

<!--html_preserve--><div id="htmlwidget-27fdaedd3ddcca9c350f" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-27fdaedd3ddcca9c350f">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->




### 29.  What is the business' distribution of payments?

To answer this question we look at the `rental`, `payment`, `inventory`, and `film` tables to answer this question.

As a sanity check, we first check the number of rentals and amount payments.



```r
rentals_payments_sql <- dbGetQuery(con,
"select 'rentals' rec_type, count(*) cnt_amt from rental
 union
 select 'payments' rec_type, sum(amount) from payment ")
sp_print_df(rentals_payments_sql)
```

<!--html_preserve--><div id="htmlwidget-a0cd32aa67630f6b8dd0" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a0cd32aa67630f6b8dd0">{"x":{"filter":"none","data":[["1","2"],["payments","rentals"],[61312.04,16045]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>rec_type<\/th>\n      <th>cnt_amt<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->





```r
business_payment_dist_sql <- dbGetQuery(
  con,
 "select no_pay_rec_due
      ,no_pay_rec_cnt
      ,round(100.0 * no_pay_rec_cnt/rentals,2) no_pay_rec_pct
      ,rate_eq_paid
      ,rate_eq_paid_cnt
      ,round(100.0 * rate_eq_paid_cnt/rentals,2) rate_eq_paid_pct
      ,rate_lt_paid
      ,rate_lt_over_paid
      ,rate_lt_paid_cnt
      ,round(100.0 * rate_lt_paid_cnt/rentals,2) rate_lt_paid_pct
      ,rate_gt_paid_due
      ,rate_gt_paid_cnt
      ,round(100.0 * rate_gt_paid_cnt/rentals,2) rate_gt_paid_pct
      ,rentals
      ,rate_eq_paid_cnt + rate_lt_paid_cnt + rate_gt_paid_cnt payments
      ,round(100.0 * 
            (no_pay_rec_cnt + rate_eq_paid_cnt + rate_lt_paid_cnt + rate_gt_paid_cnt)/rentals
            ,2) pct
      ,rate_eq_paid + rate_lt_paid + rate_lt_over_paid amt_paid
      ,no_pay_rec_due + rate_gt_paid_due amt_due
  from (
        select sum(case when p.rental_id is null then rental_rate else 0 end ) no_pay_rec_due
              ,sum(case when p.rental_id is null then 1 else 0 end) no_pay_rec_cnt
              ,sum(case when f.rental_rate = p.amount 
                        then p.amount else 0 end) rate_eq_paid
              ,sum(case when f.rental_rate = p.amount 
                        then 1 else 0 end ) rate_eq_paid_cnt
              ,sum(case when f.rental_rate < p.amount 
                        then f.rental_rate else 0 end) rate_lt_paid
              ,sum(case when f.rental_rate < p.amount 
                        then p.amount-f.rental_rate else 0 end) rate_lt_over_paid
              ,sum(case when f.rental_rate < p.amount 
                        then 1 else 0 end) rate_lt_paid_cnt
              ,sum(case when f.rental_rate > p.amount 
                        then f.rental_rate - p.amount else 0 end ) rate_gt_paid_due
              ,sum(case when f.rental_rate > p.amount 
                        then 1 else 0 end ) rate_gt_paid_cnt
              ,count(*) rentals
            FROM rental r
                 LEFT JOIN payment p ON r.rental_id = p.rental_id and r.customer_id = p.customer_id
                 INNER JOIN inventory i ON r.inventory_id = i.inventory_id
                 INNER JOIN film f ON i.film_id = f.film_id
       ) as details
;"
)
# Rental counts
sp_print_df(business_payment_dist_sql %>% select(ends_with("cnt"),rentals))
```

<!--html_preserve--><div id="htmlwidget-d603924d095b44f9f39d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d603924d095b44f9f39d">{"x":{"filter":"none","data":[["1"],[1453],[7925],[6643],[24],[16045]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>no_pay_rec_cnt<\/th>\n      <th>rate_eq_paid_cnt<\/th>\n      <th>rate_lt_paid_cnt<\/th>\n      <th>rate_gt_paid_cnt<\/th>\n      <th>rentals<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
# Payments
sp_print_df(business_payment_dist_sql %>% select(ends_with("paid")))
```

<!--html_preserve--><div id="htmlwidget-f6e01e985baca3b2a01f" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f6e01e985baca3b2a01f">{"x":{"filter":"none","data":[["1"],[23397.75],[19448.57],[18456.76],[61303.08]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>rate_eq_paid<\/th>\n      <th>rate_lt_paid<\/th>\n      <th>rate_lt_over_paid<\/th>\n      <th>amt_paid<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
# Not paid amounts
sp_print_df(business_payment_dist_sql %>% select(ends_with("due")))
```

<!--html_preserve--><div id="htmlwidget-472c2b8f6d63d7358265" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-472c2b8f6d63d7358265">{"x":{"filter":"none","data":[["1"],[4302.47],[67.76],[4370.23]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>no_pay_rec_due<\/th>\n      <th>rate_gt_paid_due<\/th>\n      <th>amt_due<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
# Rental payments
sp_print_df(business_payment_dist_sql %>% select(ends_with("pct")))
```

<!--html_preserve--><div id="htmlwidget-42cd4e14f26053aac67b" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-42cd4e14f26053aac67b">{"x":{"filter":"none","data":[["1"],[9.06],[49.39],[41.4],[0.15],[100]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>no_pay_rec_pct<\/th>\n      <th>rate_eq_paid_pct<\/th>\n      <th>rate_lt_paid_pct<\/th>\n      <th>rate_gt_paid_pct<\/th>\n      <th>pct<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>These are interesting results.  

*  09.06% of the total records have no associated payment record in the amount of 4302.47  
*  49.39% of the rentals have been fully paid in full, 23397.75.
*  41.40% of the rentals have collected more than the rental amount by 18456.75
*  00.15% of the rentals have collected less than the rental amount by 67.76.
*  The no_pay_rec_cnt + rate_gt_paid_cnt, $1453 + 24 = 1477$ is the number of rentals which have not been paid in full.
*  The total outstanding balance is $4302.47 + 67.76 = 4370.23$

With over 40 percent over collection, someone needs to find out what is wrong with the collection process.  Many customers are owed credits or free rentals.
</font>

#### Replicate the output above using dplyr syntax.

This table describes the columns in the code block answer that follows.  There are payment records where the charged amount, rental rate, is less than the amount paid.  These payments are split into two pieces, rate_lt_paid and rate_lt_over_paid.  The rate_lt_paid is rental rate amount.  The rate_lt_over_paid is the paid amount - rental rate, the over paid amount. 

Column          | Mapping             |Definition
----------------|---------------------|-------------
no_pay_rec_cnt  |                     |number of DVD rentals without an associated payment record.
rate_eq_paid_cnt|                     |number of DVD payments that match the film rental rate.
rate_lt_paid_cnt|                     |number of DVD rental with rental rate less than the amount paid.
rate_gt_paid_cnt|                     |number of DVD rentals with rental rate greater than the film rental rate.
rentals         |                     |number of rental records analyzed
rate_eq_paid    |                     |amount paid where the rate charged = amount paid
rate_lt_paid    |                     |amount paid where the rate charged <
rate_lt_over_paid|                    |rate charged < amount paid; This represents the amount over paid
amt_paid        |                     |Total amount paid
no_pay_rec_due  |                     |DVD rentals charges due without a payment record
rate_gt_paid_due|                     |DVD rentals charged due with a payment record 
amt_due         |                     |Total amount due and not collected.
no_pay_rec_pct  |                     |Percent of rentals without a payment record.
rate_lt_paid_pct|                     |Percent of rentals where the rental charge is less than the paid amount
rate_gt_paid_pct|                     |Percent of rentals where the rental charge is greater than the paid amount
pct             |                     |Sum of percentages
  

```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

business_payment_dist_dplyr <- as.data.frame("code me")
    
# Rental counts
sp_print_df(business_payment_dist_dplyr)
```

<!--html_preserve--><div id="htmlwidget-ed0cabd356ee7bf24f99" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-ed0cabd356ee7bf24f99">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### Bad data analysis

Here are the sanity check numbers calculated at the beginning of this exercise.  

  rec_type |cnt_amt
-----------|-------
payments   |61312.04
 rentals   |16045.00
 
Note that the sanity check numbers above, do not match the numbers above.  If you query returned the numbers above, use the following result set ot see where the differences exist.


```r
rs <- dbGetQuery(
  con,
 "SELECT  'correct join' hint,r.rental_id,r.customer_id,p.customer_id payment_customer_id,p.rental_id payment_rental_id,p.amount
    FROM rental r
         LEFT JOIN payment p ON r.rental_id = p.rental_id and r.customer_id = p.customer_id
   where r.rental_id = 4591
  UNION 
 SELECT  'incorrect join' hint,r.rental_id,r.customer_id,p.customer_id payment_customer_id,p.rental_id payment_rental_id,p.amount
    FROM rental r
         LEFT JOIN payment p ON r.rental_id = p.rental_id
   where r.rental_id = 4591
     and p.customer_id != 182
;")
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-e39b708ff0d549d74256" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-e39b708ff0d549d74256">{"x":{"filter":"none","data":[["1","2","3","4","5"],["incorrect join","incorrect join","incorrect join","incorrect join","correct join"],[4591,4591,4591,4591,4591],[182,182,182,182,182],[546,401,16,259,182],[4591,4591,4591,4591,4591],[3.99,0.99,1.99,1.99,3.99]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>hint<\/th>\n      <th>rental_id<\/th>\n      <th>customer_id<\/th>\n      <th>payment_customer_id<\/th>\n      <th>payment_rental_id<\/th>\n      <th>amount<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,4,5,6]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 30.  Which customers have the highest open amounts?

From the previous exercise, we know that there are 1477 missing payment records or not fully paid payment records.  List the top 5 customers from each category base on balance due amounts.

To answer this question we look at the `rental`, `payment`, `inventory`, `film` and `customer` tables to answer this question.


```r
customer_open_amts_sql <- dbGetQuery(
  con,
"  select customer_id
         ,concat(first_name,' ',last_name) customer
         ,pay_record
         ,rental_amt
         ,paid_amt
         ,due_amt
         ,cnt
         ,rn
  from (select c.customer_id
              ,c.first_name
              ,c.last_name
              ,case when p.amount is null then 'No' else 'Yes' end Pay_record
              ,sum(f.rental_rate) rental_amt
              ,sum(coalesce(p.amount,0))  paid_amt
              ,sum(f.rental_rate - coalesce(p.amount,0)) due_amt
              ,count(*) cnt
              ,row_number() over (partition by case when p.amount is null then 'No' else 'Yes' end
                                  order by sum(f.rental_rate - coalesce(p.amount,0)) desc,c.customer_id) rn
          FROM rental r
               LEFT JOIN payment p
                 ON r.rental_id = p.rental_id and r.customer_id = p.customer_id
               INNER JOIN inventory i
                 ON r.inventory_id = i.inventory_id
               INNER JOIN film f
                 ON i.film_id = f.film_id
               INNER JOIN customer c
                 ON r.customer_id = c.customer_id
        WHERE f.rental_rate > coalesce(p.amount, 0)
       group by c.customer_id,c.first_name,c.last_name,case when p.amount is null then 'No' else 'Yes' end
       ) as src
  where rn <= 5 -- and Pay_record = 'No' or Pay_record = 'Yes'
  order by Pay_record,rn
")
sp_print_df(customer_open_amts_sql)
```

<!--html_preserve--><div id="htmlwidget-8e3082ed4e5b0ee283ce" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8e3082ed4e5b0ee283ce">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10"],[293,307,316,299,274,75,53,60,155,163],["Mae Fletcher","Joseph Joy","Steven Curley","James Gannon","Naomi Jennings","Tammy Sanders","Heather Morris","Mildred Bailey","Gail Knight","Cathy Spencer"],["No","No","No","No","No","Yes","Yes","Yes","Yes","Yes"],[35.9,31.9,31.9,30.91,29.92,5.98,4.99,4.99,4.99,4.99],[0,0,0,0,0,0,0,0,0,0],[35.9,31.9,31.9,30.91,29.92,5.98,4.99,4.99,4.99,4.99],[10,10,10,9,8,2,1,1,1,1],[1,2,3,4,5,1,2,3,4,5]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>customer<\/th>\n      <th>pay_record<\/th>\n      <th>rental_amt<\/th>\n      <th>paid_amt<\/th>\n      <th>due_amt<\/th>\n      <th>cnt<\/th>\n      <th>rn<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5,6,7,8]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>From the previous exercise we see that the number of rentals that have not been paid in full is 1477.  There are 24 records that have a payment record, pay_record = 'Yes', all have a 0 paid amount.  There are 1453 DVD's rented out that have no payment record.   The top 3 customers have 10 DVD's each that have not been paid.
</font>


#### Replicate the output above using dplyr syntax.

column      | definition            | mapping
------------|-----------------------|------------------------------------------------------------
customer    | first_name + last_name|
Pay_record  | Payment record exists Y/N| case when p.amount is null then 'No' else 'Yes' end
rental_amt  | aggrgated film.rental_rate|
paid_amt    | aggregated payment.amount |
due_amt     | aggregated film.rental_rate - payment.amount|
cnt         | number of rentals/customer|
rn          | row number




```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customer_open_amts_dplyr <- as.data.frame("code me")

sp_print_df(customer_open_amts_dplyr)
```

<!--html_preserve--><div id="htmlwidget-3cafdc732b82de0842ef" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-3cafdc732b82de0842ef">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


### 31. What is the business cash flow?

In the previous exercise we saw that about 50% of the rentals collected the correct amount and 40% of the rentals over collected.  The last 10% were never collected.

Calculate the number of days it took before the payment was collected and the amount collected?

To answer this question we look at the `rental`, `customer`, `payment`, `inventory`, `payment` and `film` tables to answer this question.


```r
cash_flow_sql <- dbGetQuery(con,
"SELECT payment_date - exp_rtn_dt payment_days
    ,sum(coalesce(amount, charges)) paid_or_due
    ,count(*) late_returns
FROM (
    SELECT payment_date::DATE 
        ,(r.rental_date + INTERVAL '1 day' * f.rental_duration)::DATE exp_rtn_dt
        ,p.amount 
        ,f.rental_rate charges
        ,r.rental_date
        ,r.return_date
    FROM rental r
         LEFT JOIN customer c ON c.customer_id = r.customer_id
         LEFT JOIN address a  ON c.address_id = a.address_id
         LEFT JOIN city       ON city.city_id = a.city_id
         LEFT JOIN country ctry ON ctry.country_id = city.country_id
         LEFT JOIN inventory i  ON r.inventory_id = i.inventory_id
         LEFT JOIN payment p    ON c.customer_id = p.customer_id 
                               AND p.rental_id = r.rental_id
         LEFT JOIN film f       ON i.film_id = f.film_id
    WHERE return_date > (r.rental_date + INTERVAL '1 day' * f.rental_duration)::DATE 
    ) AS src
GROUP BY payment_date - exp_rtn_dt
ORDER BY payment_date - exp_rtn_dt DESC")

sp_print_df(cash_flow_sql)
```

<!--html_preserve--><div id="htmlwidget-9df3d00c4d83b54877ba" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-9df3d00c4d83b54877ba">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20"],[null,636,635,634,633,632,631,630,607,606,605,604,603,602,574,573,572,571,570,569],[2211.23,5599.24,5070.94,4173.02,2993.4,1692.83,316.27,1.98,1660.1,1458.22,1162.77,898.99,578.58,33.93,5234.98,4279.18,3311.73,2485.4,1438.39,51.85],[777,976,906,798,660,417,73,2,290,278,223,201,142,7,902,782,627,560,361,15]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>payment_days<\/th>\n      <th>paid_or_due<\/th>\n      <th>late_returns<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<font color='blue'>Wow those are really generous terms.  Customers are paying 1.2 to 1.7 years after they returned the DVD.  This business is in serious financial trouble!
</font>

#### Replicate the output above using dplyr syntax.

column      | definition            | mapping
------------|-----------------------|------------------------------------------------------------
paid_or_due |paid amt associated with rental or the rental_rate |ifelse(is.na(amount),rental_rate,amount)
payment_days|days til payment       | payment_date - rental_date


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

cash_flow_dplyr <- as.data.frame("code me")

sp_print_df(cash_flow_dplyr)
```

<!--html_preserve--><div id="htmlwidget-20ef643ff2d76ae434f3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-20ef643ff2d76ae434f3">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### 32.  Customer information

Create a function that takes a customer id and returns

*  customer address information
*  films rented and returned information
*  customer payment information

The hidden code block implements such a function in SQL.

To answer this question we look at the `rental`, `customer`, `address`, `city, `country`, `inventory`, `payment` and `film` tables to answer this question.  


```r
customer_details_fn_sql <- function(cust_id) {
    customer_details_sql <- dbGetQuery(con,
    "select c.customer_id id,concat(first_name,' ',c.last_name) customer
          ,c.email,a.phone,a.address,address2,city.city,a.postal_code,ctry.country
          ,c.store_id cust_store_id
          ,i.store_id inv_store_id
          ,f.film_id
          ,f.title
          ,r.rental_date::date rented
          ,r.return_date::date returned
          ,(r.rental_date + INTERVAL '1 day'  * f.rental_duration)::date exp_rtn_dt
          ,case when r.return_date is null
                then null
                else r.return_date::date  - (r.rental_date + INTERVAL '1 day'  * f.rental_duration)::date
           end rtn_stat
          ,case when r.rental_id is null
                then null
                      -- dvd returned             
                when r.return_date is null
                then 1
                else 0
           end not_rtn
          ,payment_date::date pay_dt
          ,f.rental_rate charges
          ,p.amount paid
          ,p.amount-f.rental_rate delta
          ,p.staff_id pay_staff_id
          ,payment_date::date - rental_date::date pay_days
          ,r.rental_id,i.inventory_id,payment_id
      from customer c left join rental r on c.customer_id = r.customer_id
                      left join address a on c.address_id = a.address_id
                      left join city on city.city_id = a.city_id
                      left join country ctry on ctry.country_id = city.country_id
                      left join inventory i on r.inventory_id = i.inventory_id
                      left join payment p on c.customer_id = p.customer_id and p.rental_id = r.rental_id
                      left join film f on i.film_id = f.film_id
     where c.customer_id = $1
    order by id,rented desc
    "
    ,cust_id
    )
    return(customer_details_sql)
}
```

The following code block executes the customer function. Change the `cust_id` value to see differnt customers.


```r
cust_id <- 600
sp_print_df( customer_details_fn_sql(cust_id))
```

<!--html_preserve--><div id="htmlwidget-7a1ca14bd453df078a7a" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-7a1ca14bd453df078a7a">{"x":{"filter":"none","data":[["1"],[600],["Sophie Yang"],["sophie.yang@sakilacustomer.org"],[""],["47 MySakila Drive"],[null],["Lethbridge"],[""],["Canada"],[3],[1],[1001],["Sophie's Choice"],["2019-04-20"],["2019-04-27"],["2019-04-27"],[0],[0],[null],[4.99],[null],[null],[null],[null],[16050],[4582],[null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>customer<\/th>\n      <th>email<\/th>\n      <th>phone<\/th>\n      <th>address<\/th>\n      <th>address2<\/th>\n      <th>city<\/th>\n      <th>postal_code<\/th>\n      <th>country<\/th>\n      <th>cust_store_id<\/th>\n      <th>inv_store_id<\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rented<\/th>\n      <th>returned<\/th>\n      <th>exp_rtn_dt<\/th>\n      <th>rtn_stat<\/th>\n      <th>not_rtn<\/th>\n      <th>pay_dt<\/th>\n      <th>charges<\/th>\n      <th>paid<\/th>\n      <th>delta<\/th>\n      <th>pay_staff_id<\/th>\n      <th>pay_days<\/th>\n      <th>rental_id<\/th>\n      <th>inventory_id<\/th>\n      <th>payment_id<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,10,11,12,17,18,20,21,22,23,24,25,26,27]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### Replicate the output above using dplyr syntax.

column      | definition            | mapping
------------|-----------------------|------------------------------------------------------------
id          |customer_id            | 
customer    |first_name + last_name |
exp_rtn_dt  |expected return date   | rental.rental_date + film.rental_duration
rtn_stat    |return status          | rental.return_date - (rental.rental_date + film duration)
not_rtn     |dvd not returned       | null if rental_id is null;not rented; 1 return_date null else 0
pay_dt      |payment_date           | 
delta       |                       | payment.amount-film.rental_rate
pay_staff_id|payment.staff_id       | payment.staff_id
pay_days    |days til payment       | payment_date - rental_date


```r
# sp_tbl_descr('store')
# sp_tbl_pk_fk('table_name')
# sp_print_df(table_rows_sql)

customer_details_fn_dplyr <- function(cust_id) {

customer_details_dplyr <- as.data.frame("code me")

return(customer_details_dplyr)
}
```

Use the following code block to test the dplyr function.


```r
cust_id <- 601
sp_print_df(customer_details_fn_dplyr(cust_id))
```

<!--html_preserve--><div id="htmlwidget-e07c38820216518b4dbd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-e07c38820216518b4dbd">{"x":{"filter":"none","data":[["1"],["code me"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>\"code me\"<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Diconnect from the db and clean up

```r
dbDisconnect(con)

sp_docker_stop("sql-pet")
```


```r
knitr::knit_exit()
```

