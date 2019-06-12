# This R code demonstrates some limited uses of the hrsample database.

# It depends on having run `load-hrsample-to-postgres-on-docker.R`

library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)
library(here)
require(knitr)
library(dbplyr)
library(sqlpetr)

wd <- here()

# Verify Docker is up and running.  List all containers:
sp_check_that_docker_is_up()
sp_show_all_docker_containers()

# Start up the hrsample docker container:
sp_docker_start("hrsample")

# Wait for Docker to finish its business
Sys.sleep(4)

con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "hrsample",
  seconds_to_test = 5
)

# Show the schemas in the database:

tbl(con, in_schema("information_schema", "schemata")) %>%
  select(catalog_name, schema_name, schema_owner) %>%
  collect()

# The equivalent SQL code is:

dbGetQuery(
  con,
  "select catalog_name, schema_name, schema_owner from information_schema.schemata ;"
)

# A postgreSQL trick to make the hrsample schema the default. Similar tricks are
# available on other back ends:

dbExecute(con, "set search_path to hrsample, public;")

dbListTables(con)

dbListFields(con,"employeeinfo")

tbl(con,"employeeinfo") %>% head()

employeeinfo %>% count(state, sort = TRUE)

sp_tbl_pk_fk_sql <- function(schema, table_name) {
  dbGetQuery(con,
    "SELECT c.table_name
              ,kcu.column_name
              ,c.constraint_name
              ,c.constraint_type
              ,coalesce(c2.table_name, '') ref_table
              ,coalesce(kcu2.column_name, '') ref_table_col
          FROM information_schema.tables t
               LEFT JOIN information_schema.table_constraints c
                 ON t.table_catalog = c.table_catalog
                AND t.table_schema = c.table_schema
                AND t.table_name = c.table_name
               LEFT JOIN information_schema.key_column_usage kcu
                 ON c.constraint_schema = kcu.constraint_schema
                AND c.constraint_name = kcu.constraint_name
               LEFT JOIN information_schema.referential_constraints rc
                 ON c.constraint_schema = rc.constraint_schema
                AND c.constraint_name = rc.constraint_name
               LEFT JOIN information_schema.table_constraints c2
                 ON rc.unique_constraint_schema = c2.constraint_schema
                AND rc.unique_constraint_name = c2.constraint_name
               LEFT JOIN information_schema.key_column_usage kcu2
                 ON c2.constraint_schema = kcu2.constraint_schema
                AND c2.constraint_name = kcu2.constraint_name
                AND kcu.ordinal_position = kcu2.ordinal_position
         WHERE c.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
           AND c.table_catalog = 'postgres'
           AND c.table_schema = $1
           AND (c.table_name = $2 or coalesce(c2.table_name, '') = $2)
       ORDER BY c.table_name,c.constraint_type desc",
    param = list(schema, table_name)
  )
}

sp_tbl_pk_fk_sql("hrsample", "recruiting_table")

# Refer to an individual table and schema explicitly is as follows:

recruiting_table <- tbl(con, in_schema("hrsample", "recruiting_table"))

head(recruiting_table)

# Show the indexes in the database:

tbl(con,  "pg_indexes") %>%
  select(tablename, indexname, indexdef) %>%
  arrange(tablename) %>%
  collect() %>%
  filter(!str_starts(tablename, "pg_")) %>%
  as.data.frame()

# The SQL equivalent is:

dbGetQuery(con, "select tablename,indexname,indexdef
                 from pg_indexes
                 where schemaname = 'hrsample'
                 order by tablename
                ;")

DBI::dbDisconnect(con)

sp_docker_stop("hrsample")
