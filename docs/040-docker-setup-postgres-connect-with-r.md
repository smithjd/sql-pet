# Connecting Docker, PostgreSQL, and R {#chapter_connect-docker-postgresql-r}

> This chapter demonstrates how to:
>
>  * Run, clean-up and close PostgreSQL in Docker containers.
>  * Keep necessary credentials secret while being available to R when it executes.
>  * Interact with PostgreSQL when it's running inside a Docker container.
>  * Read and write to PostgreSQL from R.

Please install the `sqlpetr` package if not already installed:

```r
library(devtools)
if (!require(sqlpetr)) devtools::install_github("smithjd/sqlpetr", 
                                                build_opts = "")
```
Note that when you install the package the first time, it will ask you to update the packages it uses and that can take some time.

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
require(knitr)
library(sqlpetr)
```

## Verify that Docker is running

Docker commands can be run from a terminal (e.g., the Rstudio Terminal pane) or with a `system2()` command.  (We discuss the diffeent ways of interacting with Docker and other elements in your environment in a [separate chapter](#your-local-environment).)  The necessary functions to start, stop Docker containers and do other busy work are provided in the `sqlpetr` package.  As time permits and curiosity dictates, feel free to look at those functions to see how they work.

### Check that Docker is up and running

> Note: The `sqlpetr` package is written to accompany this book.  The functions in the package are designed to help you focus on interacting with a dbms from R.  You can ignore how they work until you are ready to delve into the details.  They are all named to begin with `sp_`.  The first time a function is called in the book, we provide a note explaining its use.

> The `sp_check_that_docker_is_up` function from the `sqlpetr` package checks whether Docker is up and running.  If it's not, then you need to install, launch or re-install Docker.


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```

## Remove previous containers if they exist
Force remove the `cattle` and `sql-pet` containers if they exist (e.g., from prior experiments).  

> The `sp_docker_remove_container` function from the `sqlpetr` package forcibly removes a Docker container. If it is running it will be forcibly terminated and removed. If it doesn't exist you won't get an error message. Note that the `images` out of which a container is built will still exist on your system.


```r
sp_docker_remove_container("cattle")
```

```
## [1] 0
```

```r
sp_docker_remove_container("sql-pet")
```

```
## [1] 0
```

We name containers `cattle` for "throw-aways" and `pet` for ones we treasure and keep around.  :-)

> The `sp_docker_remove_container` function from the `sqlpetr` package creates a container and runs the PostgreSQL 10 image (`docker.io/postgres:10`) in it. The image will be downloaded if it doesn't exist locally.


```r
sp_make_simple_pg("cattle")
```
The first time you run this, Docker downloads the PostgreSQL image, which takes a bit of time. Did it work? The following command should show that a container named `cattle` is running `postgres:10`.


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up, running these containers:"                                                                                                       
## [2] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                  PORTS                    NAMES"   
## [3] "57920d27da2a        postgres:10         \"docker-entrypoint.s…\"   1 second ago        Up Less than a second   0.0.0.0:5432->5432/tcp   cattle"
```

> The `sp_docker_containers_tibble` function from the `sqlpetr` package provides more on the containers that Docker is running.  Basically this function creates a tibble of containers using `docker ps`.


```r
sp_docker_containers_tibble()
```

```
## # A tibble: 1 x 12
##   container_id image command created_at created ports status size  names
##   <chr>        <chr> <chr>   <chr>      <chr>   <chr> <chr>  <chr> <chr>
## 1 57920d27da2a post… docker… 2019-03-0… 1 seco… 0.0.… Up Le… 0B (… catt…
## # … with 3 more variables: labels <chr>, mounts <chr>, networks <chr>
```

## Connecting, reading and writing to PostgreSQL from R


### Connecting to PostgreSQL
The `sp_make_simple_pg` function we called above created a container from the
`postgres:10` library image downloaded from Docker Hub. As part of the process, it set the password for the PostgreSQL database superuser `postgres` to the value 
"postgres".

For simplicity, we are using a weak password at this point and it's shown here 
and in the code in plain text. That is bad practice because user credentials 
should not be shared in open code like that.  A [subsequent chapter](#dbms-login)
demonstrates how to store and use credentials to access the DBMS so that they 
are kept private.

> The `sp_get_postgres_connection` function from the `sqlpetr` package gets a DBI connection string to a PostgreSQL database, waiting if it is not ready. This function connects to an instance of PostgreSQL and we assign it to a symbol, `con`, for subsequent use.


```r
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "postgres",
  seconds_to_test = 30
)
```

Make sure that you can connect to the PostgreSQL database that you have just started. If you have been executing the code from this tutorial, the database will not contain any tables yet:


```r
DBI::dbListTables(con)
```

```
## character(0)
```

### Interact with PostgreSQL

Write `mtcars` to PostgreSQL

```r
DBI::dbWriteTable(con, "mtcars", mtcars, overwrite = TRUE)
```

List the tables in the PostgreSQL database to show that `mtcars` is now there:


```r
DBI::dbListTables(con)
```

```
## [1] "mtcars"
```

List the fields in mtcars:

```r
DBI::dbListFields(con, "mtcars")
```

```
##  [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"
## [11] "carb"
```

Download the table from the DBMS to a local data frame:

```r
mtcars_df <- DBI::dbReadTable(con, "mtcars")
```

> The `sp_print_df` function from the `sqlpetr` package shows (or print) a data frame depending on appropriate output type.  That is when running interactively or generating HTML it prints a `DT::datatable()` while it prints a `knitr::kable()` otherwise.

Tell Docker to *remove* the `cattle` container from it's library of active containers:


```r
sp_print_df(head(mtcars_df))
```

<!--html_preserve--><div id="htmlwidget-1d9f9b9fdca3023baa83" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1d9f9b9fdca3023baa83">{"x":{"filter":"none","data":[["1","2","3","4","5","6"],[21,21,22.8,21.4,18.7,18.1],[6,6,4,6,8,6],[160,160,108,258,360,225],[110,110,93,110,175,105],[3.9,3.9,3.85,3.08,3.15,2.76],[2.62,2.875,2.32,3.215,3.44,3.46],[16.46,17.02,18.61,19.44,17.02,20.22],[0,0,1,1,0,1],[1,1,1,0,0,0],[4,4,4,3,3,3],[4,4,1,1,2,1]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>mpg<\/th>\n      <th>cyl<\/th>\n      <th>disp<\/th>\n      <th>hp<\/th>\n      <th>drat<\/th>\n      <th>wt<\/th>\n      <th>qsec<\/th>\n      <th>vs<\/th>\n      <th>am<\/th>\n      <th>gear<\/th>\n      <th>carb<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4,5,6,7,8,9,10,11]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Clean up

Afterwards, always disconnect from the dbms:

```r
DBI::dbDisconnect(con)
```

> The `sp_docker_stop` function from the `sqlpetr` package stops the container given by the `container_name` parameter.

Tell Docker to stop the `cattle` container:

```r
sp_docker_stop("cattle")
```

> The `sp_docker_remove_container` function from the `sqlpetr` package removes the container given by the `container_name` parameter.

Tell Docker to *remove* the `cattle` container from it's library of active containers:


```r
sp_docker_remove_container("cattle")
```

```
## [1] 0
```

Verify that `cattle` is gone:

```r
sp_docker_containers_tibble()
```

```
## # A tibble: 0 x 0
```

If we just **stop** the Docker container but don't remove it (as we did with the `sp_docker_remove_container("cattle")` command), the `cattle` container will persist and we can start it up again later with `sp_docker_start("cattle")`.  In that case, `mtcars` would still be there and we could retrieve it from PostgreSQL again.  Since `sp_docker_remove_container("cattle")`  has removed it, the updated database has been deleted.  (There are enough copies of `mtcars` in the world, so no great loss.)
