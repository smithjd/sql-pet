# This script isn't part of the book itself.  It's what we run
#   to create a resource for the book
#
# We need to run it whenever the hrsample package is updated.
#
# Demonstrate load hrsample to SQLlite & create a persistent
#   sqlite database.

# If necessary update or load the hrsample package
#  remotes::install_github("harryahlas/hrsample", force = TRUE, quiet = TRUE, build = TRUE, build_opts = "")

library(tidyverse)
library(hrsample)
library(DBI)
library(RSQLite)
library(here)
library(glue)

wd <- here()

file.remove(here("book-src", "hr_sample.sqlite3"))   # get rid of old versions

hrsampleCreateSQLite(here("book-src", "hr_sample.sqlite3"))

con <- dbConnect(RSQLite::SQLite(), here("book-src", "hr_sample.sqlite3"))

dbListTables(con)

employeeinfo <- tbl(con, "employeeinfo")

# trivial query to show that everything works:

count(employeeinfo, state) %>% arrange(desc(n))

dbGetQuery(con,
           'SELECT "state", COUNT(*) AS "n"
FROM "employeeinfo"
GROUP BY "state"
ORDER BY "n" DESC'
)

dbDisconnect(con)

tar_cmd <- glue(
  " -czf ",
  wd, "/book-src/hr_sample.sqlite3.gz ",
  wd, "/book-src/hr_sample.sqlite3"
)

system2("tar", tar_cmd)

file.remove(here("book-src", "hr_sample.sqlite3"))
