Get data zipfile
================

## Download the data zipfile

``` r
if (!require(downloader)) install.packages("downloader")
```

    ## Loading required package: downloader

``` r
library(downloader)
download("http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip", destfile = "dvdrental.zip")
```
