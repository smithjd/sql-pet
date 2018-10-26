# Drilling into Your DB Environment (22)



Start up the `docker-pet` container

```r
sp_docker_start("sql-pet")
```

Now connect to the `dvdrental` database with R

```r
con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password =  Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10)
con
```

```
## <PqConnection> dvdrental@localhost:5432
```

## Which database?

Your DBA will create your user accounts and priviledges for the database(s) that you can access.  

One of the challenges when working with a database(s) is finding where your data actually resides.    Your best resources will be one or more subject matter experts, `SME`, and your DBA.  Your data may actually reside in multiple databases, e.g., a detail and summary databases.  In our tutorial, we focus on the one database, `dvdrental`.  Database names usually reflect something about the data that they contain.

Your laptop is a server for the Docker Postgres databases.  A database is a collection of files that Postgres manages in the background.  

## How many databases reside in the Docker Container?


```r
rs <-
  DBI::dbGetQuery(
  con,
  "SELECT 'DB Names in Docker' showing
          ,datname DB
     FROM pg_database
    WHERE datistemplate = false;
  "
  )
kable(rs)
```


\begin{tabular}{l|l}
\hline
showing & db\\
\hline
DB Names in Docker & postgres\\
\hline
DB Names in Docker & dvdrental\\
\hline
\end{tabular}

Which databases are available?

```
Modify the connection call to connect to the `postgres` database.
```


```r
con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password =  Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "your code goes here",
  seconds_to_test = 10)

con
```

```
## [1] "There is no connection"
```

```r
if (con != 'There is no connection')
    dbDisconnect(con)

#Answer: con <PqConnection> postgres@localhost:5432

# Reconnect to dvdrental

con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password =  Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10)
con
```

```
## <PqConnection> dvdrental@localhost:5432
```

Note that the two Sys.getenv function calls work in this tutorial because both the user and password are available in both databases.  This is a common practice in organinzations that have implemented single sign on across their organization.

```
Gotcha:

   If one has data in multiple databases or multiple environments, Development, Integration, and Prodution, it is very easy to connect to the wrong database in the wrong environment.  Always double check your connection information when logging in and before performing any inserts, updates, or deletes against the database.
```

The following code block should be used to reduce propagating the above gotcha.  Current_database(), CURRENT_DATE or CURRENT_TIMESTAMP, and 'result set' are the most useful and last three not so much.  Instead of the host IP address having the actual hostname would be a nice addition.


```r
rs1 <-
  DBI::dbGetQuery(
  con,
  "SELECT current_database() DB
         ,CURRENT_DATE
         ,CURRENT_TIMESTAMP
         ,'result set description' showing
         ,session_user
         ,inet_server_addr() host
         ,inet_server_port() port
  "
  )
kable(display_rows)
```


\begin{tabular}{r}
\hline
x\\
\hline
5\\
\hline
\end{tabular}

Since we will only be working in the `dvdrental` database in this tutorial and reduce the number of output columns shown, only the 'result set description' will be used. 

## Which Schema?

In the code block below, we look at the `information_schema.table` which contains information about all the schemas and table/views within our dvdrental database.  Databases can have one or more schemas, containers that hold tables or views.  Schemas partition the database into big logical blocks of related data.  Schema names usually reflect an application or logically related datasets.  Occasionally a DBA will set up a new schema and use a users name.  

What schemas are in the `dvdrental` database?
How many entries are in each schema?


```r
## Database Schemas
#  
rs1 <-
  DBI::dbGetQuery(
  con,
  "SELECT 'DB Schemas' showing,t.table_catalog DB,t.table_schema,COUNT(*) tbl_vws
     FROM information_schema.tables t
    GROUP BY t.table_catalog,t.table_schema
  "
  )
kable(rs1)
```


\begin{tabular}{l|l|l|r}
\hline
showing & db & table\_schema & tbl\_vws\\
\hline
DB Schemas & dvdrental & pg\_catalog & 121\\
\hline
DB Schemas & dvdrental & public & 22\\
\hline
DB Schemas & dvdrental & information\_schema & 67\\
\hline
\end{tabular}

We see that there are three schemas.  The pg_catalog is the standard PostgreSQL meta data and core schema.  Postgres uses this schema to manage the internal workings of the database.  DBA's are the primary users of pg_catalog. We used the pg_catalog schema to answer the question 'How many databases reside in the Docker Container?', but normally the data analyst is not interested in analyzing database data.

The information_schema contains ANSI standardized views used across the different SQL vendors, (Oracle, Sysbase, MS SQL Server, IBM DB2, etc). The information_schema contains a plethora of metadata that will help you locate your data tables, understand the relationships between the tables, and write efficient SQL queries.

## Exercises

```r
#
# Add an order by clause to order the output by the table catalog.
rs1 <- DBI::dbGetQuery(con,"SELECT '1. ORDER BY table_catalog' showing
                                  ,t.table_catalog DB,t.table_schema,COUNT(*) tbl_vws 
                              FROM information_schema.tables t
                            GROUP BY t.table_catalog,t.table_schema
                            "
                      )
kable(rs1)
```


\begin{tabular}{l|l|l|r}
\hline
showing & db & table\_schema & tbl\_vws\\
\hline
1. ORDER BY table\_catalog & dvdrental & pg\_catalog & 121\\
\hline
1. ORDER BY table\_catalog & dvdrental & public & 22\\
\hline
1. ORDER BY table\_catalog & dvdrental & information\_schema & 67\\
\hline
\end{tabular}

```r
# Add an order by clause to order the output by tbl_vws in descending order.
rs2 <- DBI::dbGetQuery(con,"SELECT '2. ORDER BY tbl_vws desc' showing
                                  ,t.table_catalog DB,t.table_schema,COUNT(*) tbl_vws 
                              FROM information_schema.tables t
                            GROUP BY t.table_catalog,t.table_schema
                            "
                      )
kable(rs2)
```


\begin{tabular}{l|l|l|r}
\hline
showing & db & table\_schema & tbl\_vws\\
\hline
2. ORDER BY tbl\_vws desc & dvdrental & pg\_catalog & 121\\
\hline
2. ORDER BY tbl\_vws desc & dvdrental & public & 22\\
\hline
2. ORDER BY tbl\_vws desc & dvdrental & information\_schema & 67\\
\hline
\end{tabular}


```r
# Complete the SQL statement to show everything about all the tables.

rs3 <- DBI::dbGetQuery(con,"SELECT '3. all information_schema tables' showing
                                  ,'your code goes here' 
                              FROM information_schema.tables t
                            "
                      )
kable(head (rs3,display_rows))
```


\begin{tabular}{l|l}
\hline
showing & ?column?\\
\hline
3. all information\_schema tables & your code goes here\\
\hline
3. all information\_schema tables & your code goes here\\
\hline
3. all information\_schema tables & your code goes here\\
\hline
3. all information\_schema tables & your code goes here\\
\hline
3. all information\_schema tables & your code goes here\\
\hline
\end{tabular}


```r
# Use the results from above to pull interesting columns from just the information_schema
rs4 <- DBI::dbGetQuery(con,"SELECT '4. information_schema.tables' showing
                                  ,'your code goes here' 
                              FROM information_schema.tables t
                             where 'your code goes here' = 'your code goes here'
                            "
                      )
head(rs4,display_rows)
```

```
##                        showing            ?column?
## 1 4. information_schema.tables your code goes here
## 2 4. information_schema.tables your code goes here
## 3 4. information_schema.tables your code goes here
## 4 4. information_schema.tables your code goes here
## 5 4. information_schema.tables your code goes here
```

```r
# Modify the SQL below with your interesting column names.
# Update the where clause to return only rows from the information schema and begin with 'tab'
rs5 <- DBI::dbGetQuery(con,"SELECT '5. information_schema.tables' showing
                                  ,'your code goes here' 
                              FROM information_schema.tables t
                             where 'your code goes here' = 'your code goes here'
                            "
                      )
kable(head(rs5,display_rows))
```


\begin{tabular}{l|l}
\hline
showing & ?column?\\
\hline
5. information\_schema.tables & your code goes here\\
\hline
5. information\_schema.tables & your code goes here\\
\hline
5. information\_schema.tables & your code goes here\\
\hline
5. information\_schema.tables & your code goes here\\
\hline
5. information\_schema.tables & your code goes here\\
\hline
\end{tabular}

```r
# Modify the SQL below with your interesting column names.
# Update the where clause to return only rows from the information schema and begin with 'col'
rs6 <- DBI::dbGetQuery(con,"SELECT '6. information_schema.tables' showing
                                  ,'your code goes here' 
                              FROM information_schema.tables t
                             where 'your code goes here' = 'your code goes here'
                            "
                      )
kable(head(rs6,display_rows))
```


\begin{tabular}{l|l}
\hline
showing & ?column?\\
\hline
6. information\_schema.tables & your code goes here\\
\hline
6. information\_schema.tables & your code goes here\\
\hline
6. information\_schema.tables & your code goes here\\
\hline
6. information\_schema.tables & your code goes here\\
\hline
6. information\_schema.tables & your code goes here\\
\hline
\end{tabular}

In the next exercise we combine both the table and column output from the previous exercises.  Review the following code block.  The last two lines of the WHERE clause are swithced.  Will the result set be the same or different?  Execute the code block and review the two datasets.


```r
rs7 <- DBI::dbGetQuery(con,"SELECT '7. information_schema.tables' showing
                                  ,table_catalog||'.'||table_schema db_info, table_name, table_type
                              FROM information_schema.tables t
                             where table_schema = 'information_schema'
                               and table_name like 'table%' OR table_name like '%col%'
                               and table_type = 'VIEW'
                            "
                      )
kable(head(rs7,display_rows))
```


\begin{tabular}{l|l|l|l}
\hline
showing & db\_info & table\_name & table\_type\\
\hline
7. information\_schema.tables & dvdrental.information\_schema & collations & VIEW\\
\hline
7. information\_schema.tables & dvdrental.information\_schema & collation\_character\_set\_applicability & VIEW\\
\hline
7. information\_schema.tables & dvdrental.information\_schema & column\_domain\_usage & VIEW\\
\hline
7. information\_schema.tables & dvdrental.information\_schema & column\_privileges & VIEW\\
\hline
7. information\_schema.tables & dvdrental.information\_schema & column\_udt\_usage & VIEW\\
\hline
\end{tabular}

```r
rs8 <- DBI::dbGetQuery(con,"SELECT '8. information_schema.tables' showing
                                  ,table_catalog||'.'||table_schema db_info, table_name, table_type
                              FROM information_schema.tables t
                             where table_schema = 'information_schema'
                               and table_type = 'VIEW'
                               and table_name like 'table%' OR table_name like '%col%'
                            "
                      )
kable(head(rs8,display_rows))
```


\begin{tabular}{l|l|l|l}
\hline
showing & db\_info & table\_name & table\_type\\
\hline
8. information\_schema.tables & dvdrental.information\_schema & column\_options & VIEW\\
\hline
8. information\_schema.tables & dvdrental.information\_schema & \_pg\_foreign\_table\_columns & VIEW\\
\hline
8. information\_schema.tables & dvdrental.information\_schema & view\_column\_usage & VIEW\\
\hline
8. information\_schema.tables & dvdrental.information\_schema & triggered\_update\_columns & VIEW\\
\hline
8. information\_schema.tables & dvdrental.information\_schema & tables & VIEW\\
\hline
\end{tabular}

Operator/Element |	Associativity |	Description
-----------------|----------------|-------------
.	|left|	table/column name separator
::|	left|	PostgreSQL-style typecast
[ ]|	left|	array element selection
-|	right|	unary minus
^|	left|	exponentiation
* / %|	left|	multiplication, division, modulo
+ -|	left|	addition, subtraction
IS||	 	IS TRUE, IS FALSE, IS UNKNOWN, IS NULL
ISNULL||	 	test for null
NOTNULL||	 	test for not null
(any other)|	left|	all other native and user-defined operators
IN||	 	set membership
BETWEEN||	 	range containment
OVERLAPS||	 	time interval overlap
LIKE ILIKE SIMILAR||	 	string pattern matching
< >||	 	less than, greater than
=|	right|	equality, assignment
NOT|	right|	logical negation
AND|	left|	logical conjunction
OR|	left|	logical disjunction




```r
rs1 <- DBI::dbGetQuery(con,"SELECT t.table_catalog DB ,t.table_schema
                                  ,t.table_name,t.table_type
                              FROM information_schema.tables t")

rs2 <- DBI::dbGetQuery(con,"SELECT t.table_catalog DB ,t.table_schema
                                  ,t.table_type,COUNT(*) tbls
                              FROM information_schema.tables t
                            group by t.table_catalog ,t.table_schema
                                  ,t.table_type
                            ")

rs3 <- DBI::dbGetQuery(con,"SELECT distinct t.table_catalog DB ,t.table_schema
                                  ,t.table_type tbls
                              FROM information_schema.tables t
                            ")



#kable(head(rs1 %>% arrange (table_name)))
# View(rs1)
# View(rs2)
# View(rs3)
kable(head(rs1))
```


\begin{tabular}{l|l|l|l}
\hline
db & table\_schema & table\_name & table\_type\\
\hline
dvdrental & public & actor\_info & VIEW\\
\hline
dvdrental & public & customer\_list & VIEW\\
\hline
dvdrental & public & film\_list & VIEW\\
\hline
dvdrental & public & nicer\_but\_slower\_film\_list & VIEW\\
\hline
dvdrental & public & sales\_by\_film\_category & VIEW\\
\hline
dvdrental & public & staff & BASE TABLE\\
\hline
\end{tabular}

```r
kable(head(rs2))
```


\begin{tabular}{l|l|l|r}
\hline
db & table\_schema & table\_type & tbls\\
\hline
dvdrental & information\_schema & BASE TABLE & 7\\
\hline
dvdrental & information\_schema & VIEW & 60\\
\hline
dvdrental & pg\_catalog & BASE TABLE & 62\\
\hline
dvdrental & public & BASE TABLE & 15\\
\hline
dvdrental & public & VIEW & 7\\
\hline
dvdrental & pg\_catalog & VIEW & 59\\
\hline
\end{tabular}

```r
kable(head(rs3))
```


\begin{tabular}{l|l|l}
\hline
db & table\_schema & tbls\\
\hline
dvdrental & information\_schema & BASE TABLE\\
\hline
dvdrental & information\_schema & VIEW\\
\hline
dvdrental & pg\_catalog & BASE TABLE\\
\hline
dvdrental & public & BASE TABLE\\
\hline
dvdrental & public & VIEW\\
\hline
dvdrental & pg\_catalog & VIEW\\
\hline
\end{tabular}


www.dataquest.io/blog/postgres-internals

Comment on the practice of putting a comma at the beginning of a line in SQL code.

```r
## Explain a `dplyr::join

tbl_pk_fk_df <- DBI::dbGetQuery(con,
"
SELECT --t.table_catalog,t.table_schema,
   c.table_name
	,kcu.column_name
	,c.constraint_name
	,c.constraint_type
	,coalesce(c2.table_name, '') ref_table
	,coalesce(kcu2.column_name, '') ref_table_col
FROM information_schema.tables t
LEFT JOIN information_schema.table_constraints c
  ON t.table_catalog = c.table_catalog
    AND t.table_schema = c.table_schema
    AND t.table_name = c.table_name
LEFT JOIN information_schema.key_column_usage kcu
	ON c.constraint_schema = kcu.constraint_schema
		AND c.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.referential_constraints rc
	ON c.constraint_schema = rc.constraint_schema
		AND c.constraint_name = rc.constraint_name
LEFT JOIN information_schema.table_constraints c2
	ON rc.unique_constraint_schema = c2.constraint_schema
		AND rc.unique_constraint_name = c2.constraint_name
LEFT JOIN information_schema.key_column_usage kcu2
	ON c2.constraint_schema = kcu2.constraint_schema
		AND c2.constraint_name = kcu2.constraint_name
		AND kcu.ordinal_position = kcu2.ordinal_position
WHERE c.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
  AND c.table_catalog = 'dvdrental'
	AND c.table_schema = 'public'
ORDER BY c.table_name;
")

# View(tbl_pk_fk_df)

tables_df <- tbl_pk_fk_df %>% distinct(table_name)
# View(tables_df)
```




```r
library(DiagrammeR)

table_nodes_ndf <- create_node_df(
  n <- nrow(tables_df)
  ,type  <- 'table'
  ,label <- tables_df$table_name
  ,shape = "rectangle"
  ,width = 1
  ,height = .5
  ,fontsize = 18
)

tbl_pk_fk_ids_df <- inner_join(tbl_pk_fk_df,table_nodes_ndf
                ,by = c('table_name' = 'label')
                ,suffix(c('st','s'))
                ) %>% 
     rename('src_tbl_id' = id) %>%
     left_join(table_nodes_ndf
               ,by = c('ref_table' = 'label') 
               ,suffix(c('st','t'))
               ) %>%
     rename('fk_tbl_id' = id) 

tbl_fk_df <- tbl_pk_fk_ids_df %>% filter(constraint_type == 'FOREIGN KEY')     
tbl_pk_df <- tbl_pk_fk_ids_df %>% filter(constraint_type == 'PRIMARY KEY') 
# View(tbl_pk_fk_ids_df)
# View(tbl_fk_df)
# View(tbl_pk_df)
kable(head(tbl_fk_df))
```


\begin{tabular}{l|l|l|l|l|l|r|l|l|r|r|r|r|l|l|r|r|r}
\hline
table\_name & column\_name & constraint\_name & constraint\_type & ref\_table & ref\_table\_col & src\_tbl\_id & type.x & shape.x & width.x & height.x & fontsize.x & fk\_tbl\_id & type.y & shape.y & width.y & height.y & fontsize.y\\
\hline
address & city\_id & fk\_address\_city & FOREIGN KEY & city & city\_id & 2 & table & rectangle & 1 & 0.5 & 18 & 4 & table & rectangle & 1 & 0.5 & 18\\
\hline
city & country\_id & fk\_city & FOREIGN KEY & country & country\_id & 4 & table & rectangle & 1 & 0.5 & 18 & 5 & table & rectangle & 1 & 0.5 & 18\\
\hline
customer & address\_id & customer\_address\_id\_fkey & FOREIGN KEY & address & address\_id & 6 & table & rectangle & 1 & 0.5 & 18 & 2 & table & rectangle & 1 & 0.5 & 18\\
\hline
film & language\_id & film\_language\_id\_fkey & FOREIGN KEY & language & language\_id & 7 & table & rectangle & 1 & 0.5 & 18 & 11 & table & rectangle & 1 & 0.5 & 18\\
\hline
film\_actor & actor\_id & film\_actor\_actor\_id\_fkey & FOREIGN KEY & actor & actor\_id & 8 & table & rectangle & 1 & 0.5 & 18 & 1 & table & rectangle & 1 & 0.5 & 18\\
\hline
film\_actor & film\_id & film\_actor\_film\_id\_fkey & FOREIGN KEY & film & film\_id & 8 & table & rectangle & 1 & 0.5 & 18 & 7 & table & rectangle & 1 & 0.5 & 18\\
\hline
\end{tabular}

```r
kable(head(tbl_pk_df))
```


\begin{tabular}{l|l|l|l|l|l|r|l|l|r|r|r|r|l|l|r|r|r}
\hline
table\_name & column\_name & constraint\_name & constraint\_type & ref\_table & ref\_table\_col & src\_tbl\_id & type.x & shape.x & width.x & height.x & fontsize.x & fk\_tbl\_id & type.y & shape.y & width.y & height.y & fontsize.y\\
\hline
actor & actor\_id & actor\_pkey & PRIMARY KEY &  &  & 1 & table & rectangle & 1 & 0.5 & 18 & NA & NA & NA & NA & NA & NA\\
\hline
address & address\_id & address\_pkey & PRIMARY KEY &  &  & 2 & table & rectangle & 1 & 0.5 & 18 & NA & NA & NA & NA & NA & NA\\
\hline
category & category\_id & category\_pkey & PRIMARY KEY &  &  & 3 & table & rectangle & 1 & 0.5 & 18 & NA & NA & NA & NA & NA & NA\\
\hline
city & city\_id & city\_pkey & PRIMARY KEY &  &  & 4 & table & rectangle & 1 & 0.5 & 18 & NA & NA & NA & NA & NA & NA\\
\hline
country & country\_id & country\_pkey & PRIMARY KEY &  &  & 5 & table & rectangle & 1 & 0.5 & 18 & NA & NA & NA & NA & NA & NA\\
\hline
customer & customer\_id & customer\_pkey & PRIMARY KEY &  &  & 6 & table & rectangle & 1 & 0.5 & 18 & NA & NA & NA & NA & NA & NA\\
\hline
\end{tabular}


```r
# Create an edge data frame, edf

fk_edf <-
  create_edge_df(
    from = tbl_fk_df$src_tbl_id,
    to = tbl_fk_df$fk_tbl_id,
    rel = "fk",
    label = tbl_fk_df$constraint_name,
    fontsize = 15
  )
# View(fk_edf)
```


```r
graph <-
  create_graph(
    nodes_df = table_nodes_ndf,
    edges_df = fk_edf,
    graph_name = 'Simple FK Graph'
  )

# export the widget to an SVG file
render_graph(graph) %>% 
  DiagrammeRsvg::export_svg() %>% 
  cat(file = "diagrams/fkgraph.svg")

# convert to PDF and PNG - LaTeX doesn't read SVGs by default
magick::image_read("diagrams/fkgraph.svg") %>%
  magick::image_write(
    path = "diagrams/fkgraph.pdf", 
    format = "pdf"
  )
magick::image_read_svg("diagrams/fkgraph.svg") %>%
  magick::image_write(
    path = "diagrams/fkgraph.png", 
    format = "png"
  )
```

![](diagrams/fkgraph.pdf)<!-- --> 


```r
dbDisconnect(con)
# system2('docker','stop sql-pet')
```
