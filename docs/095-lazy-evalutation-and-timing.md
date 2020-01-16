# Lazy Evaluation and Execution Environment {#chapter_lazy-evaluation-and-timing}

> This chapter:
> 
> * Builds on the lazy loading discussion in the previous chapter
> * Demonstrates how the use of the `dplyr::collect()` creates a boundary between code that is sent to a dbms and code that is executed locally

## Setup

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(dbplyr)
require(knitr)
library(bookdown)
library(sqlpetr)
sleep_default <- 3
```
If you have not yet set up the Docker container with PostgreSQL and the dvdrental database, go back to [those instructions][Build the pet-sql Docker Image] to configure your environment. Otherwise, start your `adventureworks` container:

```r
sqlpetr::sp_docker_start("adventureworks")
Sys.sleep(sleep_default)
```
Connect to the database:

```r
con <- dbConnect(
  RPostgres::Postgres(),
  # without the previous and next lines, some functions fail with bigint data 
  #   so change int64 to integer
  bigint = "integer",  
  host = "localhost",
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "adventureworks",
  port = 5432)
```

Here is a simple string of `dplyr` verbs similar to the query used to illustrate issues in the last chapter:

Note that in the previous example we follow this book's convention of creating a connection object to each table and fully qualifying function names (e.g., specifying the package).  In practice, it's possible and convenient to use more abbreviated notation.

```r
Q <- tbl(con, in_schema("sales", "salesperson")) %>%
  left_join(tbl(con, in_schema("humanresources", "employee")),  by = c("businessentityid" = "businessentityid")) %>%
  select(birthdate, saleslastyear)

Q
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##    birthdate  saleslastyear
##    <date>             <dbl>
##  1 1951-10-17            0 
##  2 1968-12-25      1750406.
##  3 1980-02-27      1439156.
##  4 1962-08-29      1997186.
##  5 1975-02-04      1620277.
##  6 1974-01-18      1849641.
##  7 1974-12-06      1927059.
##  8 1968-03-09      2073506.
##  9 1963-12-11      2038235.
## 10 1974-02-11      1371635.
## # … with more rows
```

### Experiment overview
Think of `Q` as a black box for the moment.  The following examples will show how `Q` is interpreted differently by different functions. It's important to remember in the following discussion that the "**and then**" operator (`%>%`) actually wraps the subsequent code inside the preceding code so that `Q %>% print()` is equivalent to `print(Q)`.

**Notation**

> |Symbol|Explanation
> |----|-------------
> | ![](screenshots/green-check.png)| A single green check indicates that some rows are returned. <br>
> | ![](screenshots/green-check.png) ![](screenshots/green-check.png)| Two green checks indicate that all the rows are returned.
> | ![](screenshots/red-x.png) |The red X indicates that no rows are returned.
>


> R code | Result 
> -------| --------------
> **Time-based, execution environment issues** | 
> [`Qc <- Q %>% count(saleslastyear, sort = TRUE)`](#lazy_q_build) | ![](screenshots/red-x.png) **Extends** the lazy query object
> 
> 

The next chapter will discuss how to build queries and how to explore intermediate steps. But first, the following subsections provide a more detailed discussion of each row in the preceding table.

### Time-based, execution environment issues

Remember that if the expression is assigned to an object, it is not executed.  If an expression is entered on the command line or appears in your script by itself, a `print()` function is implied. 

> *These two are different:*
> Q %>% sum(saleslastyear) 
> Q_query <- Q %>% sum(saleslastyear) 
>

This behavior is the basis of a useful debugging and development process where queries are built up incrementally.

### Q %>% `more dplyr` {#lazy_q_build}

![](screenshots/green-check.png) Because the following statement implies a `print()` function at the end, we can run it repeatedly, adding dplyr expressions, and only get 10 rows back.  Every time we add a dplyr expression to a chain, R will rewrite the SQL code.  For example:
As we understand more about the data, we simply add dplyr expressions to pinpoint what we are looking for:

```r
Q %>% filter(saleslastyear > 40) %>% 
  arrange(desc(saleslastyear))
```

```
## # Source:     lazy query [?? x 2]
## # Database:   postgres [postgres@localhost:5432/adventureworks]
## # Ordered by: desc(saleslastyear)
##    birthdate  saleslastyear
##    <date>             <dbl>
##  1 1975-09-30      2396540.
##  2 1977-02-14      2278549.
##  3 1968-03-09      2073506.
##  4 1963-12-11      2038235.
##  5 1962-08-29      1997186.
##  6 1974-12-06      1927059.
##  7 1974-01-18      1849641.
##  8 1968-12-25      1750406.
##  9 1968-03-17      1635823.
## 10 1975-02-04      1620277.
## # … with more rows
```


```r
Q %>% summarize(total_sales = sum(saleslastyear, na.rm = TRUE), sales_persons_count = n()) 
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [postgres@localhost:5432/adventureworks]
##   total_sales sales_persons_count
##         <dbl>               <int>
## 1   23685964.                  17
```

![](screenshots/green-check.png) When all the accumulated `dplyr` verbs are executed, they are submitted to the dbms and the number of rows that are returned follow the same rules as discussed above.
### Interspersing SQL and dplyr


```r
Q %>% 
  # mutate(birthdate = date(birthdate)) %>% 
  show_query()
```

```
## <SQL>
## SELECT "birthdate", "saleslastyear"
## FROM (SELECT "LHS"."businessentityid" AS "businessentityid", "LHS"."territoryid" AS "territoryid", "LHS"."salesquota" AS "salesquota", "LHS"."bonus" AS "bonus", "LHS"."commissionpct" AS "commissionpct", "LHS"."salesytd" AS "salesytd", "LHS"."saleslastyear" AS "saleslastyear", "LHS"."rowguid" AS "rowguid.x", "LHS"."modifieddate" AS "modifieddate.x", "RHS"."nationalidnumber" AS "nationalidnumber", "RHS"."loginid" AS "loginid", "RHS"."jobtitle" AS "jobtitle", "RHS"."birthdate" AS "birthdate", "RHS"."maritalstatus" AS "maritalstatus", "RHS"."gender" AS "gender", "RHS"."hiredate" AS "hiredate", "RHS"."salariedflag" AS "salariedflag", "RHS"."vacationhours" AS "vacationhours", "RHS"."sickleavehours" AS "sickleavehours", "RHS"."currentflag" AS "currentflag", "RHS"."rowguid" AS "rowguid.y", "RHS"."modifieddate" AS "modifieddate.y", "RHS"."organizationnode" AS "organizationnode"
## FROM sales.salesperson AS "LHS"
## LEFT JOIN humanresources.employee AS "RHS"
## ON ("LHS"."businessentityid" = "RHS"."businessentityid")
## ) "dbplyr_006"
```

```r
# Need to come up with a different example illustrating where
#  the `collect` statement goes.

# sales_person_table %>% 
#   mutate(birthdate = date(birthdate))
# 
# try(sales_person_table %>% 
#   mutate(birthdate = lubridate::date(birthdate))
# )
# 
# sales_person_table %>% collect() %>% 
#   mutate(birthdate = lubridate::date(birthdate)) 
```

This may not be relevant in the context where it turns out that dates in adventureworks come through as date!

The idea is to show how functions are interpreted BEFORE sending to the SQL translator.


```r
to_char <- function(date, fmt) {return(fmt)}

# sales_person_table %>% 
#   mutate(birthdate = to_char(birthdate, "YYYY-MM")) %>% 
#   show_query()
# 
# sales_person_table %>% 
#   mutate(birthdate = to_char(birthdate, "YYYY-MM")) 
```


### Many handy R functions can't be translated to SQL

![](screenshots/green-check.png) It just so happens that PostgreSQL has a `date` function that does the same thing as the `date` function in the `lubridate` package.  In the following code the `date` function is executed by PostreSQL.

```r
# sales_person_table %>% mutate(birthdate = date(birthdate))
```
![](screenshots/green-check.png) ![](screenshots/green-check.png) If we specify that we want to use the `lubridate` version (or any number of other R functions) they are passed to the dbms unless we explicitly tell `dplyr` to stop translating and bring the results back to the R environment for local processing.

```r
try(sales_person_table %>% collect() %>% 
  mutate(birthdate = lubridate::date(birthdate)))
```

```
## Error in eval(lhs, parent, parent) : 
##   object 'sales_person_table' not found
```

### Further lazy execution examples

See more examples of lazy execution [here](https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html).

## Disconnect from the database and stop Docker


```r
dbDisconnect(con)
sp_docker_stop("adventureworks")
```

## Other resources

* Benjamin S. Baumer. 2017. A Grammar for Reproducible and Painless Extract-Transform-Load Operations on Medium Data. [https://arxiv.org/abs/1708.07073](https://arxiv.org/abs/1708.07073) 
* dplyr Reference documentation: Remote tables. [https://dplyr.tidyverse.org/reference/index.html#section-remote-tables](https://dplyr.tidyverse.org/reference/index.html#section-remote-tables)
* Data Carpentry. SQL Databases and R. [https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html](https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html)
