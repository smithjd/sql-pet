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
  " --name adventureworks ", # tells Docker to give the container a name: `sql-pet`
  "--publish 5432:5432 ", # tells Docker to expose the PostgreSQL port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  'type=bind,source="', wd, '",target=/petdir', # not really used, but could be later
  " postgres:10 " # tells Docker the image that is to be run (after downloading if necessary)
)
cat("docker ", docker_cmd)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)
Sys.sleep(2)

# create the adventureworks database in the Docker container
system2("docker", 'exec -i adventureworks psql -U postgres -c "CREATE DATABASE adventureworks;"')

# restore the adventureworks tar file.  This might come from github rather than locally
system2("docker", glue(
  "exec -i adventureworks pg_restore -U postgres ",
  " -d adventureworks /petdir/book-src/adventureworks.sql "
))

# Wait for Docker to finish its business
Sys.sleep(4)

# sp_docker_start("adventureworks")

con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "adventureworks",
  seconds_to_test = 10
)

adventureworks_schemas <-  tbl(con, in_schema("information_schema", "schemata")) %>%
  select(catalog_name, schema_name, schema_owner) %>%
  collect()
adventureworks_schemas

adventureworks_table_columns <- tbl(con, in_schema("information_schema", "columns")) %>%
  collect() %>%
  filter(!str_detect(table_schema,"pg_|information_schema" ))

cat_info <- inspect_cat(adventureworks_table_columns)
cat_info %>% show_plot()

# select the most useful columns
adventureworks_table_columns <- adventureworks_table_columns %>%
  select(table_schema, table_name, column_name, dtd_identifier, data_type, column_default)

adventureworks_table_columns %>%
  filter(table_name == "employee") %>%
  select(column_name, dtd_identifier, data_type, column_default)

employee <- tbl(con, in_schema("humanresources", "employee")) %>%
  collect()

employee
inspect_cat(employee) %>% show_plot

# list all the tables in the database (except information_schema tables)
adventureworks_tables <- adventureworks_table_columns %>%
  count(table_name) %>% rename(n_columns = n)

# deal with multiple schemas:

dbListTables(con)
dbExecute(con, "set search_path to humanresources, public;") # watch for duplicates!
dbListTables(con)
dbListFields(con, "employee")
tbl(con, "employee") %>% collect(n = 10)

# verify that table names are unique across all schemas
adventureworks_tables %>%
  count(table_name) %>%
  filter(n > 1)

index_list <- tbl(con,  "pg_indexes") %>%
  select(schemaname, tablename, indexname, indexdef) %>%
  arrange(tablename) %>%
  collect() %>%
  filter(!str_starts(tablename, "pg_"))
index_list

index_list %>% count(schemaname)

tbl(con, "pg_tables") %>% count(schemaname)

employee <- tbl(con, dbplyr::in_schema("humanresources", "employee"))

department_history  <- tbl(con, dbplyr::in_schema("humanresources", "employeedepartmenthistory"))

employee %>%
  left_join(department_history, by = c("businessentityid") ) %>%
  count(businessentityid, sort = TRUE)

DBI::dbDisconnect(con)

# if R has not finished disconnecting, Docker returns a "137" when the
#   container is stopped.
Sys.sleep(4)

# Stop adventureworks, but don't remove it.

system2("docker", "stop adventureworks", stdout = TRUE, stderr = TRUE)

