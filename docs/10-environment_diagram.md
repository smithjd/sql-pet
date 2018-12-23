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

## Set up our standard pet-sql environment

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

You communicate with Rstudio, which can send commands to both R and to Unix.  Commands to your OS can be entered directly in the terminal pane or via an R function like `exec2()`.  On a Unix or Mac computer, you typically communicate with `bash`, while you have several choices on a Windows computer.

![Mac choices](screenshots/rstudio-shell-choices-on-mac.png)
![Windows choices](screenshots/rstudio-shell-choices-on-windows.png)

To check on the RStudio version you are using, enter this R command:

> `require(rstudioapi)` <br>
> `versionInfo()`

The [RStudio cheat sheet](https://github.com/rstudio/cheatsheets/raw/master/rstudio-ide.pdf) is handy for learning your way around the IDE.

### OS / local command line interface 

You can type commands directly into a terminal window on your computer to communicate with your operating system (OS).  It will be a `bash` prompt on a Unix or Mac, but could be one of several flavors on Windows.  Our diagram conflates the operating system with the command line interface (CLI) which is a bit of a simplification as discussed below.

In addition to operating system commands, you can communicate with the Docker client through the CLI to start and stop the Docker server, load containers with programs such as Unix, postgreSQL, communicae with those programs, etc.

To check on the OS version you are using, enter this on your RStudio terminal or local CLI:

> `version -a`

An OS can contain different comand line interfaces.  Check on it with this on your RStudio terminal or local CLI:

> `echo $0`

A [Unix / Linux command line cheet](http://cheatsheetworld.com/programming/unix-linux-cheat-sheet/) sheet is a handy reference.

### R

R processes instructions from Rstudio.  It can send instructions to your OS via the `system2` function.  R can also talks directly to postgreSQL through the DBI package.

R functions like `file.info("file.typ")` communicate with your operating system but do not visibly issue a command to your CLI.  That's an example of an equivalence that can be useful or confusing (as in our environment diagram): you can get the same information from `ls -ql README.md` on a Unix command line as `file.info("README.md")` on the R console.

Although this sandbox seeks to make it easy, connecting to the database often involves technical and organizational hurdles like getting authorization. The main purpose of this book is to provide a sandbox for database queries to experiment with sending commands with the one of the *DBI* functions to the dbms directly from R.  However, Docker and postreSQL commands are useful to know and may be necessary in extending the book's examples. 

To check on the version of R that you are using, enter this on your R command line:

> `R.version`

The [growing collection of RStudio cheet sheets](https://www.rstudio.com/resources/cheatsheets/) is indispensable.

### Docker client

The docker client sets up the Docker server, loads containers, and passes instructions from your OS to the programs running in the Docker server. A Docker container will always contain a subset of the Linux operating system, so that it contains a second CLI in your sandbox.  See more about the [Docker environment](https://docs.docker.com/engine/docker-overview/#the-docker-platform).  

In addition to interaction with docker through your computer's CLI or the RStudio terminal pane, the [`docker`](https://bhaskarvk.github.io/docker/) and 
 [`stevedore`](https://richfitz.github.io/stevedore/) packages can communicate with Docker from R.  Both packages rely on the `reticulate` packaage and python.  
 
For this book, we chose to send instructions to Docker through R's `system2()` function calls which do pass commands along to Docker through your computer's CLI.  We chose that route in order to be as transparent as possible and because the book's sandbox environment is fairly simple.  Although docker has different 44 commands, in this book we only use a subset: `ps`, `build`, `run`, `exec`, `start`, `stop`, and `rm`.  We wrap all of these commands in `sqlpetr` package functions to encourage you to focus on R and postgreSQL.

To check on the Docker version you are using, enter this on your RStudio terminal or local CLI:

> `docker version`

There are many Docker command line cheat sheets; [this one](https://dockercheatsheet.painlessdocker.com/) is recommended.

### In Docker: Linux

Docker runs a subset of the Linux operating system that in turn runs other programs like psql or postgreSQL.  You may want to poke around the Linux environment inside Docker.  To find what version of Linux Docker is running, enter the following command on your local CLI or in the RStudio terminal pane:

> `docker exec -ti sql-pet uname -a`

As Linux can itself have different CLIs, enter the following command on your local CLI or in the RStudio terminal pane to find out which CLI is running inside Docker:

> `docker exec -ti sql-pet echo $0`

To enter an interactive session inside Docker's Linux environment, enter the following command on your local CLI or in the RStudio terminal pane:

> `docker exec -ti sql-pet bash`

To exit, enter:

> `exit`

A [Unix / Linux command line cheet](http://cheatsheetworld.com/programming/unix-linux-cheat-sheet/) sheet is a handy reference.

### In Docker: `psql`

If you are comfortable executing SQL from a command line directly against the database, you can run the `psql` application in our Docker environment.  To start up a `psql` session to investigate postgreSQL from a command line enter the following command on your computer's CLI or the RStudio terminal pane:

> `$ docker exec -ti sql-pet psql -a -p 5432 -d dvdrental -U postgres`

Exit that environment with:

> `\q`

Us this handy [psql cheat sheet](https://gpdb.docs.pivotal.io/gs/43/pdf/PSQLQuickRef.pdf) to get around.

### In Docker: `postgreSQL`

The postgreSQL database is a whole environment unto itself.  It can receive instructions through bash from `psql`, and it will respond to `DBI` queries from R on port 5282.

To check on the version of postgreSQL *client* (e.g., `psql`) you are using, enter this on your RStudio terminal or local command line interface:

> `docker exec -ti sql-pet psql --version`

To check on the version of postgreSQL *server* you are running in Docker, enter this on your RStudio terminal or local command line interface:

> `docker exec -ti sql-pet psql -U postgres -c 'select version();'`

Here's a recommended [PostgreSQL cheat sheet](http://www.postgresqltutorial.com/wp-content/uploads/2018/03/PostgreSQL-Cheat-Sheet.pdf).

## Getting there from here: entity connections, equivalence, and commands

pathways, equivalences, command structures.

We use two trivial commands to explore the various *interfaces*.  `ls -l` is the unix command for listing information about a file and `\du` is the psql command to list the users that exist in postgreSQL.

Your OS and the OS inside docker may be looking at the same file but they are in different time zones.

### Get info on a local file from R code


```r
file.info("README.md")
```

```
##           size isdir mode               mtime               ctime
## README.md 4973 FALSE  644 2018-12-22 17:12:51 2018-12-22 17:12:51
##                         atime uid gid uname grname
## README.md 2018-12-22 17:18:42 502  80   jds  admin
```
The equivalent information from executing a command on the CLI or terminal would be


```r
system2("ls",  "-l README.md", stdout = TRUE, stderr = FALSE)
```

```
## [1] "-rw-r--r--  1 jds  admin  4973 Dec 22 17:12 README.md"
```
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

### Docker and psql together from R or your CLI

As you become familiar with using docker, you'll see that there are various ways to do any given task.  Here's an illustration of how to get a list of users who have access to the postegreSQL database.


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
From the RStudio terminal window, the equivalent would be a matter of dropping off some of the R code:

> `docker exec -it sql-pet psql -U postgres -c '\du'`

### Nesting commands illustrates how entities are connected

The following tables illustrates how the different entities communicate with each other by decomposing a command from the chapter on [creating a docker container one step at a time](#step-at-a-time-docker):

> `system2("docker", "exec sql-pet pg_restore -U postgres -d dvdrental petdir/dvdrental.tar", stdout = TRUE, stderr = TRUE)`

| Code element | Comment |
|----------------|------------|
| `system2(` | R command to send instructions to your computer's CLI. |
| `"docker",`  | The program (docker) on your computer that will interpret the commands passed from the `system2` function. |
| `"` | The entire string within the quotes is passed to docker | 
| `exec sql-pet`  | `exec` will pass a command to any program running in the `sql-pet` container. |
| `pg_restore`  | `pg_restore` is the program inside the `sql-pet` container that processes instructions to restore a previously downloaded backup file. |
| `-U postgres -d dvdrental` `petdir/dvdrental.tar` | The `pg_restore` program requires a username, a database and a backup file to be restored.|
| `",`  | End of the docker commands passed to the `system2` function in R. |
| `stdout = TRUE, stderr = TRUE)` | The `system2` function needs to know what to do with its output, which in this case is to print all of it. |

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
