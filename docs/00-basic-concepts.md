# Basic Concepts{#chapter_basic-concepts}

> This chapter explains:
> 
> * The overall structure of our Docker-based PostgreSQL sandbox
> * Basic concepts around each of the elements that make up our sandbox: tidy data, pipes, Docker, PostgreSQL, and data representation.

## The big picture: R and the Docker / PostgreSQL playground on your machine

Here is an overview of how R and Docker fit on your operating system in this book's sandbox:
    
![R and Docker](./screenshots/environment_overview.png)

You run R from RStudio to set up Docker, launch PostgreSQL inside it and then send queries directly to PostgreSQL from R. (We provide more details about our sandbox environment in the chapter on [mapping your environment](#chapter_appendix-sandbox-environment).

## R

We assume a general familiarity with R and RStudio. 

This book is [Tidyverse-oriented](https://www.tidyverse.org), so we assume familiarity with the pipe operator, tidy data[@Wickham2014], lazy evaluation, and techniques for tidying data[@Wickham2018].

## Docker

Docker and the DevOps tools surrounding it have fostered a revolution in the way services are delivered over the internet. In this book, we're piggybacking on a small piece of that revolution, Docker on the desktop.

### Virtual machines and hypervisors
A _virtual machine_ is a machine that is running purely as software hosted by another real machine. To the user, a virtual machine looks just like a real one. But it has no processors, memory or I/O devices of its own - all of those are supplied and managed by the host.

A virtual machine can run any operating system that will run on the host's hardware. A Linux host can run a Windows virtual machine and vice versa.

A _hypervisor_ is the component of the host system software that manages virtual machines, usually called _guests_. Linux systems have a native hypervisor called _Kernel Virtual Machine (kvm)_. And laptop, desktop and server processors from Intel and Advanced Micro Devices (AMD) have hardware that makes this hypervisor more efficient.

Windows servers and Windows 10 Pro have a hypervisor called _Hyper-V_. Like kvm, Hyper-V can take advantage of the hardware in Intel and AMD processors. On Macintosh, there is a _Hypervisor Framework_ (<https://developer.apple.com/documentation/hypervisor>) and other tools build on that.

If this book is about Docker, why do we care about virtual machines and hypervisors? Docker is a Linux subsystem - it only runs on Linux laptops, desktops and servers. As we'll see shortly, if we want to run Docker on Windows or MacOS, we'll need a hypervisor, a Linux virtual machine and some "glue logic" to provide a Docker user experience equivalent to the one on a Linux system.

### Containers
A _container_ is a set of processes running in an operating system. The host operating system is usually Linux, but other operating systems also can host containers.

Unlike a virtual machine, the container has no operating system kernel of its own. If the host is running the Linux kernel, so is the container. And since the container OS is the same as the host OS, there's no need for a hypervisor or hardware to support the hypervisor. So a container is more efficient than a virtual machine.

A container **does** have its own filesystem. From inside the container, this filesystem looks like a Linux filesystem, but it can use any Linux distro. For example, you can have an Ubuntu 18.04 LTS host running Ubuntu 14.04 LTS or Fedora 28 or CentOS 7 containers. The kernel will always be the host kernel, but the utilities and applications will be those from the container.

### Docker itself
While there are both older (_lxc_) and newer container tools, the one that has caught on in terms of widespread use is _Docker_ [@Docker2019a]. Docker is widely used on cloud providers to deploy services of all kinds. Using Docker on the desktop to deliver standardized packages, as we are doing in the book, is a secondard use case, but a common one.

If you're using a Linux laptop / desktop, all you need to do is install Docker CE [@Docker2018b]. However, most laptops and desktops don't run Linux - they run Windows or MacOS. As noted above, to use Docker on Windows or MacOS, you need a hypervisor and a Linux virtual machine.

### Docker objects
The Docker subsystem manages several kinds of objects - containers, images, volumes and networks. In this book, we are only using the basic command line tools to manage containers, images and volumes.

Docker `images` are files that define a container's initial filesystem. You can find pre-built images on Docker Hub and the Docker Store - the base PostgreSQL image we use comes from Docker Hub (<https://hub.docker.com/_/postgres/>). If there isn't a Docker image that does exactly what you want, you can build your own by creating a Dockerfile and running `docker build`. We do this in [Build the pet-sql Docker Image].

Docker `volumes` TBD

Docker `networks` TBD

### Hosting Docker on Windows machines
There are two ways to get Docker on Windows. For Windows 10 Home and older versions of Windows, you need Docker Toolbox [@Docker2019b]. Note that for Docker Toolbox, you need a 64-bit AMD or Intel processor with the virtualization hardware installed and enabled in the BIOS.

For Windows 10 Pro, you have the Hyper-V virtualizer as standard equipment, and can use Docker for Windows [@Docker2019c].

### Hosting Docker on macOS machines
As with Windows, there are two ways to get Docker. For older Intel systems, you'll need Docker Toolbox [@Docker2019d]. Newer systems (2010 or later running at least macOS El Capitan 10.11) can run Docker for Mac [@Docker2019e].

### Hosting Docker on UNIX machines

Unix was the original host.  Needs more stuff here.

## SQL

Lots of theory about data Normalization, but the bottom line is that "data normalization is practical". Getting your data into Tidy format may or may not be a tidy process. 

Efficiency: for storage and retrieval on the databse side vs for analysis

## PostgresSQL 


### Data mapping between R vs SQL concepts
factors in R, etc. Where is the discussion of DBI translation? See “9.1.8 Translating dplyr  code to SQL queries”

https://cran.r-project.org/web/packages/DBI/vignettes/spec.html#_details_

### PostgreSQL and connection parameters



We use a PostgreSQL database server running in a Docker container for the database functions.  It is installed inside Docker, so you do not have to download or install it yourself. To connect to it, you have to define some parameters. These parameters are used in two places:

1. When the Docker container is created, they're used to initialize the database, and
2. Whenever we connect to the database, we need to specify them to authenticate.

We define the parameters in an environment file that R reads when starting up. The file is called `.Renviron`, and is located in your home directory.  See the discussion of [securing and using dbms credentials](#chapter_appendix-postresql-authentication).
