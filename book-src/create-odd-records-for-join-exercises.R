# Create odd & problem records in the DVDRENTAL database for join exercises

con <- sqlpetr::sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "dvdrental",
  seconds_to_test = 30
)


dbExecute(
  con,
  "delete from customer
   where customer_id >= 600;
  "
)

dbExecute(con, "delete from store where store_id > 2;")


dbExecute(
  con,
  "
insert into customer
  (customer_id,store_id,first_name,last_name,email,address_id,activebool
  ,create_date,last_update,active)
  values(600,3,'Sophie','Yang','sophie.yang@sakilacustomer.org',1,TRUE,now(),now()::date,1)
  "
)

# this chunk raises an error.  Should it be included here or not?
dbExecute(con, "
do $$
DECLARE v_customer_id INTEGER;
begin
    v_customer_id = 600;
    insert into customer
    (customer_id,store_id,first_name,last_name,email,address_id,activebool
    ,create_date,last_update,active)
     values(v_customer_id,3,'Sophie','Yang','sophie.yang@sakilacustomer.org',1,TRUE
           ,now(),now()::date,1);
exception
when unique_violation then
    raise notice 'SQLERRM = %, customer_id = %', SQLERRM, v_customer_id;
when others then
    raise 'SQLERRM = % SQLSTATE =%', SQLERRM, SQLSTATE;
end;
$$ language 'plpgsql';")

df <- data.frame(
  customer_id = 601
  , store_id = 2
  , first_name = "Sophie"
  , last_name = "Yang"
  , email = "sophie.yang@sakilacustomer.org"
  , address_id = 1
  , activebool = TRUE
  , create_date = Sys.Date()
  , last_update = Sys.time()
  , active = 1
  , stringsAsFactors = FALSE
)
dbWriteTable(con, "customer", value = df, append = TRUE, row.names = FALSE)


dbExecute(
  con,
  "insert into customer
  (customer_id,store_id,first_name,last_name,email,address_id,activebool
  ,create_date,last_update,active)
   values(602,4,'John','Smith','john.smith@sakilacustomer.org',2,TRUE
         ,now()::date,now()::date,1)
         ,(603,5,'Ian','Frantz','ian.frantz@sakilacustomer.org',3,TRUE
         ,now()::date,now()::date,1)
         ,(604,6,'Ed','Borasky','ed.borasky@sakilacustomer.org',4,TRUE
         ,now()::date,now()::date,1)
         ;"
)

customer_id <- c(605, 606)
store_id <- c(3, 4)
first_name <- c("John", "Ian")
last_name <- c("Smith", "Frantz")
email <- c("john.smith@sakilacustomer.org", "ian.frantz@sakilacustomer.org")
address_id <- c(3, 4)
activebool <- c(TRUE, TRUE)
create_date <- c(Sys.Date(), Sys.Date())
last_update <- c(Sys.time(), Sys.time())
active <- c(1, 1)

df2 <- data.frame(customer_id, store_id, first_name, last_name, email,
                  address_id, activebool, create_date, last_update, active,
                  stringsAsFactors = FALSE
)


dbWriteTable(con, "customer",
             value = df2, append = TRUE, row.names = FALSE
)

new_customers <- dbGetQuery(con
                            , "select customer_id,store_id,first_name,last_name
                     from customer where customer_id >= 600;")


# the following raises an error.  Should it be included here?

dbExecute(con, "
do $$
DECLARE v_manager_staff_id INTEGER;
begin
    v_manager_staff_id = 1;
    insert into store (store_id,manager_staff_id,address_id,last_update)
         values (10,v_manager_staff_id,10,now()::date);
exception
when foreign_key_violation then
    raise notice 'SQLERRM = %, manager_staff_id = %', SQLERRM, v_manager_staff_id;
when others then
    raise notice 'SQLERRM = % SQLSTATE =%', SQLERRM, SQLSTATE;
end;
$$ language 'plpgsql';")


dbExecute(con, "
do $$
DECLARE v_manager_staff_id INTEGER;
begin
    v_manager_staff_id = 10;
    insert into store (store_id,manager_staff_id,address_id,last_update)
         values (10,v_manager_staff_id,10,now()::date);
exception
when foreign_key_violation then
    raise notice 'SQLERRM = %, manager_staff_id = %', SQLERRM, v_manager_staff_id;
when others then
    raise notice 'SQLERRM = % SQLSTATE =%', SQLERRM, SQLSTATE;
end;
$$ language 'plpgsql';")

dbExecute(con, "ALTER TABLE store DISABLE TRIGGER ALL;")

df <- data.frame(
  store_id = 10
  , manager_staff_id = 10
  , address_id = 10
  , last_update = Sys.time()
)
dbWriteTable(con, "store", value = df, append = TRUE, row.names = FALSE)

dbExecute(con, "ALTER TABLE store ENABLE TRIGGER ALL;")

dbExecute(con,"drop table if exists smy_customer;")

dbExecute(con,"create table smy_customer
    as select *
         from customer
        where customer_id > 594;")
dbExecute(con,"insert into smy_customer
               select *
                 from customer
                where customer_id > 594;")

