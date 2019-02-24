library(tidyverse)
library(DBI)
library(RPostgres)
library(dbplyr)
library(sqlpetr)

# Verify that Docker is up and running

sp_check_that_docker_is_up()

# Clean up if appropriate
# Force-remove the `cattle` and `sql-pet` containers if they exist (e.g., from a prior runs):

sp_docker_remove_container("cattle")
sp_docker_remove_container("sql-pet")

# Build the pet-sql Docker image

sp_make_dvdrental_image("postgres-dvdrental")

# What Docker images are available?

sp_docker_images_tibble()

sp_pg_docker_run(
  container_name = "sql-pet",
  image_tag = "postgres-dvdrental",
  postgres_password = "postgres",
  mount_here_as = "/petdir"
)

con <- sqlpetr::sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 30
)

# if desired, check that the DVDRENTAL tables are there with

# db_list_tables(con)
