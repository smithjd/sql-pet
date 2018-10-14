# SQL Pet Tutorial

## Next Meeting October/13 @10am (about 2-3 hours, followed by lunch)
Location: TBA, but could be Study room 2B at Central Library, Downtown Portland -- 801 SW 10th 

**Table of Contents**

1. [Projects](#projects)
1. [Book](#book)
1. [More Docker and PostgreSQL tips](#more-docker-and-postgresql-tips)
1. [How to contribute](#how-to-contribute)
1. [Code of Conduct](#code-of-conduct)
1. [License](#license)

## Projects

* Meeting agenda items go here: https://github.com/smithjd/sql-pet/projects/1
* Kanban is here: https://github.com/smithjd/sql-pet/projects/2 

## Book
[R, Databases and Docker](https://smithjd.github.io/sql-pet/)

* Tutorial materials go in the [Book](https://smithjd.github.io/sql-pet/).
* 
* Executable code is in the [/book-src](https://github.com/smithjd/sql-pet/tree/master/book-src) directory
  + We are using a `[Knit-then-Merge](https://bookdown.org/yihui/bookdown/new-session.html)` approach so each chapter of the book can be Knitted separately.  
  + When the book is complete, we'll put some easy to execute in a separate directory
* The book depends on the `sqlrpetr` package.  It can be downloaded using `devtools::install_github("smithjd/sqlpetr")`


## How to contribute
If you'd like to contribute to this project, start by searching through the [issues](https://github.com/smithjd/sql-pet/issues) and [pull requests](https://github.com/smithjd/sql-pet/pulls) to see whether someone else has already raised a similar idea or question.

If you don't see your idea listed, and you think it fits into the goals of this project, do one of the following:

* If your contribution is minor, such as a typo fix, open a pull request.
* If your contribution is major, such as a new learning module or a significant restructuring of current code and training material, start by opening an issue first. That way, before you do any work, other people can weigh in on the discussion to make sure that your goals are aligned with the direction of the project.

We provide more guidelines for coding style and developer's workflow in the [Contributing](https://github.com/smithjd/sql-pet/blob/master/Contributing.md) document. The [project wiki](https://github.com/smithjd/sql-pet/wiki) is also a good source of information for developers.

## Code of Conduct
If you plan to participate in the project in any way, such as a developer, reviewer, contributor, committer, or student, you are expected to follow the project's [Code of Conduct](https://github.com/smithjd/sql-pet/blob/master/CODE_OF_CONDUCT.md). Please review those guidelines before choosing to participate in the project.

## License
Software in this project is licensed under the [MIT License](https://github.com/smithjd/sql-pet/blob/master/LICENSE).

## More Docker and PostgreSQL tips 

Do these items have a place?

### PostgreSQL
* Loading the [dvdrental database into PostgreSQL](http://www.postgresqltutorial.com/load-postgresql-sample-database/)
* To explore the PostgreSQL environment it's worth browsing around inside the Docker command with a shell.

  + To run the Docker container that contains PostgreSQL, you can enter this from a command prompt:

    `$ docker exec -ti pet sh`

  + To exit Docker enter:

    `# exit`

  + Inside Docker, you can enter the PostgreSQL command-line utility psql by entering 

    `# psql -U postgres`

    Handy [psql commands](https://gpdb.docs.pivotal.io/gs/43/pdf/PSQLQuickRef.pdf) include:

    + `postgres=# \h`          # psql help
    + `postgres=# \dt`         # list PostgreSQL tables
    + `postgres=# \c dbname`   # connect to databse dbname
    + `postgres=# \l`          # list PostgreSQL databases
    + `postgres=# \conninfo`   # display information about current connection
    + `postgres=# \q`          # exit psql
