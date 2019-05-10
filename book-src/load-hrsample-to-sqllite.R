# demonstrate load hrsample to SQLlite & create a persistent sqllite database
library(tidyverse)
library(hrsample)
library(DBI)
library(RSQLite)
library(here)

file.remove("hr-sample.sqlite3")   # get rid of old versions

hrsampleCreateSQLite("hr-sample.sqlite3")

con <- dbConnect(RSQLite::SQLite(), "hr-sample.sqlite3")

dbListTables(con)

employeeinfo <- tbl(con, "employeeinfo")

count(employeeinfo, state) %>% arrange(desc(n))

dbGetQuery(con,
           'SELECT "state", COUNT(*) AS "n"
FROM "employeeinfo"
GROUP BY "state"
ORDER BY "n" DESC'
)


dbDisconnect(con)
