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
## [2] "45eafcfd494e        postgres-dvdrental   \"docker-entrypoint.s…\"   21 seconds ago      Exited (0) 2 seconds ago                       sql-pet"
```
Start up the `docker-pet` container

```r
sp_docker_start("sql-pet")
```


now connect to the database with R

```r
# need to wait for Docker & Postgres to come up before connecting.

con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10
)
```

## Database constraints

As a data analyst, you really do not have to worry about database constraints since you are primarily writing dplyr/SQL queries to pull data out of the database.  Constraints can be enforced at multiple levels, column, table, multiple tables, or at the schema itself.  

For this tutorial, we are primarily concerned with primary and foreign key constraints.  If one looks at all the tables in the DVD Rental ERD, the first column is the name of the table followed by "id".  This is the primary key on the table.  In some of the tables, there are other columns that begin with the name of a different table, the foreign table, and end in "_id".  These are foreign keys and the foreign key value is the primary key value on the foreign table.  The DBA will index the primary and foreign key columns to speed up query performanace.  

## Making up data for Join Examples

### insert yourself as a new customer


```r
# Customer 600 should be the next customer.
# It gets deleted here just in case it was added in a different session.
dbExecute(
  con,
  "delete from customer 
   where customer_id = 600;
  "
)
```

```
## [1] 0
```

```r
# Now add yourself as the next customer.  Replace Sophie Yang with your name.
dbExecute(
  con,
  "insert into customer 
  (customer_id,store_id,first_name,last_name,email,address_id
  ,activebool,create_date,last_update,active)
  values(600,2,'Sophie','Yang','email@email.com',1,TRUE,now()::date,now()::date,1)
  ;
  "
)
```

```
## [1] 1
```

The `film` table has a primary key, film_id, and a foreign key column, language_id.  One cannot insert a new row into the film table with a language_id = 10 because of a constraint on the language_id column.  The language_id value must already exist in the `language` table before the database will allow the new row to be inserted into the table.  

To work around this inconvenience for the tutorial:

1.  we drop the smy_film table if it exists from a previous session.


```r
dbExecute(con, "drop table if exists smy_film;")
```

```
## [1] 0
```

2.  we create a new table smy_film from the film table and add a new row with a language_id = 10;


```r
dbExecute(con, "create table smy_film as select * from film;")
```

```
## [1] 1000
```

3.  We create a film with language_id = 10;


```r
dbExecute(
  con,
  "insert into smy_film
  (film_id,title,description,release_year,language_id
  ,rental_duration,rental_rate,length,replacement_cost,rating
   ,last_update,special_features,fulltext)
  values(1001,'Sophie''s Choice','orphaned language_id=10',2018,10
        ,7,4.99,120,14.99,'PG'
        ,now()::date,'{Trailers}','')
  ;
  "
)
```

```
## [1] 1
```

4.  Confirm that the new record exists.


```r
dbGetQuery(
  con,
  "select film_id,title,description,language_id from smy_film where film_id = 1001;"
)
```

```
##   film_id           title             description language_id
## 1    1001 Sophie's Choice orphaned language_id=10          10
```

## Joins

In section 'SQL Quick Start Simple Retrieval', there is a brief discussion of databases and 3NF.  The goal of normalization is to push the data into separate tables at a very granular level.  

Bill Kent famously summarized 3NF as every non-key column "must provide a fact about the key,the whole key, and nothing but the key, so help me Codd." 

Normalization breaks data down and JOINs denormalizes the data and builds it back up.

![SQL_JOIN_TYPES](sql_join_types.png)

The above diagram can be found [here](https://way2tutorial.com/sql/sql_join_types_visual_venn_diagram.php)  There are additional graphics at the link, but the explanations are poorly worded and hard to follow.  

The diagram above shows nicely the hierarchy of different types of joins.  For this tutorial, we can think of joins as either an Inner Join or an Outer Join.

Instead of showing standard Venn diagrams showing the different JOINS, we use an analogy. For those interested though, the typical Venn diagrams can be found [here](http://www.sql-join.com/sql-join-types/).

### Valentines Party

Imagine you are at a large costume Valentine's Day dance party.  The hostess of the party, a data scientist, would like to learn more about the people attending her party.  She interrupts the music to let everyone know it is time for the judges to evaluate the winners for best costumes and associated prizes.

She requests the following:

1.  All the couples at the party to line up in front of her with the men on the left and the women on the right, (inner join)

2.  All the remaining men to form a second line two feet behind the married men,(left outer join)

3.  Right Outer Join: All the remaining women to form a third line two feet in front of the married women, (right outer join, all couples + unattached women)

Full Outer Join -- As our data scientist looks out at the three lines, she can clearly see the three distinct lines, her full outer join.  

As the three judges start walking down the lines, she makes one more announcement.

4.  There is a special prize for the man and woman who can guess the average age of the members of the opposite sex. To give everyone a chance to come up with an average age, she asks the men to stay in line and the women to move down the mens line in order circling back around until they get back to their starting point in line, (full outer join, every man seen by every woman and vice versa).  

It is hard enough to tell someone's age when they don't have a mask, how do you get the average age when people have masks?

The hostess knows that there is usually some data anomolies.  As she looks out she sees a small cluster of people who did not line up.  Being the hostess with the mostest, she wants to get to know that small cluster better.  Since they are far off and in costume, she cannot tell if they are men or women.  More importantly, she does not know if they identify as a man or a woman, both -- (kind of a stretch for a self join), neither, or something else.  Ahh, the inquisitive mind wants to know.

### Join Syntax

|Join|dplyr                                                                            |sql
|-----|--------------------------------------------------------------------------------|------------------------------------------------------
|inner|inner_join(customer_tbl, rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|from customer c join rental r on c.customer_id = r.customer_id
|     |customer_tbl %>% inner_join(rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|
|left |left_join(customer_tbl, rental_tbl, by = 'customer_id', suffix = c(".c", ".r")) |from customer c left outer join rental r on c.customer_id = r.customer_id
|     |customer_tbl %>% left_join(rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|
|right|right_join(customer_tbl, rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|from customer c right outer join rental r on c.customer_id = r.customer_id
|     |customer_tbl %>% right_join(rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|
|full |full_join(customer_tbl, rental_tbl, by = 'customer_id', suffix = c(".c", ".r")) |from customer c full outer join rental r on c.customer_id = r.customer_id
|     |customer_tbl %>% full_join(rental_tbl, by = 'customer_id', suffix = c(".c", ".r"))|


### Join Tables

The dplyr join documentation describes two different types of joins, `mutating` and `filtering` joins.  For those coming to R with a SQL background, the mutating documentation is misleading in one respect.  Here is the inner_join documentation.

    inner_join()
    
    return all rows from x where there are matching values in y, and all columns from x and y. If there are multiple matches between x and y, all combination of the matches are returned.

The misleading part is that all the columns from *x* and *y*.  If the join column is `KEY`, SQL will return x.KEY and y.KEY.  Dplyr retuns KEY.  It appears that the KEY value comes from the key/driving table.  This difference should become clear in the outer join examples.

In the next couple of examples, we will pull all the language and smy_film table data from the database into memory because the tables are small.  In the *_join verbs, the `by` and `suffix` parameters are included because it helps document the actual join and the source of join columns.

## Natural Join Time Bomb

The dplyr default join is a natural join, joining tables on common column names.  One of many links why one should not use natural joins can be found [here](http://gplivna.blogspot.com/2007/10/natural-joins-are-evil-motto-if-you.html).

<!-- move this example to query optimzation section 

Explain plans [here](https://robots.thoughtbot.com/reading-an-explain-analyze-query-plan)


```r
# smy_film <- dplyr::tbl(con, "smy_film") # Lazy
# x<-smy_film %>% filter(film_id == 1001)  %>% explain()
#


language_table <- dplyr::tbl(con, "language")
film_table <- dplyr::tbl(con, "smy_film")

languages_ij <- language_table %>%
  inner_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f"))) %>%
  group_by(language_id, name) %>%
  summarize(inner_joins = n()) %>%
  explain()
```

```
## <SQL>
## SELECT "language_id", "name", COUNT(*) AS "inner_joins"
## FROM (SELECT "TBL_LEFT"."language_id" AS "language_id", "TBL_LEFT"."name" AS "name", "TBL_LEFT"."last_update" AS "last_update.x", "TBL_RIGHT"."film_id" AS "film_id", "TBL_RIGHT"."title" AS "title", "TBL_RIGHT"."description" AS "description", "TBL_RIGHT"."release_year" AS "release_year", "TBL_RIGHT"."rental_duration" AS "rental_duration", "TBL_RIGHT"."rental_rate" AS "rental_rate", "TBL_RIGHT"."length" AS "length", "TBL_RIGHT"."replacement_cost" AS "replacement_cost", "TBL_RIGHT"."rating" AS "rating", "TBL_RIGHT"."last_update" AS "last_update.y", "TBL_RIGHT"."special_features" AS "special_features", "TBL_RIGHT"."fulltext" AS "fulltext"
##   FROM "language" AS "TBL_LEFT"
##   INNER JOIN "smy_film" AS "TBL_RIGHT"
##   ON ("TBL_LEFT"."language_id" = "TBL_RIGHT"."language_id")
## ) "cqpqwqagrn"
## GROUP BY "language_id", "name"
```

```
## 
```

```
## <PLAN>
## GroupAggregate  (cost=63.04..63.24 rows=6 width=96)
##   Group Key: "TBL_LEFT".language_id
##   ->  Sort  (cost=63.04..63.09 rows=18 width=88)
##         Sort Key: "TBL_LEFT".language_id
##         ->  Hash Join  (cost=1.14..62.67 rows=18 width=88)
##               Hash Cond: ("TBL_RIGHT".language_id = "TBL_LEFT".language_id)
##               ->  Seq Scan on smy_film "TBL_RIGHT"  (cost=0.00..59.94 rows=594 width=2)
##               ->  Hash  (cost=1.06..1.06 rows=6 width=88)
##                     ->  Seq Scan on language "TBL_LEFT"  (cost=0.00..1.06 rows=6 width=88)
```

```r
languages_ij
```

```
## # Source:   lazy query [?? x 3]
## # Database: postgres [postgres@localhost:5432/dvdrental]
## # Groups:   language_id
##   language_id name                   inner_joins    
##         <int> <chr>                  <S3: integer64>
## 1           1 "English             " 1000
```


```r
rs <- dbGetQuery(
  con,
  "explain analyze select l.language_id,l.name,count(*) n
   from language l join smy_film f on l.language_id = f.language_id
  group by l.language_id,l.name;"
)

rs
```

```
##                                                                                                                     QUERY PLAN
## 1                              GroupAggregate  (cost=63.04..63.24 rows=6 width=96) (actual time=45.985..45.998 rows=1 loops=1)
## 2                                                                                                     Group Key: l.language_id
## 3                                ->  Sort  (cost=63.04..63.09 rows=18 width=88) (actual time=30.581..38.037 rows=1000 loops=1)
## 4                                                                                                      Sort Key: l.language_id
## 5                                                                                        Sort Method: quicksort  Memory: 103kB
## 6                             ->  Hash Join  (cost=1.14..62.67 rows=18 width=88) (actual time=0.190..22.644 rows=1000 loops=1)
## 7                                                                                   Hash Cond: (f.language_id = l.language_id)
## 8                 ->  Seq Scan on smy_film f  (cost=0.00..59.94 rows=594 width=2) (actual time=0.012..7.538 rows=1001 loops=1)
## 9                                        ->  Hash  (cost=1.06..1.06 rows=6 width=88) (actual time=0.143..0.150 rows=6 loops=1)
## 10                                                                                Buckets: 1024  Batches: 1  Memory Usage: 9kB
## 11                     ->  Seq Scan on language l  (cost=0.00..1.06 rows=6 width=88) (actual time=0.015..0.074 rows=6 loops=1)
## 12                                                                                                     Planning time: 0.121 ms
## 13                                                                                                   Execution time: 46.153 ms
```

-->

## Join Templates

In this section we look at two tables, `language` and `smy_film` and various joins using dplyr and SQL.  Each dplyr code block has three purposes.  

1.  Show a working join example.  
2.  The code blocks can be used as templates for beginning more complex dplyr pipes.
3.  The code blocks show the number of joins performed.

In these examples, the join condition, the `by` parameter, 

    by = c('language_id','language_id')

the two columns are the same.  In multi-column joins, each language_id would be replace with a vector of column names used in the join by position.  Note the column names do not need to be identical by position.

The suffix parameter is a way to distinguish the same column name in the joined tables.  The suffixes are usually an single letter to represent the name of the table.



```r
language_table <- DBI::dbReadTable(con, "language")
film_table <- DBI::dbReadTable(con, "smy_film")
```

### dplyr Inner Join Template 


```r
languages_ij <- language_table %>%
  inner_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f"))) %>%
  group_by(language_id, name) %>%
  summarize(inner_joins = n())

languages_ij
```

```
## # A tibble: 1 x 3
## # Groups:   language_id [?]
##   language_id name                   inner_joins
##         <int> <chr>                        <int>
## 1           1 "English             "        1000
```

#### SQL Inner Join


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,count(*) n
   from language l join smy_film f on l.language_id = f.language_id
  group by l.language_id,l.name;"
)

rs
```

```
##   language_id                 name    n
## 1           1 English              1000
```

The output tells us that there are 1000 inner joins between the language_table and the film_table.

### dplyr Left Outer Join Template


```r
languages_loj <- language_table %>%
  left_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f"))) %>%
  mutate(
    join_type = "loj"
    , film_lang_id = if_else(is.na(film_id), film_id, language_id)
  ) %>%
  group_by(join_type, language_id, name, film_lang_id) %>%
  summarize(lojs = n()) %>%
  select(join_type, language_id, film_lang_id, name, lojs)
print(languages_loj)
```

```
## # A tibble: 6 x 5
## # Groups:   join_type, language_id, name [6]
##   join_type language_id film_lang_id name                    lojs
##   <chr>           <int>        <int> <chr>                  <int>
## 1 loj                 1            1 "English             "  1000
## 2 loj                 2           NA "Italian             "     1
## 3 loj                 3           NA "Japanese            "     1
## 4 loj                 4           NA "Mandarin            "     1
## 5 loj                 5           NA "French              "     1
## 6 loj                 6           NA "German              "     1
```

```r
# View(languages_loj)
# sp_print_df(languages_loj)
```

Compare the mutate verb in the above code block with film_lang_id in the equivalent SQL code block below.

#### SQL Left Outer Join


```r
rs <- dbGetQuery(
  con,
  "select l.language_id
       ,f.language_id film_lang_id
       ,trim(l.name) as name
       ,count(*) lojs
   from language l left outer join smy_film f 
        on l.language_id = f.language_id
  group by l.language_id,l.name,f.language_id
order by l.language_id;"
)
# sp_print_df(rs)
rs
```

```
##   language_id film_lang_id     name lojs
## 1           1            1  English 1000
## 2           2           NA  Italian    1
## 3           3           NA Japanese    1
## 4           4           NA Mandarin    1
## 5           5           NA   French    1
## 6           6           NA   German    1
```

The lojs column returns the number of rows found on the keys from the left table, language, and the right table, the film table.  For the "English" row, the language_id and film_lang_id match and a 1000 inner joins were performed.  For all the other languages, there was only 1 join and they all came from the left outer table, the language table, language_id's 2 - 6.  The right table, the film table returned NA, because no match was found.

1.  The left outer join always returns all rows from the left table, the driving/key table, if not reduced via a filter()/where clause.  
2.  All rows that inner join returns all the columns/derived columns specified in the select clause from both the left and right tables.  
3.  All rows from the left table, the outer table, without a matching row on the right returns all the columns/derived column values specified in the select clause from the left, but the values from right table have all values of NA. 

#### dplyr Right Outer Join


```r
languages_roj <- language_table %>%
  right_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f")), all = film_table) %>%
  mutate(
    lang_id = if_else(is.na(name), 0L, language_id)
    , join_type = "rojs"
  ) %>%
  group_by(join_type, language_id, name, lang_id) %>%
  summarize(rojs = n()) %>%
  select(join_type, lang_id, language_id, name, rojs)

sp_print_df(languages_roj)
```

<!--html_preserve--><div id="htmlwidget-74434d812ec23342fdce" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-74434d812ec23342fdce">{"x":{"filter":"none","data":[["1","2"],["rojs","rojs"],[1,0],[1,10],["English             ",null],[1000,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>lang_id<\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>rojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
languages_roj
```

```
## # A tibble: 2 x 5
## # Groups:   join_type, language_id, name [2]
##   join_type lang_id language_id name                    rojs
##   <chr>       <int>       <int> <chr>                  <int>
## 1 rojs            1           1 "English             "  1000
## 2 rojs            0          10 <NA>                       1
```

Review the mutate above with l.language_id below.

#### SQL Right Outer Join


```r
rs <- dbGetQuery(
  con,
  "select 'roj' join_type,l.language_id,f.language_id language_id_f,l.name,count(*) rojs
   from language l right outer join smy_film f on l.language_id = f.language_id
  group by l.language_id,l.name,f.language_id
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-8da54f9f5480ad7c3ec3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-8da54f9f5480ad7c3ec3">{"x":{"filter":"none","data":[["1","2"],["roj","roj"],[1,null],[1,10],["English             ",null],[1000,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>join_type<\/th>\n      <th>language_id<\/th>\n      <th>language_id_f<\/th>\n      <th>name<\/th>\n      <th>rojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,3,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   join_type language_id language_id_f                 name rojs
## 1       roj           1             1 English              1000
## 2       roj          NA            10                 <NA>    1
```

The rojs column returns the number of rows found on the keys from the right table, film, and the left table, the language table.  For the "English" row, the language_id and film_lang_id match and a 1000 inner joins were performed.  For language_id = 10 from the right table, there was only 1 join to a non-existant row in the language table on the left.  

1.  The right outer join always returns all rows from the right table, the driving/key table, if not reduced via a filter()/where clause.  
2.  All rows that inner join returns all the columns/derived columns specified in the select clause from both the left and right tables.  
3.  All rows from the right table, the outer table, without a matching row on the left returns all the columns/derived column values specified in the select clause from the right, but the values from left table have all values of NA. 

#### dplyr Full Outer Join


```r
languages_foj <- language_table %>%
  full_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f"))) %>%
  mutate(film_lang = if_else(is.na(film_id), paste0("No ", name, " films."), if_else(is.na(name), "Alien", name))) %>%
  group_by(language_id, name, film_lang) %>%
  summarize(n = n())

sp_print_df(languages_foj)
```

<!--html_preserve--><div id="htmlwidget-124fb78127817ec02cd9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-124fb78127817ec02cd9">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[1,2,3,4,5,6,10],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              ",null],["English             ","No Italian              films.","No Japanese             films.","No Mandarin             films.","No French               films.","No German               films.","Alien"],[1000,1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>film_lang<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
languages_foj
```

```
## # A tibble: 7 x 4
## # Groups:   language_id, name [?]
##   language_id name                   film_lang                          n
##         <int> <chr>                  <chr>                          <int>
## 1           1 "English             " "English             "          1000
## 2           2 "Italian             " No Italian              films.     1
## 3           3 "Japanese            " No Japanese             films.     1
## 4           4 "Mandarin            " No Mandarin             films.     1
## 5           5 "French              " No French               films.     1
## 6           6 "German              " No German               films.     1
## 7          10 <NA>                   Alien                              1
```

#### SQL full Outer Join


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,f.language_id language_id_f,count(*) fojs
   from language l full outer join smy_film f on l.language_id = f.language_id
  group by l.language_id,l.name,f.language_id
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-dd0a51033db44e820d90" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-dd0a51033db44e820d90">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[1,2,3,4,5,6,null],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              ",null],[1,null,null,null,null,null,10],[1000,1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>language_id_f<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name language_id_f fojs
## 1           1 English                          1 1000
## 2           2 Italian                         NA    1
## 3           3 Japanese                        NA    1
## 4           4 Mandarin                        NA    1
## 5           5 French                          NA    1
## 6           6 German                          NA    1
## 7          NA                 <NA>            10    1
```

Looking at the SQL output, the full outer join is the combination of the left and right outer joins.  

1.  Language_id = 1 is the inner join.
2.  Language_id = 2 - 6 is the left outer join
3.  Language_id = 10 is the right outer join.

One can also just look at the language_id on the left and language_id_f on the right for a non NA value to see which side  is outer side/driving side of the join.

#### dplyr anti Join

The anti join is a left outer join without the inner joined rows.  It only returns the rows from the left table that do not have a match from the right table.


```r
languages_aj <- language_table %>%
  anti_join(film_table, by = c("language_id", "language_id"), suffix(c(".l", ".f"))) %>%
  mutate(type = "anti_join") %>%
  group_by(type, language_id, name) %>%
  summarize(anti_joins = n()) %>%
  select(type, language_id, name, anti_joins)
sp_print_df(languages_aj)
```

<!--html_preserve--><div id="htmlwidget-1fe403c81784621152ab" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1fe403c81784621152ab">{"x":{"filter":"none","data":[["1","2","3","4","5"],["anti_join","anti_join","anti_join","anti_join","anti_join"],[2,3,4,5,6],["Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>type<\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>anti_joins<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[2,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
languages_aj
```

```
## # A tibble: 5 x 4
## # Groups:   type, language_id [5]
##   type      language_id name                   anti_joins
##   <chr>           <int> <chr>                       <int>
## 1 anti_join           2 "Italian             "          1
## 2 anti_join           3 "Japanese            "          1
## 3 anti_join           4 "Mandarin            "          1
## 4 anti_join           5 "French              "          1
## 5 anti_join           6 "German              "          1
```

#### SQL anti Join 1, Left Outer Join where NULL on Right

SQL doesn't have an anti join key word.  Here are three different ways to achieve the same result.


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,count(*) fojs
   from language l left outer join smy_film f on l.language_id = f.language_id
  where f.language_id is null
  group by l.language_id,l.name
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-ed78248b32e6634f28e5" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-ed78248b32e6634f28e5">{"x":{"filter":"none","data":[["1","2","3","4","5"],[2,3,4,5,6],["Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name fojs
## 1           2 Italian                 1
## 2           3 Japanese                1
## 3           4 Mandarin                1
## 4           5 French                  1
## 5           6 German                  1
```

#### SQL anti Join 2, ID in driving table and NOT IN lookup table


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,count(*) fojs
   from language l 
  where l.language_id NOT IN (select language_id from film)
  group by l.language_id,l.name
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-2ae622211a824c064fbd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-2ae622211a824c064fbd">{"x":{"filter":"none","data":[["1","2","3","4","5"],[2,3,4,5,6],["Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name fojs
## 1           2 Italian                 1
## 2           3 Japanese                1
## 3           4 Mandarin                1
## 4           5 French                  1
## 5           6 German                  1
```

#### SQL anti Join 3, NOT EXISTS and Correlated subquery


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,count(*) fojs
   from language l 
  where not exists (select language_id from film f where f.language_id = l.language_id)
 group by l.language_id,l.name
"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-09904734225327216f09" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-09904734225327216f09">{"x":{"filter":"none","data":[["1","2","3","4","5"],[2,3,4,5,6],["Italian             ","Japanese            ","Mandarin            ","French              ","German              "],[1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name fojs
## 1           2 Italian                 1
## 2           3 Japanese                1
## 3           4 Mandarin                1
## 4           5 French                  1
## 5           6 German                  1
```

## SQL anti join Costs


```r
sql_aj1 <- dbGetQuery(
  con,
  "explain analyze select l.language_id,l.name,count(*) fojs
   from language l left outer join smy_film f on l.language_id = f.language_id
  where f.language_id is null
  group by l.language_id,l.name
"
)

sql_aj2 <- dbGetQuery(
  con,
  "explain analyze select l.language_id,l.name,count(*) fojs
   from language l 
  where l.language_id NOT IN (select language_id from film)
  group by l.language_id,l.name
"
)

sql_aj3 <- dbGetQuery(
  con,
  "explain analyze select l.language_id,l.name,count(*) fojs
   from language l 
  where not exists (select language_id from film f where f.language_id = l.language_id)
 group by l.language_id,l.name
"
)
```

##### SQL Costs


```r
print(glue("sql_aj1 loj-null costs=", sql_aj1[1, 1]))
```

```
## sql_aj1 loj-null costs=GroupAggregate  (cost=68.56..68.61 rows=3 width=96) (actual time=16.951..17.058 rows=5 loops=1)
```

```r
print(glue("sql_aj2 not in costs=", sql_aj2[1, 1]))
```

```
## sql_aj2 not in costs=GroupAggregate  (cost=67.60..67.65 rows=3 width=96) (actual time=15.377..15.480 rows=5 loops=1)
```

```r
print(glue("sql_aj3 not exist costs=", sql_aj3[1, 1]))
```

```
## sql_aj3 not exist costs=GroupAggregate  (cost=24.24..24.30 rows=3 width=96) (actual time=0.365..0.464 rows=5 loops=1)
```

## dplyr Anti joins  

In this next section we look at two methods to implemnt an anti join in dplyr.


```r
customer_table <- tbl(con, "customer") # DBI::dbReadTable(con, "customer")
rental_table <- tbl(con, "rental") # DBI::dbReadTable(con, "rental")

# Method 1.  dplyr anti_join
daj1 <-
  anti_join(customer_table, rental_table, by = "customer_id", suffix = c(".c", ".r")) %>%
  select(c("first_name", "last_name", "email")) %>%
  explain()
```

```
## <SQL>
## SELECT "first_name", "last_name", "email"
## FROM (SELECT * FROM "customer" AS "TBL_LEFT"
## 
## WHERE NOT EXISTS (
##   SELECT 1 FROM "rental" AS "TBL_RIGHT"
##   WHERE ("TBL_LEFT"."customer_id" = "TBL_RIGHT"."customer_id")
## )) "lghnetfgzu"
```

```
## 
```

```
## <PLAN>
## Hash Anti Join  (cost=510.99..552.63 rows=300 width=334)
##   Hash Cond: ("TBL_LEFT".customer_id = "TBL_RIGHT".customer_id)
##   ->  Seq Scan on customer "TBL_LEFT"  (cost=0.00..14.99 rows=599 width=338)
##   ->  Hash  (cost=310.44..310.44 rows=16044 width=2)
##         ->  Seq Scan on rental "TBL_RIGHT"  (cost=0.00..310.44 rows=16044 width=2)
```


```r
customer_table <- tbl(con, "customer") # DBI::dbReadTable(con, "customer")
rental_table <- tbl(con, "rental") # DBI::dbReadTable(con, "rental")

# Method 2.  dplyr loj with NA
daj2 <-
  left_join(customer_table, rental_table, by = c("customer_id", "customer_id"), suffix = c(".c", ".r")) %>%
  filter(is.na(rental_id)) %>%
  select(c("first_name", "last_name", "email")) %>%
  explain()
```

```
## <SQL>
## SELECT "first_name", "last_name", "email"
## FROM (SELECT "TBL_LEFT"."customer_id" AS "customer_id", "TBL_LEFT"."store_id" AS "store_id", "TBL_LEFT"."first_name" AS "first_name", "TBL_LEFT"."last_name" AS "last_name", "TBL_LEFT"."email" AS "email", "TBL_LEFT"."address_id" AS "address_id", "TBL_LEFT"."activebool" AS "activebool", "TBL_LEFT"."create_date" AS "create_date", "TBL_LEFT"."last_update" AS "last_update.c", "TBL_LEFT"."active" AS "active", "TBL_RIGHT"."rental_id" AS "rental_id", "TBL_RIGHT"."rental_date" AS "rental_date", "TBL_RIGHT"."inventory_id" AS "inventory_id", "TBL_RIGHT"."return_date" AS "return_date", "TBL_RIGHT"."staff_id" AS "staff_id", "TBL_RIGHT"."last_update" AS "last_update.r"
##   FROM "customer" AS "TBL_LEFT"
##   LEFT JOIN "rental" AS "TBL_RIGHT"
##   ON ("TBL_LEFT"."customer_id" = "TBL_RIGHT"."customer_id")
## ) "bisndnmtew"
## WHERE ((("rental_id") IS NULL))
```

```
## 
```

```
## <PLAN>
## Hash Right Join  (cost=22.48..375.33 rows=80 width=334)
##   Hash Cond: ("TBL_RIGHT".customer_id = "TBL_LEFT".customer_id)
##   Filter: ("TBL_RIGHT".rental_id IS NULL)
##   ->  Seq Scan on rental "TBL_RIGHT"  (cost=0.00..310.44 rows=16044 width=6)
##   ->  Hash  (cost=14.99..14.99 rows=599 width=338)
##         ->  Seq Scan on customer "TBL_LEFT"  (cost=0.00..14.99 rows=599 width=338)
```


### dplyr Costs

```
<PLAN>
Hash Anti Join  (cost=510.99..529.72 rows=1 width=45)
  Hash Cond: ("TBL_LEFT".customer_id = "TBL_RIGHT".customer_id)
  ->  Seq Scan on customer "TBL_LEFT"  (cost=0.00..14.99 rows=599 width=49)
  ->  Hash  (cost=310.44..310.44 rows=16044 width=2)
        ->  Seq Scan on rental "TBL_RIGHT"  (cost=0.00..310.44 rows=16044 width=2)
```

```
<PLAN>
Hash Right Join  (cost=22.48..375.33 rows=1 width=45)
  Hash Cond: ("TBL_RIGHT".customer_id = "TBL_LEFT".customer_id)
  Filter: ("TBL_RIGHT".rental_id IS NULL)
  ->  Seq Scan on rental "TBL_RIGHT"  (cost=0.00..310.44 rows=16044 width=6)
  ->  Hash  (cost=14.99..14.99 rows=599 width=49)
        ->  Seq Scan on customer "TBL_LEFT"  (cost=0.00..14.99 rows=599 width=49)
```

In this example, the dplyr anti_join verb is *1.4113447 to 22.7308719* times more expensive than the left outer join with a null condition.



```r
sql_aj1 <- dbGetQuery(
  con,
  "explain analyze select c.customer_id,count(*) lojs
   from customer c left outer join rental r on c.customer_id = r.customer_id
  where r.customer_id is null
  group by c.customer_id
order by c.customer_id;"
)
sp_print_df(sql_aj1)
```

<!--html_preserve--><div id="htmlwidget-b619f31f38e9f2471fcc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-b619f31f38e9f2471fcc">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13"],["GroupAggregate  (cost=564.97..570.22 rows=300 width=12) (actual time=266.630..266.647 rows=1 loops=1)","  Group Key: c.customer_id","  -&gt;  Sort  (cost=564.97..565.72 rows=300 width=4) (actual time=266.591..266.609 rows=1 loops=1)","        Sort Key: c.customer_id","        Sort Method: quicksort  Memory: 25kB","        -&gt;  Hash Anti Join  (cost=510.99..552.63 rows=300 width=4) (actual time=266.527..266.563 rows=1 loops=1)","              Hash Cond: (c.customer_id = r.customer_id)","              -&gt;  Seq Scan on customer c  (cost=0.00..14.99 rows=599 width=4) (actual time=0.049..4.501 rows=600 loops=1)","              -&gt;  Hash  (cost=310.44..310.44 rows=16044 width=2) (actual time=257.403..257.412 rows=16044 loops=1)","                    Buckets: 16384  Batches: 1  Memory Usage: 661kB","                    -&gt;  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=2) (actual time=0.048..128.224 rows=16044 loops=1)","Planning time: 0.154 ms","Execution time: 266.866 ms"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>QUERY PLAN<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
sql_aj1
```

```
##                                                                                                                              QUERY PLAN
## 1                                 GroupAggregate  (cost=564.97..570.22 rows=300 width=12) (actual time=266.630..266.647 rows=1 loops=1)
## 2                                                                                                              Group Key: c.customer_id
## 3                                        ->  Sort  (cost=564.97..565.72 rows=300 width=4) (actual time=266.591..266.609 rows=1 loops=1)
## 4                                                                                                               Sort Key: c.customer_id
## 5                                                                                                  Sort Method: quicksort  Memory: 25kB
## 6                              ->  Hash Anti Join  (cost=510.99..552.63 rows=300 width=4) (actual time=266.527..266.563 rows=1 loops=1)
## 7                                                                                            Hash Cond: (c.customer_id = r.customer_id)
## 8                           ->  Seq Scan on customer c  (cost=0.00..14.99 rows=599 width=4) (actual time=0.049..4.501 rows=600 loops=1)
## 9                                  ->  Hash  (cost=310.44..310.44 rows=16044 width=2) (actual time=257.403..257.412 rows=16044 loops=1)
## 10                                                                                      Buckets: 16384  Batches: 1  Memory Usage: 661kB
## 11                     ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=2) (actual time=0.048..128.224 rows=16044 loops=1)
## 12                                                                                                              Planning time: 0.154 ms
## 13                                                                                                           Execution time: 266.866 ms
```

```r
sql_aj3 <- dbGetQuery(
  con,
  "explain analyze 
select c.customer_id,count(*) lojs
   from customer c 
  where not exists (select customer_id from rental r where c.customer_id = r.customer_id)
 group by c.customer_id
"
)

print(glue("sql_aj1 loj-null costs=", sql_aj1[1, 1]))
```

```
## sql_aj1 loj-null costs=GroupAggregate  (cost=564.97..570.22 rows=300 width=12) (actual time=266.630..266.647 rows=1 loops=1)
```

```r
print(glue("sql_aj3 not exist costs=", sql_aj3[1, 1]))
```

```
## sql_aj3 not exist costs=HashAggregate  (cost=554.13..557.13 rows=300 width=12) (actual time=261.507..261.522 rows=1 loops=1)
```

## Exercises

### Anti joins  -- Find customers who have never rented a movie, take 2.

This is a left outer join from customer to the rental table with an NA rental_id.

#### SQL Anti-Join


```r
rs <- dbGetQuery(
  con,
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

<!--html_preserve--><div id="htmlwidget-beeafef17c4840807f51" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-beeafef17c4840807f51">{"x":{"filter":"none","data":[["1"],["Sophie"],["Yang"],["email@email.com"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<-- Add dplyr semi-join example -->



### SQL Rows Per Table 

In the examples above, we looked at how many rows were involved in each of the join examples and which side of the join they came from.  It is often helpful to know how many rows are in each table as a sanity check on the joins.  

Below is the SQL version to return all the row counts from each table in the DVD Rental System.


```r
rs <- dbGetQuery(
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
                       union select 'smy_film' tbl_name,count(*) from smy_film
                       ) counts
                  order by tbl_name
                 ;
                "
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-f6a2206cea77e899a1de" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-f6a2206cea77e899a1de">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],["actor","address","category","city","country","customer"],[200,603,16,600,109,600]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>tbl_name<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##         tbl_name count
## 1          actor   200
## 2        address   603
## 3       category    16
## 4           city   600
## 5        country   109
## 6       customer   600
## 7           film  1000
## 8     film_actor  5462
## 9  film_category  1000
## 10     inventory  4581
## 11      language     6
## 12       payment 14596
## 13        rental 16044
## 14      smy_film  1001
## 15         staff     2
## 16         store     2
```

#### Exercise dplyr Rows Per Table 

In the code block below 

1.  Get the row counts for a couple more tables
2.  What is the structure of film_table object?



```r
film_table <- tbl(con, "film") # DBI::dbReadTable(con, "customer")
language_table <- tbl(con, "language") # DBI::dbReadTable(con, "rental")

film_rows <- film_table %>% mutate(name = "film") %>% group_by(name) %>% summarize(rows = n())
language_rows <- language_table %>%
  mutate(name = "language") %>%
  group_by(name) %>%
  summarize(rows = n())
rows_per_table <- rbind(as.data.frame(film_rows), as.data.frame(language_rows))
rows_per_table
```

```
##       name rows
## 1     film 1000
## 2 language    6
```

#### SQL film distribution based on language

The SQL below is very similar to the `SQL full Outer Join` above.  Instead of counting the joins, it counts the number films associated with each language.


```r
rs <- dbGetQuery(
  con,
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

<!--html_preserve--><div id="htmlwidget-80fb537b5ba0bd90fb93" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-80fb537b5ba0bd90fb93">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[1,5,6,2,3,4],["English             ","French              ","German              ","Italian             ","Japanese            ","Mandarin            "],[1000,0,0,0,0,0]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>id<\/th>\n      <th>name<\/th>\n      <th>total<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
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

#### Exercise dplyr film distribution based on language

Below is the code block from the `dplyr Full Outer Join` section above.  Modify the code block to match the output from the SQL version.


```r
rs <- dbGetQuery(
  con,
  "select l.language_id,l.name,f.language_id language_id_f,count(*) fojs
   from language l full outer join smy_film f on l.language_id = f.language_id
  group by l.language_id,l.name,f.language_id
order by l.language_id;"
)
sp_print_df(rs)
```

<!--html_preserve--><div id="htmlwidget-703a15d93cfc9aff608e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-703a15d93cfc9aff608e">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7"],[1,2,3,4,5,6,null],["English             ","Italian             ","Japanese            ","Mandarin            ","French              ","German              ",null],[1,null,null,null,null,null,10],[1000,1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>language_id<\/th>\n      <th>name<\/th>\n      <th>language_id_f<\/th>\n      <th>fojs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   language_id                 name language_id_f fojs
## 1           1 English                          1 1000
## 2           2 Italian                         NA    1
## 3           3 Japanese                        NA    1
## 4           4 Mandarin                        NA    1
## 5           5 French                          NA    1
## 6           6 German                          NA    1
## 7          NA                 <NA>            10    1
```

## Store analysis

How are the stores performing.  

### SQL store revenue stream

How are the stores performing?  The SQL code shows the payments made to each store in the business.


```r
rs <- dbGetQuery(
  con,
  "select store_id,sum(p.amount) amt,count(*) cnt 
                   from payment p 
                        join staff s 
                          on p.staff_id = s.staff_id  
                 group by store_id order by 2 desc
                 ;
                "
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-6d936e3915a36e12cd53" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6d936e3915a36e12cd53">{"x":{"filter":"none","data":[["1","2"],[2,1],[31059.92,30252.12],[7304,7292]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store_id<\/th>\n      <th>amt<\/th>\n      <th>cnt<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

#### Exercise dplyr store revenue stream

Complete the following code block to return the payments made to each store.


```r
payment_table <- tbl(con, "payment") # DBI::dbReadTable(con, "payment")
staff_table <- tbl(con, "staff") # DBI::dbReadTable(con, "staff")

store_revenue <- payment_table %>%
  inner_join(staff_table, by = "staff_id", suffix = c(".p", ".s")) %>%
  head()

store_revenue
```

```
## # Source:   lazy query [?? x 16]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   payment_id customer_id staff_id rental_id amount payment_date       
##        <int>       <int>    <int>     <int>  <dbl> <dttm>             
## 1      17503         341        2      1520   7.99 2007-02-15 22:25:46
## 2      17504         341        1      1778   1.99 2007-02-16 17:23:14
## 3      17505         341        1      1849   7.99 2007-02-16 22:41:45
## 4      17506         341        2      2829   2.99 2007-02-19 19:39:56
## 5      17507         341        2      3130   7.99 2007-02-20 17:31:48
## 6      17508         341        1      3382   5.99 2007-02-21 12:33:49
## # ... with 10 more variables: first_name <chr>, last_name <chr>,
## #   address_id <int>, email <chr>, store_id <int>, active <lgl>,
## #   username <chr>, password <chr>, last_update <dttm>, picture <blob>
```

<!-- answer
    # group_by(store_id) %>%
    # summarize (amt=sum(amount,na.rm=TRUE),n=n()) %>%
    # arrange (desc(amt))
-->    


### SQL:Estimate Outstanding Balance

The following SQL code calculates for each store

1.  the number of payments still open and closed from the DVD Rental Stores customer base.
2.  the total amount that their customers have paid
3.  the average price per/movie based off of the movies that have been paid.
4.  the estimated outstanding balance based off the open unpaid rentals * the average price per paid movie.


```r
rs <- dbGetQuery(
  con,
  "SELECT s.store_id store,sum(CASE WHEN payment_id IS NULL THEN 1 ELSE 0 END) open
    ,sum(CASE WHEN payment_id IS NOT NULL THEN 1 ELSE 0 END) paid
    ,sum(p.amount) paid_amt
    ,count(*) rentals
    ,round(sum(p.amount) / sum(CASE WHEN payment_id IS NOT NULL 
                                    THEN 1 
                                    ELSE 0 
                               END), 2) avg_price
    ,round(round(sum(p.amount) / sum(CASE WHEN payment_id IS NOT NULL 
                                          THEN 1 
                                          ELSE 0 
                                     END), 2) * sum(CASE WHEN payment_id IS NULL 
                                                         THEN 1 
                                                         ELSE 0 
                                                    END), 2) est_balance
FROM rental r
LEFT JOIN payment p
    ON r.rental_id = p.rental_id
JOIN staff s
    ON r.staff_id = s.staff_id
group by s.store_id;
"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-c195b56d57c26c8f1d4d" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c195b56d57c26c8f1d4d">{"x":{"filter":"none","data":[["1","2"],[1,2],[713,739],[7331,7265],[30498.71,30813.33],[8044,8004],[4.16,4.24],[2966.08,3133.36]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>store<\/th>\n      <th>open<\/th>\n      <th>paid<\/th>\n      <th>paid_amt<\/th>\n      <th>rentals<\/th>\n      <th>avg_price<\/th>\n      <th>est_balance<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   store open paid paid_amt rentals avg_price est_balance
## 1     1  713 7331 30498.71    8044      4.16     2966.08
## 2     2  739 7265 30813.33    8004      4.24     3133.36
```

#### Exercise Dplyr Modify the following dplyr code to match the SQL output from above.


```r
payment_table <- tbl(con, "payment") # DBI::dbReadTable(con, "payment")
rental_table <- tbl(con, "rental") # DBI::dbReadTable(con, "rental")

est_bal <- rental_table %>%
  left_join(payment_table, by = c("rental_id", "rental_id"), suffix = c(".r", ".p")) %>%
  mutate(
    missing = ifelse(is.na(payment_id), 1, 0)
    , found = ifelse(!is.na(payment_id), 1, 0)
  ) %>%
  summarize(
    open = sum(missing, na.rm = TRUE)
    , paid = sum(found, na.rm = TRUE)
    , paid_amt = sum(amount, na.rm = TRUE)
    , rentals = n()
  ) %>%
  summarize(
    open = open
    , paid = paid
    , paid_amt = paid_amt
    , rentals = rentals
    , avg_price = paid_amt / paid
    , est_balance = paid_amt / paid * open
  )
est_bal
```

```
## # Source:   lazy query [?? x 6]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##    open  paid paid_amt rentals         avg_price est_balance
##   <dbl> <dbl>    <dbl> <S3: integer64>     <dbl>       <dbl>
## 1  1452 14596   61312. 16048                4.20       6099.
```

### SQL actual outstanding balance

In the previous exercise, we estimated the outstanding amount.  After reviewing the rental table, the actual movie rental rate is in the table.  We use that to calculate the outstanding balance below.


```r
rs <- dbGetQuery(
  con,
  "SELECT sum(f.rental_rate) open_amt
    ,count(*) count
FROM rental r
LEFT JOIN payment p
    ON r.rental_id = p.rental_id
INNER JOIN inventory i
    ON r.inventory_id = i.inventory_id
INNER JOIN film f
    ON i.film_id = f.film_id
WHERE p.rental_id IS NULL
;"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-7a589913f405d7a14fbe" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-7a589913f405d7a14fbe">{"x":{"filter":"none","data":[["1"],[4297.48],[1452]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##   open_amt count
## 1  4297.48  1452
```


```r
payment_table <- tbl(con, "payment") # DBI::dbReadTable(con, "payment")
rental_table <- tbl(con, "rental") # DBI::dbReadTable(con, "rental")
inventory_table <- tbl(con, "inventory") # DBI::dbReadTable(con, "inventory")
film_table <- tbl(con, "film") # DBI::dbReadTable(con, "film")

act_bal <- rental_table %>%
  left_join(payment_table, by = c("rental_id", "rental_id"), suffix = c(".r", ".p")) %>%
  inner_join(inventory_table, by = c("inventory_id", "inventory_id"), suffix = c(".r", ".i")) %>%
  inner_join(film_table, by = c("film_id", "film_id"), suffix = c(".i", ".f")) %>%
  head()

act_bal
```

```
## # Source:   lazy query [?? x 27]
## # Database: postgres [postgres@localhost:5432/dvdrental]
##   rental_id rental_date         inventory_id customer_id.r
##       <int> <dttm>                     <int>         <int>
## 1         1 2005-05-24 22:53:30          367           130
## 2         2 2005-05-24 22:54:33         1525           459
## 3         3 2005-05-24 23:03:39         1711           408
## 4         4 2005-05-24 23:04:41         2452           333
## 5         5 2005-05-24 23:05:21         2079           222
## 6         6 2005-05-24 23:08:07         2792           549
## # ... with 23 more variables: return_date <dttm>, staff_id.r <int>,
## #   last_update.r <dttm>, payment_id <int>, customer_id.p <int>,
## #   staff_id.p <int>, amount <dbl>, payment_date <dttm>, film_id <int>,
## #   store_id <int>, last_update.i <dttm>, title <chr>, description <chr>,
## #   release_year <int>, language_id <int>, rental_duration <int>,
## #   rental_rate <dbl>, length <int>, replacement_cost <dbl>, rating <S3:
## #   pq_mpaa_rating>, last_update <dttm>, special_features <S3: pq__text>,
## #   fulltext <S3: pq_tsvector>
```

<!--
    filter(is.na(customer_id.p)) %>%
    summarize(open_amount=sum(rental_rate,na.rm = TRUE)
             ,open = n()
             )
-->             

### Rank customers with highest open amounts


```r
rs <- dbGetQuery(
  con,
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

<!--html_preserve--><div id="htmlwidget-a3fe20e2cfd2d5bbfba3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a3fe20e2cfd2d5bbfba3">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[293,307,316,299,274,326],["Mae","Joseph","Steven","James","Naomi","Jose"],["Fletcher","Joy","Curley","Gannon","Jennings","Andrew"],[35.9,31.9,31.9,30.91,29.92,28.93],[10,10,10,9,8,7]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##    customer_id first_name   last_name open_amt count
## 1          293        Mae    Fletcher    35.90    10
## 2          307     Joseph         Joy    31.90    10
## 3          316     Steven      Curley    31.90    10
## 4          299      James      Gannon    30.91     9
## 5          274      Naomi    Jennings    29.92     8
## 6          326       Jose      Andrew    28.93     7
## 7          338     Dennis      Gilman    27.92     8
## 8          277       Olga     Jimenez    27.92     8
## 9          327      Larry    Thrasher    26.93     7
## 10         330      Scott     Shelley    26.93     7
## 11         322      Jason   Morrissey    26.91     9
## 12         340    Patrick      Newsom    25.92     8
## 13         336     Joshua        Mark    25.92     8
## 14         304      David       Royal    24.93     7
## 15         339     Walter    Perryman    23.94     6
## 16         239     Minnie      Romero    23.94     6
## 17         310     Daniel      Cabral    22.93     7
## 18         296     Ramona        Hale    22.93     7
## 19         313     Donald       Mahon    22.93     7
## 20         287      Becky       Miles    22.93     7
## 21         272        Kay    Caldwell    22.93     7
## 22         303    William Satterfield    22.93     7
## 23         329      Frank    Waggoner    22.91     9
## 24         311       Paul       Trout    21.92     8
## 25         109       Edna        West    20.93     7
```
### what film has been rented the most

```r
rs <- dbGetQuery(
  con,
  "SELECT i.film_id
    ,f.title
    ,rental_rate
    ,sum(rental_rate) revenue
    ,count(*) count --16044
FROM rental r
INNER JOIN inventory i
    ON r.inventory_id = i.inventory_id
INNER JOIN film f
    ON i.film_id = f.film_id
GROUP BY i.film_id
    ,f.title
    ,rental_rate
ORDER BY count DESC
LIMIT 25
;"
)
sp_print_df(head(rs))
```

<!--html_preserve--><div id="htmlwidget-a98751c486bb4e6734fc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-a98751c486bb4e6734fc">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[103,738,489,730,767,331],["Bucket Brotherhood","Rocketeer Mother","Juggler Hardly","Ridgemont Submarine","Scalawag Duck","Forward Temple"],[4.99,0.99,0.99,0.99,4.99,2.99],[169.66,32.67,31.68,31.68,159.68,95.68],[34,33,32,32,32,32]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>revenue<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
rs
```

```
##    film_id               title rental_rate revenue count
## 1      103  Bucket Brotherhood        4.99  169.66    34
## 2      738    Rocketeer Mother        0.99   32.67    33
## 3      489      Juggler Hardly        0.99   31.68    32
## 4      730 Ridgemont Submarine        0.99   31.68    32
## 5      767       Scalawag Duck        4.99  159.68    32
## 6      331      Forward Temple        2.99   95.68    32
## 7      382      Grit Clockwork        0.99   31.68    32
## 8      735        Robbers Joon        2.99   92.69    31
## 9      973           Wife Turn        4.99  154.69    31
## 10     621        Network Peak        2.99   92.69    31
## 11    1000           Zorro Ark        4.99  154.69    31
## 12      31       Apache Divine        4.99  154.69    31
## 13     369   Goodfellas Salute        4.99  154.69    31
## 14     753     Rush Goodfellas        0.99   30.69    31
## 15     891      Timberland Sky        0.99   30.69    31
## 16     418        Hobbit Alien        0.99   30.69    31
## 17     127       Cat Coneheads        4.99  149.70    30
## 18     559          Married Go        2.99   89.70    30
## 19     374       Graffiti Love        0.99   29.70    30
## 20     748 Rugrats Shakespeare        0.99   29.70    30
## 21     239        Dogma Family        4.99  149.70    30
## 22     285    English Bulworth        0.99   29.70    30
## 23     109  Butterfly Chocolat        0.99   29.70    30
## 24     450     Idols Snatchers        2.99   89.70    30
## 25     609       Muscle Bright        2.99   89.70    30
```

### what film has been generated the most revenue assuming all amounts are collected

```r
rs <- dbGetQuery(
  con,
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

<!--html_preserve--><div id="htmlwidget-90472fc291eea3b37ad9" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-90472fc291eea3b37ad9">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[103,767,973,31,369,1000],["Bucket Brotherhood","Scalawag Duck","Wife Turn","Apache Divine","Goodfellas Salute","Zorro Ark"],[4.99,4.99,4.99,4.99,4.99,4.99],[169.66,159.68,154.69,154.69,154.69,154.69],[34,32,31,31,31,31]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>revenue<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### which films are in one store but not the other.

```r
rs <- dbGetQuery(
  con,
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

<!--html_preserve--><div id="htmlwidget-6c084255227fcd56827e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6c084255227fcd56827e">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[2,3,5,8,13,20],["Ace Goldfinger","Adaptation Holes","African Egg","Airport Pollock","Ali Forever","Amelie Hellfighters"],[4.99,2.99,2.99,4.99,4.99,4.99],[null,null,null,null,null,1],[null,null,null,null,null,3],[2,2,2,2,2,null],[3,4,3,4,4,null]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>film_id<\/th>\n      <th>title<\/th>\n      <th>rental_rate<\/th>\n      <th>store_id<\/th>\n      <th>count<\/th>\n      <th>store_id..6<\/th>\n      <th>count..7<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,3,4,5,6,7]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Compute the outstanding balance.

```r
rs <- dbGetQuery(
  con,
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

<!--html_preserve--><div id="htmlwidget-cc911bce9136bf4e7dfd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-cc911bce9136bf4e7dfd">{"x":{"filter":"none","data":[["1"],[4297.48],[1452]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>open_amt<\/th>\n      <th>count<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


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
rs1 <- dbGetQuery(con, "select * from customer;")
sp_print_df(head(rs1))
```

<!--html_preserve--><div id="htmlwidget-6c3e37b0fa7ac693f7cc" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-6c3e37b0fa7ac693f7cc">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[524,1,2,3,4,5],[1,1,1,1,2,1],["Jared","Mary","Patricia","Linda","Barbara","Elizabeth"],["Ely","Smith","Johnson","Williams","Jones","Brown"],["jared.ely@sakilacustomer.org","mary.smith@sakilacustomer.org","patricia.johnson@sakilacustomer.org","linda.williams@sakilacustomer.org","barbara.jones@sakilacustomer.org","elizabeth.brown@sakilacustomer.org"],[530,5,6,7,8,9],[true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
pco <- dbSendQuery(con, "select * from customer;")
rs2 <- dbFetch(pco)
dbClearResult(pco)
sp_print_df(head(rs2))
```

<!--html_preserve--><div id="htmlwidget-88984347109043009685" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-88984347109043009685">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[524,1,2,3,4,5],[1,1,1,1,2,1],["Jared","Mary","Patricia","Linda","Barbara","Elizabeth"],["Ely","Smith","Johnson","Williams","Jones","Brown"],["jared.ely@sakilacustomer.org","mary.smith@sakilacustomer.org","patricia.johnson@sakilacustomer.org","linda.williams@sakilacustomer.org","barbara.jones@sakilacustomer.org","elizabeth.brown@sakilacustomer.org"],[530,5,6,7,8,9],[true,true,true,true,true,true],["2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14","2006-02-14"],["2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z","2013-05-26T21:49:45Z"],[1,1,1,1,1,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>customer_id<\/th>\n      <th>store_id<\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n      <th>address_id<\/th>\n      <th>activebool<\/th>\n      <th>create_date<\/th>\n      <th>last_update<\/th>\n      <th>active<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,6,10]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

### Use dbExecute


### Anti join -- Find Sophie who has never rented a movie.


```r
customer_table <- DBI::dbReadTable(con, "customer")
rental_table <- DBI::dbReadTable(con, "rental")

customer_tbl <- dplyr::tbl(con, "customer")
rental_tbl <- dplyr::tbl(con, "rental")

dplyr_tbl_loj <-
  left_join(customer_tbl, rental_tbl, by = "customer_id", suffix = c(".c", ".r")) %>%
  filter(is.na(rental_id)) %>%
  select(c("first_name", "last_name", "email"))

rs <- dbGetQuery(
  con,
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

<!--html_preserve--><div id="htmlwidget-d80799441e19bf040cbf" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-d80799441e19bf040cbf">{"x":{"filter":"none","data":[["1"],["Sophie"],["Yang"],["email@email.com"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>first_name<\/th>\n      <th>last_name<\/th>\n      <th>email<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```r
View(dplyr_tbl_loj)
```







<!--html_preserve--><div id="htmlwidget-5bc260cc0681d28b4458" style="width:672px;height:1000px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-5bc260cc0681d28b4458">{"x":{"diagram":"digraph {\n\ngraph [layout = \"neato\",\n       outputorder = \"edgesfirst\",\n       bgcolor = \"white\"]\n\nnode [fontname = \"Helvetica\",\n      fontsize = \"10\",\n      shape = \"circle\",\n      fixedsize = \"true\",\n      width = \"0.5\",\n      style = \"filled\",\n      fillcolor = \"aliceblue\",\n      color = \"gray70\",\n      fontcolor = \"gray50\"]\n\nedge [fontname = \"Helvetica\",\n     fontsize = \"8\",\n     len = \"1.5\",\n     color = \"gray80\",\n     arrowsize = \"0.5\"]\n\n  \"1\" [label = \"actor\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"2\" [label = \"address\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"3\" [label = \"category\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"4\" [label = \"city\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"5\" [label = \"country\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"6\" [label = \"customer\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"7\" [label = \"film\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"8\" [label = \"film_actor\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"9\" [label = \"film_category\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"10\" [label = \"inventory\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"11\" [label = \"language\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"12\" [label = \"payment\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"13\" [label = \"rental\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"14\" [label = \"staff\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n  \"15\" [label = \"store\", shape = \"rectangle\", width = \"1\", height = \"0.5\", fontsize = \"18\", fillcolor = \"#F0F8FF\", fontcolor = \"#000000\"] \n\"2\"->\"4\" [label = \"fk_address_city\", fontsize = \"15\"] \n\"4\"->\"5\" [label = \"fk_city\", fontsize = \"15\"] \n\"6\"->\"2\" [label = \"customer_address_id_fkey\", fontsize = \"15\"] \n\"7\"->\"11\" [label = \"film_language_id_fkey\", fontsize = \"15\"] \n\"8\"->\"1\" [label = \"film_actor_actor_id_fkey\", fontsize = \"15\"] \n\"8\"->\"7\" [label = \"film_actor_film_id_fkey\", fontsize = \"15\"] \n\"9\"->\"3\" [label = \"film_category_category_id_fkey\", fontsize = \"15\"] \n\"9\"->\"7\" [label = \"film_category_film_id_fkey\", fontsize = \"15\"] \n\"10\"->\"7\" [label = \"inventory_film_id_fkey\", fontsize = \"15\"] \n\"12\"->\"14\" [label = \"payment_staff_id_fkey\", fontsize = \"15\"] \n\"12\"->\"6\" [label = \"payment_customer_id_fkey\", fontsize = \"15\"] \n\"12\"->\"13\" [label = \"payment_rental_id_fkey\", fontsize = \"15\"] \n\"13\"->\"6\" [label = \"rental_customer_id_fkey\", fontsize = \"15\"] \n\"13\"->\"14\" [label = \"rental_staff_id_key\", fontsize = \"15\"] \n\"13\"->\"10\" [label = \"rental_inventory_id_fkey\", fontsize = \"15\"] \n\"14\"->\"2\" [label = \"staff_address_id_fkey\", fontsize = \"15\"] \n\"15\"->\"2\" [label = \"store_address_id_fkey\", fontsize = \"15\"] \n\"15\"->\"14\" [label = \"store_manager_staff_id_fkey\", fontsize = \"15\"] \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


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


