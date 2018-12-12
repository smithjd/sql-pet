# Mapping your local environment (10)

> This chapter explores:
> 
> * The different entities of your components that are involved in running the examples in this book
> * What the different roles that each entity plays in your components
> * How those entities are connected and how you can send messages from one to another
> * How each entity has its own set of commands

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

## Set up docker environment

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go.  Start up the `docker-pet` container:


```r
sp_docker_start("sql-pet")
```

Now connect to the `dvdrental` database with R.  


```r
con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10
)
```

## Tutorial Environment

Here is an overview of your environment.  In this chapter we explore what these pieces are, how they are connected, what commands send a message from one environment to another, and some pass-through commands that take two hops at a time.  You can skip this chapter and come back later when you are curious about the setup that we're using in this book.

<center>
![](screenshots/your-environment-diagram.png)
</center>

### each entity in turn and what entities it can communicate with

### Rstudio

You communicate with Rstudio, which can send commands to both R and to Unix (via the terminal pane or via R).  On a Unix or Mac computer, you communicate with `bash`.

### Unix (command interpreter on your computer)

You can type `bash` commands in a terminal window directly.  Called command prompt on Windows.  Unix can communicate with the Docker client, which can start and stop the Docker server and load containers with programs such as Unix, postgreSQL, etc.

### R

R processes instructions from Rstudio.  It can send instructions to Unix via the `system2` function.  R talks directly to postgreSQL through the DBI package. 

Connecting to the database should be a simple task, but often turns out to take a lot of time to actually get it to work.  We assume that your final write ups are done in some flavor of an Rmd document and others will have access to the database to confirm or further your analysis.

One focus of this tutorial is SQL processing through a dbConnection and we will come back to this in a future section.  The remainder of this section focuses on some specific Docker commands. 

### Docker client

The docker client receives instructions from your local Unix program.  Sets up the Docker server, loads containers, and passes instructions from Unix to the programs running in the Docker server. See more about the [Docker environment](https://docs.docker.com/engine/docker-overview/#the-docker-platform).

Docker has about 44 commands.  We are interested in only those related to Postgres status, started, stopped, and available.  In this tutorial, complete docker commands are printed out before being executed via a `system2` call.  In the event that a code block fails, one can copy and paste the docker command into your local CLI and see if Docker is returning additional information.

Typing `docker` at the terminal command line will print up a summary of all available `docker` commands.  Below are the docker commands used in the exercises.

    Commands:
      ps          List containers
      start       Start one or more stopped containers
      stop        Stop one or more running containers

The general format for a Docker command is 

    docker [OPTIONS] COMMAND ARGUMENTS
    
Below is the output for the Docker exec help command which was used in the `bash` and `psql` command examples above and for an exercise below.

```
$ docker help exec

Usage:  docker exec [OPTIONS] CONTAINER COMMAND [ARG...]

Run a command in a running container

Options:
  -d, --detach               Detached mode: run command in the background
      --detach-keys string   Override the key sequence for detaching a
                             container
  -e, --env list             Set environment variables
  -i, --interactive          Keep STDIN open even if not attached
      --privileged           Give extended privileges to the command
  -t, --tty                  Allocate a pseudo-TTY
  -u, --user string          Username or UID (format:
                             <name|uid>[:<group|gid>])
  -w, --workdir string       Working directory inside the container
```                   
### bash (inside Docker)

Since Mac and Linux users run a version of Linux already, they may want to poke around the Docker environment directly from the bash command line interface (CLI).  Below is the CLI command to start up a bash session, execute a version of hello world, and exit the `bash` session.

(In this and subsequent example, an initial `$` represents your system prompt, which varies according to operating system and local environment.)

In your computer's command prompt:

  `$ docker exec -ti sql-pet bash`

Inside the `bash` (UNIX command) environment:
```
$ echo "hello world!" 
```
The system echoes back:
```
Hello world!
$
```
To execute the same thing in the Docker's version of Unix, send the following command from your local terminal to the Docker client, which sends it to the bash interpreter:

```
docker exec -ti sql-pet echo "hello"
```
### psql (inside Docker)

For users comfortable executing SQL from a command line directly against the database, can run the `psql` application directly.  Below is the CLI command to start up `psql` session, execute a version of hello world, and quitting the `psql` version.

In your computer's command prompt:

   `$ docker exec -ti sql-pet psql -a -p 5432 -d dvdrental -U postgres`

That executes a postreSQL program in docker called `psql`, which is a command line interface to postgreSQL.  `psql` responds with:

```
psql (10.5 (Debian 10.5-1.pgdg90+1))
Type "help" for help.
```
To exit, you enter:

```
dvdrental-#\q
```

* To explore the PostgreSQL environment it's worth browsing around inside the Docker command with a shell.

  + To run the Docker container that contains PostgreSQL, you can enter this from a command prompt:

    `$ docker exec -ti pet sh`

  + To exit Docker enter:

    `# exit`

  + Inside Docker, you can enter the PostgreSQL command-line utility psql by entering 

    `# psql -U postgres`

    Handy [psql commands](https://gpdb.docs.pivotal.io/gs/43/pdf/PSQLQuickRef.pdf) include:

    + `postgres=# \h`          # psql help
    + `postgres=# \dt`         # list PostgreSQL tables
    + `postgres=# \c dbname`   # connect to databse dbname
    + `postgres=# \l`          # list PostgreSQL databases
    + `postgres=# \conninfo`   # display information about current connection
    + `postgres=# \q`          # exit psql


To exit `psql`, enter:
```
    \q
```
The docker bash and psql command options are optional for this tutorial, but open up a gateway to some very powerful programming techniques for future exploration.

### postgreSQL (inside Docker)

The postreSQL database is a whole environment unto itself.  It can receive instructions from bash, psql, and it will respond to `DBI` queries from R on port 5282.

## command structure

We use two trivial commands to explore the various *interfaces*.  `ls -l` is the unix command for listing information about a file and `\du` is the psql command to list the users that exist in postgreSQL.

Your OS and the OS inside docker may be looking at the same file but they are in different time zones.

### Get info on a local file from R code


```r
file.info("README.md")
```

```
##           size isdir mode               mtime               ctime
## README.md 4973 FALSE  644 2018-12-10 14:02:01 2018-12-10 14:02:01
##                         atime  uid  gid uname grname
## README.md 2018-12-11 20:03:54 1000 1000 znmeb  znmeb
```

```r
# Or, using the system2 command:

system2("ls",  "-l README.md", stdout = TRUE, stderr = FALSE)
```

```
## [1] "-rw-r--r-- 1 znmeb znmeb 4973 Dec 10 14:02 README.md"
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

### List postgreSQL users from Rstudio terminal (simulated)

We can't show exactly what a terminal session looks like in this R Markdown book, so we resort to representing it indirectly.

To get a unix command line *inside the sql-pet Docker environment*, enter this command:

> `$ docker exec -it sql-pet bash`

The `$` represents the unix command prompt in your R Studio terminal session.  The unix command prompt inside Docker in this case is `root@ce265d6e5361:/#`.  A trivial Unix command to get the date therefore is: 

> `root@ce265d6e5361:/# date`
>
> `Fri Nov 30 00:29:04 UTC 2018`
 
From that unix command prompt you can also enter the `psql` app (which has sit's own command line interface).  Execute the postgreSQL comand line program `psql`, logging on as `postgres`, and show a list of users:

> `root@ce265d6e5361:/# psql -U postgres -c '\du'`
`psql` returns:

> 
>                                    List of roles
>  `Role name` |                         `Attributes`                         | `Member of`
> -----------+------------------------------------------------------------+-----------
>  `postgres`  | `Superuser, Create role, Create DB, Replication, Bypass RLS` | `{}`

To exit unix inside the Docker container, enter `exit`:

> `root@ce265d6e5361:/# exit`
> 
> `exit`
> 
We are then back to the R Studio terminal command:

> `$`
>

### List postgreSQL users from R code

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


| Example                                                      | R            | OS           | Docker       | Alpine container | pg_restore / ls | postgreSQL    |
| -------------------------------------------------- | ---------- | ---------- | ---------- | -------------- | ------------- | ----------- |
| -U postgres <br />-d dvdrental  <br />petdir/dvdrental.tar               |              |              |              |                  | ![](./screenshots/arrow-right.png)    | --------* |
| ls petdir \|  <br />grep "dvdrental.tar"                           |              |              |              | \|------->     | --------*   |               |
| exec sql-pet <br />ls petdir \|  <br />grep "dvdrental.tar               |              |              | \|-------> | ---------      | --------*   |               |
| docker <br />exec sql-pet  <br />ls petdir \|  <br />grep "dvdrental.tar"      |              | \|-------> | ---------  | ---------      | --------*   |               |
| system2('docker',  <br />'exec sql-pet <br />ls petdir \|  <br />grep "dvdrental.tar" ',  <br />stdout = TRUE,  <br />stderr = TRUE) | \|-------> | ---------  | ---------  | ---------      | --------*   |               |

`docker exec sql-pet ls -l petdir/README.md`
`docker exec -it sql-pet psql -U postgres -c '\l'`

## Exercises

Docker containers have a small foot print.  In our container, we are running a limited Linux kernel and a Postgres database.  To show how tiny the docker environment is, we will look at all the processes running inside Docker and the top level file structure.


In the following exercies, use the `-i` option and the CONTAINER = `sql-pet`.


## Dynamic environment graph
Below is a high level diagram of our tutorial environment.  The single black or blue boxed items are the apps running on your PC, (Linux, Mac, Windows), RStudio, R, Docker, and CLI, a command line interface.  The red boxed items are the versions of the applications shown.  The labels are to the right of the line.

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
    




<!--html_preserve--><div id="htmlwidget-b4c41abe7f743d3a6727" style="width:672px;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-b4c41abe7f743d3a6727">{"x":{"diagram":"\ndigraph Envgraph {\n\n  # graph, node, and edge definitions\n  graph [compound = true, nodesep = .5, ranksep = .25,\n         color = pink]\n\n  node [fontname = Helvetica, fontcolor = darkslategray,\n        shape = rectangle, fixedsize = true, width = 1,\n        color = darkslategray]\n\n  edge [color = grey, arrowhead = none, arrowtail = none]\n\n  # subgraph for PC Environment information\n  subgraph cluster1 {node [fixedsize = true, width = 3] \"unix:\n4.19.8-arch1-1-ARCH\" }\n\n  # subgraph for R information\n  subgraph cluster2 {node [fixedsize = true, width = 3] \"version:\n3.5.1\" }\n\n  # subgraph for RStudio information\n  subgraph cluster3 {node [fixedsize = true, width = 3] \"RStudio version:\n1.2.1114\" }\n\n  # subgraph for Docker information\n  subgraph cluster4 {node [fixedsize = true, width = 3] \"client version:\n18.09.0-ce\" -> \"server version:\n18.09.0-ce\"}\n\n  # subgraph for Docker-Linux information\n  subgraph cluster5 {node [fixedsize = true, width = 3] \"Linux Version:\n4.19.8-arch1-1-ARCH\" }\n\n  # subgraph for Docker-Postgres information\n  subgraph cluster6 {node [fixedsize = true, width = 3] \"PostgreSQL:\nPostgreSQL 10.6 \" }\n\n  # subgraph for Docker-Postgres information\n  graph[color = \"blue\"]\n  subgraph cluster7 {node [fixedsize = true, width = 4.0, color=black, fontcolor = \"blue\"] \"docker exec -it sql-pet bash\" -> \"docker exec -ti sql-pet psql -a \n-p 5432 -d dvdrental -U postgres\" }\n\n  CLI [label=\"CLI\nR system2\",height = .75,width=3.0, color = \"blue\" ]\n  R   [color=\"blue\"]\n  Environment             [label = \"Environment\nLinux,Mac,Windows\",width = 2.5]\n\n  Environment -> RStudio -> R \n  R           -> Docker [label = \"system2 call\"]\n\n  \n  Environment -> \"unix:\n4.19.8-arch1-1-ARCH\"    [lhead = cluster1] # Environment Information\n  R           -> \"version:\n3.5.1\"  [lhead = cluster2] # R Information\n  R           -> \"PostgreSQL:\nPostgreSQL 10.6 \"    [lhead = cluster6, label=\"1. dbConnect\"] # Docker-Postgres Information\n  RStudio     -> \"RStudio version:\n1.2.1114\"    [lhead = cluster3] # RStudio Information\n  Docker      -> \"client version:\n18.09.0-ce\"    [lhead = cluster4] # Docker Information\n  Docker      -> \"Linux Version:\n4.19.8-arch1-1-ARCH\"    [lhead = cluster5] # Docker-Linux Information\n  Docker      -> \"PostgreSQL:\nPostgreSQL 10.6 \"    [lhead = cluster6, label=\"4.  start-stop\"] # Docker-Postgres Information\n  Docker      -> CLI\n\n  \"unix:\n4.19.8-arch1-1-ARCH\" -> CLI\n  CLI         -> \"docker exec -it sql-pet bash\"    [lhead = cluster7] # CLI \n  \"docker exec -it sql-pet bash\"     -> \"Linux Version:\n4.19.8-arch1-1-ARCH\"    [label = \"2.  bash\"]\n  \"docker exec -ti sql-pet psql -a \n-p 5432 -d dvdrental -U postgres\"     -> \"PostgreSQL:\nPostgreSQL 10.6 \"    [label = \"3.  psql\"]\n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->
