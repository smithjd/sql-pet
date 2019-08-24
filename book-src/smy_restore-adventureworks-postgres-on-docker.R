#' This is a utility job to create the Docker container with the adventureworks
#'  database that's used in the book.

#' This job depends on the output from
#'  `load-adventureworks-to-postgres-on-docker.R`

library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)
library(here)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(inspectdf)

wd <- here()

# Verify Docker is up and running and list all containers:
sp_check_that_docker_is_up()
# sp_show_all_docker_containers()

# Remove previous container if it exists.

# sp_docker_remove_container("adventureworks")
sp_docker_remove_container("adventureworks")


# create new adventureworks container
docker_cmd <- glue(
  "run ", # Run is the Docker command.  Everything that follows are `run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  " --name adventureworks ", # tells Docker to give the container a name: `adventureworks`
  "--publish 5432:5432 ", # tells Docker to expose the PostgreSQL port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  'type=bind,source="', wd, '",target=/petdir', # not really used, but could be later
  " postgres:10 " # tells Docker the image that is to be run (after downloading if necessary)
)
cat("docker ", docker_cmd)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
Sys.sleep(10)

# create the adventureworks database in the Docker container
system2("docker", 'exec -i adventureworks psql -U postgres -c "CREATE DATABASE adventureworks;"')

# restore the adventureworks tar file.  This might come from github rather than locally
system2("docker", glue(
  "exec -i adventureworks pg_restore -U postgres ",
  " -d adventureworks /petdir/book-src/adventureworks.sql "
))

# Wait for Docker to finish its business
Sys.sleep(7)
