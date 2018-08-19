This runs after the dvdrental database is created by
\_dvdrental-in-postgres.Rmd

Bring up Docker-compose with Postgres running the dvdrental database

    system("docker-compose up -d")

Connect to Postgres

    Sys.sleep(5) # need to wait for Docker & Postgres to come up before connecting.
    con <- DBI::dbConnect(RPostgres::Postgres(),
                          host = "localhost",
                          port = "5432",
                          user = "postgres",
                          password = "postgres",
                          dbname = "dvdrental" ) # note that the dbname is specified

    dbListTables(con)

    ##  [1] "actor_info"                 "customer_list"             
    ##  [3] "film_list"                  "nicer_but_slower_film_list"
    ##  [5] "sales_by_film_category"     "sales_by_store"            
    ##  [7] "staff"                      "inventory"                 
    ##  [9] "country"                    "store"                     
    ## [11] "staff_list"                 "language"                  
    ## [13] "actor"                      "category"                  
    ## [15] "city"                       "rental"                    
    ## [17] "film_actor"                 "address"                   
    ## [19] "film_category"              "film"                      
    ## [21] "customer"                   "payment"

    dbListFields(con, "rental")

    ## [1] "rental_id"    "rental_date"  "inventory_id" "customer_id" 
    ## [5] "return_date"  "staff_id"     "last_update"

Explore one table a bit, starting with “rental”

    rental <- tbl(con,  "rental") 

    rental %>% count() %>% collect(n = Inf)

    ## # A tibble: 1 x 1
    ##   n              
    ##   <S3: integer64>
    ## 1 16044

    rental %>% 
      summarize(start_date = min(rental_date, na.rm = TRUE),
                end_date = max(return_date, na.rm = TRUE)) %>% 
      collect(n = Inf)

    ## # A tibble: 1 x 2
    ##   start_date          end_date           
    ##   <dttm>              <dttm>             
    ## 1 2005-05-24 22:53:30 2005-09-02 02:35:22

    # rental %>% collect(n = 50) %>% View()

    rental %>%
      count(customer_id) %>%
      collect(n = Inf) %>%
      mutate(n = as.numeric(n)) %>%
      ggplot(aes(n)) +
        geom_bar() +
        ggtitle("Customer activity - number of lifetime rentals per customer")

![](4_test_dvdrental-database_files/figure-markdown_strict/unnamed-chunk-3-1.png)

Always disconnect from the database and close down docker:

    dbDisconnect(con)
    system("docker-compose stop")
