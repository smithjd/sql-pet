# Mapping your local environment (10)



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

The following code block confirms that one can connect to the Postgres database.  The connection is needed for some of the examples/exercises used in this section.  If the connection is successful, the output is `<PostgreSQLConnection>`.




## Tutorial Environment

Below is a high level diagram of our tutorial environment.  The single black or blue boxed items are the apps running on your PC, (Linux, Mac, Windows), RStudio, R, Docker, and CLI, a command line interface.  The red boxed items are the versions of the applications shown.  The labels are to the right of the line.


<!--html_preserve--><div id="htmlwidget-1d9f9b9fdca3023baa83" style="width:672px;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-1d9f9b9fdca3023baa83">{"x":{"diagram":"\ndigraph Envgraph {\n\n  # graph, node, and edge definitions\n  graph [compound = true, nodesep = .5, ranksep = .25,\n         color = pink]\n\n  node [fontname = Helvetica, fontcolor = darkslategray,\n        shape = rectangle, fixedsize = true, width = 1,\n        color = darkslategray]\n\n  edge [color = grey, arrowhead = none, arrowtail = none]\n\n  # subgraph for PC Environment information\n  subgraph cluster1 {node [fixedsize = true, width = 3] \"unix:\n18.0.0\" }\n\n  # subgraph for R information\n  subgraph cluster2 {node [fixedsize = true, width = 3] \"version:\n3.3.1\" }\n\n  # subgraph for RStudio information\n  subgraph cluster3 {node [fixedsize = true, width = 3] \"RStudio version:\n1.0.36\" }\n\n  # subgraph for Docker information\n  subgraph cluster4 {node [fixedsize = true, width = 3] \"client version:\n18.06.1-ce\" -> \"server version:\n18.06.1-ce\"}\n\n  # subgraph for Docker-Linux information\n  subgraph cluster5 {node [fixedsize = true, width = 3] \"Linux Version:\n4.9.93-linuxkit-aufs\" }\n\n  # subgraph for Docker-Postgres information\n  subgraph cluster6 {node [fixedsize = true, width = 3] \"PostgreSQL:\nPostgreSQL 10.5 \" }\n\n  # subgraph for Docker-Postgres information\n  graph[color = \"blue\"]\n  subgraph cluster7 {node [fixedsize = true, width = 4.0, color=black, fontcolor = \"blue\"] \"docker exec -it sql-pet bash\" -> \"docker exec -ti sql-pet psql -a \n-p 5432 -d dvdrental -U postgres\" }\n\n  CLI [label=\"CLI\nR system2\",height = .75,width=3.0, color = \"blue\" ]\n  R   [color=\"blue\"]\n  Environment             [label = \"Environment\nLinux,Mac,Windows\",width = 2.5]\n\n  Environment -> RStudio -> R \n  R           -> Docker [label = \"system2 call\"]\n\n  \n  Environment -> \"unix:\n18.0.0\"    [lhead = cluster1] # Environment Information\n  R           -> \"version:\n3.3.1\"  [lhead = cluster2] # R Information\n  R           -> \"PostgreSQL:\nPostgreSQL 10.5 \"    [lhead = cluster6, label=\"1. dbConnect\"] # Docker-Postgres Information\n  RStudio     -> \"RStudio version:\n1.0.36\"    [lhead = cluster3] # RStudio Information\n  Docker      -> \"client version:\n18.06.1-ce\"    [lhead = cluster4] # Docker Information\n  Docker      -> \"Linux Version:\n4.9.93-linuxkit-aufs\"    [lhead = cluster5] # Docker-Linux Information\n  Docker      -> \"PostgreSQL:\nPostgreSQL 10.5 \"    [lhead = cluster6, label=\"4.  start-stop\"] # Docker-Postgres Information\n  Docker      -> CLI\n\n  \"unix:\n18.0.0\" -> CLI\n  CLI         -> \"docker exec -it sql-pet bash\"    [lhead = cluster7] # CLI \n  \"docker exec -it sql-pet bash\"     -> \"Linux Version:\n4.9.93-linuxkit-aufs\"    [label = \"2.  bash\"]\n  \"docker exec -ti sql-pet psql -a \n-p 5432 -d dvdrental -U postgres\"     -> \"PostgreSQL:\nPostgreSQL 10.5 \"    [label = \"3.  psql\"]\n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->


## Communicating with Docker Applications

One assumption we made is that most users use `RStudio` to interface with `R`. The four take aways from the diagram above are labeled:

1.  dbConnect

R-SQL processing, the purpose of this tutorial, is performed via a database connection. This should be a simple task, but often turns out to take a lot of time to actually get it to work.  We assume that your final write ups are done in some flavor of an Rmd document and others will have access to the database to confirm or further your analysis.

For this tutorial, the following are the hardcoded values used to make the Postgres database connection.

     con <- dbConnect(drv = "PostgreSQL",
                     user = "postgres",
                     password = "postgres",
                     host = "localhost",
                     port = 5432,
                     dbname = "dvdrental"                 
                     ) 
                     
The main focus of the entire tutorial is SQL processing through a dbConnection.  The remainder of this section focuses on some specific Docker commands.                      
                     
2.  bash

The Docker container runs on top of a small Linux kernel foot print.  Since Mac and Linux users run a version of Linux already, they may want to poke around the Docker environment.  Below is the CLI command to start up a bash session, execute a version of hello world, and exit the `bash` session.

```
c:\Git\sql-pet>docker exec -ti sql-pet bash
root@7e43294b72cf:/# echo "'hello world'" talking to you live from a bash shell session within Docker!
'hello world' talking to you live from a bash shell session within Docker!
root@7e43294b72cf:/# exit
exit
```
Note that the user in the example is root.  Root has all priviledges and can destroy the Docker environment.  

3.  psql

For users comfortable executing SQL from a command line directly against the database, one can run the `psql` application directly.  Below is the CLI command to start up `psql` session, execute a version of hello world, and quitting the `psql` version.

```
c:\Git\sql-pet>docker exec -ti sql-pet psql -a -p 5432 -d dvdrental -U postgres
psql (10.5 (Debian 10.5-1.pgdg90+1))
Type "help" for help.

dvdrental=# select '"hello world" talking to you live from postgres session within Docker!' hello;
                                hello
------------------------------------------------------------------------
 "hello world" talking to you live from postgres session within Docker!
(1 row)

dvdrental=# \q
```

All SQL commands need to end with a semi-colon. To exit `psql`, use a '\q' at the command prompt.

The docker bash and psql command options are optional for this tutorial, but open up a gateway to some very powerful programming techniques for future exploration.

4.  start-stop

Docker has about 44 commands.  We are interested in only those related to Postgres status, started, stopped, and available.  In this tutorial, complete docker commands are printed out before being executed via a `system2` call.  In the event that a code block fails, one can copy and paste the docker command into your local CLI and see if Docker is returning additional information.
                     
## Exercises

Docker containers have a small foot print.  In our container, we are running a limited Linux kernel and a Postgres database.  To show how tiny the docker environment is, we will look at all the processes running inside Docker and the top level file structure.

### Docker Help

Typing `docker` at the command line will print up a summary of all available `docker` commands.  Below are the docker commands used in the exercises.

    Commands:
      ps          List containers
      start       Start one or more stopped containers
      stop        Stop one or more running containers

The general format for a Docker command is 

    docker [OPTIONS] COMMAND ARGUMENTS
    
Below is the output for the Docker exec help command which was used in the `bash` and `psql` command examples above and for an exercise below.

```
C:\Users\SMY>docker help exec

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
In these exercies, the `-i` option and the CONTAINER = `sql-pet` are used in two of the exercises.

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
|4b|What is the size of Postgres?|docker ps -a||
|4c|What is the size of your laptop OS|||https://www.quora.com/What-is-the-actual-size-of-Windows-10-ISO-file
|5 |If sql-pet status is Up, How do I stop it?|docker stop sql-pet||
|5a|If sql-pet status is Exited, How do I start it?|docker start sql-pet||

