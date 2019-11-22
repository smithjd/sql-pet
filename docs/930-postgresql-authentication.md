# Appendix C - PostgreSQL Authentication {#chapter_appendix-postresql-authentication}

## Introduction
PostgreSQL has a very robust and flexible set of authentication methods [@PGDG2018a]. In most production environments, these will be managed by the database administrator (DBA) on a need-to-access basis. People and programs will be granted access only to a minimum set of capabilities required to function, and nothing more.

In this book, we are using a PostgreSQL Docker image [@Docker2018]. When we create a container from that image, we use its native mechanism to create the `postgres` database superuser with a password specified in an R environment file `~/.Renviron`. See [Securing and using your dbms log-in credentials](#chapter_dbms-login-credentials) for how we do this.

What that means is that you are the DBA - the database superuser - for the PostgreSQL database cluster running in the container! You can create and destroy databases, schemas, tables, views, etc. You can also create and destroy users - called `roles` in PostgreSQL, and `GRANT` or `REVOKE` their privileges with great precision.

You don't have to do that to use this book. But if you want to experiment with it, feel free!

## Password authentication on the PostgreSQL Docker image
Of the many PostgreSQL authentication mechanisms, the simplest that's universallly available is `password authentication` [@PGDG2018b]. That's what we use for the `postgres` database superuser, and what we recommend for any roles you may create.

Once a role has been created, you need five items to open a connection to the PostgreSQL database cluster:

1. The `host`. This is a name or IP address that your network can access. In this book, with the database running in a Docker container, that's usually `localhost`.
2. The `port`. This is the port the server is listening on. It's usually the default, `5439`, and that's what we use. But in a secure environment, it will often be some random number to lower the chances that an attacker can find the database server. And if you have more than one server on the network, you'll need to use different ports for each of them.
3. The `dbname` to connect to. This database must exist or the connection attempt will fail.
4. The `user`. This user must exist in the database cluster and be allowed to access the database. We are using the database superuser `postgres` in this book.
5. The `password`. This is set by the DBA for the user. In this book we use the password defined in [Securing and using your dbms log-in credentials](#chapter_dbms-login-credentials).

## Adding roles
As noted above, PostgreSQL has a very flexible fine-grained access permissions system. We can't cover all of it; see @PGDG2018c for the full details. But we can give an example.

### Setting up Docker
First, we need to make sure we don't have any other databases listening on the default port `5439`.


```r
sqlpetr::sp_check_that_docker_is_up()
```

```
## [1] "Docker is up but running no containers"
```

```r
sqlpetr::sp_docker_remove_container("cattle")
```

```
## [1] 0
```

```r
# in case you've been doing things out of order, stop a container named 'adventureworks' if it exists:
# sqlpetr::sp_docker_stop("adventureworks")
```

### Creating a new container
We'll create a "cattle" container with a default PostgreSQL 10 database cluster.


```r
sqlpetr::sp_make_simple_pg("cattle")

con <- sqlpetr::sp_get_postgres_connection(
  host = "localhost",
  port = 5439,
  dbname = "postgres",
  user = "postgres",
  password = "postgres",
  seconds_to_test = 30
)
```

### Adding a role
Now, let's add a role. We'll add a role that can log in and create databases, but isn't a superuser. Since this is a demo and not a real production database cluster, we'll specify a password in plaintext. And we'll create a database for our new user.

Create the role:

```r
DBI::dbExecute(
  con,
  "CREATE ROLE charlie LOGIN CREATEDB PASSWORD 'chaplin';"
)
```

```
## [1] 0
```

Create the database:

```r
DBI::dbExecute(
  con,
 "CREATE DATABASE charlie OWNER = charlie")
```

```
## [1] 0
```

### Did it work?

```r
DBI::dbDisconnect(con)

con <- sqlpetr::sp_get_postgres_connection(
  host = "localhost",
  port = 5439,
  dbname = "postgres",
  user = "charlie",
  password = "chaplin",
  seconds_to_test = 30
)
```

OK, we can connect. Let's do some stuff!

```r
data("iris")
```

`dbCreateTable` creates the table with columns matching the data frame. But it does not send data to the table.


```r
DBI::dbCreateTable(con, "iris", iris)
```

To send data, we use `dbAppendTable`.


```r
DBI::dbAppendTable(con, "iris", iris)
```

```
## Warning: Factors converted to character
```

```
## [1] 150
```

```r
DBI::dbListTables(con)
```

```
## [1] "iris"
```

```r
head(DBI::dbReadTable(con, "iris"))
```

```
##   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
## 1          5.1         3.5          1.4         0.2  setosa
## 2          4.9         3.0          1.4         0.2  setosa
## 3          4.7         3.2          1.3         0.2  setosa
## 4          4.6         3.1          1.5         0.2  setosa
## 5          5.0         3.6          1.4         0.2  setosa
## 6          5.4         3.9          1.7         0.4  setosa
```

### Disconnect and remove the container


```r
DBI::dbDisconnect(con)

sqlpetr::sp_docker_remove_container("cattle")
```

```
## [1] 0
```
 
