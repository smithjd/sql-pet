Miniconda Integration
================

## Why do this?

A number of R deep learning packages use Python under the hood.
RStudio’s [`keras`](https://keras.rstudio.com/) package, for example,
works this way. Also, the R
[`docker`](https://bhaskarvk.github.io/docker/) package works by calling
a Python Docker API library from R via
[`reticulate`](https://rstudio.github.io/reticulate/). And, of course,
you’ll probably end up receiving a Jupyter notebook or two even if
you’re a die-hard RStudio user.

[`Miniconda`](https://conda.io/miniconda.html) is a bare-bones
minimalist version of the rather large Anaconda environment. If you’re
doing Python data science, you probably have the full Anaconda installed
already. But for R programmers, we only want enough Python for the R
packages that use Python libraries to work. So … here we go\!

## Install the `installr` package.

There’s an R package called
[`installr`](https://github.com/talgalili/installr) that can run a
Windows installer.

``` r
if (!require(installr)) install.packages("installr")
```

    ## Loading required package: installr

    ## Loading required package: stringr

    ## 
    ## Welcome to installr version 0.20.0
    ## 
    ## More information is available on the installr project website:
    ## https://github.com/talgalili/installr/
    ## 
    ## Contact: <tal.galili@gmail.com>
    ## Suggestions and bug-reports can be submitted at: https://github.com/talgalili/installr/issues
    ## 
    ##          To suppress this message use:
    ##          suppressPackageStartupMessages(library(installr))

``` r
library(installr)
```

## Install `Miniconda3`

The following R code chunk will install `Miniconda3.` I’ve commented it
out because I already ran
it.

``` r
#install.URL("https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe")
```

Here are the screenshots you’ll
see:

![](screenshots/2018-08-31%2016_12_57-Miniconda3%204.5.4%20\(64-bit\)%20Setup.png)<!-- -->
<br>Click
`Next`.

-----

![](screenshots/2018-08-31%2016_13_57-Miniconda3%204.5.4%20\(64-bit\)%20Setup.png)<!-- -->
<br>Click `I
Agree`.

-----

![](screenshots/2018-08-31%2016_14_23-Miniconda3%204.5.4%20\(64-bit\)%20Setup.png)<!-- -->
<br>`Just Me`,
`Next`.

-----

![](screenshots/2018-08-31%2016_16_11-Miniconda3%204.5.4%20\(64-bit\)%20Setup.png)<!-- -->
<br>Choose the install location. The default is your home directory,
which on my laptop is a small SSD. So I changed it to the `D` drive,
which is a terabyte spinning disk. After you’ve set the install
location, click
`Next`.

-----

![](screenshots/2018-08-31%2016_18_47-Miniconda3%204.5.4%20\(64-bit\)%20Setup.png)<!-- -->
<br>Clear both check boxes and click
`Install`.

-----

![](screenshots/2018-08-31%2016_21_12-Miniconda3%204.5.4%20\(64-bit\)%20Setup.png)<!-- -->
<br>Click
`Next`.

-----

![](screenshots/2018-08-31%2016_21_44-Miniconda3%204.5.4%20\(64-bit\)%20Setup.png)<!-- -->
<br>Clear the check boxes and click `Finish`.

## Install `reticulate`

``` r
if (!require(reticulate)) install.packages("reticulate")
```

    ## Loading required package: reticulate

``` r
library(reticulate)
```

<br>Did it work?

``` r
py_discover_config()
```

    ## python:         D:\Users\znmeb\Miniconda3\python.exe
    ## libpython:      D:/Users/znmeb/Miniconda3/python36.dll
    ## pythonhome:     D:\Users\znmeb\Miniconda3
    ## version:        3.6.5 |Anaconda, Inc.| (default, Mar 29 2018, 13:32:41) [MSC v.1900 64 bit (AMD64)]
    ## Architecture:   64bit
    ## numpy:           [NOT FOUND]
    ## 
    ## python versions found: 
    ##  D:\Users\znmeb\Miniconda3\python.exe
    ##  D:\Users\znmeb\Miniconda3\envs\docker\python.exe
