* APPENDIX E - Potential Docker Architectures



## Small architecture
The simplest architecture we can possibly use has just one container, running PostgreSQL. 

* We talk to the PostgreSQL container for data analysis from RStudio on the host, using the `DBI` and `RPostgres` packages.
* We talk to the PostgreSQL container for administration by building `docker exec` commands and executing them with `system2`.
* We either mount the `Backups` volume on the host filesystem or we copy files to and from `Backups` with `docker cp` commands wrapped with `system2`.

![](95-potential_architectures_files/figure-latex/unnamed-chunk-1-1.pdf)<!-- --> 

<br><br><br>

## Medium architecture
The medium architecture adds a `pgAdmin4` container for administering the PostgreSQL server. We have the same workflow for backups, and we still do the data analysis with host RStudio, but we manage the server with a browser pointed at the `pgAdmin4` web service.

![](95-potential_architectures_files/figure-latex/unnamed-chunk-2-1.pdf)<!-- --> 

<br><br><br>

## Large architecture (95)
In the large architecture, we add a `rocker/rstudio` container, thus creating a fully-containerized workflow. We talk to the containers via a browser only.

![](95-potential_architectures_files/figure-latex/unnamed-chunk-3-1.pdf)<!-- --> 

 -- M. Edward (Ed) Borasky
 -- M. Edward (Ed) Borasky
