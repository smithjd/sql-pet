# Appendix E - Install 'dvdrental' or 'hrsample' on your own machine {#chapter_appendix-postgres-local-db-installation}

> This appendix demonstrates how to:
> 
> * Setup the `dvdrental` or `hrsample`database locally on your machine
> * Connect to the `dvdrental` or `hrsample`database
> * Instructions specific to the `hrsample` database will be added in the future
> * These instructions should be tested by a Windows user
> * The PostgreSQL tutorial links do not work, despite being pasted from the site

## Overview

This appendix details the process to download and restore the `dvdrental` database so that you can work with the database locally on your own machine. This tutorial assumes that (1) you have PostgreSQL installed on your computer, and (2) that you have configured your system to run psql at the command line. Installation of PostgreSQL and configuration of psql are outside the scope of this book.   

### Download the `dvdrental` database

Download the `dvdrental` database from [here](http://www.postgresqltutorial.com/postgresql-sample-database/).

Locate the zip file in your downloads folder and move the zip file to the desired folder location on your machine. 

Navigate to the location where the `dvdrental.zip` file is stored. Unzip the file to retrieve the `dvdrental.tar` file. 

Note to Mac users: The default Mac OS unpacking feature may not show the `dvdrental.tar` file when unzipping the file. It may be necessary to use [another program](https://theunarchiver.com/) to unzip the file and retain the `dvdrental.tar` file.   

### Restore the `dvdrental` database at the command line

1. Launch the psql tool
1. Enter account information to log into the PostgreSQL database server, if prompted
1. Enter the following command to create a new database `CREATE DATABASE dvdrental;`
1. Open a **new terminal window** (not in psql) and navigate to the folder where the `dvdrental.tar` file is locate. Use the `cd` command in the terminal, followed by the file path to change directories to the location of `dvdrental.tar`. For example: `cd /Users/username/Documents/dvdrental`.
1. Enter the following command prompt: `pg_restore -d dvdrental -U user_name dvdrental.tar` 

Alternatively, if you did not unzip the file to `.tar` format, you can use psql to restore the database from the `.sql` file. Enter the following command at the **psql command line**: `psql -U postgres -d newdvdrental -f restore.sql`. Note that this method is not recommended for the `dvdrental` database because it was backed up with the intent to be restored only from `.tar` format. Restoring via this method does work, but errors are introduced that do not occur when restoring the `.tar` file. 

### Restore the `dvdrental` database using pgAdmin
Another option to restore the `dvdrental` database locally on your machine is with the pgAdmin graphical user interface. However, we highly recommend using the command line methods detailed above. Installation and configuration of pgAdmin is outside the scope of this book.  

## Resources

* [Instructions by PostgreSQL Tutorial](www.postgresqltutorial.com/load-postgresql-sample-database/]) to load the `dvdrental` database. (PostgreSQL Tutorial Website 2019).

* [Windows installation of PostgreSQL](www.postgresqltutorial.com/install-postgresql/) by PostgreSQL Tutorial. (PostgreSQL Tutorial Website 2019).

* [Installation of PostgreSQL on a Mac](https://postgresapp.com/) using Postgres.app. (Postgres.app 2019).

* [Command line configuration of PosgreSQL on a Mac](https://postgresapp.com/documentation/cli-tools.html) with Postgres.app. (Postgres.app 2019). 

* [Installing PostgreSQL for Linux, Arch Linux, Windows, Mac](http://postgresguide.com/setup/install.html) and other operating systems, by Postgres Guide. (Postgres Guide Website 2019). 





