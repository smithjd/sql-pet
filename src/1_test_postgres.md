    library(tidyverse)

    ## ── Attaching packages ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
    ## ✔ tibble  1.4.2     ✔ dplyr   0.7.6
    ## ✔ tidyr   0.8.1     ✔ stringr 1.3.1
    ## ✔ readr   1.1.1     ✔ forcats 0.3.0

    ## ── Conflicts ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

    library(DBI)
    library(RPostgres)

    system2("docker-compose", "up -d", stdout = TRUE, stderr = TRUE)

    ## [1] "Starting sql-pet_dat_1 ... \r"                                                                           
    ## [2] "\033[1A\033[2K\rStarting sql-pet_dat_1 ... \033[32mdone\033[0m\r\033[1Bsql-pet_postgres9_1 is up-to-date"

    system2("docker", "ps -a", stdout = TRUE, stderr = TRUE)

    ## [1] "CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS                          PORTS                    NAMES"                  
    ## [2] "f8f2eb335f6d        postgres:9.4        \"docker-entrypoint.s…\"   About a minute ago   Exited (0) 41 seconds ago                                determined_montalcini"
    ## [3] "c1c11654b012        postgres:9.4        \"docker-entrypoint.s…\"   2 minutes ago        Exited (0) About a minute ago                            jovial_pike"          
    ## [4] "128a4299a222        postgres:9.4        \"docker-entrypoint.s…\"   5 days ago           Up 20 seconds                   0.0.0.0:5432->5432/tcp   sql-pet_postgres9_1"  
    ## [5] "58be504c00f3        alpine:latest       \"true\"                   11 days ago          Up Less than a second                                    sql-pet_dat_1"        
    ## [6] "eb4237180959        alpine:latest       \"true\"                   11 days ago          Exited (0) 11 days ago                                   sql-pet_pg_data_1"

Docker should return a response containing CONTAINER, ID, etc.

Next bring up the docker container with Postgres running in it.

If this is the first time you’ve brought up the Postgres container, you
can see more of what’s going on if you run the following command in a
terminal window:

`docker-compose up`

The last message from docker should read:

`postgres9_1  | LOG:  database system is ready to accept connections`

Your terminal window is attached to the Docker image and you can’t use
it for anything else until Docker releases the terminal’s connection.
You can send the `stop` command from R or from another terminal and then
bring up Postgres in *disconnected* mode, so that you have your terminal
back.

To stop Postgres (momentarily), from R, enter:

`system2("docker-compose stop")`

From another terminal window, just enter:

`docker-compose stop`

After the first time, you can always bring up Postgres and disconnect
the process from your window:

    Sys.sleep(5) # need to wait for Docker & Postgres to come up before connecting.

Connect with Postgres

    con <- DBI::dbConnect(RPostgres::Postgres(),
                          host = "localhost",
                          port = "5432",
                          user = "postgres",
                          password = "postgres")

At first Postgres won’t contain any tables:

    dbListTables(con)

    ## character(0)

    # Write data frame to Postgres:
    dbWriteTable(con, "mtcars", mtcars)

    # List the tables in the Postgres database again:
    dbListTables(con)

    ## [1] "mtcars"

    # demonstrate that mtcars is really there:
    dbListFields(con, "mtcars")

    ##  [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"
    ## [11] "carb"

    dbReadTable(con, "mtcars")

    ##     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
    ## 1  21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
    ## 2  21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
    ## 3  22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
    ## 4  21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
    ## 5  18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
    ## 6  18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
    ## 7  14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
    ## 8  24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
    ## 9  22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
    ## 10 19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
    ## 11 17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
    ## 12 16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
    ## 13 17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
    ## 14 15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
    ## 15 10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
    ## 16 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
    ## 17 14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
    ## 18 32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
    ## 19 30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
    ## 20 33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
    ## 21 21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
    ## 22 15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
    ## 23 15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
    ## 24 13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
    ## 25 19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
    ## 26 27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
    ## 27 26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
    ## 28 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
    ## 29 15.8   8 351.0 264 4.22 3.170 14.50  0  1    5    4
    ## 30 19.7   6 145.0 175 3.62 2.770 15.50  0  1    5    6
    ## 31 15.0   8 301.0 335 3.54 3.570 14.60  0  1    5    8
    ## 32 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2

    # be sure to disconnect from Postgres before shutting down
    dbDisconnect(con)

    # close down the Docker container.
    # Note that there's a big difference between "stop" and "down".
    #  `docker-compose stop` will keeps the contents of the Postgres database
    #  `docker-compose down` will delete the contents of the Postgres database
    # in this case use:

    system2("docker-compose", "stop", stdout = TRUE, stderr = TRUE)

    ## [1] "Stopping sql-pet_postgres9_1 ... \r"                                          
    ## [2] "\033[1A\033[2K\rStopping sql-pet_postgres9_1 ... \033[32mdone\033[0m\r\033[1B"

After closing Docker down, bring it up again and verify that tables are
still there.

    # Bring up Docker-compose and Postgres:

    system2("docker-compose", "up -d", stdout = TRUE, stderr = TRUE)

    ## [1] "Starting sql-pet_dat_1 ... \r"                                                                             
    ## [2] "\033[1A\033[2K\rStarting sql-pet_dat_1 ... \033[32mdone\033[0m\r\033[1BStarting sql-pet_postgres9_1 ... \r"
    ## [3] "\033[1A\033[2K\rStarting sql-pet_postgres9_1 ... \033[32mdone\033[0m\r\033[1B"

Connect to Postgres

    Sys.sleep(5)

    con <- DBI::dbConnect(RPostgres::Postgres(),
                          host = "localhost",
                          port = "5432",
                          user = "postgres",
                          password = "postgres")

    # Postgres should still have mtcars in it:
    dbListTables(con)

    ## [1] "mtcars"

    # Might as well delete mtcars, since there are enough copies of it in the world.
    dbRemoveTable(con, "mtcars")
    dbExistsTable(con, "mtcars")

    ## [1] FALSE

    dbDisconnect(con)
    system2("docker-compose", "stop", stdout = TRUE, stderr = TRUE)

    ## [1] "Stopping sql-pet_postgres9_1 ... \r"                                          
    ## [2] "\033[1A\033[2K\rStopping sql-pet_postgres9_1 ... \033[32mdone\033[0m\r\033[1B"

    #Start Docker PostgreSQL manually, without access to the `/src` directory:
    # system2("docker", "run postgres:9.4", , stdout = TRUE, stderr = TRUE)

    #Manual stop and remove of Docker container
    # system2("docker stop {containerid")
    # system2("docker rm {containerid}")

    #Environmental Commands
    # Sys.getenv()

    #  Not sure what these are or what their function is:
    # Sys.which('whoami')
    # Sys.setenv(PATH = X)
