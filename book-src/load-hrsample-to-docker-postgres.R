# This script isn't part of the book itself.  It's what we run
#   to create a resource for the book
#
# We need to run it whenever the hrsample package is updated.
# Demonstrate load hrsample to SQLlite & create a persistent
#   sqlite database.

# If necessary update or load the hrsample package
#  remotes::install_github("harryahlas/hrsample", force = TRUE, quiet = TRUE, build = TRUE, build_opts = "")
#  devtools::install_github("harryahlas/hrsample") # deprecated

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
# Having different schemas is realistic.

# con <- sp_get_postgres_connection(
#   host = "localhost",
#   port = 5432,
#   user = "postgres",
#   password = "postgres",
#   dbname = "hr_sample",
#   seconds_to_test = 10,
#   connection_tab = TRUE
# )

# Harry's code has "public" hard-coded.
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

# copy_to(con, employeeinfo_table, in_schema("hr_sample", "employeeinfo"))

## adding
dbExecute(con,'alter table postgres.public.employeeinfo
          add primary key (employee_num)')
dbExecute(con,'alter table postgres.public.deskhistory
          add primary key (employee_num, desk_id, desk_id_start_date)')

#####deskjob two columns, not indexed

dbExecute(con,'alter table postgres.public.hierarchy
          add primary key (desk_id)')
dbExecute(con,'CREATE INDEX perfreview_employee_num ON
          postgres.public.performancereview (employee_num)');
dbExecute(con,'CREATE INDEX salhistory ON
          postgres.public.salaryhistory (employee_num)');
dbExecute(con,'alter table postgres.public.recruiting_table
          add primary key (employee_num)')
dbExecute(con,'CREATE INDEX contact_employee_num
          ON postgres.public.contact_table (employee_num)');
dbExecute(con,'CREATE INDEX education_employee_num
          ON postgres.public.education_table (employee_num)');
dbExecute(con,'CREATE INDEX skills_employee_num
          ON postgres.public.skills_table (employee_num)');

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

file.remove(glue("book-src/", "hr_sample.sql"))
