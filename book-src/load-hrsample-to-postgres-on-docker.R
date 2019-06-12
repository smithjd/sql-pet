# This is a utility job to create the hrsample database backup that's used
# in the book.  Source it when the hrsample package is updated.

# more about schemas and DBI here: https://db.rstudio.com/best-practices/schema/

library(tidyverse)
library(hrsample)
library(DBI)
library(RPostgres)
library(glue)
library(here)
require(knitr)
library(dbplyr)
library(sqlpetr)
wd <- here()


# Verify Docker is up and running:
sp_check_that_docker_is_up()

# Verify pet DB is available, it may be stopped.
sp_show_all_docker_containers()

# Remove previous instanaces of hrsample
sp_docker_remove_container("hrsample")

# Create new hrsample container
docker_cmd <- glue(
  "run ", # Run is the Docker command.  Everything that follows are `run` parameters.
  "--detach ", # (or `-d`) tells Docker to disconnect from the terminal / program issuing the command
  " --name hrsample ", # tells Docker to give the container a name: `sql-pet`
  "--publish 5432:5432 ", # tells Docker to expose the PostgreSQL port 5432 to the local network with 5432
  "--mount ", # tells Docker to mount a volume -- mapping Docker's internal file structure to the host file structure
  'type=bind,source="', wd, '",target=/petdir', # not really used, but could be later
  " postgres:10 " # tells Docker the image that is to be run (after downloading if necessary)
)
cat("docker ", docker_cmd)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)

Sys.sleep(4)

# Log in to new container
con <- sp_get_postgres_connection(
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "postgres",
  dbname = "postgres",
  seconds_to_test = 10
)

get_schema_info <- function() {
  dbGetQuery(
    con,
    "select * from information_schema.schemata ;"
  )
}
# Schemas at initiation.  Uncomment when investigating
# get_schema_info()

# Create hrsample schema
dbExecute(con, "create schema if not exists hrsample")

# The following is not needed when executed just to set-up hrsample
# get_schema_info()

# this is a very obscure function name:
sp_tbl_pk_fk_sql <- function(schema, table_name) {
  dbGetQuery(
    con,
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

# Set search path sequence
dbExecute(con, "set search_path to hrsample, public;")

# Load hrsample tables

dbWriteTable(con, "employeeinfo", employeeinfo_table, overwrite = TRUE)
dbWriteTable(con, "deskhistory", deskhistory_table, overwrite = TRUE)
dbWriteTable(con, "deskjob", deskjob_table, overwrite = TRUE)
dbWriteTable(con, "hierarchy", hierarchy_table, overwrite = TRUE)
dbWriteTable(con, "performancereview", performancereview_table, overwrite = TRUE)
dbWriteTable(con, "salaryhistory", salaryhistory_table, overwrite = TRUE)
dbWriteTable(con, "recruiting_table", recruiting_table, overwrite = TRUE)
dbWriteTable(con, "rollup_view", rollup_view, overwrite = TRUE)
dbWriteTable(con, "contact_table", contact_table, overwrite = TRUE)
dbWriteTable(con, "education_table", education_table, overwrite = TRUE)
dbWriteTable(con, "skills_table", skills_table, overwrite = TRUE)

dbGetQuery(con, "select table_schema,table_name,table_type
                    from information_schema.tables where table_schema = 'hrsample' ;")

# Add table primary keys}
dbExecute(con, "alter table employeeinfo add primary key (employee_num)")
dbExecute(con, "alter table deskhistory add primary key (employee_num, desk_id, desk_id_start_date)")

##### deskjob two columns, not indexed

dbExecute(con, "alter table hierarchy add primary key (desk_id)")
dbExecute(con, "CREATE INDEX perfreview_employee_num ON performancereview (employee_num)")
dbExecute(con, "CREATE INDEX salhistory ON salaryhistory (employee_num)")
dbExecute(con, "alter table recruiting_table add primary key (employee_num)")
dbExecute(con, "CREATE INDEX contact_employee_num ON contact_table (employee_num)")
dbExecute(con, "CREATE INDEX education_employee_num ON education_table (employee_num)")
dbExecute(con, "CREATE INDEX skills_employee_num ON skills_table (employee_num)")
sp_tbl_pk_fk_sql("hrsample", "recruiting_table")

# Not needed when merely setting up the database:
# dbGetQuery(con, "select tablename,indexname,indexdef
#                  from pg_indexes
#                  where schemaname = 'hrsample'
#                  order by tablename
#                 ;")

DBI::dbDisconnect(con)

# Create the hrsample.tar backup file used in the book
docker_cmd <- glue(
  "exec  hrsample  pg_dump -U postgres -F t > book-src/hrsample.tar"
)

system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)

system2("docker", "stop hrsample", stdout = TRUE, stderr = TRUE)
