# Asking Business Questions From a Single Table {#chapter_exploring-a-single-table}

> This chapter explores:
>
>   * Issues that come up when investigating a single table from a business perspective
>   * Show the multiple data anomalies found in a single AdventureWorks table (*salesorderheader*)
>   * The interplay between "data questions" and "business questions"

The previous chapter has demonstrated some of the automated techniques for showing what's in a table using some standard R functions and packages.  Now we demonstrate a step-by-step process of making sense of what's in one table with more of a business perspective.  We illustrate the kind of detective work that's often involved as we investigate the *organizational meaning* of the data in a table.  We'll investigate the `salesorderheader` table in the `sales` schema in this example to understand the sales profile of the "AdventureWorks" business.  We show that there are quite a few interpretation issues even when we are examining just 3 out of the 25 columns in one table.

For this kind of detective work we are seeking to understand the following elements separately and as they interact with each other:

  * What data is stored in the database
  * How information is represented
  * How the data is entered at a day-to-day level to represent business activities
  * How the business itself is changing over time

## Setup our standard working environment



Use these libraries:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(connections)
library(glue)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(bookdown)
library(here)
library(lubridate)
library(gt)
library(scales)
library(patchwork)
theme_set(theme_light())
```

Connect to `adventureworks`.  In an interactive session we prefer to use `connections::connection_open` instead of dbConnect





















































































