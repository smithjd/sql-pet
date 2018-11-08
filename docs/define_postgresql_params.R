#! /usr/bin/env Rscript

cat(
  "\nDEFAULT_POSTGRES_USER_NAME=postgres",
  file = "~/.Renviron",
  sep = "",
  append = TRUE
)
cat(
  "\nDEFAULT_POSTGRES_PASSWORD=postgres\n",
  file = "~/.Renviron",
  sep = "",
  append = TRUE
)
