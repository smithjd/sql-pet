* APPENDIX E - Potential Docker Architectures



## Small architecture
The simplest architecture we can possibly use has just one container, running PostgreSQL. 

* We talk to the PostgreSQL container for data analysis from RStudio on the host, using the `DBI` and `RPostgres` packages.
* We talk to the PostgreSQL container for administration by building `docker exec` commands and executing them with `system2`.
* We either mount the `Backups` volume on the host filesystem or we copy files to and from `Backups` with `docker cp` commands wrapped with `system2`.

<!--html_preserve--><div id="htmlwidget-1d9f9b9fdca3023baa83" style="width:672px;height:480px;" class="DiagrammeR html-widget"></div>
<script type="application/json" data-for="htmlwidget-1d9f9b9fdca3023baa83">{"x":{"diagram":"\ngraph LR\n    Host_Filesystem---Backups\n    RStudio---PostgreSQL\n    subgraph Containers\n    PostgreSQL\n    end\n    subgraph Volumes\n    PostgreSQL---pgdata\n    PostgreSQL---Backups\n    end\nend\n"},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<br><br><br>

## Medium architecture
The medium architecture adds a `pgAdmin4` container for administering the PostgreSQL server. We have the same workflow for backups, and we still do the data analysis with host RStudio, but we manage the server with a browser pointed at the `pgAdmin4` web service.

<!--html_preserve--><div id="htmlwidget-b18b48ec4ad649442f3b" style="width:672px;height:480px;" class="DiagrammeR html-widget"></div>
<script type="application/json" data-for="htmlwidget-b18b48ec4ad649442f3b">{"x":{"diagram":"\ngraph LR\n    Host_Filesystem---Backups\n    RStudio---PostgreSQL\n    Browser---pgAdmin4\n    subgraph Containers\n    PostgreSQL---pgAdmin4\n    end\n    subgraph Volumes\n    pgAdmin4---Backups\n    PostgreSQL---pgdata\n    end\nend\n"},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

<br><br><br>

## Large architecture (95)
In the large architecture, we add a `rocker/rstudio` container, thus creating a fully-containerized workflow. We talk to the containers via a browser only.

<!--html_preserve--><div id="htmlwidget-514d280a38cf86ead40b" style="width:672px;height:480px;" class="DiagrammeR html-widget"></div>
<script type="application/json" data-for="htmlwidget-514d280a38cf86ead40b">{"x":{"diagram":"\ngraph LR\n    Host_Filesystem---Backups\n    Browser---Rocker_RStudio\n    Browser---pgAdmin4\n    subgraph Containers\n    PostgreSQL---pgAdmin4\n    Rocker_RStudio---PostgreSQL\n    end\n    subgraph Volumes\n    pgAdmin4---Backups\n    PostgreSQL---pgdata\n    end\nend"},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

 -- M. Edward (Ed) Borasky
 -- M. Edward (Ed) Borasky
