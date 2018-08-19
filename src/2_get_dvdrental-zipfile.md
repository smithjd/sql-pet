Get dvdrental zipfile and conver to a .tar file
================

## Download the data zipfile

``` r
if (!require(downloader)) install.packages("downloader")
```

    ## Loading required package: downloader

``` r
if (!require(here)) install.packages("here")
```

    ## Loading required package: here

    ## here() starts at /Users/jds/Documents/Library/R/r-system/sql-pet

``` r
library(downloader, here)

download("http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip", destfile = here("src", "dvdrental.zip"))

unzip(here("src", "dvdrental.zip"), exdir = here("src"))

file.remove( here("src", "dvdrental.zip"))
```

    ## [1] TRUE
