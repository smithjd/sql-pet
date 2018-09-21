## External snippets of R code to share across chapters
## How to: http://zevross.com/blog/2014/07/09/making-use-of-external-r-code-in-knitr-and-r-markdown/

## @knitr get_postgres_connection

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

## @knitr show_date

Sys.Date()

## @knitr interactive_postgres_connection

wait_for_postgres <- function(seconds_to_test){
  for (i in 1:seconds_to_test) {
    db_ready <- DBI::dbCanConnect(RPostgres::Postgres(),
                                  host = "localhost",
                                  port = "5432",
                                  user = dplyr::filter(environment_variables, variable == "username")[, "value"],
                                  password = dplyr::filter(environment_variables, variable == "password")[, "value"],
                                  dbname = "postgres")
    if ( !db_ready ) {Sys.sleep(1)}
    else {con <- DBI::dbConnect(RPostgres::Postgres(),
                                host = "localhost",
                                port = "5432",
                                user = dplyr::filter(environment_variables, variable == "username")[, "value"],
                                password = dplyr::filter(environment_variables, variable == "password")[, "value"],
                                dbname = "postgres")
    }
    if (i == seconds_to_test & !db_ready) {con <- "there is no connection "}
  }
  con
}

DB_USERNAME <- trimws(readline(prompt = "username: "), which = "both")
DB_PASSWORD <- getPass::getPass(msg = "password: ")
environment_variables = data.frame(
  variable = c("username", "password"),
  value = c(DB_USERNAME, DB_PASSWORD),
  stringsAsFactors = FALSE)
write.csv(environment_variables, "./dev_environment.csv", row.names = FALSE)
