#' ---
#' title: "Docker postgress installation and test"
#' author: "John D. Smith and friends"
#' date: "7/19/2018"
#' output: md_document
#' ---
library(tidyverse)
library(DBI)
library(RPostgres)

#' #Start Postgres in Docker:
#'
docker_cmd <- paste0(
  "run -d --name temporary-postgres --publish 5432:5432 ",
  " postgres:9.4"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)

system2("docker", "ps -a", stdout = TRUE, stderr = TRUE)

#' Docker should return a response containing CONTAINER ID, IMAGE, etc.
#'
#' Next bring up the docker container with Postgres running in it.
#'
#' If this is the first time you've brought up the Postgres container, you can see more of what's going on if you run the following command in a terminal window:
#'
#'
#'
#' The last message from docker should read:
#'
#'
#'
#' Your terminal window is attached to the Docker image and you can't use it for anything else until Docker releases the terminal's connection.  You can send the `stop` command from R or from another terminal and then
#' bring up Postgres in *disconnected* mode, so that you have your terminal back.
#'
#' To stop Postgres (momentarily), from R, enter:
#'
#'
#'
#' From another terminal window, just enter:
#'
#'
#'
#' After the first time, you can always bring up Postgres and disconnect the process from your window:

Sys.sleep(5) # need to wait for Docker & Postgres to come up before connecting.
#-----Establish connection vector-----
#'
#' Connect with Postgres
#'

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres")

#' -----Write mtcars table-----
#'
#' Show that at first Postgres database doesn't contain any tables:
dbListTables(con)

#' Write data frame to Postgres:
dbWriteTable(con, "mtcars", mtcars)

#' List the tables in the Postgres database again:
dbListTables(con)

#' Demonstrate that mtcars is really there:
dbListFields(con, "mtcars")
dbReadTable(con, "mtcars")

#' Be sure to disconnect from Postgres before shutting down
dbDisconnect(con)

#' Close down the Docker container.
#' Note that there's a big difference between "stop" and "down".
#'
#'
#'
#' in this case use:

system2("docker", "stop temporary-postgres", stdout = TRUE, stderr = TRUE)

#' -----Database Persistence Check-----
#'
#' After closing Docker down, bring it up again and verify that tables are still there.
#'
#' Bring up Docker-compose and Postgres:

system2("docker", "start temporary-postgres", stdout = TRUE, stderr = TRUE)
#'
#' Connect to Postgres
#'
Sys.sleep(1)

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres")

#' Postgres should still have mtcars in it:
dbListTables(con)

#' Might as well delete mtcars, since there are enough copies of it in the world.
dbRemoveTable(con, "mtcars")
dbExistsTable(con, "mtcars")

dbDisconnect(con)
system2("docker", "stop temporary-postgres", stdout = TRUE, stderr = TRUE)
system2("docker", "rm temporary-postgres", stdout = TRUE, stderr = TRUE)

# show that we haven't left anything behind:

system2("docker", "ps -a", stdout = TRUE, stderr = TRUE)

#' Troubleshooting commands:
# This section needs work, depending on what we are trying to accomplish

#Start Docker PostgreSQL manually, without access to the `/src` directory:
# system2("docker", "run postgres:9.4", , stdout = TRUE, stderr = TRUE)

#Manual stop and remove of Docker container
# system2("docker stop {containerid")
# system2("docker rm {containerid}")

#Environmental Commands
# Sys.getenv()

#  Not sure what these are or what their function is:
# Sys.which('whoami')
# Sys.setenv(PATH = X)




