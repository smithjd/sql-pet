#' ---
#' title: "Docker postgress installation and test"
#' author: "John D. Smith"
#' date: "7/19/2018"
#' output: md_document
#' ---

library(tidyverse)
library(DBI)
library(RPostgres)

#' This demonstrates connecting, reading and writing to postgres -- using the default database.
#'
#' Most useful if you run a line or two at a time, rather than the chunks in their entirety.
#'
#' First, verify that Docker is up and running and that it responds to your commands:
#'

# (Note that Knitr doesn't always capture the output of these system commands in its output.)
system("docker ps -a")

#' Docker should return a response containing CONTAINER, ID, etc.
#'
#' Next bring up the docker container with Postgres running in it.
#'
#' If this is the first time you've brought up the Postgres container, you can see more of what's going on if you run the following command in a terminal window:
#'
#'  `docker-compose up`
#'
#' The last message from docker should read:
#'
#'   `postgres9_1  | LOG:  database system is ready to accept connections`
#'
#' Your terminal window is attached to the Docker image and you can't use it for anything else.  You can send the `stop` command from R or from another terminal and then #' bring up Postgres in *disconnected* mode, so that you have your terminal back.
#'
#' To stop Postgres (momentarily), from R, enter:
#'
#'   `system("docker-compose stop")`
#'
#' From another terminal window, just enter:
#'
#'   `docker-compose stop`
#'
#' After the first time, you can always bring up Postgres and disconnect the process from your window:

system("docker-compose up -d")

#'
#' Connect with Postgres
#'

Sys.sleep(5) # need to wait for Docker & Postgres to come up before connecting.

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres")

#' At first Postgres won't contain any tables:
dbListTables(con)

# Write data frame to Postgres:
dbWriteTable(con, "mtcars", mtcars)

dbListTables(con)

# demonstrate that mtcars is really there:
dbListFields(con, "mtcars")
dbReadTable(con, "mtcars")

# be sure to disconnect from Postgres before shutting down
dbDisconnect(con)

# close down the Docker container
system("docker-compose stop")

#'
#' After closing Docker down, bring it up again and verify that tables are still there.
#'
# Bring up Docker-compose and Postgres:

system("docker-compose up -d")
#'
#' Connect to Postgres
#'
Sys.sleep(5)

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "localhost",
                      port = "5432",
                      user = "postgres",
                      password = "postgres")

# Postgres should still have mtcars in it:
dbListTables(con)

# Might as well delete mtcars, since there are enough copies of it in the world.
dbRemoveTable(con, "mtcars")
dbExistsTable(con, "mtcars")

dbDisconnect(con)
system("docker-compose stop")

