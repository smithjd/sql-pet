# Sales Forecasting {#chapter_sales-forecasting}

> This chapter demonstrates how to:
>
> * Use [`tidyverts`](https://tidyverts.org/) packages to explore and forecast sales data.

## Setup

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
require(knitr)
library(bookdown)
library(sqlpetr)
library(tsibble)
library(fable)
library(zoo)
library(connections)
```
Analyzing sales time series, in particular determining seasonality and forecasting future sales, is a common activty in business management. A collection of packages called `tidyverst` is designed to do this in a tidy data framework.

First, we make sure the Docker container is ready and connect to the `adventureworks` database.


















