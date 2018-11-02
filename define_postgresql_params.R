#! /usr/bin/env Rscript

cat(
  "DEFAULT_POSTGRES_USER_NAME=postgres\n",
  file = "~/.Renviron",
  sep = "",
  append = TRUE
)
cat(
  "DEFAULT_POSTGRES_PASSWORD=postgres\n",
  file = "~/.Renviron",
  sep = "",
  append = TRUE
)
