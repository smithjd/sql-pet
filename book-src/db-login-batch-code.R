## External snippets of R code to share across chapters
## How to: http://zevross.com/blog/2014/07/09/making-use-of-external-r-code-in-knitr-and-r-markdown/

## @knitr get_postgres_connection

#' Connect to PostgreSQL, waiting if it is not ready
#'
#' @param user Username that will be found
#' @param password Password that corresponds to the username
#' @param dbname the name of the database in the database
#' @param seconds_to_test the number of iterations to try while waiting for PostgreSQL to be ready
#' @export
wait_for_postgres <- function(user, password, dbname, seconds_to_test = 10) {
  for (i in 1:seconds_to_test) {
    db_ready <- DBI::dbCanConnect(RPostgres::Postgres(),
                                  host = "localhost",
                                  port = "5432",
                                  user = user,
                                  password = password,
                                  dbname = dbname)
    if ( !db_ready ) {Sys.sleep(1)}
    else {con <- DBI::dbConnect(RPostgres::Postgres(),
                                host = "localhost",
                                port = "5432",
                                user = user,
                                password = password,
                                dbname = dbname)
    }
    if (i == seconds_to_test & !db_ready) {con <- "There is no connection"}
  }
  con
}
