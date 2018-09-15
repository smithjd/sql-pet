# Docker, Postgres, and R

We always load the tidyverse and some other packages, but don't show it unless we are using packages other than `tidyverse`, `DBI`, and `RPostgres`.

## Verify that Docker running

Docker commands can be run from a terminal (e.g., the Rstudio Terminal pane) or with a `system()` command.  In this tutorial, we use `system2()` so that all the output that is created externally is shown.  Note that `system2` calls are divided into several parts:

1. The program that you are sending a command to.
2. The parameters or commands that are being sent
3. `stdout = TRUE, stderr = TRUE` are two parameters that are standard in this book, so that the comand's full output is shown in the book.

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

The convention we use in this book is to assemble a command with `paste0` so that the parts of the command can be specified separately.

```r
docker_cmd <- paste0(
  "run -d --name cattle --publish 5432:5432 ",
  " postgres:10"
)
docker_cmd
```

```
## [1] "run -d --name cattle --publish 5432:5432  postgres:10"
```

```r
# Naming containers `cattle` for throw-aways and `pet` for ones we treasure and keep around.  :-)
```

Submit the command constructed above:

```r
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
```

```
## Warning in system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE):
## running command ''docker' run -d --name cattle --publish 5432:5432
## postgres:10 2>&1' had status 125
```

```
## [1] "6f517ecefe4366c73a7918c4a0e70a68f2ca4274a9052b08a54b15a9107d165a"                                                                                                                                                                   
## [2] "docker: Error response from daemon: driver failed programming external connectivity on endpoint cattle (d15d0ae850de5166f58d91ef9a34b592977c16e002c28b1627bd8d2da541814d): Bind for 0.0.0.0:5432 failed: port is already allocated."
## attr(,"status")
## [1] 125
```
Docker returns a long string of numbers.  If you are running this command for the first time, Docker is downloading the Postgres image and it takes a bit of time.

The following comand shows that `postgres:10` is still running:

```r
system2("docker", "ps", stdout = TRUE, stderr = TRUE)
```

```
## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES"
## [2] "f2e14cb8faae        postgres:10         \"docker-entrypoint.s…\"   37 seconds ago      Up 11 seconds       0.0.0.0:5432->5432/tcp   pet"
```
## Connect, read and write to Postgres from R

Create a connection to Postgres after waiting 3 seconds so that Docker has time to do its thing.

```r
Sys.sleep(3)

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres")
```

Show that you can connect but that Postgres database doesn't contain any tables:


```r
dbListTables(con)
```

```
## character(0)
```

Write `mtcars` to Postgres

```r
dbWriteTable(con, "mtcars", mtcars)
```

List the tables in the Postgres database to show that `mtcars` is now there:


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
system2("docker", "stop cattle", stdout = TRUE, stderr = TRUE)
```

```
## [1] "cattle"
```

```r
system2("docker", "rm cattle", stdout = TRUE, stderr = TRUE)
```

```
## [1] "cattle"
```

If we `stop` the docker container but don't remove it (with the `rm cattle` command), the container will persist and we can start it up with `start cattle`.  In that case, `mtcars` would still be there and we could download it again.  Since we have now removed the `cattle` container, the whole database has been deleted.  (There are enough copies of `mtcars` in the world, so no great loss.)
