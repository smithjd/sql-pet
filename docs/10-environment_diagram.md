# Mapping your local environment (10)

> This chapter explores:
> 
> * The different entities involved in running the examples in this book's sandbox
> * The different roles that each entity plays in the sandbox
> * How those entities are connected and how communication between those entities happens
> * Pointers to the commands that go with each entity

These packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(DiagrammeR)
display_rows <- 5
```

## Set up docker environment and connect to PostgreSQL

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go.  Start up the `docker-pet` container:


```r
sp_docker_start("sql-pet")
```

Connect to the `dvdrental` database with R.  


```r
con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10
)
```

## Sandbox Environment

Here is an overview of our sandbox environment.  In this chapter we explore each of the entities in the sandbox, how they are connected and how they communicate with each other.  You can skip this chapter and come back later when you are curious about the setup that we're using in this book.

<center>
![](screenshots/your-environment-diagram.png)
</center>

### Sandbox entities and their roles

### RStudio

You communicate with Rstudio, which can send commands to both R and to Unix (via the terminal pane or via a function like `exec2()` in R).  On a Unix or Mac computer, you communicate with `bash`.

To check on the RStudio version you are using, enter this R command:

> `require(rstudioapi)` <br>
> `versionInfo()`

The [RStudio cheat sheet](https://github.com/rstudio/cheatsheets/raw/master/rstudio-ide.pdf) is handy for learning your way around the IDE.

### OS / Local command line interface

You can type commands directly into a terminal window on your computer.  It will be a `bash` prompt on a Unix or Mac, but could be one of several flavors on Windows.  In addition to the normal operating system commands, you can communicate with the Docker client through the command line interpreter to start and stop the Docker server, load containers with programs such as Unix, postgreSQL, etc.

To check on the OS version you are using, enter this on your RStudio terminal or local command line interface:

> `version -a`

An OS can contain different comand line interfaces.  Check on it with this on your RStudio terminal or local command line interface:

> `echo $0`

A [Unix / Linux command line cheet](http://cheatsheetworld.com/programming/unix-linux-cheat-sheet/) sheet is a handy reference.

### R

R processes instructions from Rstudio.  It can send instructions to Unix via the `system2` function.  R talks directly to postgreSQL through the DBI package. 

The diagram conflates the operating system with the command line interface which is a bit of a simplification.  For example, R functions like `file.size("file.typ")` communicate with your operating system but do not issue a command to the command line interpreter.

Although this sandbox seeks to make it easy, connecting to the database often involves technical and organizational hurdles like getting authorization. The main purpose of this book is to provide a sandbox for database queries to experiment with sending commands with the one of the *DBI* functions to the dbms directly from R.  However, Docker and postreSQL commands are useful to know and may be necessary in extending the book's examples. 

To check on the version of R that you are using, enter this on your R command line:

> `R.version`

The [growing collection of RStudio cheet sheets](https://www.rstudio.com/resources/cheatsheets/) is indispensable.

### Docker client

The docker client sets up the Docker server, loads containers, and passes instructions from your OS to the programs running in the Docker server. A Docker container will always contain a subset of the Linux operating system, so that it contains a second command line interepreter in your sandbox.  See more about the [Docker environment](https://docs.docker.com/engine/docker-overview/#the-docker-platform).  

In addition to interaction with docker through the command line interface, there are at least two other methods for communicating with Docker from R.

* The [`docker`](https://bhaskarvk.github.io/docker/) package.
* The [`stevedore`](https://richfitz.github.io/stevedore/) package.

Both packages rely on the `retiulcate` packaage and python.  For this book, we chose to use the command line interface through the `system2()` function calls in order to be as transparent as possible and because the book's sandbox environment is fairly simple.  Although docker has different 44 commands, we only use a subset: `ps`, `build`, `run`, `exec`, `start`, `stop`, and `rm`.  We wrap all of these commands in `sqlpetr` package functions to encourage you to focus on R and postgreSQL.

To check on the Docker version you are using, enter this on your RStudio terminal or local command line interface:

> `docker version`

There are many Docker command line cheat sheets; [this one](https://dockercheatsheet.painlessdocker.com/) is recommended.

### In Docker: Linux

Since Mac and Linux users run a version of Linux already, they may want to poke around the Docker environment directly from the bash command line interface (CLI).  Below is the CLI command to start up a bash session, execute a version of hello world, and exit the `bash` session.

(In this and subsequent example, an initial `$` represents your system prompt, which varies according to operating system and local environment.)

> `docker exec -ti sql-pet uname -a`

> `docker exec -ti sql-pet echo $0`

A [Unix / Linux command line cheet](http://cheatsheetworld.com/programming/unix-linux-cheat-sheet/) sheet is a handy reference.

### In Docker: `psql`

For users comfortable executing SQL from a command line directly against the database, can run the `psql` application directly.  Below is the CLI command to start up `psql` session, execute a version of hello world, and quitting the `psql` version.

In your computer's command prompt:

   `$ docker exec -ti sql-pet psql -a -p 5432 -d dvdrental -U postgres`

A handy [psql cheat sheet](https://gpdb.docs.pivotal.io/gs/43/pdf/PSQLQuickRef.pdf)

### In Docker: `postgreSQL`

The postgreSQL database is a whole environment unto itself.  It can receive instructions from bash, psql, and it will respond to `DBI` queries from R on port 5282.

To check on the version of postgreSQL *client* you are using, enter this on your RStudio terminal or local command line interface:

> `docker exec -ti sql-pet psql --version`

To check on the version of postgreSQL *server* you are using, enter this on your RStudio terminal or local command line interface:

> `docker exec -ti sql-pet psql -U postgres -c 'select version();'`

Here's a recommended [PostgreSQL cheat sheet](http://www.postgresqltutorial.com/wp-content/uploads/2018/03/PostgreSQL-Cheat-Sheet.pdf).

## Getting there from here: entity command structure

We use two trivial commands to explore the various *interfaces*.  `ls -l` is the unix command for listing information about a file and `\du` is the psql command to list the users that exist in postgreSQL.

Your OS and the OS inside docker may be looking at the same file but they are in different time zones.

### Get info on a local file from R code


```r
file.info("README.md")
```

```
##           size isdir mode               mtime               ctime
## README.md 4973 FALSE  644 2018-11-01 14:23:56 2018-11-01 14:23:56
##                         atime uid gid uname grname
## README.md 2018-12-14 16:54:00 502  80   jds  admin
```

```r
# Or, using the system2 command:

system2("ls",  "-l README.md", stdout = TRUE, stderr = FALSE)
```

```
## [1] "-rw-r--r--  1 jds  admin  4973 Nov  1 14:23 README.md"
```
### Poke around inside the OS inside docker

> `docker exec -it sql-pet bash`

### Get info on the same OS file inside Docker from R Code


```r
system2("docker", "exec sql-pet ls -l petdir/README.md", stdout = TRUE, stderr = FALSE)
```

```
## Warning in system2("docker", "exec sql-pet ls -l petdir/README.md", stdout
## = TRUE, : running command ''docker' exec sql-pet ls -l petdir/README.md 2>/
## dev/null' had status 2
```

```
## character(0)
## attr(,"status")
## [1] 2
```


### List postgreSQL users from R code

A trivial command to 


```r
system2("docker", "exec sql-pet psql -U postgres -c '\\du' ", 
        stdout = TRUE, stderr = FALSE)
```

```
## [1] "                                   List of roles"                                    
## [2] " Role name |                         Attributes                         | Member of "
## [3] "-----------+------------------------------------------------------------+-----------"
## [4] " postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}"        
## [5] ""
```
From the RStudio terminal window, the equialent would be:

> `docker exec -it sql-pet psql -U postgres -c '\du'`

## Exercises

Docker containers have a small foot print.  In our container, we are running a limited Linux kernel and a Postgres database.  To show how tiny the docker environment is, we will look at all the processes running inside Docker and the top level file structure.


In the following exercies, use the `-i` option and the CONTAINER = `sql-pet`.

Start up R/RStudio and convert the CLI command to an R/RStudio command 
    
|# |Question          | Docker CLI Command         | R RStudio command | Local Command LINE
|--|------------------|----------------------------|-------------------|---------------
|1 |How many processes are running inside the Docker container?| docker exec -i sql-pet ps -eF|
|1a|How many process are running on your local machine?|||widows: tasklist Mac/Linux: ps -ef
|2 |What is the total number of files and directories in Docker?|docker exec -i sql-pet ls -al||
|2a|What is the total number of files and directories on your local machine?||||
|3 |Is Docker Running?|docker version|||
|3a|What are your Client and Server Versions?|||
|4 |Does Postgres exist in the container?|docker ps -a||
|4a|What is the status of Postgres?|docker ps -a||
|4b|What is the size of Postgres?|docker images||
|4c|What is the size of your laptop OS|||https://www.quora.com/What-is-the-actual-size-of-Windows-10-ISO-file
|5 |If sql-pet status is Up, How do I stop it?|docker stop sql-pet||
|5a|If sql-pet status is Exited, How do I start it?|docker start sql-pet||
    
