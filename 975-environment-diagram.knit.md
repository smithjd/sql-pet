# Fx Mapping your local environment {#chapter_appendix-your-local-environment}

> This chapter explores:
> 
> * The different entities involved in running the examples in this book's sandbox
> * The different roles that each entity plays in the sandbox
> * How those entities are connected and how communication between those entities happens
> * Pointers to the commands that go with each entity

> **Explain that closing Docker down is like stopping / closing dbms. normally you can't do that.**

These packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(DiagrammeR)
display_rows <- 5
```

## Set up our standard pet-sql environment

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go.  Start up the `docker-pet` container:













