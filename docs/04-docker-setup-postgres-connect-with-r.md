# Docker, Postgres, and R (04)

We always load the tidyverse and some other packages, but don't show it unless we are using packages other than `tidyverse`, `DBI`, `RPostgres`, and `glue`.


## Verify that Docker is running

Docker commands can be run from a terminal (e.g., the Rstudio Terminal pane) or with a `system()` command.  In this tutorial, we use `system2()` so that all the output that is created externally is shown.  Note that `system2` calls are divided into several parts:

1. The program that you are sending a command to.
2. The parameters or commands that are being sent.
3. `stdout = TRUE, stderr = TRUE` are two parameters that are standard in this book, so that the command's full output is shown in the book.


The `docker version` command returns the details about the docker daemon that is running on your computer.


```r
system2("docker", "version", stdout = TRUE, stderr = TRUE)
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

## Clean up if appropriate
Remove the `cattle` and `sql-pet` containers if they exists (e.g., from a prior experiments).  

```r
if (system2("docker", "ps -a", stdout = TRUE) %>% 
   grepl(x = ., pattern = 'cattle') %>% 
   any()) {
     system2("docker", "rm -f cattle")
}
if (system2("docker", "ps -a", stdout = TRUE) %>% 
   grepl(x = ., pattern = 'sql-pet') %>% 
   any()) {
     system2("docker", "rm -f sql-pet")
}
```

The convention we use in this book is to assemble a command with `glue` so that the you can see all of its separate parts.  The following chunk just constructs the command, but does not execute it.  If you have problems executing a command, you can always copy the command and execute in your terminal session.

```r
docker_cmd <- glue(
  "run ",      # Run is the Docker command.  Everything that follows are `docker run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  "--name cattle ",       # tells Docker to give the container a name: `cattle`
  "--publish 5432:5432 ", # tells Docker to expose the Postgres port 5432 to the local network with 5432
  " postgres:10 "  # tells Docker the image that is to be run (after downloading if necessary)
)

# We name containers `cattle` for "throw-aways" and `pet` for ones we treasure and keep around.  :-)
```

Submit the command constructed above:

```r
# this is what you would submit from a terminal:
cat(glue(" docker ", docker_cmd))
```

```
##  docker run --detach --name cattle --publish 5432:5432  postgres:10
```

```r
# this is how R submits it to Docker:
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## [1] "12b9285bd4144529d98b79a9d723e4dd944e369956bd6ec81fc7f42f20fcb0c9"
```

Docker returns a long string of numbers.  If you are running this command for the first time, Docker downloads the PostgreSQL image, which takes a bit of time.

The following command shows that a container named `cattle` is running `postgres:10`.  `postgres` is waiting for a connection:

```r
system2("docker", "ps", stdout = TRUE, stderr = TRUE)
```

```
## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED                  STATUS                  PORTS                    NAMES"   
## [2] "12b9285bd414        postgres:10         \"docker-entrypoint.s…\"   Less than a second ago   Up Less than a second   0.0.0.0:5432->5432/tcp   cattle"
```
## Connect, read and write to Postgres from R

### Pause for some security considerations

We use the following `wait_for_postgres` function, which will repeatedly try to connect to PostgreSQL.  PostgreSQL can take different amounts of time to come up and be ready to accept connections from R, depending on various factors that will be discussed later on.

```r
#' Connect to Postgres, waiting if it is not ready
#'
#' @param user Username that will be found
#' @param password Password that corresponds to the username
#' @param dbname the name of the database in the database
#' @param seconds_to_test the number of iterations to try while waiting for Postgres to be ready
#' @export
wait_for_postgres <- function(user, password, dbname, seconds_to_test = 10) {
  for (i in 1:seconds_to_test) {
    db_ready <- DBI::dbCanConnect(RPostgres::Postgres(),
                                  host = "localhost",
                                  port = "5432",
                                  user = user,
                                  password = password,
                                  dbname = dbname)
    if ( !db_ready ) {Sys.sleep(1)}
    else {con <- DBI::dbConnect(RPostgres::Postgres(),
                                host = "localhost",
                                port = "5432",
                                user = user,
                                password = password,
                                dbname = dbname)
    }
    if (i == seconds_to_test & !db_ready) {con <- "There is no connection"}
  }
  con
}
```
When we call `wait_for_postgres` we'll use environment variables that R obtains from reading a file named `.Rprofile`.  That file is not uploaded to Github and R looks for it in your default directory.  To see whether you have already created that file, execute:


```r
dir(path = "~", pattern = ".Rprofile", all.files = TRUE)
```

```
## [1] ".Rprofile"
```

It should contain lines such as:
```
  DEFAULT_POSTGRES_PASSWORD=postgres
  DEFAULT_POSTGRES_USER_NAME=postgres
```
Those are the default values for the username and password, but this approach demonstrates how they would be kept secret and not uploaded to Github or some other public location.

This is how the `wait_for_postgres` function is used:

```r
con <- wait_for_postgres(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                         password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                         dbname = "postgres",
                         seconds_to_test = 10)
```
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


```r
prompt_for_postgres <- function(seconds_to_test){
  for (i in 1:seconds_to_test) {
    db_ready <- DBI::dbCanConnect(RPostgres::Postgres(),
                                  host = "localhost",
                                  port = "5432",
                                  user = dplyr::filter(environment_variables, variable == "username")[, "value"],
                                  password = dplyr::filter(environment_variables, variable == "password")[, "value"],
                                  dbname = "postgres")
    if ( !db_ready ) {Sys.sleep(1)}
    else {con <- DBI::dbConnect(RPostgres::Postgres(),
                                host = "localhost",
                                port = "5432",
                                user = dplyr::filter(environment_variables, variable == "username")[, "value"],
                                password = dplyr::filter(environment_variables, variable == "password")[, "value"],
                                dbname = "postgres")
    }
    if (i == seconds_to_test & !db_ready) {con <- "there is no connection "}
  }
  con
}

DB_USERNAME <- trimws(readline(prompt = "username: "), which = "both")
DB_PASSWORD <- getPass::getPass(msg = "password: ")
environment_variables = data.frame(
  variable = c("username", "password"),
  value = c(DB_USERNAME, DB_PASSWORD),
  stringsAsFactors = FALSE)
write.csv(environment_variables, "./dev_environment.csv", row.names = FALSE)
```
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


\begin{tabular}{r|r|r|r|r|r|r|r|r|r|r}
\hline
mpg & cyl & disp & hp & drat & wt & qsec & vs & am & gear & carb\\
\hline
21.0 & 6 & 160 & 110 & 3.90 & 2.620 & 16.46 & 0 & 1 & 4 & 4\\
\hline
21.0 & 6 & 160 & 110 & 3.90 & 2.875 & 17.02 & 0 & 1 & 4 & 4\\
\hline
22.8 & 4 & 108 & 93 & 3.85 & 2.320 & 18.61 & 1 & 1 & 4 & 1\\
\hline
21.4 & 6 & 258 & 110 & 3.08 & 3.215 & 19.44 & 1 & 0 & 3 & 1\\
\hline
18.7 & 8 & 360 & 175 & 3.15 & 3.440 & 17.02 & 0 & 0 & 3 & 2\\
\hline
18.1 & 6 & 225 & 105 & 2.76 & 3.460 & 20.22 & 1 & 0 & 3 & 1\\
\hline
\end{tabular}

## Clean up

Afterwards, always disconnect from the DBMS, stop the docker container and (optionally) remove it.

```r
dbDisconnect(con)

# tell Docker to stop the container:
system2("docker", "stop cattle", stdout = TRUE, stderr = TRUE)
```

```
## [1] "cattle"
```

```r
# Tell Docker to remove the container from it's library of active containers:
system2("docker", "rm cattle", stdout = TRUE, stderr = TRUE)
```

```
## [1] "cattle"
```

If we `stop` the docker container but don't remove it (with the `rm cattle` command), the container will persist and we can start it up again later with `start cattle`.  In that case, `mtcars` would still be there and we could retrieve it from R again.  Since we have now removed the `cattle` container, the whole database has been deleted.  (There are enough copies of `mtcars` in the world, so no great loss.)
