# Docker, Postgres, with the dvdrental datbase

(the links may not be working correctly yet...)

## Black box, one fell swoop:

## Step-by-step if you want to dive in


### DVD Rental database installation

* Download the backup file for the dvdrental test database and convert it to a .tar file with:

   [./src/2_get_dvdrental-zipfile.Rmd](./src/2_get_dvdrental-zipfile.Rmd). See the results here: [./src/2_get_dvdrental-zipfile.md](./src/2_get_dvdrental-zipfile.md)

* Create the dvdrental database in Postgres and restore the data in the .tar file with:

   [./src/3_install_dvdrental-in-postgres-b.Rmd](./src/3_install_dvdrental-in-postgres-b.Rmd).  See the results here: [./src/3_install_dvdrental-in-postgres-b.md](./src/3_install_dvdrental-in-postgres-b.md)

### Verify that the dvdrental database is running and browse some tables

* Explore the dvdrental database:

   [./src/4_test_dvdrental-database-b.Rmd](./src/4_test_dvdrental-database-b.Rmd) See the results here: [./src/4_test_dvdrental-database-b.md](./src/4_test_dvdrental-database-b.md)

