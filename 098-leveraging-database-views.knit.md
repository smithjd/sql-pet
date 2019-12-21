# Leveraging Database Views {#chapter_leveraging-database-views}

> This chapter demonstrates how to:
>
>   * Assess database views, understand their importance
>   * Unpack a database view and check its assumptions
>   * Create a database view either for personal use or for submittal to your enterprise DBA


## Setup our standard working environment



Use these libraries:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)
require(knitr)
library(dbplyr)
library(sqlpetr)
library(bookdown)
library(here)
library(lubridate)
library(skimr)
library(DiagrammeR)

library(scales) # ggplot xy scales
theme_set(theme_light())
```

Connect to `adventureworks`:
























