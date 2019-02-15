# Appendix A - Setup instructions{#chapter_appendix-setup-instructions}

> This appendix explains:
> 
> * Hardware and software prerequisites for setting up the sandbox used in this book
> * Documentation for all of the elements used in this sandbox

## Sandbox prerequisites

The sandbox environment requires:

* A computer running 
  + Windows (Windows 7 64-bit or later - Windows 10-Pro is recommended),
  + MacOS, or
  + Linux (any Linux distro that will run Docker Community Edition, R and RStudio will work)
* Current versions of [R and RStudio](https://www.datacamp.com/community/tutorials/installing-R-windows-mac-ubuntu) [@Vargas2018) required.
* Docker (instructions below)
* Our companion package `sqlpetr` [@Borasky2018a] 

The database we use is PostgreSQL 10, but you do not need to install it - it's installed via a Docker image. 

In addition to the current version of R and RStudio, you will need current versions of the following packages:

* `DBI` [@R-DBI]
* `DiagrammeR` [@R-DiagrammeR]
* `RPostgres` [@R-RPostgres]
* `dbplyr` [@R-dbplyr]
* `devtools` [@R-devtools]
* `downloader` [@R-downloader]
* `glue` [@R-glue]
* `here` [@R-here]
* `knitr` [@R-knitr]
* `skimr` [@R-skimr]
* `tidyverse` [@R-tidyverse]

* `bookdown` [@R-bookdown] (for compiling the book, if you want to)

## R, RStudio and Git

Most readers will probably have these already, but if not:

1. If you do not have R:
    * Go to <https://cran.rstudio.com/> [@RCT2018].
    * Select the download link for your system. For Linux, choose your distro. We recommend Ubuntu 18.04 LTS "Bionic Beaver". It's much easier to find support answers on the web for Ubuntu than other distros.
    * Follow the instructions.
    * Note: if you already have R, make sure it's upgraded to R 3.5.1. We don't test on older versions!
2. If you do not have RStudio: go to <https://www.rstudio.com/products/rstudio/download/#download>. Make sure you have version 1.1.463 or later.
3. If you do not have Git:
    * On Windows, go to <https://git-scm.com/download/win> and follow instructions. There are a lot of options. Just pick the defaults!!!
    * On MacOS, go to <https://sourceforge.net/projects/git-osx-installer/files/> and follow instructions.
    * On Linux, install Git from your distribution.

## Install Docker

Installation depends on your operating system and we have found that it can be somewhat intricate.  You will need Docker Community Edition (Docker CE):

* For Windows, [consider these issues and follow these instructions](#windows-tech-details): Go to <https://store.docker.com/editions/community/docker-ce-desktop-windows>. If you don't have a Docker Store log in, you'll need to create one. Then:
    * If you have Windows 10 Pro, download and install Docker for Windows.
    * If you have an older version of Windows, download and install Docker Toolbox (<https://docs.docker.com/toolbox/overview/>).
    * Note that both versions require 64-bit hardware and the virtualization needs to be enabled in the firmware.
* [On a Mac](https://docs.docker.com/docker-for-mac/install/) [@Docker2018c]: Go to <https://store.docker.com/editions/community/docker-ce-desktop-mac>. If you don't have a Docker Store login, you'll need to create one. Then download and install Docker for Mac. Your MacOS must be at least release Yosemite (10.10.3).
* [On UNIX flavors](https://docs.docker.com/install/#supported-platforms) [@Docker2018b]: note that, as with Windows and MacOS, you'll need a Docker Store loin. Although most Linux distros ship with some version of Docker, chances are it's not the same as the official Docker CE version.
    * Ubuntu: <https://store.docker.com/editions/community/docker-ce-server-ubuntu>,
    * Fedora: <https://store.docker.com/editions/community/docker-ce-server-fedora>,
    * Cent OS: <https://store.docker.com/editions/community/docker-ce-server-centos>,
    * Debian: <https://store.docker.com/editions/community/docker-ce-server-debian>.
    
***Note that on Linux, you will need to be a member of the `docker` group to use Docker.*** To do that, execute `sudo usermod -aG docker ${USER}`. Then, log out and back in again.
