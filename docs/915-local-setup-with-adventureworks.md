# Appendix E - Install `adventureworks` on your own machine {#chapter_appendix-postgres-local-db-installation}

> This appendix demonstrates how to:
> 
> * Setup the `adventureworks` database locally on your machine
> * Connect to the `adventureworks` database
> * These instructions should be tested by a Windows user
> * The PostgreSQL tutorial links do not work, despite being pasted from the site

## Overview

This appendix details the process to download and restore the `adventureworks` database so that you can work with the database locally on your own machine. This tutorial assumes that (1) you have PostgreSQL installed on your computer, and (2) that you have configured your system to run psql at the command line. Installation of PostgreSQL and configuration of psql are outside the scope of this book.   

### Download the `adventureworks` database

Download the `adventureworks` database from [here](https://github.com/smithjd/sql-pet/blob/master/book-src/adventureworks.sql).

### Restore the `dvdrental` database at the command line

1. Launch the psql tool
1. Enter account information to log into the PostgreSQL database server, if prompted
1. Enter the following command to create a new database `CREATE DATABASE adventureworks;`
1. Open a **new terminal window** (not in psql) and navigate to the folder where the `adventureworks.sql` file is located. Use the `cd` command in the terminal, followed by the file path to change directories to the location of `adventureworks.sql`. For example: `cd /Users/username/Documents/adventureworks`.
1. Enter the following command prompt: `pg_restore -d adventureworks -f -U postgres adventureworks.sql` 

### Restore the `adventureworks` database using pgAdmin
Another option to restore the `adventureworks` database locally on your machine is with the pgAdmin graphical user interface. However, we highly recommend using the command line methods detailed above. Installation and configuration of pgAdmin is outside the scope of this book.  

## Resources

* [Instructions by PostgreSQL Tutorial](www.postgresqltutorial.com/load-postgresql-sample-database/]) to load the `dvdrental` database. (PostgreSQL Tutorial Website 2019).

* [Windows installation of PostgreSQL](www.postgresqltutorial.com/install-postgresql/) by PostgreSQL Tutorial. (PostgreSQL Tutorial Website 2019).

* [Installation of PostgreSQL on a Mac](https://postgresapp.com/) using Postgres.app. (Postgres.app 2019).

* [Command line configuration of PosgreSQL on a Mac](https://postgresapp.com/documentation/cli-tools.html) with Postgres.app. (Postgres.app 2019). 

* [Installing PostgreSQL for Linux, Arch Linux, Windows, Mac](http://postgresguide.com/setup/install.html) and other operating systems, by Postgres Guide. (Postgres Guide Website 2019). 

