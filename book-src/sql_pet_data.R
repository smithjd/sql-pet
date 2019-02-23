# This file gathers changes that need to be made to the DVDRENTAL database
# in order for it to have complete examples of all possible joins.

# First, delete the odd rows in case they have been inserted in a previous run:

dbExecute(con, "delete from film_category where film_id >= 1001;")
dbExecute(con, "delete from rental where rental_id >= 16050;")
dbExecute(con, "delete from inventory where film_id >= 1001;")
dbExecute(con, "delete from film where film_id >= 1001;")
dbExecute(con, "delete from customer where customer_id >= 600;")
dbExecute(con, "delete from store where store_id > 2;")

# Insert new customers
dbExecute(
  con,
  "insert into customer
  (customer_id,store_id,first_name,last_name,email,address_id,activebool
  ,create_date,last_update,active)
  values(600,3,'Sophie','Yang','sophie.yang@sakilacustomer.org',1,TRUE,now(),now()::date,1)
  ,(601,2,'Sophie','Yang','sophie.yang@sakilacustomer.org',1,TRUE,now(),now()::date,1)
  ,(602,4,'John','Smith','john.smith@sakilacustomer.org',2,TRUE,now()::date,now()::date,1)
  ,(603,5,'Ian','Frantz','ian.frantz@sakilacustomer.org',3,TRUE,now()::date,now()::date,1)
  ,(604,6,'Ed','Borasky','ed.borasky@sakilacustomer.org',4,TRUE,now()::date,now()::date,1)
  ;"
)

# Insert new store record
dbExecute(con, "ALTER TABLE store DISABLE TRIGGER ALL;")
df <- data.frame(
  store_id = 10
  , manager_staff_id = 10
  , address_id = 10
  , last_update = Sys.time()
)
dbWriteTable(con, "store", value = df, append = TRUE, row.names = FALSE)
dbExecute(con, "ALTER TABLE store ENABLE TRIGGER ALL;")

# Insert new film row.
dbExecute(
  con,
  "insert into film
  (film_id,title,description,release_year,language_id
  ,rental_duration,rental_rate,length,replacement_cost,rating
  ,last_update,special_features,fulltext)
  values(1001,'Sophie''s Choice','orphaned language_id=10',2018,1
  ,7,4.99,120,14.99,'PG'
  ,now()::date,'{Trailers}','')
  ;
  ")

# Insert Film Category
dbExecute(
  con,
  "insert into film_category
  (film_id,category_id,last_update)
  values(1001,6,now()::date)
  ,(1001,7,now()::date)
  ;")

# Insert new film into inventory.
dbExecute(
  con,
  "insert into inventory
  (inventory_id,film_id,store_id,last_update)
  values(4582,1001,1,now()::date)
  ,(4583,1001,2,now()::date)
  ;")

# Insert new film rental record.
dbExecute(
  con,
  "insert into rental
  (rental_id,rental_date,inventory_id,customer_id,return_date,staff_id,last_update)
  values(16050,now()::date - interval '1 week',4582,600,now()::date,1,now()::date)
  ;")

