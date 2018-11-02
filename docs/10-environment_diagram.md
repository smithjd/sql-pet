# Mapping your local environment (10)



## Basics

* Keeping passwords secure.
* Coverage in this book.  There are many SQL tutorials that are available.  For example, we are drawing some materials from  [a tutorial we recommend](http://www.postgresqltutorial.com/postgresql-sample-database/).  In particular, we will not replicate the lessons there, which you might want to complete.  Instead, we are showing strategies that are recommended for R users.  That will include some translations of queries that are discussed there.

## Ask yourself, what are you aiming for?

* Differences between production and data warehouse environments.
* Learning to keep your DBAs happy:
  + You are your own DBA in this simulation, so you can wreak havoc and learn from it, but you can learn to be DBA-friendly here.
  + In the end it's the subject-matter experts that understand your data, but you have to work with your DBAs first.

## Get some basic information about your database

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go.
Start up the `docker-pet` container


```r
sp_docker_start("sql-pet")
```

Now connect to the `dvdrental` database with R.  
The following code block confirms that one can connect to the Postgres database.  The connection is needed for some of the examples/exercises used in this section.  If the connection is successful, the output is `<PostgreSQLConnection>`.


```r
con <- sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 10
)
con
```

```
## <PqConnection> dvdrental@localhost:5432
```

## Tutorial Environment




Below is a high level diagram of our tutorial environment.  The single black or blue boxed items are the apps running on your PC, (Linux, Mac, Windows), RStudio, R, Docker, and CLI, a command line interface.  The red boxed items are the versions of the applications shown.  The labels are to the right of the line.




![](diagrams/envgraph.png)<!-- -->

## Communicating with Docker Applications

One assumption we made is that most users use `RStudio` to interface with `R`. The four take aways from the diagram above are labeled:

### dbConnect

R-SQL processing, the purpose of this tutorial, is performed via a database connection. This should be a simple task, but often turns out to take a lot of time to actually get it to work.  We assume that your final write ups are done in some flavor of an Rmd document and others will have access to the database to confirm or further your analysis.

One focus of this tutorial is SQL processing through a dbConnection and we will come back to this in a future section.  The remainder of this section focuses on some specific Docker commands.                      
                     
### bash

The Docker container runs on top of a small Linux kernel foot print.  Since Mac and Linux users run a version of Linux already, they may want to poke around the Docker environment.  Below is the CLI command to start up a bash session, execute a version of hello world, and exit the `bash` session.

(In this and subsequent example, an initial `$` represents your system prompt, which varies according to operating system and local environment.)

In your computer's command prompt:

  `$ docker exec -ti sql-pet bash`

Inside the `bash` (UNIX command) environment:
```

$ echo "'hello world'" talking to you live from a bash shell session within Docker!

'hello world' talking to you live from a bash shell session within Docker!
$ exit
```
Now back at your computer command prompt with:

  `$ exit`

Note that the user in the example is root.  Root has all priviledges and can destroy the Docker environment.  

### psql

For users comfortable executing SQL from a command line directly against the database, one can run the `psql` application directly.  Below is the CLI command to start up `psql` session, execute a version of hello world, and quitting the `psql` version.

In your computer's command prompt:

   `$ docker exec -ti sql-pet psql -a -p 5432 -d dvdrental -U postgres`

That executes a postreSQL program in docker called `psql`, which is a command line interface to postgreSQL.  `psql` responds with:

```
psql (10.5 (Debian 10.5-1.pgdg90+1))
Type "help" for help.
```
You enter:

    `select '"hello world" talking to you live from postgres inside Docker!' hello;`

All SQL commands need to end with a semi-colon. `psql` responds with:

```
                                hello
------------------------------------------------------------------------
 "hello world" talking to you live from postgres inside Docker!
(1 row)
```

To exit `psql`, enter:
```
    \q
```

The docker bash and psql command options are optional for this tutorial, but open up a gateway to some very powerful programming techniques for future exploration.

### start-stop

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
    
