# DBI package functions - INDEX {#chapter_appendix-dbi-index}

Where are these covered and should the by included?

| DBI             | 1st time   | Call Example/Notes                                           |
| --------------- | ---------- | ------------------------------------------------------------ |
| DBIConnct       | 6.3.2 (04) | in sp_get_postgres_connection                                |
| dbAppendTable   |            |                                                              |
| dbCreateTable   |            |                                                              |
| dbDisconnect    | 6.4n (04)  | dbDisconnect(con)                                            |
| dbExecute       | 10.4.2 (13)  | Executes a statement and returns the number of rows affected. dbExecute() comes with a default implementation (which should work with most backends) that calls dbSendStatement(), then dbGetRowsAffected(), ensuring that the result is always free-d by dbClearResult(). |
| dbExistsTable   |            | dbExistsTable(con,'actor')                                   |
| dbFetch         | 17.1 (72) | dbFetch(rs)                                                  |
| dbGetException  |            |                                                              |
| dbGetInfo       |            | dbGetInfo(con)                                               |
| dbGetQuery      | 10.4.1  (13) | dbGetQuery(con,'select * from store;')                     |
| dbIsReadOnly    |            | dbIsReadOnly(con)                                            |
| dbIsValid       |            | dbIsValid(con)                                               |
| dbListFields    | 6.3.3 (04) | DBI::dbListFields(con, "mtcars")                             |
| dbListObjects   |            | dbListObjects(con)                                           |
| dbListTables    | 6.3.2 (04) | DBI::dbListTables(con, con)                                  |
| dbReadTable     | 8.1.2      | DBI::dbReadTable(con, "rental")                              |
| dbRemoveTable   |            |                                                              |
| dbSendQuery     | 17.1 (72) | rs <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4") |
| dbSendStatement |            | The dbSendStatement() method only submits and synchronously executes the SQL data manipulation statement (e.g., UPDATE, DELETE, INSERT INTO, DROP TABLE, ...) to the database engine. |
| dbWriteTable    | 6.3.3 (04) | dbWriteTable(con, "mtcars", mtcars, overwrite = TRUE)        |
