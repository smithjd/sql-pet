# Setup instructions (00)

> This chapter explains:
> 
> * What you need to run the code in this book
> * Where to get documentation for Docker
> * How you can contribute to the book project


## R, RStudio and Git
Most of you will probably have these already, but if you don't:

1. If you do not have R:
    * Go to <https://cran.rstudio.com/>.
    * Select the download link for your system. For Linux, choose your distro. We recommend Ubuntu 18.04 LTS "Bionic Beaver". It's much easier to find support answers on the web for Ubuntu than other distros.
    * Follow the instructions.
    * Note: if you already have R, make sure it's upgraded to R 3.5.1. We don't test on older versions!
2. If you do not have RStudio: go to <https://www.rstudio.com/products/rstudio/download/#download>. Make sure you have version 1.1.463 or later.
3. If you do not have Git:
    * On Windows, go to <https://git-scm.com/download/win> and follow instructions. There are a lot of options. Just pick the defaults!!!
    * On MacOS, go to <https://sourceforge.net/projects/git-osx-installer/files/> and follow instructions.
    * On Linux, install Git from your distribution.

## Docker
You will need Docker Community Edition (Docker CE).

* Windows: Go to <https://store.docker.com/editions/community/docker-ce-desktop-windows>. If you don't have a Docker Store login, you'll need to create one. Then:
    * If you have Windows 10 Pro, download and install Docker for Windows.
    * If you have an older version of Windows, download and install Docker Toolbox (<https://docs.docker.com/toolbox/overview/>).
    * Note that both versions require 64-bit hardware and the virtualization needs to be enabled in the firmware.
* MacOS: Go to <https://store.docker.com/editions/community/docker-ce-desktop-mac>. If you don't have a Docker Store login, you'll need to create one. Then download and install Docker for Mac. Your MacOS must be at least release Yosemite (10.10.3).
* Linux: note that, as with Windows and MacOS, you'll need a Docker Store login. Although most Linux distros ship with some version of Docker, chances are it's not the same as the official Docker CE version.
    * Ubuntu: <https://store.docker.com/editions/community/docker-ce-server-ubuntu>,
    * Fedora: <https://store.docker.com/editions/community/docker-ce-server-fedora>,
    * CentOS: <https://store.docker.com/editions/community/docker-ce-server-centos>,
    * Debian: <https://store.docker.com/editions/community/docker-ce-server-debian>.
    
***Note that on Linux, you will need to be a member of the `docker` group to use Docker.*** To do that, execute `sudo usermod -aG docker ${USER}`. Then, log out and back in again.

## Defining the PostgreSQL connection parameters
We use a PostgreSQL database server running in a Docker container for the database functions. To connect to it, you have to define some parameters. These parameters are used in two places:

1. When the Docker container is created, they're used to initialize the database, and
2. Whenever we connect to the database, we need to specify them to authenticate.

We define the parameters in an environment file that R reads when starting up. The file is called `.Renviron`, and is located in your home directory.

The easiest way to make this file is to copy the following R code and paste it into the R console:

```
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
```

## Next steps

### Browsing the book
If you just want to read the book and copy / paste code into your working environment, simply browse to <https://smithjd.github.io/sql-pet>. If you get stuck, or find things aren't working, open an issue at <https://github.com/smithjd/sql-pet/issues/new/>.

### Diving in
If you want to experiment with the code in the book, run it in RStudio and interact with it, you'll need to do two more things:

1. Install the `sqlpetr` R package. See <https://smithjd.github.io/sqlpetr> for the package documentation. This will take some time; it is installing a number of packages.
2. Clone the Git repository <https://github.com/smithjd/sql-pet.git> and open the project file `sql-pet.Rproj` in RStudio.

Onward!
