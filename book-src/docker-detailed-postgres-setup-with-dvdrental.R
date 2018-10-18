#' ---
#' output: github_document
#' author: John David Smith
#' date: "`r Sys.Date()`"
#' ---
#' Step-by-step Docker container setup with dvdrental database installed

#' This needs to run *outside a project* to compile correctly because of the complexities of how knitr sets working directories (or because we don't really understand how it works!)

#' The purpose of this code is to
#'
#'   * Replicate the docker container generated in Chapter 5 of the book, but in a step-by-step fashion
#'   * Show that the `dvdrental` database persists when stopped and started up again.
#'
#' ## Overview
#'
#' Doing all of this in a step-by-step way that might be useful to understand how each of the steps involved in setting up a persistent PostgreSQL database works.  If you are satisfied with the method shown in Chapter 5, skip this and only come back if you're interested in picking apart the steps.

library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(bookdown)

#' ## Download the `dvdrental` backup file
#'
#' The first step is to get a local copy of the `dvdrental` PostgreSQL **restore file**.  It comes in a zip format and needs to be un-zipped.

opts_knit$set(root.dir = normalizePath('../'))
if (!require(downloader)) install.packages("downloader")

library(downloader)

download("http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip", destfile = "dvdrental.zip")

unzip("dvdrental.zip", exdir = ".") # creates a tar archhive named "dvdrental.tar"

#' Check on where we are and what we have in this directory:
#'

getwd()

#' ## Verify that Docker is up and running:
#'

sp_check_that_docker_is_up()

#'
#' Remove the `sql-pet` container if it exists (e.g., from a prior run)

sp_docker_remove_container("sql-pet")


#' ## Build the Docker Container

#' Build an image that derives from postgres:10.  Connect the local and Docker directories that need to be shared.  Expose the standard PostgreSQL port 5432.

wd <- getwd()

docker_cmd <- glue(
  "run ",      # Run is the Docker command.  Everything that follows are `run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  " --name sql-pet ",     # tells Docker to give the container a name: `sql-pet`
  "--publish 5432:5432 ", # tells Docker to expose the Postgres port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  'type=bind,source="', wd, '",target=/petdir',
  " postgres:10 " # tells Docker the image that is to be run (after downloading if necessary)
)
cat('docker ',docker_cmd)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)

#' Peek inside the docker container and list the files in the `petdir` directory.  Notice that `dvdrental.tar` is in both.

opts_knit$set(root.dir = normalizePath('../'))
system2('docker', 'exec sql-pet ls petdir | grep "dvdrental.tar" ',
        stdout = TRUE, stderr = TRUE)

dir(wd, pattern = "dvdrental.tar")


#' ## Create the database and restore from the backup
#'
#' We can execute programs inside the Docker container with the `exec` command.  In this case we tell Docker to execute the `psql` program inside the `sql-pet` container and pass it some commands as follows.

system2("docker", "ps -a", stdout = TRUE, stderr = TRUE)
#' inside Docker, execute the postgress SQL command-line program to create the dvdrental database:
system2('docker', 'exec sql-pet psql -U postgres -c "CREATE DATABASE dvdrental;"',
        stdout = TRUE, stderr = TRUE)

#' The `psql` program repeats back to us what it has done, e.g., to create a database named `dvdrental`.

#' Next we execute a different program in the Docker container, `pg_restore`, and tell it where the restore file is located.  If successful, the `pg_restore` just responds with a very laconic `character(0)`.

#' restore the database from the .tar file

Sys.sleep(2)  # the wait may or may not be needed.
system2("docker", "exec sql-pet pg_restore -U postgres -d dvdrental petdir/dvdrental.tar", stdout = TRUE, stderr = TRUE)

#' ## Connect to the database with R
#'
#' If you are interested take a look inside the `sp_get_postgres_connection` function to see how the DBI package is being used.

con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                                  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                                  dbname = "dvdrental",
                                  seconds_to_test = 20)

dbListTables(con)

dbDisconnect(con)

## Stop and start to demonstrate persistence

#' Stop the container

sp_docker_stop("sql-pet")

#' Restart the container and verify that the dvdrental tables are still there

sp_docker_start("sql-pet")

con <- sp_get_postgres_connection(user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
                                  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
                                  dbname = "dvdrental",
                                  seconds_to_test = 10)

#' ## Cleaning up
#'
#' It's always good to have R disconnect from the database

dbDisconnect(con)

#' Stop the container and show that the container is still there, so can be started again.

sp_docker_stop("sql-pet")

#' show that the container still exists even though it's not running
psout <- system2("docker", "ps -a", stdout = TRUE)
psout[grepl(x = psout, pattern = 'sql-pet')]

#' We are leaving the `sql-pet` container so it can be used in running the rest of the examples and book.
#'
#' Clean up with:
#'

file.remove("dvdrental.zip")
file.remove("dvdrental.tar")