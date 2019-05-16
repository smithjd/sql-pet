# This script isn't part of the book itself.  It's what we run
#   to create a resource for the book
#
# We need to run it whenever the hrsample package is updated.
# Demonstrate load hrsample to SQLlite & create a persistent
#   sqlite database,
library(tidyverse)
library(hrsample)
library(RPostgres)
library(DBI)
library(sqlpetr)
library(glue)
library(here)

sp_docker_remove_container("hr_sample")

wd <- here()

docker_cmd <- glue(
  "run ", # Run is the Docker command.  Everything that follows are `run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  " --name hr_sample ", # tells Docker to give the container a name: `sql-pet`
  "--publish 5432:5432 ", # tells Docker to expose the PostgreSQL port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  'type=bind,source="', wd, '",target=/petdir', # not really used, but could be later
  " postgres:10 " # tells Docker the image that is to be run (after downloading if necessary)
)
cat("docker ", docker_cmd)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)

con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "postgres",
  seconds_to_test = 10,
  connection_tab = TRUE
)

# note sure the following dbExecute or the connect statement that follows really works.
dbExecute(con, "CREATE SCHEMA hr_sample;")

# con <- sp_get_postgres_connection(
#   host = "localhost",
#   port = 5432,
#   user = "postgres",
#   password = "postgres",
#   dbname = "hr_sample",
#   seconds_to_test = 10,
#   connection_tab = TRUE
# )

hrsampleCreatePostgreSQL(
  dbname = "postgres",
  host = "localhost",
  user = "postgres",
  port = 5432,
  password = "postgres"
)

con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "postgres",
  seconds_to_test = 10,
  connection_tab = TRUE
)

dbListTables(con)

employeeinfo <- tbl(con, "employeeinfo")

count(employeeinfo, state) %>% arrange(desc(n)) %>% show_query()

dbGetQuery(
  con,
  'SELECT "state", COUNT(*) AS "n"
   FROM "employeeinfo"
   GROUP BY "state"
   ORDER BY "n" DESC'
   )

DBI::dbDisconnect(con)

docker_cmd <- glue(
  "exec  hr_sample  pg_dump -U postgres > book-src/hr_sample.sql"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)

tar_cmd <- glue(
  " -czf ",
  wd, "/book-src/hr_sample.gz ",
  wd, "/book-src/hr_sample.sql"
)

system2("tar", tar_cmd)

file.remove(here("book-src", "hr_sample.sql"))

