# Docker, Postgres, and R (04)

At the end of this chapter, you will be able to 

  * Run, clean-up and close Docker containers.
  * See how to keep credentials secret in code that's visible to the world.
  * Interact with Postgres using Rstudio inside Docker container.
  # Read and write to postgreSQL from R.


We always load the tidyverse and some other packages, but don't show it unless we are using packages other than `tidyverse`, `DBI`, `RPostgres`, and `glue`.


Devtools install of sqlpetr if not already installed



## Verify that Docker is running

Docker commands can be run from a terminal (e.g., the Rstudio Terminal pane) or with a `system()` command.  In this tutorial, we use `system2()` so that all the output that is created externally is shown.  Note that `system2` calls are divided into several parts:

1. The program that you are sending a command to.
2. The parameters or commands that are being sent.
3. `stdout = TRUE, stderr = TRUE` are two parameters that are standard in this book, so that the command's full output is shown in the book.

Check that docker is up and running:


```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```

## Clean up if appropriate
Remove the `cattle` and `sql-pet` containers if they exists (e.g., from a prior experiments).  

```r
sp_docker_remove_container("cattle")
```

```
## Warning in system2("docker", docker_command, stdout = TRUE, stderr = TRUE):
## running command ''docker' rm -f cattle 2>&1' had status 1
```

```
## [1] "Error: No such container: cattle"
## attr(,"status")
## [1] 1
```

```r
sp_docker_remove_container("sql-pet")
```

```
## [1] "sql-pet"
```

The convention we use in this book is to put docker commands in the `sqlpetr` package so that you can ignore them if you want.  However, the functions are set up so that you can easily see how to do things with Docker and modify if you want.

We name containers `cattle` for "throw-aways" and `pet` for ones we treasure and keep around.  :-)

```r
sp_make_simple_pg("cattle")
```

```
## [1] 0
```

Docker returns a long string of numbers.  If you are running this command for the first time, Docker downloads the PostgreSQL image, which takes a bit of time.

The following command shows that a container named `cattle` is running `postgres:10`.  `postgres` is waiting for a connection:

```r
sp_check_that_docker_is_up()
```

```
## [1] "Docker is up, running these containers:"                                                                                                            
## [2] "CONTAINER ID        IMAGE               COMMAND                  CREATED                  STATUS                  PORTS                    NAMES"   
## [3] "9be8cd12aadf        postgres:10         \"docker-entrypoint.s…\"   Less than a second ago   Up Less than a second   0.0.0.0:5432->5432/tcp   cattle"
```
## Connect, read and write to Postgres from R

### Pause for some security considerations

We use the following `sp_get_postgres_connection` function, which will repeatedly try to connect to PostgreSQL.  PostgreSQL can take different amounts of time to come up and be ready to accept connections from R, depending on various factors that will be discussed later on.

<table border = 2)
<tr><td>
When we call </i>sp_get_postgres_connection</i> we'll use environment variables that R obtains from reading a file named <i>.Renviron</i>.  That file is not uploaded to Github and R looks for it in your default directory.  To see whether you have already created that file, execute this in your R session:</br></br>
<ul>
<i><b>dir(path = "~", pattern = ".Renviron", all.files = TRUE)</b></i>
</ul>
That file should contain lines such as:</br></br>
<ul>
  <i><b>DEFAULT_POSTGRES_PASSWORD=postgres</br>
  DEFAULT_POSTGRES_USER_NAME=postgres</b></i></br>
</ul>
Those are the PostreSQL default values for the username and password, so not secret.  But this approach demonstrates how they would be kept secret and not uploaded to Github or some other public location when you need to keep credentials secret.
</td></tr>
</table>

This is how the `sp_get_postgres_connection` function is used:

```r
con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "postgres",
                         seconds_to_test = 10)
```
If you don't have an `.Rprofile` file that defines those passwords, you can just insert a string for the parameter, like:

  `password = 'whatever',`

Make sure that you can connect to the PostgreSQL database that you started earlier. If you have been executing the code from this tutorial, the database will not contain any tables yet:


```r
dbListTables(con)
```

```
## character(0)
```

### Alternative: put the database password in an environment file

The goal is to put the password in an untracked file that will **not** be committed in your source code repository. Your code can reference the name of the variable, but the value of that variable will not appear in open text in your source code.

We have chosen to call the file `dev_environment.csv` in the current working directory where you are executing this script. That file name appears in the `.gitignore` file, so that you will not accidentally commit it. We are going to create that file now.

You will be prompted for the database password. By default, a PostgreSQL database defines a database user named `postgres`, whose password is `postgres`. If you have changed the password or created a new user with a different password, then enter those new values when prompted. Otherwise, enter `postgres` and `postgres` at the two prompts.

In an interactive environment, you could execute a snippet of code that prompts the user for their username and password with the following snippet (which isn't run in the book):

Your password is still in plain text in the file, `dev_environment.csv`, so you should protect that file from exposure. However, you do not need to worry about committing that file accidentally to your git repository, because the name of the file appears in the `.gitignore` file.

For security, we use values from the `environment_variables` data.frame, rather than keeping the `username` and `password` in plain text in a source file.

### Interact with Postgres

Write `mtcars` to PostgreSQL

```r
dbWriteTable(con, "mtcars", mtcars, overwrite = TRUE)
```

List the tables in the PostgreSQL database to show that `mtcars` is now there:


```r
dbListTables(con)
```

```
## [1] "mtcars"
```

```r
# list the fields in mtcars:
dbListFields(con, "mtcars")
```

```
##  [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"
## [11] "carb"
```

Download the table from the DBMS to a local data frame:

```r
mtcars_df <- tbl(con, "mtcars")

# Show a few rows:
knitr::kable(head(mtcars_df))
```



  mpg   cyl   disp    hp   drat      wt    qsec   vs   am   gear   carb
-----  ----  -----  ----  -----  ------  ------  ---  ---  -----  -----
 21.0     6    160   110   3.90   2.620   16.46    0    1      4      4
 21.0     6    160   110   3.90   2.875   17.02    0    1      4      4
 22.8     4    108    93   3.85   2.320   18.61    1    1      4      1
 21.4     6    258   110   3.08   3.215   19.44    1    0      3      1
 18.7     8    360   175   3.15   3.440   17.02    0    0      3      2
 18.1     6    225   105   2.76   3.460   20.22    1    0      3      1

## Clean up

Afterwards, always disconnect from the DBMS, stop the docker container and (optionally) remove it.

```r
dbDisconnect(con)

# tell Docker to stop the container:
sp_docker_stop("cattle")
```

```
## [1] "cattle"
```

```r
# Tell Docker to remove the container from it's library of active containers:
sp_docker_remove_container("cattle")
```

```
## [1] "cattle"
```

If we `stop` the docker container but don't remove it (with the `rm cattle` command), the container will persist and we can start it up again later with `start cattle`.  In that case, `mtcars` would still be there and we could retrieve it from R again.  Since we have now removed the `cattle` container, the whole database has been deleted.  (There are enough copies of `mtcars` in the world, so no great loss.)
