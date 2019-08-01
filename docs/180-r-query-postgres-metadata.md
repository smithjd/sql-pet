# Getting metadata about and from PostgreSQL {#chapter_postgresql-metadata}

> This chapter demonstrates:
> 
> * What kind of data about the database is contained in a dbms
> * Several methods for obtaining metadata from the dbms

The following packages are used in this chapter:

```r
library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)
library(here)
require(knitr)
library(dbplyr)
library(sqlpetr)
```

Assume that the Docker container with PostgreSQL and the dvdrental database are ready to go. 

```r
sp_docker_start("adventureworks")
```
Connect to the database:

```r
con <- sqlpetr::sp_get_postgres_connection(
  user = Sys.getenv("DEFAULT_POSTGRES_USER_NAME"),
  password = Sys.getenv("DEFAULT_POSTGRES_PASSWORD"),
  dbname = "adventureworks",
  port = 5432, 
  seconds_to_test = 20, 
  connection_tab = TRUE
)
```

## Database contents and structure

After just looking at the data you seek, it might be worthwhile stepping back and looking at the big picture.

### Database structure

For large or complex databases you need to use both the available documentation for your database (e.g.,  [the dvdrental](http://www.postgresqltutorial.com/postgresql-sample-database/) database) and the other empirical tools that are available.  For example it's worth learning to interpret the symbols in an [Entity Relationship Diagram](https://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model):

![](./screenshots/ER-diagram-symbols.png)

The `information_schema` is a trove of information *about* the database.  Its format is more or less consistent across the different SQL implementations that are available.   Here we explore some of what's available using several different methods.  PostgreSQL stores [a lot of metadata](https://www.postgresql.org/docs/current/static/infoschema-columns.html).

### Contents of the `information_schema` 
For this chapter R needs the `dbplyr` package to access alternate schemas.  A [schema](http://www.postgresqltutorial.com/postgresql-server-and-database-objects/) is an object that contains one or more tables.  Most often there will be a default schema, but to access the metadata, you need to explicitly specify which schema contains the data you want.

### What tables are in the database?
The simplest way to get a list of tables is with ... *NO LONGER WORKS*:

```r
schema_list <- tbl(con, in_schema("information_schema", "schemata")) %>%
  select(catalog_name, schema_name, schema_owner) %>%
  collect()


kable(schema_list)
```



catalog_name     schema_name          schema_owner 
---------------  -------------------  -------------
adventureworks   pg_toast             postgres     
adventureworks   pg_temp_1            postgres     
adventureworks   pg_toast_temp_1      postgres     
adventureworks   pg_catalog           postgres     
adventureworks   public               postgres     
adventureworks   information_schema   postgres     
adventureworks   hr                   postgres     
adventureworks   humanresources       postgres     
adventureworks   pe                   postgres     
adventureworks   person               postgres     
adventureworks   pr                   postgres     
adventureworks   production           postgres     
adventureworks   pu                   postgres     
adventureworks   purchasing           postgres     
adventureworks   sa                   postgres     
adventureworks   sales                postgres     
### Digging into the `information_schema`

We usually need more detail than just a list of tables. Most SQL databases have an `information_schema` that has a standard structure to describe and control the database.

The `information_schema` is in a different schema from the default, so to connect to the `tables` table in the  `information_schema` we connect to the database in a different way:

```r
table_info_schema_table <- tbl(con, dbplyr::in_schema("information_schema", "tables"))
```
The `information_schema` is large and complex and contains 343 tables.  So it's easy to get lost in it.

This query retrieves a list of the tables in the database that includes additional detail, not just the name of the table.

```r
table_info <- table_info_schema_table %>%
  # filter(table_schema == "public") %>%
  select(table_catalog, table_schema, table_name, table_type) %>%
  arrange(table_type, table_name) %>%
  collect()

kable(table_info)
```



table_catalog    table_schema         table_name                              table_type 
---------------  -------------------  --------------------------------------  -----------
adventureworks   person               address                                 BASE TABLE 
adventureworks   person               addresstype                             BASE TABLE 
adventureworks   production           billofmaterials                         BASE TABLE 
adventureworks   person               businessentity                          BASE TABLE 
adventureworks   person               businessentityaddress                   BASE TABLE 
adventureworks   person               businessentitycontact                   BASE TABLE 
adventureworks   person               contacttype                             BASE TABLE 
adventureworks   person               countryregion                           BASE TABLE 
adventureworks   sales                countryregioncurrency                   BASE TABLE 
adventureworks   sales                creditcard                              BASE TABLE 
adventureworks   production           culture                                 BASE TABLE 
adventureworks   sales                currency                                BASE TABLE 
adventureworks   sales                currencyrate                            BASE TABLE 
adventureworks   sales                customer                                BASE TABLE 
adventureworks   humanresources       department                              BASE TABLE 
adventureworks   production           document                                BASE TABLE 
adventureworks   person               emailaddress                            BASE TABLE 
adventureworks   humanresources       employee                                BASE TABLE 
adventureworks   humanresources       employeedepartmenthistory               BASE TABLE 
adventureworks   humanresources       employeepayhistory                      BASE TABLE 
adventureworks   production           illustration                            BASE TABLE 
adventureworks   humanresources       jobcandidate                            BASE TABLE 
adventureworks   production           location                                BASE TABLE 
adventureworks   person               password                                BASE TABLE 
adventureworks   person               person                                  BASE TABLE 
adventureworks   sales                personcreditcard                        BASE TABLE 
adventureworks   person               personphone                             BASE TABLE 
adventureworks   pg_catalog           pg_aggregate                            BASE TABLE 
adventureworks   pg_catalog           pg_am                                   BASE TABLE 
adventureworks   pg_catalog           pg_amop                                 BASE TABLE 
adventureworks   pg_catalog           pg_amproc                               BASE TABLE 
adventureworks   pg_catalog           pg_attrdef                              BASE TABLE 
adventureworks   pg_catalog           pg_attribute                            BASE TABLE 
adventureworks   pg_catalog           pg_authid                               BASE TABLE 
adventureworks   pg_catalog           pg_auth_members                         BASE TABLE 
adventureworks   pg_catalog           pg_cast                                 BASE TABLE 
adventureworks   pg_catalog           pg_class                                BASE TABLE 
adventureworks   pg_catalog           pg_collation                            BASE TABLE 
adventureworks   pg_catalog           pg_constraint                           BASE TABLE 
adventureworks   pg_catalog           pg_conversion                           BASE TABLE 
adventureworks   pg_catalog           pg_database                             BASE TABLE 
adventureworks   pg_catalog           pg_db_role_setting                      BASE TABLE 
adventureworks   pg_catalog           pg_default_acl                          BASE TABLE 
adventureworks   pg_catalog           pg_depend                               BASE TABLE 
adventureworks   pg_catalog           pg_description                          BASE TABLE 
adventureworks   pg_catalog           pg_enum                                 BASE TABLE 
adventureworks   pg_catalog           pg_event_trigger                        BASE TABLE 
adventureworks   pg_catalog           pg_extension                            BASE TABLE 
adventureworks   pg_catalog           pg_foreign_data_wrapper                 BASE TABLE 
adventureworks   pg_catalog           pg_foreign_server                       BASE TABLE 
adventureworks   pg_catalog           pg_foreign_table                        BASE TABLE 
adventureworks   pg_catalog           pg_index                                BASE TABLE 
adventureworks   pg_catalog           pg_inherits                             BASE TABLE 
adventureworks   pg_catalog           pg_init_privs                           BASE TABLE 
adventureworks   pg_catalog           pg_language                             BASE TABLE 
adventureworks   pg_catalog           pg_largeobject                          BASE TABLE 
adventureworks   pg_catalog           pg_largeobject_metadata                 BASE TABLE 
adventureworks   pg_catalog           pg_namespace                            BASE TABLE 
adventureworks   pg_catalog           pg_opclass                              BASE TABLE 
adventureworks   pg_catalog           pg_operator                             BASE TABLE 
adventureworks   pg_catalog           pg_opfamily                             BASE TABLE 
adventureworks   pg_catalog           pg_partitioned_table                    BASE TABLE 
adventureworks   pg_catalog           pg_pltemplate                           BASE TABLE 
adventureworks   pg_catalog           pg_policy                               BASE TABLE 
adventureworks   pg_catalog           pg_proc                                 BASE TABLE 
adventureworks   pg_catalog           pg_publication                          BASE TABLE 
adventureworks   pg_catalog           pg_publication_rel                      BASE TABLE 
adventureworks   pg_catalog           pg_range                                BASE TABLE 
adventureworks   pg_catalog           pg_replication_origin                   BASE TABLE 
adventureworks   pg_catalog           pg_rewrite                              BASE TABLE 
adventureworks   pg_catalog           pg_seclabel                             BASE TABLE 
adventureworks   pg_catalog           pg_sequence                             BASE TABLE 
adventureworks   pg_catalog           pg_shdepend                             BASE TABLE 
adventureworks   pg_catalog           pg_shdescription                        BASE TABLE 
adventureworks   pg_catalog           pg_shseclabel                           BASE TABLE 
adventureworks   pg_catalog           pg_statistic                            BASE TABLE 
adventureworks   pg_catalog           pg_statistic_ext                        BASE TABLE 
adventureworks   pg_catalog           pg_subscription                         BASE TABLE 
adventureworks   pg_catalog           pg_subscription_rel                     BASE TABLE 
adventureworks   pg_catalog           pg_tablespace                           BASE TABLE 
adventureworks   pg_catalog           pg_transform                            BASE TABLE 
adventureworks   pg_catalog           pg_trigger                              BASE TABLE 
adventureworks   pg_catalog           pg_ts_config                            BASE TABLE 
adventureworks   pg_catalog           pg_ts_config_map                        BASE TABLE 
adventureworks   pg_catalog           pg_ts_dict                              BASE TABLE 
adventureworks   pg_catalog           pg_ts_parser                            BASE TABLE 
adventureworks   pg_catalog           pg_ts_template                          BASE TABLE 
adventureworks   pg_catalog           pg_type                                 BASE TABLE 
adventureworks   pg_catalog           pg_user_mapping                         BASE TABLE 
adventureworks   person               phonenumbertype                         BASE TABLE 
adventureworks   production           product                                 BASE TABLE 
adventureworks   production           productcategory                         BASE TABLE 
adventureworks   production           productcosthistory                      BASE TABLE 
adventureworks   production           productdescription                      BASE TABLE 
adventureworks   production           productdocument                         BASE TABLE 
adventureworks   production           productinventory                        BASE TABLE 
adventureworks   production           productlistpricehistory                 BASE TABLE 
adventureworks   production           productmodel                            BASE TABLE 
adventureworks   production           productmodelillustration                BASE TABLE 
adventureworks   production           productmodelproductdescriptionculture   BASE TABLE 
adventureworks   production           productphoto                            BASE TABLE 
adventureworks   production           productproductphoto                     BASE TABLE 
adventureworks   production           productreview                           BASE TABLE 
adventureworks   production           productsubcategory                      BASE TABLE 
adventureworks   purchasing           productvendor                           BASE TABLE 
adventureworks   purchasing           purchaseorderdetail                     BASE TABLE 
adventureworks   purchasing           purchaseorderheader                     BASE TABLE 
adventureworks   sales                salesorderdetail                        BASE TABLE 
adventureworks   sales                salesorderheader                        BASE TABLE 
adventureworks   sales                salesorderheadersalesreason             BASE TABLE 
adventureworks   sales                salesperson                             BASE TABLE 
adventureworks   sales                salespersonquotahistory                 BASE TABLE 
adventureworks   sales                salesreason                             BASE TABLE 
adventureworks   sales                salestaxrate                            BASE TABLE 
adventureworks   sales                salesterritory                          BASE TABLE 
adventureworks   sales                salesterritoryhistory                   BASE TABLE 
adventureworks   production           scrapreason                             BASE TABLE 
adventureworks   humanresources       shift                                   BASE TABLE 
adventureworks   purchasing           shipmethod                              BASE TABLE 
adventureworks   sales                shoppingcartitem                        BASE TABLE 
adventureworks   sales                specialoffer                            BASE TABLE 
adventureworks   sales                specialofferproduct                     BASE TABLE 
adventureworks   information_schema   sql_features                            BASE TABLE 
adventureworks   information_schema   sql_implementation_info                 BASE TABLE 
adventureworks   information_schema   sql_languages                           BASE TABLE 
adventureworks   information_schema   sql_packages                            BASE TABLE 
adventureworks   information_schema   sql_parts                               BASE TABLE 
adventureworks   information_schema   sql_sizing                              BASE TABLE 
adventureworks   information_schema   sql_sizing_profiles                     BASE TABLE 
adventureworks   person               stateprovince                           BASE TABLE 
adventureworks   sales                store                                   BASE TABLE 
adventureworks   production           transactionhistory                      BASE TABLE 
adventureworks   production           transactionhistoryarchive               BASE TABLE 
adventureworks   production           unitmeasure                             BASE TABLE 
adventureworks   purchasing           vendor                                  BASE TABLE 
adventureworks   production           workorder                               BASE TABLE 
adventureworks   production           workorderrouting                        BASE TABLE 
adventureworks   pe                   a                                       VIEW       
adventureworks   information_schema   administrable_role_authorizations       VIEW       
adventureworks   information_schema   applicable_roles                        VIEW       
adventureworks   pe                   at                                      VIEW       
adventureworks   information_schema   attributes                              VIEW       
adventureworks   pe                   be                                      VIEW       
adventureworks   pe                   bea                                     VIEW       
adventureworks   pe                   bec                                     VIEW       
adventureworks   pr                   bom                                     VIEW       
adventureworks   pr                   c                                       VIEW       
adventureworks   sa                   c                                       VIEW       
adventureworks   sa                   cc                                      VIEW       
adventureworks   information_schema   character_sets                          VIEW       
adventureworks   information_schema   check_constraint_routine_usage          VIEW       
adventureworks   information_schema   check_constraints                       VIEW       
adventureworks   information_schema   collation_character_set_applicability   VIEW       
adventureworks   information_schema   collations                              VIEW       
adventureworks   information_schema   column_domain_usage                     VIEW       
adventureworks   information_schema   column_options                          VIEW       
adventureworks   information_schema   column_privileges                       VIEW       
adventureworks   information_schema   columns                                 VIEW       
adventureworks   information_schema   column_udt_usage                        VIEW       
adventureworks   information_schema   constraint_column_usage                 VIEW       
adventureworks   information_schema   constraint_table_usage                  VIEW       
adventureworks   sa                   cr                                      VIEW       
adventureworks   pe                   cr                                      VIEW       
adventureworks   sa                   crc                                     VIEW       
adventureworks   pe                   ct                                      VIEW       
adventureworks   sa                   cu                                      VIEW       
adventureworks   hr                   d                                       VIEW       
adventureworks   pr                   d                                       VIEW       
adventureworks   information_schema   data_type_privileges                    VIEW       
adventureworks   information_schema   domain_constraints                      VIEW       
adventureworks   information_schema   domains                                 VIEW       
adventureworks   information_schema   domain_udt_usage                        VIEW       
adventureworks   pe                   e                                       VIEW       
adventureworks   hr                   e                                       VIEW       
adventureworks   hr                   edh                                     VIEW       
adventureworks   information_schema   element_types                           VIEW       
adventureworks   information_schema   enabled_roles                           VIEW       
adventureworks   hr                   eph                                     VIEW       
adventureworks   information_schema   foreign_data_wrapper_options            VIEW       
adventureworks   information_schema   foreign_data_wrappers                   VIEW       
adventureworks   information_schema   foreign_server_options                  VIEW       
adventureworks   information_schema   foreign_servers                         VIEW       
adventureworks   information_schema   foreign_table_options                   VIEW       
adventureworks   information_schema   foreign_tables                          VIEW       
adventureworks   pr                   i                                       VIEW       
adventureworks   information_schema   information_schema_catalog_name         VIEW       
adventureworks   hr                   jc                                      VIEW       
adventureworks   information_schema   key_column_usage                        VIEW       
adventureworks   pr                   l                                       VIEW       
adventureworks   pr                   p                                       VIEW       
adventureworks   pe                   p                                       VIEW       
adventureworks   pe                   pa                                      VIEW       
adventureworks   information_schema   parameters                              VIEW       
adventureworks   pr                   pc                                      VIEW       
adventureworks   sa                   pcc                                     VIEW       
adventureworks   pr                   pch                                     VIEW       
adventureworks   pr                   pd                                      VIEW       
adventureworks   pr                   pdoc                                    VIEW       
adventureworks   pg_catalog           pg_available_extensions                 VIEW       
adventureworks   pg_catalog           pg_available_extension_versions         VIEW       
adventureworks   pg_catalog           pg_config                               VIEW       
adventureworks   pg_catalog           pg_cursors                              VIEW       
adventureworks   pg_catalog           pg_file_settings                        VIEW       
adventureworks   information_schema   _pg_foreign_data_wrappers               VIEW       
adventureworks   information_schema   _pg_foreign_servers                     VIEW       
adventureworks   information_schema   _pg_foreign_table_columns               VIEW       
adventureworks   information_schema   _pg_foreign_tables                      VIEW       
adventureworks   pg_catalog           pg_group                                VIEW       
adventureworks   pg_catalog           pg_hba_file_rules                       VIEW       
adventureworks   pg_catalog           pg_indexes                              VIEW       
adventureworks   pg_catalog           pg_locks                                VIEW       
adventureworks   pg_catalog           pg_matviews                             VIEW       
adventureworks   pg_catalog           pg_policies                             VIEW       
adventureworks   pg_catalog           pg_prepared_statements                  VIEW       
adventureworks   pg_catalog           pg_prepared_xacts                       VIEW       
adventureworks   pg_catalog           pg_publication_tables                   VIEW       
adventureworks   pg_catalog           pg_replication_origin_status            VIEW       
adventureworks   pg_catalog           pg_replication_slots                    VIEW       
adventureworks   pg_catalog           pg_roles                                VIEW       
adventureworks   pg_catalog           pg_rules                                VIEW       
adventureworks   pg_catalog           pg_seclabels                            VIEW       
adventureworks   pg_catalog           pg_sequences                            VIEW       
adventureworks   pg_catalog           pg_settings                             VIEW       
adventureworks   pg_catalog           pg_shadow                               VIEW       
adventureworks   pg_catalog           pg_stat_activity                        VIEW       
adventureworks   pg_catalog           pg_stat_all_indexes                     VIEW       
adventureworks   pg_catalog           pg_stat_all_tables                      VIEW       
adventureworks   pg_catalog           pg_stat_archiver                        VIEW       
adventureworks   pg_catalog           pg_stat_bgwriter                        VIEW       
adventureworks   pg_catalog           pg_stat_database                        VIEW       
adventureworks   pg_catalog           pg_stat_database_conflicts              VIEW       
adventureworks   pg_catalog           pg_statio_all_indexes                   VIEW       
adventureworks   pg_catalog           pg_statio_all_sequences                 VIEW       
adventureworks   pg_catalog           pg_statio_all_tables                    VIEW       
adventureworks   pg_catalog           pg_statio_sys_indexes                   VIEW       
adventureworks   pg_catalog           pg_statio_sys_sequences                 VIEW       
adventureworks   pg_catalog           pg_statio_sys_tables                    VIEW       
adventureworks   pg_catalog           pg_statio_user_indexes                  VIEW       
adventureworks   pg_catalog           pg_statio_user_sequences                VIEW       
adventureworks   pg_catalog           pg_statio_user_tables                   VIEW       
adventureworks   pg_catalog           pg_stat_progress_vacuum                 VIEW       
adventureworks   pg_catalog           pg_stat_replication                     VIEW       
adventureworks   pg_catalog           pg_stats                                VIEW       
adventureworks   pg_catalog           pg_stat_ssl                             VIEW       
adventureworks   pg_catalog           pg_stat_subscription                    VIEW       
adventureworks   pg_catalog           pg_stat_sys_indexes                     VIEW       
adventureworks   pg_catalog           pg_stat_sys_tables                      VIEW       
adventureworks   pg_catalog           pg_stat_user_functions                  VIEW       
adventureworks   pg_catalog           pg_stat_user_indexes                    VIEW       
adventureworks   pg_catalog           pg_stat_user_tables                     VIEW       
adventureworks   pg_catalog           pg_stat_wal_receiver                    VIEW       
adventureworks   pg_catalog           pg_stat_xact_all_tables                 VIEW       
adventureworks   pg_catalog           pg_stat_xact_sys_tables                 VIEW       
adventureworks   pg_catalog           pg_stat_xact_user_functions             VIEW       
adventureworks   pg_catalog           pg_stat_xact_user_tables                VIEW       
adventureworks   pg_catalog           pg_tables                               VIEW       
adventureworks   pg_catalog           pg_timezone_abbrevs                     VIEW       
adventureworks   pg_catalog           pg_timezone_names                       VIEW       
adventureworks   pg_catalog           pg_user                                 VIEW       
adventureworks   information_schema   _pg_user_mappings                       VIEW       
adventureworks   pg_catalog           pg_user_mappings                        VIEW       
adventureworks   pg_catalog           pg_views                                VIEW       
adventureworks   pr                   pi                                      VIEW       
adventureworks   pr                   plph                                    VIEW       
adventureworks   pr                   pm                                      VIEW       
adventureworks   pr                   pmi                                     VIEW       
adventureworks   pr                   pmpdc                                   VIEW       
adventureworks   pe                   pnt                                     VIEW       
adventureworks   pu                   pod                                     VIEW       
adventureworks   pu                   poh                                     VIEW       
adventureworks   pr                   pp                                      VIEW       
adventureworks   pe                   pp                                      VIEW       
adventureworks   pr                   ppp                                     VIEW       
adventureworks   pr                   pr                                      VIEW       
adventureworks   pr                   psc                                     VIEW       
adventureworks   pu                   pv                                      VIEW       
adventureworks   information_schema   referential_constraints                 VIEW       
adventureworks   information_schema   role_column_grants                      VIEW       
adventureworks   information_schema   role_routine_grants                     VIEW       
adventureworks   information_schema   role_table_grants                       VIEW       
adventureworks   information_schema   role_udt_grants                         VIEW       
adventureworks   information_schema   role_usage_grants                       VIEW       
adventureworks   information_schema   routine_privileges                      VIEW       
adventureworks   information_schema   routines                                VIEW       
adventureworks   hr                   s                                       VIEW       
adventureworks   sa                   s                                       VIEW       
adventureworks   information_schema   schemata                                VIEW       
adventureworks   sa                   sci                                     VIEW       
adventureworks   information_schema   sequences                               VIEW       
adventureworks   pu                   sm                                      VIEW       
adventureworks   sa                   so                                      VIEW       
adventureworks   sa                   sod                                     VIEW       
adventureworks   sa                   soh                                     VIEW       
adventureworks   sa                   sohsr                                   VIEW       
adventureworks   sa                   sop                                     VIEW       
adventureworks   sa                   sp                                      VIEW       
adventureworks   pe                   sp                                      VIEW       
adventureworks   sa                   spqh                                    VIEW       
adventureworks   pr                   sr                                      VIEW       
adventureworks   sa                   sr                                      VIEW       
adventureworks   sa                   st                                      VIEW       
adventureworks   sa                   sth                                     VIEW       
adventureworks   information_schema   table_constraints                       VIEW       
adventureworks   information_schema   table_privileges                        VIEW       
adventureworks   information_schema   tables                                  VIEW       
adventureworks   pr                   th                                      VIEW       
adventureworks   pr                   tha                                     VIEW       
adventureworks   sa                   tr                                      VIEW       
adventureworks   information_schema   transforms                              VIEW       
adventureworks   information_schema   triggered_update_columns                VIEW       
adventureworks   information_schema   triggers                                VIEW       
adventureworks   information_schema   udt_privileges                          VIEW       
adventureworks   pr                   um                                      VIEW       
adventureworks   information_schema   usage_privileges                        VIEW       
adventureworks   information_schema   user_defined_types                      VIEW       
adventureworks   information_schema   user_mapping_options                    VIEW       
adventureworks   information_schema   user_mappings                           VIEW       
adventureworks   pu                   v                                       VIEW       
adventureworks   person               vadditionalcontactinfo                  VIEW       
adventureworks   humanresources       vemployee                               VIEW       
adventureworks   humanresources       vemployeedepartment                     VIEW       
adventureworks   humanresources       vemployeedepartmenthistory              VIEW       
adventureworks   information_schema   view_column_usage                       VIEW       
adventureworks   information_schema   view_routine_usage                      VIEW       
adventureworks   information_schema   views                                   VIEW       
adventureworks   information_schema   view_table_usage                        VIEW       
adventureworks   sales                vindividualcustomer                     VIEW       
adventureworks   humanresources       vjobcandidate                           VIEW       
adventureworks   humanresources       vjobcandidateeducation                  VIEW       
adventureworks   humanresources       vjobcandidateemployment                 VIEW       
adventureworks   sales                vpersondemographics                     VIEW       
adventureworks   production           vproductmodelcatalogdescription         VIEW       
adventureworks   production           vproductmodelinstructions               VIEW       
adventureworks   sales                vsalesperson                            VIEW       
adventureworks   sales                vsalespersonsalesbyfiscalyears          VIEW       
adventureworks   sales                vsalespersonsalesbyfiscalyearsdata      VIEW       
adventureworks   sales                vstorewithaddresses                     VIEW       
adventureworks   sales                vstorewithcontacts                      VIEW       
adventureworks   sales                vstorewithdemographics                  VIEW       
adventureworks   purchasing           vvendorwithaddresses                    VIEW       
adventureworks   purchasing           vvendorwithcontacts                     VIEW       
adventureworks   pr                   w                                       VIEW       
adventureworks   pr                   wr                                      VIEW       
In this context `table_catalog` is synonymous with `database`.

Notice that *VIEWS* are composites made up of one or more *BASE TABLES*.

The SQL world has its own terminology.  For example `rs` is shorthand for `result set`.  That's equivalent to using `df` for a `data frame`.  The following SQL query returns the same information as the previous one.

```r
rs <- dbGetQuery(
  con,
  "select table_catalog, table_schema, table_name, table_type 
  from information_schema.tables 
  where table_schema not in ('pg_catalog','information_schema')
  order by table_type, table_name 
  ;"
)
kable(rs)
```



table_catalog    table_schema     table_name                              table_type 
---------------  ---------------  --------------------------------------  -----------
adventureworks   person           address                                 BASE TABLE 
adventureworks   person           addresstype                             BASE TABLE 
adventureworks   production       billofmaterials                         BASE TABLE 
adventureworks   person           businessentity                          BASE TABLE 
adventureworks   person           businessentityaddress                   BASE TABLE 
adventureworks   person           businessentitycontact                   BASE TABLE 
adventureworks   person           contacttype                             BASE TABLE 
adventureworks   person           countryregion                           BASE TABLE 
adventureworks   sales            countryregioncurrency                   BASE TABLE 
adventureworks   sales            creditcard                              BASE TABLE 
adventureworks   production       culture                                 BASE TABLE 
adventureworks   sales            currency                                BASE TABLE 
adventureworks   sales            currencyrate                            BASE TABLE 
adventureworks   sales            customer                                BASE TABLE 
adventureworks   humanresources   department                              BASE TABLE 
adventureworks   production       document                                BASE TABLE 
adventureworks   person           emailaddress                            BASE TABLE 
adventureworks   humanresources   employee                                BASE TABLE 
adventureworks   humanresources   employeedepartmenthistory               BASE TABLE 
adventureworks   humanresources   employeepayhistory                      BASE TABLE 
adventureworks   production       illustration                            BASE TABLE 
adventureworks   humanresources   jobcandidate                            BASE TABLE 
adventureworks   production       location                                BASE TABLE 
adventureworks   person           password                                BASE TABLE 
adventureworks   person           person                                  BASE TABLE 
adventureworks   sales            personcreditcard                        BASE TABLE 
adventureworks   person           personphone                             BASE TABLE 
adventureworks   person           phonenumbertype                         BASE TABLE 
adventureworks   production       product                                 BASE TABLE 
adventureworks   production       productcategory                         BASE TABLE 
adventureworks   production       productcosthistory                      BASE TABLE 
adventureworks   production       productdescription                      BASE TABLE 
adventureworks   production       productdocument                         BASE TABLE 
adventureworks   production       productinventory                        BASE TABLE 
adventureworks   production       productlistpricehistory                 BASE TABLE 
adventureworks   production       productmodel                            BASE TABLE 
adventureworks   production       productmodelillustration                BASE TABLE 
adventureworks   production       productmodelproductdescriptionculture   BASE TABLE 
adventureworks   production       productphoto                            BASE TABLE 
adventureworks   production       productproductphoto                     BASE TABLE 
adventureworks   production       productreview                           BASE TABLE 
adventureworks   production       productsubcategory                      BASE TABLE 
adventureworks   purchasing       productvendor                           BASE TABLE 
adventureworks   purchasing       purchaseorderdetail                     BASE TABLE 
adventureworks   purchasing       purchaseorderheader                     BASE TABLE 
adventureworks   sales            salesorderdetail                        BASE TABLE 
adventureworks   sales            salesorderheader                        BASE TABLE 
adventureworks   sales            salesorderheadersalesreason             BASE TABLE 
adventureworks   sales            salesperson                             BASE TABLE 
adventureworks   sales            salespersonquotahistory                 BASE TABLE 
adventureworks   sales            salesreason                             BASE TABLE 
adventureworks   sales            salestaxrate                            BASE TABLE 
adventureworks   sales            salesterritory                          BASE TABLE 
adventureworks   sales            salesterritoryhistory                   BASE TABLE 
adventureworks   production       scrapreason                             BASE TABLE 
adventureworks   humanresources   shift                                   BASE TABLE 
adventureworks   purchasing       shipmethod                              BASE TABLE 
adventureworks   sales            shoppingcartitem                        BASE TABLE 
adventureworks   sales            specialoffer                            BASE TABLE 
adventureworks   sales            specialofferproduct                     BASE TABLE 
adventureworks   person           stateprovince                           BASE TABLE 
adventureworks   sales            store                                   BASE TABLE 
adventureworks   production       transactionhistory                      BASE TABLE 
adventureworks   production       transactionhistoryarchive               BASE TABLE 
adventureworks   production       unitmeasure                             BASE TABLE 
adventureworks   purchasing       vendor                                  BASE TABLE 
adventureworks   production       workorder                               BASE TABLE 
adventureworks   production       workorderrouting                        BASE TABLE 
adventureworks   pe               a                                       VIEW       
adventureworks   pe               at                                      VIEW       
adventureworks   pe               be                                      VIEW       
adventureworks   pe               bea                                     VIEW       
adventureworks   pe               bec                                     VIEW       
adventureworks   pr               bom                                     VIEW       
adventureworks   pr               c                                       VIEW       
adventureworks   sa               c                                       VIEW       
adventureworks   sa               cc                                      VIEW       
adventureworks   sa               cr                                      VIEW       
adventureworks   pe               cr                                      VIEW       
adventureworks   sa               crc                                     VIEW       
adventureworks   pe               ct                                      VIEW       
adventureworks   sa               cu                                      VIEW       
adventureworks   hr               d                                       VIEW       
adventureworks   pr               d                                       VIEW       
adventureworks   pe               e                                       VIEW       
adventureworks   hr               e                                       VIEW       
adventureworks   hr               edh                                     VIEW       
adventureworks   hr               eph                                     VIEW       
adventureworks   pr               i                                       VIEW       
adventureworks   hr               jc                                      VIEW       
adventureworks   pr               l                                       VIEW       
adventureworks   pr               p                                       VIEW       
adventureworks   pe               p                                       VIEW       
adventureworks   pe               pa                                      VIEW       
adventureworks   pr               pc                                      VIEW       
adventureworks   sa               pcc                                     VIEW       
adventureworks   pr               pch                                     VIEW       
adventureworks   pr               pd                                      VIEW       
adventureworks   pr               pdoc                                    VIEW       
adventureworks   pr               pi                                      VIEW       
adventureworks   pr               plph                                    VIEW       
adventureworks   pr               pm                                      VIEW       
adventureworks   pr               pmi                                     VIEW       
adventureworks   pr               pmpdc                                   VIEW       
adventureworks   pe               pnt                                     VIEW       
adventureworks   pu               pod                                     VIEW       
adventureworks   pu               poh                                     VIEW       
adventureworks   pr               pp                                      VIEW       
adventureworks   pe               pp                                      VIEW       
adventureworks   pr               ppp                                     VIEW       
adventureworks   pr               pr                                      VIEW       
adventureworks   pr               psc                                     VIEW       
adventureworks   pu               pv                                      VIEW       
adventureworks   sa               s                                       VIEW       
adventureworks   hr               s                                       VIEW       
adventureworks   sa               sci                                     VIEW       
adventureworks   pu               sm                                      VIEW       
adventureworks   sa               so                                      VIEW       
adventureworks   sa               sod                                     VIEW       
adventureworks   sa               soh                                     VIEW       
adventureworks   sa               sohsr                                   VIEW       
adventureworks   sa               sop                                     VIEW       
adventureworks   sa               sp                                      VIEW       
adventureworks   pe               sp                                      VIEW       
adventureworks   sa               spqh                                    VIEW       
adventureworks   pr               sr                                      VIEW       
adventureworks   sa               sr                                      VIEW       
adventureworks   sa               st                                      VIEW       
adventureworks   sa               sth                                     VIEW       
adventureworks   pr               th                                      VIEW       
adventureworks   pr               tha                                     VIEW       
adventureworks   sa               tr                                      VIEW       
adventureworks   pr               um                                      VIEW       
adventureworks   pu               v                                       VIEW       
adventureworks   person           vadditionalcontactinfo                  VIEW       
adventureworks   humanresources   vemployee                               VIEW       
adventureworks   humanresources   vemployeedepartment                     VIEW       
adventureworks   humanresources   vemployeedepartmenthistory              VIEW       
adventureworks   sales            vindividualcustomer                     VIEW       
adventureworks   humanresources   vjobcandidate                           VIEW       
adventureworks   humanresources   vjobcandidateeducation                  VIEW       
adventureworks   humanresources   vjobcandidateemployment                 VIEW       
adventureworks   sales            vpersondemographics                     VIEW       
adventureworks   production       vproductmodelcatalogdescription         VIEW       
adventureworks   production       vproductmodelinstructions               VIEW       
adventureworks   sales            vsalesperson                            VIEW       
adventureworks   sales            vsalespersonsalesbyfiscalyears          VIEW       
adventureworks   sales            vsalespersonsalesbyfiscalyearsdata      VIEW       
adventureworks   sales            vstorewithaddresses                     VIEW       
adventureworks   sales            vstorewithcontacts                      VIEW       
adventureworks   sales            vstorewithdemographics                  VIEW       
adventureworks   purchasing       vvendorwithaddresses                    VIEW       
adventureworks   purchasing       vvendorwithcontacts                     VIEW       
adventureworks   pr               w                                       VIEW       
adventureworks   pr               wr                                      VIEW       

## What columns do those tables contain?

Of course, the `DBI` package has a `dbListFields` function that provides the simplest way to get the minimum, a list of column names:

```r
# DBI::dbListFields(con, "rental")
```

But the `information_schema` has a lot more useful information that we can use.  

```r
columns_info_schema_table <- tbl(con, dbplyr::in_schema("information_schema", "columns"))
```

Since the `information_schema` contains 2951 columns, we are narrowing our focus to just one table.  This query retrieves more information about the `rental` table:

```r
columns_info_schema_info <- columns_info_schema_table %>%
  # filter(table_schema == "public") %>%
  select(
    table_catalog, table_schema, table_name, column_name, data_type, ordinal_position,
    character_maximum_length, column_default, numeric_precision, numeric_precision_radix
  ) %>%
  collect(n = Inf) %>%
  mutate(data_type = case_when(
    data_type == "character varying" ~ paste0(data_type, " (", character_maximum_length, ")"),
    data_type == "real" ~ paste0(data_type, " (", numeric_precision, ",", numeric_precision_radix, ")"),
    TRUE ~ data_type
  )) %>%
  # filter(table_name == "rental") %>%
  select(-table_schema, -numeric_precision, -numeric_precision_radix)

glimpse(columns_info_schema_info)
```

```
## Observations: 2,951
## Variables: 7
## $ table_catalog            <chr> "adventureworks", "adventureworks", "ad…
## $ table_name               <chr> "pg_proc", "pg_proc", "pg_proc", "pg_pr…
## $ column_name              <chr> "proname", "pronamespace", "proowner", …
## $ data_type                <chr> "name", "oid", "oid", "oid", "real (24,…
## $ ordinal_position         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, …
## $ character_maximum_length <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
## $ column_default           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
```

```r
kable(columns_info_schema_info)
```



table_catalog    table_name                              column_name                           data_type                      ordinal_position   character_maximum_length  column_default                                                                
---------------  --------------------------------------  ------------------------------------  ----------------------------  -----------------  -------------------------  ------------------------------------------------------------------------------
adventureworks   pg_proc                                 proname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_proc                                 pronamespace                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_proc                                 proowner                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_proc                                 prolang                               oid                                           4                         NA  NA                                                                            
adventureworks   pg_proc                                 procost                               real (24,2)                                   5                         NA  NA                                                                            
adventureworks   pg_proc                                 prorows                               real (24,2)                                   6                         NA  NA                                                                            
adventureworks   pg_proc                                 provariadic                           oid                                           7                         NA  NA                                                                            
adventureworks   pg_proc                                 protransform                          regproc                                       8                         NA  NA                                                                            
adventureworks   pg_proc                                 proisagg                              boolean                                       9                         NA  NA                                                                            
adventureworks   pg_proc                                 proiswindow                           boolean                                      10                         NA  NA                                                                            
adventureworks   pg_proc                                 prosecdef                             boolean                                      11                         NA  NA                                                                            
adventureworks   pg_proc                                 proleakproof                          boolean                                      12                         NA  NA                                                                            
adventureworks   pg_proc                                 proisstrict                           boolean                                      13                         NA  NA                                                                            
adventureworks   pg_proc                                 proretset                             boolean                                      14                         NA  NA                                                                            
adventureworks   pg_proc                                 provolatile                           "char"                                       15                         NA  NA                                                                            
adventureworks   pg_proc                                 proparallel                           "char"                                       16                         NA  NA                                                                            
adventureworks   pg_proc                                 pronargs                              smallint                                     17                         NA  NA                                                                            
adventureworks   pg_proc                                 pronargdefaults                       smallint                                     18                         NA  NA                                                                            
adventureworks   pg_proc                                 prorettype                            oid                                          19                         NA  NA                                                                            
adventureworks   pg_proc                                 proargtypes                           ARRAY                                        20                         NA  NA                                                                            
adventureworks   pg_proc                                 proallargtypes                        ARRAY                                        21                         NA  NA                                                                            
adventureworks   pg_proc                                 proargmodes                           ARRAY                                        22                         NA  NA                                                                            
adventureworks   pg_proc                                 proargnames                           ARRAY                                        23                         NA  NA                                                                            
adventureworks   pg_proc                                 proargdefaults                        pg_node_tree                                 24                         NA  NA                                                                            
adventureworks   pg_proc                                 protrftypes                           ARRAY                                        25                         NA  NA                                                                            
adventureworks   pg_proc                                 prosrc                                text                                         26                         NA  NA                                                                            
adventureworks   pg_proc                                 probin                                text                                         27                         NA  NA                                                                            
adventureworks   pg_proc                                 proconfig                             ARRAY                                        28                         NA  NA                                                                            
adventureworks   pg_proc                                 proacl                                ARRAY                                        29                         NA  NA                                                                            
adventureworks   pg_type                                 typname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_type                                 typnamespace                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_type                                 typowner                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_type                                 typlen                                smallint                                      4                         NA  NA                                                                            
adventureworks   pg_type                                 typbyval                              boolean                                       5                         NA  NA                                                                            
adventureworks   pg_type                                 typtype                               "char"                                        6                         NA  NA                                                                            
adventureworks   pg_type                                 typcategory                           "char"                                        7                         NA  NA                                                                            
adventureworks   pg_type                                 typispreferred                        boolean                                       8                         NA  NA                                                                            
adventureworks   pg_type                                 typisdefined                          boolean                                       9                         NA  NA                                                                            
adventureworks   pg_type                                 typdelim                              "char"                                       10                         NA  NA                                                                            
adventureworks   pg_type                                 typrelid                              oid                                          11                         NA  NA                                                                            
adventureworks   pg_type                                 typelem                               oid                                          12                         NA  NA                                                                            
adventureworks   pg_type                                 typarray                              oid                                          13                         NA  NA                                                                            
adventureworks   pg_type                                 typinput                              regproc                                      14                         NA  NA                                                                            
adventureworks   pg_type                                 typoutput                             regproc                                      15                         NA  NA                                                                            
adventureworks   pg_type                                 typreceive                            regproc                                      16                         NA  NA                                                                            
adventureworks   pg_type                                 typsend                               regproc                                      17                         NA  NA                                                                            
adventureworks   pg_type                                 typmodin                              regproc                                      18                         NA  NA                                                                            
adventureworks   pg_type                                 typmodout                             regproc                                      19                         NA  NA                                                                            
adventureworks   pg_type                                 typanalyze                            regproc                                      20                         NA  NA                                                                            
adventureworks   pg_type                                 typalign                              "char"                                       21                         NA  NA                                                                            
adventureworks   pg_type                                 typstorage                            "char"                                       22                         NA  NA                                                                            
adventureworks   pg_type                                 typnotnull                            boolean                                      23                         NA  NA                                                                            
adventureworks   pg_type                                 typbasetype                           oid                                          24                         NA  NA                                                                            
adventureworks   pg_type                                 typtypmod                             integer                                      25                         NA  NA                                                                            
adventureworks   pg_type                                 typndims                              integer                                      26                         NA  NA                                                                            
adventureworks   pg_type                                 typcollation                          oid                                          27                         NA  NA                                                                            
adventureworks   pg_type                                 typdefaultbin                         pg_node_tree                                 28                         NA  NA                                                                            
adventureworks   pg_type                                 typdefault                            text                                         29                         NA  NA                                                                            
adventureworks   pg_type                                 typacl                                ARRAY                                        30                         NA  NA                                                                            
adventureworks   pg_attribute                            attrelid                              oid                                           1                         NA  NA                                                                            
adventureworks   pg_attribute                            attname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_attribute                            atttypid                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_attribute                            attstattarget                         integer                                       4                         NA  NA                                                                            
adventureworks   pg_attribute                            attlen                                smallint                                      5                         NA  NA                                                                            
adventureworks   pg_attribute                            attnum                                smallint                                      6                         NA  NA                                                                            
adventureworks   pg_attribute                            attndims                              integer                                       7                         NA  NA                                                                            
adventureworks   pg_attribute                            attcacheoff                           integer                                       8                         NA  NA                                                                            
adventureworks   pg_attribute                            atttypmod                             integer                                       9                         NA  NA                                                                            
adventureworks   pg_attribute                            attbyval                              boolean                                      10                         NA  NA                                                                            
adventureworks   pg_attribute                            attstorage                            "char"                                       11                         NA  NA                                                                            
adventureworks   pg_attribute                            attalign                              "char"                                       12                         NA  NA                                                                            
adventureworks   pg_attribute                            attnotnull                            boolean                                      13                         NA  NA                                                                            
adventureworks   pg_attribute                            atthasdef                             boolean                                      14                         NA  NA                                                                            
adventureworks   pg_attribute                            attidentity                           "char"                                       15                         NA  NA                                                                            
adventureworks   pg_attribute                            attisdropped                          boolean                                      16                         NA  NA                                                                            
adventureworks   pg_attribute                            attislocal                            boolean                                      17                         NA  NA                                                                            
adventureworks   pg_attribute                            attinhcount                           integer                                      18                         NA  NA                                                                            
adventureworks   pg_attribute                            attcollation                          oid                                          19                         NA  NA                                                                            
adventureworks   pg_attribute                            attacl                                ARRAY                                        20                         NA  NA                                                                            
adventureworks   pg_attribute                            attoptions                            ARRAY                                        21                         NA  NA                                                                            
adventureworks   pg_attribute                            attfdwoptions                         ARRAY                                        22                         NA  NA                                                                            
adventureworks   pg_class                                relname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_class                                relnamespace                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_class                                reltype                               oid                                           3                         NA  NA                                                                            
adventureworks   pg_class                                reloftype                             oid                                           4                         NA  NA                                                                            
adventureworks   pg_class                                relowner                              oid                                           5                         NA  NA                                                                            
adventureworks   pg_class                                relam                                 oid                                           6                         NA  NA                                                                            
adventureworks   pg_class                                relfilenode                           oid                                           7                         NA  NA                                                                            
adventureworks   pg_class                                reltablespace                         oid                                           8                         NA  NA                                                                            
adventureworks   pg_class                                relpages                              integer                                       9                         NA  NA                                                                            
adventureworks   pg_class                                reltuples                             real (24,2)                                  10                         NA  NA                                                                            
adventureworks   pg_class                                relallvisible                         integer                                      11                         NA  NA                                                                            
adventureworks   pg_class                                reltoastrelid                         oid                                          12                         NA  NA                                                                            
adventureworks   pg_class                                relhasindex                           boolean                                      13                         NA  NA                                                                            
adventureworks   pg_class                                relisshared                           boolean                                      14                         NA  NA                                                                            
adventureworks   pg_class                                relpersistence                        "char"                                       15                         NA  NA                                                                            
adventureworks   pg_class                                relkind                               "char"                                       16                         NA  NA                                                                            
adventureworks   pg_class                                relnatts                              smallint                                     17                         NA  NA                                                                            
adventureworks   pg_class                                relchecks                             smallint                                     18                         NA  NA                                                                            
adventureworks   pg_class                                relhasoids                            boolean                                      19                         NA  NA                                                                            
adventureworks   pg_class                                relhaspkey                            boolean                                      20                         NA  NA                                                                            
adventureworks   pg_class                                relhasrules                           boolean                                      21                         NA  NA                                                                            
adventureworks   pg_class                                relhastriggers                        boolean                                      22                         NA  NA                                                                            
adventureworks   pg_class                                relhassubclass                        boolean                                      23                         NA  NA                                                                            
adventureworks   pg_class                                relrowsecurity                        boolean                                      24                         NA  NA                                                                            
adventureworks   pg_class                                relforcerowsecurity                   boolean                                      25                         NA  NA                                                                            
adventureworks   pg_class                                relispopulated                        boolean                                      26                         NA  NA                                                                            
adventureworks   pg_class                                relreplident                          "char"                                       27                         NA  NA                                                                            
adventureworks   pg_class                                relispartition                        boolean                                      28                         NA  NA                                                                            
adventureworks   pg_class                                relfrozenxid                          xid                                          29                         NA  NA                                                                            
adventureworks   pg_class                                relminmxid                            xid                                          30                         NA  NA                                                                            
adventureworks   pg_class                                relacl                                ARRAY                                        31                         NA  NA                                                                            
adventureworks   pg_class                                reloptions                            ARRAY                                        32                         NA  NA                                                                            
adventureworks   pg_class                                relpartbound                          pg_node_tree                                 33                         NA  NA                                                                            
adventureworks   pg_attrdef                              adrelid                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_attrdef                              adnum                                 smallint                                      2                         NA  NA                                                                            
adventureworks   pg_attrdef                              adbin                                 pg_node_tree                                  3                         NA  NA                                                                            
adventureworks   pg_attrdef                              adsrc                                 text                                          4                         NA  NA                                                                            
adventureworks   pg_constraint                           conname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_constraint                           connamespace                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_constraint                           contype                               "char"                                        3                         NA  NA                                                                            
adventureworks   pg_constraint                           condeferrable                         boolean                                       4                         NA  NA                                                                            
adventureworks   pg_constraint                           condeferred                           boolean                                       5                         NA  NA                                                                            
adventureworks   pg_constraint                           convalidated                          boolean                                       6                         NA  NA                                                                            
adventureworks   pg_constraint                           conrelid                              oid                                           7                         NA  NA                                                                            
adventureworks   pg_constraint                           contypid                              oid                                           8                         NA  NA                                                                            
adventureworks   pg_constraint                           conindid                              oid                                           9                         NA  NA                                                                            
adventureworks   pg_constraint                           confrelid                             oid                                          10                         NA  NA                                                                            
adventureworks   pg_constraint                           confupdtype                           "char"                                       11                         NA  NA                                                                            
adventureworks   pg_constraint                           confdeltype                           "char"                                       12                         NA  NA                                                                            
adventureworks   pg_constraint                           confmatchtype                         "char"                                       13                         NA  NA                                                                            
adventureworks   pg_constraint                           conislocal                            boolean                                      14                         NA  NA                                                                            
adventureworks   pg_constraint                           coninhcount                           integer                                      15                         NA  NA                                                                            
adventureworks   pg_constraint                           connoinherit                          boolean                                      16                         NA  NA                                                                            
adventureworks   pg_constraint                           conkey                                ARRAY                                        17                         NA  NA                                                                            
adventureworks   pg_constraint                           confkey                               ARRAY                                        18                         NA  NA                                                                            
adventureworks   pg_constraint                           conpfeqop                             ARRAY                                        19                         NA  NA                                                                            
adventureworks   pg_constraint                           conppeqop                             ARRAY                                        20                         NA  NA                                                                            
adventureworks   pg_constraint                           conffeqop                             ARRAY                                        21                         NA  NA                                                                            
adventureworks   pg_constraint                           conexclop                             ARRAY                                        22                         NA  NA                                                                            
adventureworks   pg_constraint                           conbin                                pg_node_tree                                 23                         NA  NA                                                                            
adventureworks   pg_constraint                           consrc                                text                                         24                         NA  NA                                                                            
adventureworks   pg_inherits                             inhrelid                              oid                                           1                         NA  NA                                                                            
adventureworks   pg_inherits                             inhparent                             oid                                           2                         NA  NA                                                                            
adventureworks   pg_inherits                             inhseqno                              integer                                       3                         NA  NA                                                                            
adventureworks   pg_index                                indexrelid                            oid                                           1                         NA  NA                                                                            
adventureworks   pg_index                                indrelid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_index                                indnatts                              smallint                                      3                         NA  NA                                                                            
adventureworks   pg_index                                indisunique                           boolean                                       4                         NA  NA                                                                            
adventureworks   pg_index                                indisprimary                          boolean                                       5                         NA  NA                                                                            
adventureworks   pg_index                                indisexclusion                        boolean                                       6                         NA  NA                                                                            
adventureworks   pg_index                                indimmediate                          boolean                                       7                         NA  NA                                                                            
adventureworks   pg_index                                indisclustered                        boolean                                       8                         NA  NA                                                                            
adventureworks   pg_index                                indisvalid                            boolean                                       9                         NA  NA                                                                            
adventureworks   pg_index                                indcheckxmin                          boolean                                      10                         NA  NA                                                                            
adventureworks   pg_index                                indisready                            boolean                                      11                         NA  NA                                                                            
adventureworks   pg_index                                indislive                             boolean                                      12                         NA  NA                                                                            
adventureworks   pg_index                                indisreplident                        boolean                                      13                         NA  NA                                                                            
adventureworks   pg_index                                indkey                                ARRAY                                        14                         NA  NA                                                                            
adventureworks   pg_index                                indcollation                          ARRAY                                        15                         NA  NA                                                                            
adventureworks   pg_index                                indclass                              ARRAY                                        16                         NA  NA                                                                            
adventureworks   pg_index                                indoption                             ARRAY                                        17                         NA  NA                                                                            
adventureworks   pg_index                                indexprs                              pg_node_tree                                 18                         NA  NA                                                                            
adventureworks   pg_index                                indpred                               pg_node_tree                                 19                         NA  NA                                                                            
adventureworks   pg_operator                             oprname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_operator                             oprnamespace                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_operator                             oprowner                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_operator                             oprkind                               "char"                                        4                         NA  NA                                                                            
adventureworks   pg_operator                             oprcanmerge                           boolean                                       5                         NA  NA                                                                            
adventureworks   pg_operator                             oprcanhash                            boolean                                       6                         NA  NA                                                                            
adventureworks   pg_operator                             oprleft                               oid                                           7                         NA  NA                                                                            
adventureworks   pg_operator                             oprright                              oid                                           8                         NA  NA                                                                            
adventureworks   pg_operator                             oprresult                             oid                                           9                         NA  NA                                                                            
adventureworks   pg_operator                             oprcom                                oid                                          10                         NA  NA                                                                            
adventureworks   pg_operator                             oprnegate                             oid                                          11                         NA  NA                                                                            
adventureworks   pg_operator                             oprcode                               regproc                                      12                         NA  NA                                                                            
adventureworks   pg_operator                             oprrest                               regproc                                      13                         NA  NA                                                                            
adventureworks   pg_operator                             oprjoin                               regproc                                      14                         NA  NA                                                                            
adventureworks   pg_opfamily                             opfmethod                             oid                                           1                         NA  NA                                                                            
adventureworks   pg_opfamily                             opfname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_opfamily                             opfnamespace                          oid                                           3                         NA  NA                                                                            
adventureworks   pg_opfamily                             opfowner                              oid                                           4                         NA  NA                                                                            
adventureworks   pg_opclass                              opcmethod                             oid                                           1                         NA  NA                                                                            
adventureworks   pg_opclass                              opcname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_opclass                              opcnamespace                          oid                                           3                         NA  NA                                                                            
adventureworks   pg_opclass                              opcowner                              oid                                           4                         NA  NA                                                                            
adventureworks   pg_opclass                              opcfamily                             oid                                           5                         NA  NA                                                                            
adventureworks   pg_opclass                              opcintype                             oid                                           6                         NA  NA                                                                            
adventureworks   pg_opclass                              opcdefault                            boolean                                       7                         NA  NA                                                                            
adventureworks   pg_opclass                              opckeytype                            oid                                           8                         NA  NA                                                                            
adventureworks   pg_am                                   amname                                name                                          1                         NA  NA                                                                            
adventureworks   pg_am                                   amhandler                             regproc                                       2                         NA  NA                                                                            
adventureworks   pg_am                                   amtype                                "char"                                        3                         NA  NA                                                                            
adventureworks   pg_amop                                 amopfamily                            oid                                           1                         NA  NA                                                                            
adventureworks   pg_amop                                 amoplefttype                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_amop                                 amoprighttype                         oid                                           3                         NA  NA                                                                            
adventureworks   pg_amop                                 amopstrategy                          smallint                                      4                         NA  NA                                                                            
adventureworks   pg_amop                                 amoppurpose                           "char"                                        5                         NA  NA                                                                            
adventureworks   pg_amop                                 amopopr                               oid                                           6                         NA  NA                                                                            
adventureworks   pg_amop                                 amopmethod                            oid                                           7                         NA  NA                                                                            
adventureworks   pg_amop                                 amopsortfamily                        oid                                           8                         NA  NA                                                                            
adventureworks   pg_amproc                               amprocfamily                          oid                                           1                         NA  NA                                                                            
adventureworks   pg_amproc                               amproclefttype                        oid                                           2                         NA  NA                                                                            
adventureworks   pg_amproc                               amprocrighttype                       oid                                           3                         NA  NA                                                                            
adventureworks   pg_amproc                               amprocnum                             smallint                                      4                         NA  NA                                                                            
adventureworks   pg_amproc                               amproc                                regproc                                       5                         NA  NA                                                                            
adventureworks   pg_language                             lanname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_language                             lanowner                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_language                             lanispl                               boolean                                       3                         NA  NA                                                                            
adventureworks   pg_language                             lanpltrusted                          boolean                                       4                         NA  NA                                                                            
adventureworks   pg_language                             lanplcallfoid                         oid                                           5                         NA  NA                                                                            
adventureworks   pg_language                             laninline                             oid                                           6                         NA  NA                                                                            
adventureworks   pg_language                             lanvalidator                          oid                                           7                         NA  NA                                                                            
adventureworks   pg_language                             lanacl                                ARRAY                                         8                         NA  NA                                                                            
adventureworks   pg_largeobject_metadata                 lomowner                              oid                                           1                         NA  NA                                                                            
adventureworks   pg_largeobject_metadata                 lomacl                                ARRAY                                         2                         NA  NA                                                                            
adventureworks   pg_largeobject                          loid                                  oid                                           1                         NA  NA                                                                            
adventureworks   pg_largeobject                          pageno                                integer                                       2                         NA  NA                                                                            
adventureworks   pg_largeobject                          data                                  bytea                                         3                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggfnoid                              regproc                                       1                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggkind                               "char"                                        2                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggnumdirectargs                      smallint                                      3                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggtransfn                            regproc                                       4                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggfinalfn                            regproc                                       5                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggcombinefn                          regproc                                       6                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggserialfn                           regproc                                       7                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggdeserialfn                         regproc                                       8                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggmtransfn                           regproc                                       9                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggminvtransfn                        regproc                                      10                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggmfinalfn                           regproc                                      11                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggfinalextra                         boolean                                      12                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggmfinalextra                        boolean                                      13                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggsortop                             oid                                          14                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggtranstype                          oid                                          15                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggtransspace                         integer                                      16                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggmtranstype                         oid                                          17                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggmtransspace                        integer                                      18                         NA  NA                                                                            
adventureworks   pg_aggregate                            agginitval                            text                                         19                         NA  NA                                                                            
adventureworks   pg_aggregate                            aggminitval                           text                                         20                         NA  NA                                                                            
adventureworks   pg_statistic_ext                        stxrelid                              oid                                           1                         NA  NA                                                                            
adventureworks   pg_statistic_ext                        stxname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_statistic_ext                        stxnamespace                          oid                                           3                         NA  NA                                                                            
adventureworks   pg_statistic_ext                        stxowner                              oid                                           4                         NA  NA                                                                            
adventureworks   pg_statistic_ext                        stxkeys                               ARRAY                                         5                         NA  NA                                                                            
adventureworks   pg_statistic_ext                        stxkind                               ARRAY                                         6                         NA  NA                                                                            
adventureworks   pg_statistic_ext                        stxndistinct                          pg_ndistinct                                  7                         NA  NA                                                                            
adventureworks   pg_statistic_ext                        stxdependencies                       pg_dependencies                               8                         NA  NA                                                                            
adventureworks   pg_statistic                            starelid                              oid                                           1                         NA  NA                                                                            
adventureworks   pg_statistic                            staattnum                             smallint                                      2                         NA  NA                                                                            
adventureworks   pg_statistic                            stainherit                            boolean                                       3                         NA  NA                                                                            
adventureworks   pg_statistic                            stanullfrac                           real (24,2)                                   4                         NA  NA                                                                            
adventureworks   pg_statistic                            stawidth                              integer                                       5                         NA  NA                                                                            
adventureworks   pg_statistic                            stadistinct                           real (24,2)                                   6                         NA  NA                                                                            
adventureworks   pg_statistic                            stakind1                              smallint                                      7                         NA  NA                                                                            
adventureworks   pg_statistic                            stakind2                              smallint                                      8                         NA  NA                                                                            
adventureworks   pg_statistic                            stakind3                              smallint                                      9                         NA  NA                                                                            
adventureworks   pg_statistic                            stakind4                              smallint                                     10                         NA  NA                                                                            
adventureworks   pg_statistic                            stakind5                              smallint                                     11                         NA  NA                                                                            
adventureworks   pg_statistic                            staop1                                oid                                          12                         NA  NA                                                                            
adventureworks   pg_statistic                            staop2                                oid                                          13                         NA  NA                                                                            
adventureworks   pg_statistic                            staop3                                oid                                          14                         NA  NA                                                                            
adventureworks   pg_statistic                            staop4                                oid                                          15                         NA  NA                                                                            
adventureworks   pg_statistic                            staop5                                oid                                          16                         NA  NA                                                                            
adventureworks   pg_statistic                            stanumbers1                           ARRAY                                        17                         NA  NA                                                                            
adventureworks   pg_statistic                            stanumbers2                           ARRAY                                        18                         NA  NA                                                                            
adventureworks   pg_statistic                            stanumbers3                           ARRAY                                        19                         NA  NA                                                                            
adventureworks   pg_statistic                            stanumbers4                           ARRAY                                        20                         NA  NA                                                                            
adventureworks   pg_statistic                            stanumbers5                           ARRAY                                        21                         NA  NA                                                                            
adventureworks   pg_statistic                            stavalues1                            anyarray                                     22                         NA  NA                                                                            
adventureworks   pg_statistic                            stavalues2                            anyarray                                     23                         NA  NA                                                                            
adventureworks   pg_statistic                            stavalues3                            anyarray                                     24                         NA  NA                                                                            
adventureworks   pg_statistic                            stavalues4                            anyarray                                     25                         NA  NA                                                                            
adventureworks   pg_statistic                            stavalues5                            anyarray                                     26                         NA  NA                                                                            
adventureworks   pg_rewrite                              rulename                              name                                          1                         NA  NA                                                                            
adventureworks   pg_rewrite                              ev_class                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_rewrite                              ev_type                               "char"                                        3                         NA  NA                                                                            
adventureworks   pg_rewrite                              ev_enabled                            "char"                                        4                         NA  NA                                                                            
adventureworks   pg_rewrite                              is_instead                            boolean                                       5                         NA  NA                                                                            
adventureworks   pg_rewrite                              ev_qual                               pg_node_tree                                  6                         NA  NA                                                                            
adventureworks   pg_rewrite                              ev_action                             pg_node_tree                                  7                         NA  NA                                                                            
adventureworks   pg_trigger                              tgrelid                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_trigger                              tgname                                name                                          2                         NA  NA                                                                            
adventureworks   pg_trigger                              tgfoid                                oid                                           3                         NA  NA                                                                            
adventureworks   pg_trigger                              tgtype                                smallint                                      4                         NA  NA                                                                            
adventureworks   pg_trigger                              tgenabled                             "char"                                        5                         NA  NA                                                                            
adventureworks   pg_trigger                              tgisinternal                          boolean                                       6                         NA  NA                                                                            
adventureworks   pg_trigger                              tgconstrrelid                         oid                                           7                         NA  NA                                                                            
adventureworks   pg_trigger                              tgconstrindid                         oid                                           8                         NA  NA                                                                            
adventureworks   pg_trigger                              tgconstraint                          oid                                           9                         NA  NA                                                                            
adventureworks   pg_trigger                              tgdeferrable                          boolean                                      10                         NA  NA                                                                            
adventureworks   pg_trigger                              tginitdeferred                        boolean                                      11                         NA  NA                                                                            
adventureworks   pg_trigger                              tgnargs                               smallint                                     12                         NA  NA                                                                            
adventureworks   pg_trigger                              tgattr                                ARRAY                                        13                         NA  NA                                                                            
adventureworks   pg_trigger                              tgargs                                bytea                                        14                         NA  NA                                                                            
adventureworks   pg_trigger                              tgqual                                pg_node_tree                                 15                         NA  NA                                                                            
adventureworks   pg_trigger                              tgoldtable                            name                                         16                         NA  NA                                                                            
adventureworks   pg_trigger                              tgnewtable                            name                                         17                         NA  NA                                                                            
adventureworks   pg_event_trigger                        evtname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_event_trigger                        evtevent                              name                                          2                         NA  NA                                                                            
adventureworks   pg_event_trigger                        evtowner                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_event_trigger                        evtfoid                               oid                                           4                         NA  NA                                                                            
adventureworks   pg_event_trigger                        evtenabled                            "char"                                        5                         NA  NA                                                                            
adventureworks   pg_event_trigger                        evttags                               ARRAY                                         6                         NA  NA                                                                            
adventureworks   pg_description                          objoid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_description                          classoid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_description                          objsubid                              integer                                       3                         NA  NA                                                                            
adventureworks   pg_description                          description                           text                                          4                         NA  NA                                                                            
adventureworks   pg_cast                                 castsource                            oid                                           1                         NA  NA                                                                            
adventureworks   pg_cast                                 casttarget                            oid                                           2                         NA  NA                                                                            
adventureworks   pg_cast                                 castfunc                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_cast                                 castcontext                           "char"                                        4                         NA  NA                                                                            
adventureworks   pg_cast                                 castmethod                            "char"                                        5                         NA  NA                                                                            
adventureworks   pg_enum                                 enumtypid                             oid                                           1                         NA  NA                                                                            
adventureworks   pg_enum                                 enumsortorder                         real (24,2)                                   2                         NA  NA                                                                            
adventureworks   pg_enum                                 enumlabel                             name                                          3                         NA  NA                                                                            
adventureworks   pg_namespace                            nspname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_namespace                            nspowner                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_namespace                            nspacl                                ARRAY                                         3                         NA  NA                                                                            
adventureworks   pg_conversion                           conname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_conversion                           connamespace                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_conversion                           conowner                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_conversion                           conforencoding                        integer                                       4                         NA  NA                                                                            
adventureworks   pg_conversion                           contoencoding                         integer                                       5                         NA  NA                                                                            
adventureworks   pg_conversion                           conproc                               regproc                                       6                         NA  NA                                                                            
adventureworks   pg_conversion                           condefault                            boolean                                       7                         NA  NA                                                                            
adventureworks   pg_depend                               classid                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_depend                               objid                                 oid                                           2                         NA  NA                                                                            
adventureworks   pg_depend                               objsubid                              integer                                       3                         NA  NA                                                                            
adventureworks   pg_depend                               refclassid                            oid                                           4                         NA  NA                                                                            
adventureworks   pg_depend                               refobjid                              oid                                           5                         NA  NA                                                                            
adventureworks   pg_depend                               refobjsubid                           integer                                       6                         NA  NA                                                                            
adventureworks   pg_depend                               deptype                               "char"                                        7                         NA  NA                                                                            
adventureworks   pg_database                             datname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_database                             datdba                                oid                                           2                         NA  NA                                                                            
adventureworks   pg_database                             encoding                              integer                                       3                         NA  NA                                                                            
adventureworks   pg_database                             datcollate                            name                                          4                         NA  NA                                                                            
adventureworks   pg_database                             datctype                              name                                          5                         NA  NA                                                                            
adventureworks   pg_database                             datistemplate                         boolean                                       6                         NA  NA                                                                            
adventureworks   pg_database                             datallowconn                          boolean                                       7                         NA  NA                                                                            
adventureworks   pg_database                             datconnlimit                          integer                                       8                         NA  NA                                                                            
adventureworks   pg_database                             datlastsysoid                         oid                                           9                         NA  NA                                                                            
adventureworks   pg_database                             datfrozenxid                          xid                                          10                         NA  NA                                                                            
adventureworks   pg_database                             datminmxid                            xid                                          11                         NA  NA                                                                            
adventureworks   pg_database                             dattablespace                         oid                                          12                         NA  NA                                                                            
adventureworks   pg_database                             datacl                                ARRAY                                        13                         NA  NA                                                                            
adventureworks   pg_db_role_setting                      setdatabase                           oid                                           1                         NA  NA                                                                            
adventureworks   pg_db_role_setting                      setrole                               oid                                           2                         NA  NA                                                                            
adventureworks   pg_db_role_setting                      setconfig                             ARRAY                                         3                         NA  NA                                                                            
adventureworks   pg_tablespace                           spcname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_tablespace                           spcowner                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_tablespace                           spcacl                                ARRAY                                         3                         NA  NA                                                                            
adventureworks   pg_tablespace                           spcoptions                            ARRAY                                         4                         NA  NA                                                                            
adventureworks   pg_pltemplate                           tmplname                              name                                          1                         NA  NA                                                                            
adventureworks   pg_pltemplate                           tmpltrusted                           boolean                                       2                         NA  NA                                                                            
adventureworks   pg_pltemplate                           tmpldbacreate                         boolean                                       3                         NA  NA                                                                            
adventureworks   pg_pltemplate                           tmplhandler                           text                                          4                         NA  NA                                                                            
adventureworks   pg_pltemplate                           tmplinline                            text                                          5                         NA  NA                                                                            
adventureworks   pg_pltemplate                           tmplvalidator                         text                                          6                         NA  NA                                                                            
adventureworks   pg_pltemplate                           tmpllibrary                           text                                          7                         NA  NA                                                                            
adventureworks   pg_pltemplate                           tmplacl                               ARRAY                                         8                         NA  NA                                                                            
adventureworks   pg_authid                               rolname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_authid                               rolsuper                              boolean                                       2                         NA  NA                                                                            
adventureworks   pg_authid                               rolinherit                            boolean                                       3                         NA  NA                                                                            
adventureworks   pg_authid                               rolcreaterole                         boolean                                       4                         NA  NA                                                                            
adventureworks   pg_authid                               rolcreatedb                           boolean                                       5                         NA  NA                                                                            
adventureworks   pg_authid                               rolcanlogin                           boolean                                       6                         NA  NA                                                                            
adventureworks   pg_authid                               rolreplication                        boolean                                       7                         NA  NA                                                                            
adventureworks   pg_authid                               rolbypassrls                          boolean                                       8                         NA  NA                                                                            
adventureworks   pg_authid                               rolconnlimit                          integer                                       9                         NA  NA                                                                            
adventureworks   pg_authid                               rolpassword                           text                                         10                         NA  NA                                                                            
adventureworks   pg_authid                               rolvaliduntil                         timestamp with time zone                     11                         NA  NA                                                                            
adventureworks   pg_auth_members                         roleid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_auth_members                         member                                oid                                           2                         NA  NA                                                                            
adventureworks   pg_auth_members                         grantor                               oid                                           3                         NA  NA                                                                            
adventureworks   pg_auth_members                         admin_option                          boolean                                       4                         NA  NA                                                                            
adventureworks   pg_shdepend                             dbid                                  oid                                           1                         NA  NA                                                                            
adventureworks   pg_shdepend                             classid                               oid                                           2                         NA  NA                                                                            
adventureworks   pg_shdepend                             objid                                 oid                                           3                         NA  NA                                                                            
adventureworks   pg_shdepend                             objsubid                              integer                                       4                         NA  NA                                                                            
adventureworks   pg_shdepend                             refclassid                            oid                                           5                         NA  NA                                                                            
adventureworks   pg_shdepend                             refobjid                              oid                                           6                         NA  NA                                                                            
adventureworks   pg_shdepend                             deptype                               "char"                                        7                         NA  NA                                                                            
adventureworks   pg_shdescription                        objoid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_shdescription                        classoid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_shdescription                        description                           text                                          3                         NA  NA                                                                            
adventureworks   pg_ts_config                            cfgname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_ts_config                            cfgnamespace                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_ts_config                            cfgowner                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_ts_config                            cfgparser                             oid                                           4                         NA  NA                                                                            
adventureworks   pg_ts_config_map                        mapcfg                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_ts_config_map                        maptokentype                          integer                                       2                         NA  NA                                                                            
adventureworks   pg_ts_config_map                        mapseqno                              integer                                       3                         NA  NA                                                                            
adventureworks   pg_ts_config_map                        mapdict                               oid                                           4                         NA  NA                                                                            
adventureworks   pg_ts_dict                              dictname                              name                                          1                         NA  NA                                                                            
adventureworks   pg_ts_dict                              dictnamespace                         oid                                           2                         NA  NA                                                                            
adventureworks   pg_ts_dict                              dictowner                             oid                                           3                         NA  NA                                                                            
adventureworks   pg_ts_dict                              dicttemplate                          oid                                           4                         NA  NA                                                                            
adventureworks   pg_ts_dict                              dictinitoption                        text                                          5                         NA  NA                                                                            
adventureworks   pg_ts_parser                            prsname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_ts_parser                            prsnamespace                          oid                                           2                         NA  NA                                                                            
adventureworks   pg_ts_parser                            prsstart                              regproc                                       3                         NA  NA                                                                            
adventureworks   pg_ts_parser                            prstoken                              regproc                                       4                         NA  NA                                                                            
adventureworks   pg_ts_parser                            prsend                                regproc                                       5                         NA  NA                                                                            
adventureworks   pg_ts_parser                            prsheadline                           regproc                                       6                         NA  NA                                                                            
adventureworks   pg_ts_parser                            prslextype                            regproc                                       7                         NA  NA                                                                            
adventureworks   pg_ts_template                          tmplname                              name                                          1                         NA  NA                                                                            
adventureworks   pg_ts_template                          tmplnamespace                         oid                                           2                         NA  NA                                                                            
adventureworks   pg_ts_template                          tmplinit                              regproc                                       3                         NA  NA                                                                            
adventureworks   pg_ts_template                          tmpllexize                            regproc                                       4                         NA  NA                                                                            
adventureworks   pg_extension                            extname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_extension                            extowner                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_extension                            extnamespace                          oid                                           3                         NA  NA                                                                            
adventureworks   pg_extension                            extrelocatable                        boolean                                       4                         NA  NA                                                                            
adventureworks   pg_extension                            extversion                            text                                          5                         NA  NA                                                                            
adventureworks   pg_extension                            extconfig                             ARRAY                                         6                         NA  NA                                                                            
adventureworks   pg_extension                            extcondition                          ARRAY                                         7                         NA  NA                                                                            
adventureworks   pg_foreign_data_wrapper                 fdwname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_foreign_data_wrapper                 fdwowner                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_foreign_data_wrapper                 fdwhandler                            oid                                           3                         NA  NA                                                                            
adventureworks   pg_foreign_data_wrapper                 fdwvalidator                          oid                                           4                         NA  NA                                                                            
adventureworks   pg_foreign_data_wrapper                 fdwacl                                ARRAY                                         5                         NA  NA                                                                            
adventureworks   pg_foreign_data_wrapper                 fdwoptions                            ARRAY                                         6                         NA  NA                                                                            
adventureworks   pg_foreign_server                       srvname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_foreign_server                       srvowner                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_foreign_server                       srvfdw                                oid                                           3                         NA  NA                                                                            
adventureworks   pg_foreign_server                       srvtype                               text                                          4                         NA  NA                                                                            
adventureworks   pg_foreign_server                       srvversion                            text                                          5                         NA  NA                                                                            
adventureworks   pg_foreign_server                       srvacl                                ARRAY                                         6                         NA  NA                                                                            
adventureworks   pg_foreign_server                       srvoptions                            ARRAY                                         7                         NA  NA                                                                            
adventureworks   pg_user_mapping                         umuser                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_user_mapping                         umserver                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_user_mapping                         umoptions                             ARRAY                                         3                         NA  NA                                                                            
adventureworks   pg_foreign_table                        ftrelid                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_foreign_table                        ftserver                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_foreign_table                        ftoptions                             ARRAY                                         3                         NA  NA                                                                            
adventureworks   pg_policy                               polname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_policy                               polrelid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_policy                               polcmd                                "char"                                        3                         NA  NA                                                                            
adventureworks   pg_policy                               polpermissive                         boolean                                       4                         NA  NA                                                                            
adventureworks   pg_policy                               polroles                              ARRAY                                         5                         NA  NA                                                                            
adventureworks   pg_policy                               polqual                               pg_node_tree                                  6                         NA  NA                                                                            
adventureworks   pg_policy                               polwithcheck                          pg_node_tree                                  7                         NA  NA                                                                            
adventureworks   pg_replication_origin                   roident                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_replication_origin                   roname                                text                                          2                         NA  NA                                                                            
adventureworks   pg_default_acl                          defaclrole                            oid                                           1                         NA  NA                                                                            
adventureworks   pg_default_acl                          defaclnamespace                       oid                                           2                         NA  NA                                                                            
adventureworks   pg_default_acl                          defaclobjtype                         "char"                                        3                         NA  NA                                                                            
adventureworks   pg_default_acl                          defaclacl                             ARRAY                                         4                         NA  NA                                                                            
adventureworks   pg_init_privs                           objoid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_init_privs                           classoid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_init_privs                           objsubid                              integer                                       3                         NA  NA                                                                            
adventureworks   pg_init_privs                           privtype                              "char"                                        4                         NA  NA                                                                            
adventureworks   pg_init_privs                           initprivs                             ARRAY                                         5                         NA  NA                                                                            
adventureworks   pg_seclabel                             objoid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_seclabel                             classoid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_seclabel                             objsubid                              integer                                       3                         NA  NA                                                                            
adventureworks   pg_seclabel                             provider                              text                                          4                         NA  NA                                                                            
adventureworks   pg_seclabel                             label                                 text                                          5                         NA  NA                                                                            
adventureworks   pg_shseclabel                           objoid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_shseclabel                           classoid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_shseclabel                           provider                              text                                          3                         NA  NA                                                                            
adventureworks   pg_shseclabel                           label                                 text                                          4                         NA  NA                                                                            
adventureworks   pg_collation                            collname                              name                                          1                         NA  NA                                                                            
adventureworks   pg_collation                            collnamespace                         oid                                           2                         NA  NA                                                                            
adventureworks   pg_collation                            collowner                             oid                                           3                         NA  NA                                                                            
adventureworks   pg_collation                            collprovider                          "char"                                        4                         NA  NA                                                                            
adventureworks   pg_collation                            collencoding                          integer                                       5                         NA  NA                                                                            
adventureworks   pg_collation                            collcollate                           name                                          6                         NA  NA                                                                            
adventureworks   pg_collation                            collctype                             name                                          7                         NA  NA                                                                            
adventureworks   pg_collation                            collversion                           text                                          8                         NA  NA                                                                            
adventureworks   pg_partitioned_table                    partrelid                             oid                                           1                         NA  NA                                                                            
adventureworks   pg_partitioned_table                    partstrat                             "char"                                        2                         NA  NA                                                                            
adventureworks   pg_partitioned_table                    partnatts                             smallint                                      3                         NA  NA                                                                            
adventureworks   pg_partitioned_table                    partattrs                             ARRAY                                         4                         NA  NA                                                                            
adventureworks   pg_partitioned_table                    partclass                             ARRAY                                         5                         NA  NA                                                                            
adventureworks   pg_partitioned_table                    partcollation                         ARRAY                                         6                         NA  NA                                                                            
adventureworks   pg_partitioned_table                    partexprs                             pg_node_tree                                  7                         NA  NA                                                                            
adventureworks   pg_range                                rngtypid                              oid                                           1                         NA  NA                                                                            
adventureworks   pg_range                                rngsubtype                            oid                                           2                         NA  NA                                                                            
adventureworks   pg_range                                rngcollation                          oid                                           3                         NA  NA                                                                            
adventureworks   pg_range                                rngsubopc                             oid                                           4                         NA  NA                                                                            
adventureworks   pg_range                                rngcanonical                          regproc                                       5                         NA  NA                                                                            
adventureworks   pg_range                                rngsubdiff                            regproc                                       6                         NA  NA                                                                            
adventureworks   pg_transform                            trftype                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_transform                            trflang                               oid                                           2                         NA  NA                                                                            
adventureworks   pg_transform                            trffromsql                            regproc                                       3                         NA  NA                                                                            
adventureworks   pg_transform                            trftosql                              regproc                                       4                         NA  NA                                                                            
adventureworks   pg_sequence                             seqrelid                              oid                                           1                         NA  NA                                                                            
adventureworks   pg_sequence                             seqtypid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_sequence                             seqstart                              bigint                                        3                         NA  NA                                                                            
adventureworks   pg_sequence                             seqincrement                          bigint                                        4                         NA  NA                                                                            
adventureworks   pg_sequence                             seqmax                                bigint                                        5                         NA  NA                                                                            
adventureworks   pg_sequence                             seqmin                                bigint                                        6                         NA  NA                                                                            
adventureworks   pg_sequence                             seqcache                              bigint                                        7                         NA  NA                                                                            
adventureworks   pg_sequence                             seqcycle                              boolean                                       8                         NA  NA                                                                            
adventureworks   pg_publication                          pubname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_publication                          pubowner                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_publication                          puballtables                          boolean                                       3                         NA  NA                                                                            
adventureworks   pg_publication                          pubinsert                             boolean                                       4                         NA  NA                                                                            
adventureworks   pg_publication                          pubupdate                             boolean                                       5                         NA  NA                                                                            
adventureworks   pg_publication                          pubdelete                             boolean                                       6                         NA  NA                                                                            
adventureworks   pg_publication_rel                      prpubid                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_publication_rel                      prrelid                               oid                                           2                         NA  NA                                                                            
adventureworks   pg_subscription                         subconninfo                           text                                          5                         NA  NA                                                                            
adventureworks   pg_subscription                         subsynccommit                         text                                          7                         NA  NA                                                                            
adventureworks   pg_subscription_rel                     srsubid                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_subscription_rel                     srrelid                               oid                                           2                         NA  NA                                                                            
adventureworks   pg_subscription_rel                     srsubstate                            "char"                                        3                         NA  NA                                                                            
adventureworks   pg_subscription_rel                     srsublsn                              pg_lsn                                        4                         NA  NA                                                                            
adventureworks   pg_roles                                rolname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_roles                                rolsuper                              boolean                                       2                         NA  NA                                                                            
adventureworks   pg_roles                                rolinherit                            boolean                                       3                         NA  NA                                                                            
adventureworks   pg_roles                                rolcreaterole                         boolean                                       4                         NA  NA                                                                            
adventureworks   pg_roles                                rolcreatedb                           boolean                                       5                         NA  NA                                                                            
adventureworks   pg_roles                                rolcanlogin                           boolean                                       6                         NA  NA                                                                            
adventureworks   pg_roles                                rolreplication                        boolean                                       7                         NA  NA                                                                            
adventureworks   pg_roles                                rolconnlimit                          integer                                       8                         NA  NA                                                                            
adventureworks   pg_roles                                rolpassword                           text                                          9                         NA  NA                                                                            
adventureworks   pg_roles                                rolvaliduntil                         timestamp with time zone                     10                         NA  NA                                                                            
adventureworks   pg_roles                                rolbypassrls                          boolean                                      11                         NA  NA                                                                            
adventureworks   pg_roles                                rolconfig                             ARRAY                                        12                         NA  NA                                                                            
adventureworks   pg_roles                                oid                                   oid                                          13                         NA  NA                                                                            
adventureworks   pg_shadow                               usename                               name                                          1                         NA  NA                                                                            
adventureworks   pg_shadow                               usesysid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_shadow                               usecreatedb                           boolean                                       3                         NA  NA                                                                            
adventureworks   pg_shadow                               usesuper                              boolean                                       4                         NA  NA                                                                            
adventureworks   pg_shadow                               userepl                               boolean                                       5                         NA  NA                                                                            
adventureworks   pg_shadow                               usebypassrls                          boolean                                       6                         NA  NA                                                                            
adventureworks   pg_shadow                               passwd                                text                                          7                         NA  NA                                                                            
adventureworks   pg_shadow                               valuntil                              abstime                                       8                         NA  NA                                                                            
adventureworks   pg_shadow                               useconfig                             ARRAY                                         9                         NA  NA                                                                            
adventureworks   pg_group                                groname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_group                                grosysid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_group                                grolist                               ARRAY                                         3                         NA  NA                                                                            
adventureworks   pg_user                                 usename                               name                                          1                         NA  NA                                                                            
adventureworks   pg_user                                 usesysid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_user                                 usecreatedb                           boolean                                       3                         NA  NA                                                                            
adventureworks   pg_user                                 usesuper                              boolean                                       4                         NA  NA                                                                            
adventureworks   pg_user                                 userepl                               boolean                                       5                         NA  NA                                                                            
adventureworks   pg_user                                 usebypassrls                          boolean                                       6                         NA  NA                                                                            
adventureworks   pg_user                                 passwd                                text                                          7                         NA  NA                                                                            
adventureworks   pg_user                                 valuntil                              abstime                                       8                         NA  NA                                                                            
adventureworks   pg_user                                 useconfig                             ARRAY                                         9                         NA  NA                                                                            
adventureworks   pg_policies                             schemaname                            name                                          1                         NA  NA                                                                            
adventureworks   pg_policies                             tablename                             name                                          2                         NA  NA                                                                            
adventureworks   pg_policies                             policyname                            name                                          3                         NA  NA                                                                            
adventureworks   pg_policies                             permissive                            text                                          4                         NA  NA                                                                            
adventureworks   pg_policies                             roles                                 ARRAY                                         5                         NA  NA                                                                            
adventureworks   pg_policies                             cmd                                   text                                          6                         NA  NA                                                                            
adventureworks   pg_policies                             qual                                  text                                          7                         NA  NA                                                                            
adventureworks   pg_policies                             with_check                            text                                          8                         NA  NA                                                                            
adventureworks   pg_rules                                schemaname                            name                                          1                         NA  NA                                                                            
adventureworks   pg_rules                                tablename                             name                                          2                         NA  NA                                                                            
adventureworks   pg_rules                                rulename                              name                                          3                         NA  NA                                                                            
adventureworks   pg_rules                                definition                            text                                          4                         NA  NA                                                                            
adventureworks   pg_views                                schemaname                            name                                          1                         NA  NA                                                                            
adventureworks   pg_views                                viewname                              name                                          2                         NA  NA                                                                            
adventureworks   pg_views                                viewowner                             name                                          3                         NA  NA                                                                            
adventureworks   pg_views                                definition                            text                                          4                         NA  NA                                                                            
adventureworks   pg_tables                               schemaname                            name                                          1                         NA  NA                                                                            
adventureworks   pg_tables                               tablename                             name                                          2                         NA  NA                                                                            
adventureworks   pg_tables                               tableowner                            name                                          3                         NA  NA                                                                            
adventureworks   pg_tables                               tablespace                            name                                          4                         NA  NA                                                                            
adventureworks   pg_tables                               hasindexes                            boolean                                       5                         NA  NA                                                                            
adventureworks   pg_tables                               hasrules                              boolean                                       6                         NA  NA                                                                            
adventureworks   pg_tables                               hastriggers                           boolean                                       7                         NA  NA                                                                            
adventureworks   pg_tables                               rowsecurity                           boolean                                       8                         NA  NA                                                                            
adventureworks   pg_matviews                             schemaname                            name                                          1                         NA  NA                                                                            
adventureworks   pg_matviews                             matviewname                           name                                          2                         NA  NA                                                                            
adventureworks   pg_matviews                             matviewowner                          name                                          3                         NA  NA                                                                            
adventureworks   pg_matviews                             tablespace                            name                                          4                         NA  NA                                                                            
adventureworks   pg_matviews                             hasindexes                            boolean                                       5                         NA  NA                                                                            
adventureworks   pg_matviews                             ispopulated                           boolean                                       6                         NA  NA                                                                            
adventureworks   pg_matviews                             definition                            text                                          7                         NA  NA                                                                            
adventureworks   pg_indexes                              schemaname                            name                                          1                         NA  NA                                                                            
adventureworks   pg_indexes                              tablename                             name                                          2                         NA  NA                                                                            
adventureworks   pg_indexes                              indexname                             name                                          3                         NA  NA                                                                            
adventureworks   pg_indexes                              tablespace                            name                                          4                         NA  NA                                                                            
adventureworks   pg_indexes                              indexdef                              text                                          5                         NA  NA                                                                            
adventureworks   pg_sequences                            schemaname                            name                                          1                         NA  NA                                                                            
adventureworks   pg_sequences                            sequencename                          name                                          2                         NA  NA                                                                            
adventureworks   pg_sequences                            sequenceowner                         name                                          3                         NA  NA                                                                            
adventureworks   pg_sequences                            data_type                             regtype                                       4                         NA  NA                                                                            
adventureworks   pg_sequences                            start_value                           bigint                                        5                         NA  NA                                                                            
adventureworks   pg_sequences                            min_value                             bigint                                        6                         NA  NA                                                                            
adventureworks   pg_sequences                            max_value                             bigint                                        7                         NA  NA                                                                            
adventureworks   pg_sequences                            increment_by                          bigint                                        8                         NA  NA                                                                            
adventureworks   pg_sequences                            cycle                                 boolean                                       9                         NA  NA                                                                            
adventureworks   pg_sequences                            cache_size                            bigint                                       10                         NA  NA                                                                            
adventureworks   pg_sequences                            last_value                            bigint                                       11                         NA  NA                                                                            
adventureworks   pg_stats                                schemaname                            name                                          1                         NA  NA                                                                            
adventureworks   pg_stats                                tablename                             name                                          2                         NA  NA                                                                            
adventureworks   pg_stats                                attname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stats                                inherited                             boolean                                       4                         NA  NA                                                                            
adventureworks   pg_stats                                null_frac                             real (24,2)                                   5                         NA  NA                                                                            
adventureworks   pg_stats                                avg_width                             integer                                       6                         NA  NA                                                                            
adventureworks   pg_stats                                n_distinct                            real (24,2)                                   7                         NA  NA                                                                            
adventureworks   pg_stats                                most_common_vals                      anyarray                                      8                         NA  NA                                                                            
adventureworks   pg_stats                                most_common_freqs                     ARRAY                                         9                         NA  NA                                                                            
adventureworks   pg_stats                                histogram_bounds                      anyarray                                     10                         NA  NA                                                                            
adventureworks   pg_stats                                correlation                           real (24,2)                                  11                         NA  NA                                                                            
adventureworks   pg_stats                                most_common_elems                     anyarray                                     12                         NA  NA                                                                            
adventureworks   pg_stats                                most_common_elem_freqs                ARRAY                                        13                         NA  NA                                                                            
adventureworks   pg_stats                                elem_count_histogram                  ARRAY                                        14                         NA  NA                                                                            
adventureworks   pg_publication_tables                   pubname                               name                                          1                         NA  NA                                                                            
adventureworks   pg_publication_tables                   schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_publication_tables                   tablename                             name                                          3                         NA  NA                                                                            
adventureworks   pg_locks                                locktype                              text                                          1                         NA  NA                                                                            
adventureworks   pg_locks                                database                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_locks                                relation                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_locks                                page                                  integer                                       4                         NA  NA                                                                            
adventureworks   pg_locks                                tuple                                 smallint                                      5                         NA  NA                                                                            
adventureworks   pg_locks                                virtualxid                            text                                          6                         NA  NA                                                                            
adventureworks   pg_locks                                transactionid                         xid                                           7                         NA  NA                                                                            
adventureworks   pg_locks                                classid                               oid                                           8                         NA  NA                                                                            
adventureworks   pg_locks                                objid                                 oid                                           9                         NA  NA                                                                            
adventureworks   pg_locks                                objsubid                              smallint                                     10                         NA  NA                                                                            
adventureworks   pg_locks                                virtualtransaction                    text                                         11                         NA  NA                                                                            
adventureworks   pg_locks                                pid                                   integer                                      12                         NA  NA                                                                            
adventureworks   pg_locks                                mode                                  text                                         13                         NA  NA                                                                            
adventureworks   pg_locks                                granted                               boolean                                      14                         NA  NA                                                                            
adventureworks   pg_locks                                fastpath                              boolean                                      15                         NA  NA                                                                            
adventureworks   pg_cursors                              name                                  text                                          1                         NA  NA                                                                            
adventureworks   pg_cursors                              statement                             text                                          2                         NA  NA                                                                            
adventureworks   pg_cursors                              is_holdable                           boolean                                       3                         NA  NA                                                                            
adventureworks   pg_cursors                              is_binary                             boolean                                       4                         NA  NA                                                                            
adventureworks   pg_cursors                              is_scrollable                         boolean                                       5                         NA  NA                                                                            
adventureworks   pg_cursors                              creation_time                         timestamp with time zone                      6                         NA  NA                                                                            
adventureworks   pg_available_extensions                 name                                  name                                          1                         NA  NA                                                                            
adventureworks   pg_available_extensions                 default_version                       text                                          2                         NA  NA                                                                            
adventureworks   pg_available_extensions                 installed_version                     text                                          3                         NA  NA                                                                            
adventureworks   pg_available_extensions                 comment                               text                                          4                         NA  NA                                                                            
adventureworks   pg_available_extension_versions         name                                  name                                          1                         NA  NA                                                                            
adventureworks   pg_available_extension_versions         version                               text                                          2                         NA  NA                                                                            
adventureworks   pg_available_extension_versions         installed                             boolean                                       3                         NA  NA                                                                            
adventureworks   pg_available_extension_versions         superuser                             boolean                                       4                         NA  NA                                                                            
adventureworks   pg_available_extension_versions         relocatable                           boolean                                       5                         NA  NA                                                                            
adventureworks   pg_available_extension_versions         schema                                name                                          6                         NA  NA                                                                            
adventureworks   pg_available_extension_versions         requires                              ARRAY                                         7                         NA  NA                                                                            
adventureworks   pg_available_extension_versions         comment                               text                                          8                         NA  NA                                                                            
adventureworks   pg_prepared_xacts                       transaction                           xid                                           1                         NA  NA                                                                            
adventureworks   pg_prepared_xacts                       gid                                   text                                          2                         NA  NA                                                                            
adventureworks   pg_prepared_xacts                       prepared                              timestamp with time zone                      3                         NA  NA                                                                            
adventureworks   pg_prepared_xacts                       owner                                 name                                          4                         NA  NA                                                                            
adventureworks   pg_prepared_xacts                       database                              name                                          5                         NA  NA                                                                            
adventureworks   pg_prepared_statements                  name                                  text                                          1                         NA  NA                                                                            
adventureworks   pg_prepared_statements                  statement                             text                                          2                         NA  NA                                                                            
adventureworks   pg_prepared_statements                  prepare_time                          timestamp with time zone                      3                         NA  NA                                                                            
adventureworks   pg_prepared_statements                  parameter_types                       ARRAY                                         4                         NA  NA                                                                            
adventureworks   pg_prepared_statements                  from_sql                              boolean                                       5                         NA  NA                                                                            
adventureworks   pg_seclabels                            objoid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_seclabels                            classoid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_seclabels                            objsubid                              integer                                       3                         NA  NA                                                                            
adventureworks   pg_seclabels                            objtype                               text                                          4                         NA  NA                                                                            
adventureworks   pg_seclabels                            objnamespace                          oid                                           5                         NA  NA                                                                            
adventureworks   pg_seclabels                            objname                               text                                          6                         NA  NA                                                                            
adventureworks   pg_seclabels                            provider                              text                                          7                         NA  NA                                                                            
adventureworks   pg_seclabels                            label                                 text                                          8                         NA  NA                                                                            
adventureworks   pg_settings                             name                                  text                                          1                         NA  NA                                                                            
adventureworks   pg_settings                             setting                               text                                          2                         NA  NA                                                                            
adventureworks   pg_settings                             unit                                  text                                          3                         NA  NA                                                                            
adventureworks   pg_settings                             category                              text                                          4                         NA  NA                                                                            
adventureworks   pg_settings                             short_desc                            text                                          5                         NA  NA                                                                            
adventureworks   pg_settings                             extra_desc                            text                                          6                         NA  NA                                                                            
adventureworks   pg_settings                             context                               text                                          7                         NA  NA                                                                            
adventureworks   pg_settings                             vartype                               text                                          8                         NA  NA                                                                            
adventureworks   pg_settings                             source                                text                                          9                         NA  NA                                                                            
adventureworks   pg_settings                             min_val                               text                                         10                         NA  NA                                                                            
adventureworks   pg_settings                             max_val                               text                                         11                         NA  NA                                                                            
adventureworks   pg_settings                             enumvals                              ARRAY                                        12                         NA  NA                                                                            
adventureworks   pg_settings                             boot_val                              text                                         13                         NA  NA                                                                            
adventureworks   pg_settings                             reset_val                             text                                         14                         NA  NA                                                                            
adventureworks   pg_settings                             sourcefile                            text                                         15                         NA  NA                                                                            
adventureworks   pg_settings                             sourceline                            integer                                      16                         NA  NA                                                                            
adventureworks   pg_settings                             pending_restart                       boolean                                      17                         NA  NA                                                                            
adventureworks   pg_file_settings                        sourcefile                            text                                          1                         NA  NA                                                                            
adventureworks   pg_file_settings                        sourceline                            integer                                       2                         NA  NA                                                                            
adventureworks   pg_file_settings                        seqno                                 integer                                       3                         NA  NA                                                                            
adventureworks   pg_file_settings                        name                                  text                                          4                         NA  NA                                                                            
adventureworks   pg_file_settings                        setting                               text                                          5                         NA  NA                                                                            
adventureworks   pg_file_settings                        applied                               boolean                                       6                         NA  NA                                                                            
adventureworks   pg_file_settings                        error                                 text                                          7                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       line_number                           integer                                       1                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       type                                  text                                          2                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       database                              ARRAY                                         3                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       user_name                             ARRAY                                         4                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       address                               text                                          5                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       netmask                               text                                          6                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       auth_method                           text                                          7                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       options                               ARRAY                                         8                         NA  NA                                                                            
adventureworks   pg_hba_file_rules                       error                                 text                                          9                         NA  NA                                                                            
adventureworks   pg_timezone_abbrevs                     abbrev                                text                                          1                         NA  NA                                                                            
adventureworks   pg_timezone_abbrevs                     utc_offset                            interval                                      2                         NA  NA                                                                            
adventureworks   pg_timezone_abbrevs                     is_dst                                boolean                                       3                         NA  NA                                                                            
adventureworks   pg_timezone_names                       name                                  text                                          1                         NA  NA                                                                            
adventureworks   pg_timezone_names                       abbrev                                text                                          2                         NA  NA                                                                            
adventureworks   pg_timezone_names                       utc_offset                            interval                                      3                         NA  NA                                                                            
adventureworks   pg_timezone_names                       is_dst                                boolean                                       4                         NA  NA                                                                            
adventureworks   pg_config                               name                                  text                                          1                         NA  NA                                                                            
adventureworks   pg_config                               setting                               text                                          2                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      seq_scan                              bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      seq_tup_read                          bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      idx_tup_fetch                         bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      n_tup_ins                             bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      n_tup_upd                             bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      n_tup_del                             bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      n_tup_hot_upd                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      n_live_tup                            bigint                                       12                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      n_dead_tup                            bigint                                       13                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      n_mod_since_analyze                   bigint                                       14                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      last_vacuum                           timestamp with time zone                     15                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      last_autovacuum                       timestamp with time zone                     16                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      last_analyze                          timestamp with time zone                     17                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      last_autoanalyze                      timestamp with time zone                     18                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      vacuum_count                          bigint                                       19                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      autovacuum_count                      bigint                                       20                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      analyze_count                         bigint                                       21                         NA  NA                                                                            
adventureworks   pg_stat_all_tables                      autoanalyze_count                     bigint                                       22                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 seq_scan                              bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 seq_tup_read                          bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 idx_tup_fetch                         bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 n_tup_ins                             bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 n_tup_upd                             bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 n_tup_del                             bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_xact_all_tables                 n_tup_hot_upd                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      seq_scan                              bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      seq_tup_read                          bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      idx_tup_fetch                         bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      n_tup_ins                             bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      n_tup_upd                             bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      n_tup_del                             bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      n_tup_hot_upd                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      n_live_tup                            bigint                                       12                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      n_dead_tup                            bigint                                       13                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      n_mod_since_analyze                   bigint                                       14                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      last_vacuum                           timestamp with time zone                     15                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      last_autovacuum                       timestamp with time zone                     16                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      last_analyze                          timestamp with time zone                     17                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      last_autoanalyze                      timestamp with time zone                     18                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      vacuum_count                          bigint                                       19                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      autovacuum_count                      bigint                                       20                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      analyze_count                         bigint                                       21                         NA  NA                                                                            
adventureworks   pg_stat_sys_tables                      autoanalyze_count                     bigint                                       22                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 seq_scan                              bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 seq_tup_read                          bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 idx_tup_fetch                         bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 n_tup_ins                             bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 n_tup_upd                             bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 n_tup_del                             bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_xact_sys_tables                 n_tup_hot_upd                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     seq_scan                              bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     seq_tup_read                          bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     idx_tup_fetch                         bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     n_tup_ins                             bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     n_tup_upd                             bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     n_tup_del                             bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     n_tup_hot_upd                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     n_live_tup                            bigint                                       12                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     n_dead_tup                            bigint                                       13                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     n_mod_since_analyze                   bigint                                       14                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     last_vacuum                           timestamp with time zone                     15                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     last_autovacuum                       timestamp with time zone                     16                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     last_analyze                          timestamp with time zone                     17                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     last_autoanalyze                      timestamp with time zone                     18                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     vacuum_count                          bigint                                       19                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     autovacuum_count                      bigint                                       20                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     analyze_count                         bigint                                       21                         NA  NA                                                                            
adventureworks   pg_stat_user_tables                     autoanalyze_count                     bigint                                       22                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                seq_scan                              bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                seq_tup_read                          bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                idx_tup_fetch                         bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                n_tup_ins                             bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                n_tup_upd                             bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                n_tup_del                             bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_tables                n_tup_hot_upd                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    heap_blks_read                        bigint                                        4                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    heap_blks_hit                         bigint                                        5                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    idx_blks_read                         bigint                                        6                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    idx_blks_hit                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    toast_blks_read                       bigint                                        8                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    toast_blks_hit                        bigint                                        9                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    tidx_blks_read                        bigint                                       10                         NA  NA                                                                            
adventureworks   pg_statio_all_tables                    tidx_blks_hit                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    heap_blks_read                        bigint                                        4                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    heap_blks_hit                         bigint                                        5                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    idx_blks_read                         bigint                                        6                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    idx_blks_hit                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    toast_blks_read                       bigint                                        8                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    toast_blks_hit                        bigint                                        9                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    tidx_blks_read                        bigint                                       10                         NA  NA                                                                            
adventureworks   pg_statio_sys_tables                    tidx_blks_hit                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   heap_blks_read                        bigint                                        4                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   heap_blks_hit                         bigint                                        5                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   idx_blks_read                         bigint                                        6                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   idx_blks_hit                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   toast_blks_read                       bigint                                        8                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   toast_blks_hit                        bigint                                        9                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   tidx_blks_read                        bigint                                       10                         NA  NA                                                                            
adventureworks   pg_statio_user_tables                   tidx_blks_hit                         bigint                                       11                         NA  NA                                                                            
adventureworks   pg_stat_all_indexes                     relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_all_indexes                     indexrelid                            oid                                           2                         NA  NA                                                                            
adventureworks   pg_stat_all_indexes                     schemaname                            name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_all_indexes                     relname                               name                                          4                         NA  NA                                                                            
adventureworks   pg_stat_all_indexes                     indexrelname                          name                                          5                         NA  NA                                                                            
adventureworks   pg_stat_all_indexes                     idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_all_indexes                     idx_tup_read                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_all_indexes                     idx_tup_fetch                         bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_sys_indexes                     relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_sys_indexes                     indexrelid                            oid                                           2                         NA  NA                                                                            
adventureworks   pg_stat_sys_indexes                     schemaname                            name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_sys_indexes                     relname                               name                                          4                         NA  NA                                                                            
adventureworks   pg_stat_sys_indexes                     indexrelname                          name                                          5                         NA  NA                                                                            
adventureworks   pg_stat_sys_indexes                     idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_sys_indexes                     idx_tup_read                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_sys_indexes                     idx_tup_fetch                         bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_user_indexes                    relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_user_indexes                    indexrelid                            oid                                           2                         NA  NA                                                                            
adventureworks   pg_stat_user_indexes                    schemaname                            name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_user_indexes                    relname                               name                                          4                         NA  NA                                                                            
adventureworks   pg_stat_user_indexes                    indexrelname                          name                                          5                         NA  NA                                                                            
adventureworks   pg_stat_user_indexes                    idx_scan                              bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_user_indexes                    idx_tup_read                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_user_indexes                    idx_tup_fetch                         bigint                                        8                         NA  NA                                                                            
adventureworks   pg_statio_all_indexes                   relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_all_indexes                   indexrelid                            oid                                           2                         NA  NA                                                                            
adventureworks   pg_statio_all_indexes                   schemaname                            name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_all_indexes                   relname                               name                                          4                         NA  NA                                                                            
adventureworks   pg_statio_all_indexes                   indexrelname                          name                                          5                         NA  NA                                                                            
adventureworks   pg_statio_all_indexes                   idx_blks_read                         bigint                                        6                         NA  NA                                                                            
adventureworks   pg_statio_all_indexes                   idx_blks_hit                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_statio_sys_indexes                   relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_sys_indexes                   indexrelid                            oid                                           2                         NA  NA                                                                            
adventureworks   pg_statio_sys_indexes                   schemaname                            name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_sys_indexes                   relname                               name                                          4                         NA  NA                                                                            
adventureworks   pg_statio_sys_indexes                   indexrelname                          name                                          5                         NA  NA                                                                            
adventureworks   pg_statio_sys_indexes                   idx_blks_read                         bigint                                        6                         NA  NA                                                                            
adventureworks   pg_statio_sys_indexes                   idx_blks_hit                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_statio_user_indexes                  relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_user_indexes                  indexrelid                            oid                                           2                         NA  NA                                                                            
adventureworks   pg_statio_user_indexes                  schemaname                            name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_user_indexes                  relname                               name                                          4                         NA  NA                                                                            
adventureworks   pg_statio_user_indexes                  indexrelname                          name                                          5                         NA  NA                                                                            
adventureworks   pg_statio_user_indexes                  idx_blks_read                         bigint                                        6                         NA  NA                                                                            
adventureworks   pg_statio_user_indexes                  idx_blks_hit                          bigint                                        7                         NA  NA                                                                            
adventureworks   pg_statio_all_sequences                 relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_all_sequences                 schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_statio_all_sequences                 relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_all_sequences                 blks_read                             bigint                                        4                         NA  NA                                                                            
adventureworks   pg_statio_all_sequences                 blks_hit                              bigint                                        5                         NA  NA                                                                            
adventureworks   pg_statio_sys_sequences                 relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_sys_sequences                 schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_statio_sys_sequences                 relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_sys_sequences                 blks_read                             bigint                                        4                         NA  NA                                                                            
adventureworks   pg_statio_sys_sequences                 blks_hit                              bigint                                        5                         NA  NA                                                                            
adventureworks   pg_statio_user_sequences                relid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_statio_user_sequences                schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_statio_user_sequences                relname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_statio_user_sequences                blks_read                             bigint                                        4                         NA  NA                                                                            
adventureworks   pg_statio_user_sequences                blks_hit                              bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_activity                        datid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_activity                        datname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_activity                        pid                                   integer                                       3                         NA  NA                                                                            
adventureworks   pg_stat_activity                        usesysid                              oid                                           4                         NA  NA                                                                            
adventureworks   pg_stat_activity                        usename                               name                                          5                         NA  NA                                                                            
adventureworks   pg_stat_activity                        application_name                      text                                          6                         NA  NA                                                                            
adventureworks   pg_stat_activity                        client_addr                           inet                                          7                         NA  NA                                                                            
adventureworks   pg_stat_activity                        client_hostname                       text                                          8                         NA  NA                                                                            
adventureworks   pg_stat_activity                        client_port                           integer                                       9                         NA  NA                                                                            
adventureworks   pg_stat_activity                        backend_start                         timestamp with time zone                     10                         NA  NA                                                                            
adventureworks   pg_stat_activity                        xact_start                            timestamp with time zone                     11                         NA  NA                                                                            
adventureworks   pg_stat_activity                        query_start                           timestamp with time zone                     12                         NA  NA                                                                            
adventureworks   pg_stat_activity                        state_change                          timestamp with time zone                     13                         NA  NA                                                                            
adventureworks   pg_stat_activity                        wait_event_type                       text                                         14                         NA  NA                                                                            
adventureworks   pg_stat_activity                        wait_event                            text                                         15                         NA  NA                                                                            
adventureworks   pg_stat_activity                        state                                 text                                         16                         NA  NA                                                                            
adventureworks   pg_stat_activity                        backend_xid                           xid                                          17                         NA  NA                                                                            
adventureworks   pg_stat_activity                        backend_xmin                          xid                                          18                         NA  NA                                                                            
adventureworks   pg_stat_activity                        query                                 text                                         19                         NA  NA                                                                            
adventureworks   pg_stat_activity                        backend_type                          text                                         20                         NA  NA                                                                            
adventureworks   pg_stat_replication                     pid                                   integer                                       1                         NA  NA                                                                            
adventureworks   pg_stat_replication                     usesysid                              oid                                           2                         NA  NA                                                                            
adventureworks   pg_stat_replication                     usename                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_replication                     application_name                      text                                          4                         NA  NA                                                                            
adventureworks   pg_stat_replication                     client_addr                           inet                                          5                         NA  NA                                                                            
adventureworks   pg_stat_replication                     client_hostname                       text                                          6                         NA  NA                                                                            
adventureworks   pg_stat_replication                     client_port                           integer                                       7                         NA  NA                                                                            
adventureworks   pg_stat_replication                     backend_start                         timestamp with time zone                      8                         NA  NA                                                                            
adventureworks   pg_stat_replication                     backend_xmin                          xid                                           9                         NA  NA                                                                            
adventureworks   pg_stat_replication                     state                                 text                                         10                         NA  NA                                                                            
adventureworks   pg_stat_replication                     sent_lsn                              pg_lsn                                       11                         NA  NA                                                                            
adventureworks   pg_stat_replication                     write_lsn                             pg_lsn                                       12                         NA  NA                                                                            
adventureworks   pg_stat_replication                     flush_lsn                             pg_lsn                                       13                         NA  NA                                                                            
adventureworks   pg_stat_replication                     replay_lsn                            pg_lsn                                       14                         NA  NA                                                                            
adventureworks   pg_stat_replication                     write_lag                             interval                                     15                         NA  NA                                                                            
adventureworks   pg_stat_replication                     flush_lag                             interval                                     16                         NA  NA                                                                            
adventureworks   pg_stat_replication                     replay_lag                            interval                                     17                         NA  NA                                                                            
adventureworks   pg_stat_replication                     sync_priority                         integer                                      18                         NA  NA                                                                            
adventureworks   pg_stat_replication                     sync_state                            text                                         19                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    pid                                   integer                                       1                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    status                                text                                          2                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    receive_start_lsn                     pg_lsn                                        3                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    receive_start_tli                     integer                                       4                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    received_lsn                          pg_lsn                                        5                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    received_tli                          integer                                       6                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    last_msg_send_time                    timestamp with time zone                      7                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    last_msg_receipt_time                 timestamp with time zone                      8                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    latest_end_lsn                        pg_lsn                                        9                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    latest_end_time                       timestamp with time zone                     10                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    slot_name                             text                                         11                         NA  NA                                                                            
adventureworks   pg_stat_wal_receiver                    conninfo                              text                                         12                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    subid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    subname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    pid                                   integer                                       3                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    relid                                 oid                                           4                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    received_lsn                          pg_lsn                                        5                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    last_msg_send_time                    timestamp with time zone                      6                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    last_msg_receipt_time                 timestamp with time zone                      7                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    latest_end_lsn                        pg_lsn                                        8                         NA  NA                                                                            
adventureworks   pg_stat_subscription                    latest_end_time                       timestamp with time zone                      9                         NA  NA                                                                            
adventureworks   pg_stat_ssl                             pid                                   integer                                       1                         NA  NA                                                                            
adventureworks   pg_stat_ssl                             ssl                                   boolean                                       2                         NA  NA                                                                            
adventureworks   pg_stat_ssl                             version                               text                                          3                         NA  NA                                                                            
adventureworks   pg_stat_ssl                             cipher                                text                                          4                         NA  NA                                                                            
adventureworks   pg_stat_ssl                             bits                                  integer                                       5                         NA  NA                                                                            
adventureworks   pg_stat_ssl                             compression                           boolean                                       6                         NA  NA                                                                            
adventureworks   pg_stat_ssl                             clientdn                              text                                          7                         NA  NA                                                                            
adventureworks   pg_replication_slots                    slot_name                             name                                          1                         NA  NA                                                                            
adventureworks   pg_replication_slots                    plugin                                name                                          2                         NA  NA                                                                            
adventureworks   pg_replication_slots                    slot_type                             text                                          3                         NA  NA                                                                            
adventureworks   pg_replication_slots                    datoid                                oid                                           4                         NA  NA                                                                            
adventureworks   pg_replication_slots                    database                              name                                          5                         NA  NA                                                                            
adventureworks   pg_replication_slots                    temporary                             boolean                                       6                         NA  NA                                                                            
adventureworks   pg_replication_slots                    active                                boolean                                       7                         NA  NA                                                                            
adventureworks   pg_replication_slots                    active_pid                            integer                                       8                         NA  NA                                                                            
adventureworks   pg_replication_slots                    xmin                                  xid                                           9                         NA  NA                                                                            
adventureworks   pg_replication_slots                    catalog_xmin                          xid                                          10                         NA  NA                                                                            
adventureworks   pg_replication_slots                    restart_lsn                           pg_lsn                                       11                         NA  NA                                                                            
adventureworks   pg_replication_slots                    confirmed_flush_lsn                   pg_lsn                                       12                         NA  NA                                                                            
adventureworks   pg_stat_database                        datid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_database                        datname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_database                        numbackends                           integer                                       3                         NA  NA                                                                            
adventureworks   pg_stat_database                        xact_commit                           bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_database                        xact_rollback                         bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_database                        blks_read                             bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_database                        blks_hit                              bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_database                        tup_returned                          bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_database                        tup_fetched                           bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_database                        tup_inserted                          bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_database                        tup_updated                           bigint                                       11                         NA  NA                                                                            
adventureworks   pg_stat_database                        tup_deleted                           bigint                                       12                         NA  NA                                                                            
adventureworks   pg_stat_database                        conflicts                             bigint                                       13                         NA  NA                                                                            
adventureworks   pg_stat_database                        temp_files                            bigint                                       14                         NA  NA                                                                            
adventureworks   pg_stat_database                        temp_bytes                            bigint                                       15                         NA  NA                                                                            
adventureworks   pg_stat_database                        deadlocks                             bigint                                       16                         NA  NA                                                                            
adventureworks   pg_stat_database                        blk_read_time                         double precision                             17                         NA  NA                                                                            
adventureworks   pg_stat_database                        blk_write_time                        double precision                             18                         NA  NA                                                                            
adventureworks   pg_stat_database                        stats_reset                           timestamp with time zone                     19                         NA  NA                                                                            
adventureworks   pg_stat_database_conflicts              datid                                 oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_database_conflicts              datname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_database_conflicts              confl_tablespace                      bigint                                        3                         NA  NA                                                                            
adventureworks   pg_stat_database_conflicts              confl_lock                            bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_database_conflicts              confl_snapshot                        bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_database_conflicts              confl_bufferpin                       bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_database_conflicts              confl_deadlock                        bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_user_functions                  funcid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_user_functions                  schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_user_functions                  funcname                              name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_user_functions                  calls                                 bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_user_functions                  total_time                            double precision                              5                         NA  NA                                                                            
adventureworks   pg_stat_user_functions                  self_time                             double precision                              6                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_functions             funcid                                oid                                           1                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_functions             schemaname                            name                                          2                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_functions             funcname                              name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_functions             calls                                 bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_functions             total_time                            double precision                              5                         NA  NA                                                                            
adventureworks   pg_stat_xact_user_functions             self_time                             double precision                              6                         NA  NA                                                                            
adventureworks   pg_stat_archiver                        archived_count                        bigint                                        1                         NA  NA                                                                            
adventureworks   pg_stat_archiver                        last_archived_wal                     text                                          2                         NA  NA                                                                            
adventureworks   pg_stat_archiver                        last_archived_time                    timestamp with time zone                      3                         NA  NA                                                                            
adventureworks   pg_stat_archiver                        failed_count                          bigint                                        4                         NA  NA                                                                            
adventureworks   pg_stat_archiver                        last_failed_wal                       text                                          5                         NA  NA                                                                            
adventureworks   pg_stat_archiver                        last_failed_time                      timestamp with time zone                      6                         NA  NA                                                                            
adventureworks   pg_stat_archiver                        stats_reset                           timestamp with time zone                      7                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        checkpoints_timed                     bigint                                        1                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        checkpoints_req                       bigint                                        2                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        checkpoint_write_time                 double precision                              3                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        checkpoint_sync_time                  double precision                              4                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        buffers_checkpoint                    bigint                                        5                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        buffers_clean                         bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        maxwritten_clean                      bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        buffers_backend                       bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        buffers_backend_fsync                 bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        buffers_alloc                         bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_bgwriter                        stats_reset                           timestamp with time zone                     11                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 pid                                   integer                                       1                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 datid                                 oid                                           2                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 datname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 relid                                 oid                                           4                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 phase                                 text                                          5                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 heap_blks_total                       bigint                                        6                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 heap_blks_scanned                     bigint                                        7                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 heap_blks_vacuumed                    bigint                                        8                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 index_vacuum_count                    bigint                                        9                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 max_dead_tuples                       bigint                                       10                         NA  NA                                                                            
adventureworks   pg_stat_progress_vacuum                 num_dead_tuples                       bigint                                       11                         NA  NA                                                                            
adventureworks   pg_user_mappings                        umid                                  oid                                           1                         NA  NA                                                                            
adventureworks   pg_user_mappings                        srvid                                 oid                                           2                         NA  NA                                                                            
adventureworks   pg_user_mappings                        srvname                               name                                          3                         NA  NA                                                                            
adventureworks   pg_user_mappings                        umuser                                oid                                           4                         NA  NA                                                                            
adventureworks   pg_user_mappings                        usename                               name                                          5                         NA  NA                                                                            
adventureworks   pg_user_mappings                        umoptions                             ARRAY                                         6                         NA  NA                                                                            
adventureworks   pg_replication_origin_status            local_id                              oid                                           1                         NA  NA                                                                            
adventureworks   pg_replication_origin_status            external_id                           text                                          2                         NA  NA                                                                            
adventureworks   pg_replication_origin_status            remote_lsn                            pg_lsn                                        3                         NA  NA                                                                            
adventureworks   pg_replication_origin_status            local_lsn                             pg_lsn                                        4                         NA  NA                                                                            
adventureworks   pg_subscription                         subdbid                               oid                                           1                         NA  NA                                                                            
adventureworks   pg_subscription                         subname                               name                                          2                         NA  NA                                                                            
adventureworks   pg_subscription                         subowner                              oid                                           3                         NA  NA                                                                            
adventureworks   pg_subscription                         subenabled                            boolean                                       4                         NA  NA                                                                            
adventureworks   pg_subscription                         subslotname                           name                                          6                         NA  NA                                                                            
adventureworks   pg_subscription                         subpublications                       ARRAY                                         8                         NA  NA                                                                            
adventureworks   department                              name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   department                              groupname                             character varying (50)                        3                         50  NA                                                                            
adventureworks   department                              modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   department                              departmentid                          integer                                       1                         NA  nextval('humanresources.department_departmentid_seq'::regclass)               
adventureworks   d                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   d                                       departmentid                          integer                                       2                         NA  NA                                                                            
adventureworks   d                                       name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   d                                       groupname                             character varying (50)                        4                         50  NA                                                                            
adventureworks   d                                       modifieddate                          timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   employee                                businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   employee                                nationalidnumber                      character varying (15)                        2                         15  NA                                                                            
adventureworks   employee                                loginid                               character varying (256)                       3                        256  NA                                                                            
adventureworks   employee                                jobtitle                              character varying (50)                        4                         50  NA                                                                            
adventureworks   employee                                birthdate                             date                                          5                         NA  NA                                                                            
adventureworks   employee                                maritalstatus                         character                                     6                          1  NA                                                                            
adventureworks   employee                                gender                                character                                     7                          1  NA                                                                            
adventureworks   employee                                hiredate                              date                                          8                         NA  NA                                                                            
adventureworks   information_schema_catalog_name         catalog_name                          character varying (NA)                        1                         NA  NA                                                                            
adventureworks   applicable_roles                        grantee                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   applicable_roles                        role_name                             character varying (NA)                        2                         NA  NA                                                                            
adventureworks   applicable_roles                        is_grantable                          character varying (3)                         3                          3  NA                                                                            
adventureworks   administrable_role_authorizations       grantee                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   administrable_role_authorizations       role_name                             character varying (NA)                        2                         NA  NA                                                                            
adventureworks   administrable_role_authorizations       is_grantable                          character varying (3)                         3                          3  NA                                                                            
adventureworks   attributes                              udt_catalog                           character varying (NA)                        1                         NA  NA                                                                            
adventureworks   attributes                              udt_schema                            character varying (NA)                        2                         NA  NA                                                                            
adventureworks   attributes                              udt_name                              character varying (NA)                        3                         NA  NA                                                                            
adventureworks   attributes                              attribute_name                        character varying (NA)                        4                         NA  NA                                                                            
adventureworks   attributes                              ordinal_position                      integer                                       5                         NA  NA                                                                            
adventureworks   attributes                              attribute_default                     character varying (NA)                        6                         NA  NA                                                                            
adventureworks   attributes                              is_nullable                           character varying (3)                         7                          3  NA                                                                            
adventureworks   attributes                              data_type                             character varying (NA)                        8                         NA  NA                                                                            
adventureworks   attributes                              character_maximum_length              integer                                       9                         NA  NA                                                                            
adventureworks   attributes                              character_octet_length                integer                                      10                         NA  NA                                                                            
adventureworks   attributes                              character_set_catalog                 character varying (NA)                       11                         NA  NA                                                                            
adventureworks   attributes                              character_set_schema                  character varying (NA)                       12                         NA  NA                                                                            
adventureworks   attributes                              character_set_name                    character varying (NA)                       13                         NA  NA                                                                            
adventureworks   attributes                              collation_catalog                     character varying (NA)                       14                         NA  NA                                                                            
adventureworks   attributes                              collation_schema                      character varying (NA)                       15                         NA  NA                                                                            
adventureworks   attributes                              collation_name                        character varying (NA)                       16                         NA  NA                                                                            
adventureworks   attributes                              numeric_precision                     integer                                      17                         NA  NA                                                                            
adventureworks   attributes                              numeric_precision_radix               integer                                      18                         NA  NA                                                                            
adventureworks   attributes                              numeric_scale                         integer                                      19                         NA  NA                                                                            
adventureworks   attributes                              datetime_precision                    integer                                      20                         NA  NA                                                                            
adventureworks   attributes                              interval_type                         character varying (NA)                       21                         NA  NA                                                                            
adventureworks   attributes                              interval_precision                    integer                                      22                         NA  NA                                                                            
adventureworks   attributes                              attribute_udt_catalog                 character varying (NA)                       23                         NA  NA                                                                            
adventureworks   attributes                              attribute_udt_schema                  character varying (NA)                       24                         NA  NA                                                                            
adventureworks   attributes                              attribute_udt_name                    character varying (NA)                       25                         NA  NA                                                                            
adventureworks   attributes                              scope_catalog                         character varying (NA)                       26                         NA  NA                                                                            
adventureworks   attributes                              scope_schema                          character varying (NA)                       27                         NA  NA                                                                            
adventureworks   attributes                              scope_name                            character varying (NA)                       28                         NA  NA                                                                            
adventureworks   attributes                              maximum_cardinality                   integer                                      29                         NA  NA                                                                            
adventureworks   attributes                              dtd_identifier                        character varying (NA)                       30                         NA  NA                                                                            
adventureworks   attributes                              is_derived_reference_attribute        character varying (3)                        31                          3  NA                                                                            
adventureworks   character_sets                          character_set_catalog                 character varying (NA)                        1                         NA  NA                                                                            
adventureworks   character_sets                          character_set_schema                  character varying (NA)                        2                         NA  NA                                                                            
adventureworks   character_sets                          character_set_name                    character varying (NA)                        3                         NA  NA                                                                            
adventureworks   character_sets                          character_repertoire                  character varying (NA)                        4                         NA  NA                                                                            
adventureworks   character_sets                          form_of_use                           character varying (NA)                        5                         NA  NA                                                                            
adventureworks   character_sets                          default_collate_catalog               character varying (NA)                        6                         NA  NA                                                                            
adventureworks   character_sets                          default_collate_schema                character varying (NA)                        7                         NA  NA                                                                            
adventureworks   character_sets                          default_collate_name                  character varying (NA)                        8                         NA  NA                                                                            
adventureworks   check_constraint_routine_usage          constraint_catalog                    character varying (NA)                        1                         NA  NA                                                                            
adventureworks   check_constraint_routine_usage          constraint_schema                     character varying (NA)                        2                         NA  NA                                                                            
adventureworks   check_constraint_routine_usage          constraint_name                       character varying (NA)                        3                         NA  NA                                                                            
adventureworks   check_constraint_routine_usage          specific_catalog                      character varying (NA)                        4                         NA  NA                                                                            
adventureworks   check_constraint_routine_usage          specific_schema                       character varying (NA)                        5                         NA  NA                                                                            
adventureworks   check_constraint_routine_usage          specific_name                         character varying (NA)                        6                         NA  NA                                                                            
adventureworks   check_constraints                       constraint_catalog                    character varying (NA)                        1                         NA  NA                                                                            
adventureworks   check_constraints                       constraint_schema                     character varying (NA)                        2                         NA  NA                                                                            
adventureworks   check_constraints                       constraint_name                       character varying (NA)                        3                         NA  NA                                                                            
adventureworks   check_constraints                       check_clause                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   collations                              collation_catalog                     character varying (NA)                        1                         NA  NA                                                                            
adventureworks   collations                              collation_schema                      character varying (NA)                        2                         NA  NA                                                                            
adventureworks   collations                              collation_name                        character varying (NA)                        3                         NA  NA                                                                            
adventureworks   collations                              pad_attribute                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   collation_character_set_applicability   collation_catalog                     character varying (NA)                        1                         NA  NA                                                                            
adventureworks   collation_character_set_applicability   collation_schema                      character varying (NA)                        2                         NA  NA                                                                            
adventureworks   collation_character_set_applicability   collation_name                        character varying (NA)                        3                         NA  NA                                                                            
adventureworks   collation_character_set_applicability   character_set_catalog                 character varying (NA)                        4                         NA  NA                                                                            
adventureworks   collation_character_set_applicability   character_set_schema                  character varying (NA)                        5                         NA  NA                                                                            
adventureworks   collation_character_set_applicability   character_set_name                    character varying (NA)                        6                         NA  NA                                                                            
adventureworks   column_domain_usage                     domain_catalog                        character varying (NA)                        1                         NA  NA                                                                            
adventureworks   column_domain_usage                     domain_schema                         character varying (NA)                        2                         NA  NA                                                                            
adventureworks   column_domain_usage                     domain_name                           character varying (NA)                        3                         NA  NA                                                                            
adventureworks   column_domain_usage                     table_catalog                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   column_domain_usage                     table_schema                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   column_domain_usage                     table_name                            character varying (NA)                        6                         NA  NA                                                                            
adventureworks   column_domain_usage                     column_name                           character varying (NA)                        7                         NA  NA                                                                            
adventureworks   column_privileges                       grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   column_privileges                       grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   column_privileges                       table_catalog                         character varying (NA)                        3                         NA  NA                                                                            
adventureworks   column_privileges                       table_schema                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   column_privileges                       table_name                            character varying (NA)                        5                         NA  NA                                                                            
adventureworks   column_privileges                       column_name                           character varying (NA)                        6                         NA  NA                                                                            
adventureworks   column_privileges                       privilege_type                        character varying (NA)                        7                         NA  NA                                                                            
adventureworks   column_privileges                       is_grantable                          character varying (3)                         8                          3  NA                                                                            
adventureworks   column_udt_usage                        udt_catalog                           character varying (NA)                        1                         NA  NA                                                                            
adventureworks   column_udt_usage                        udt_schema                            character varying (NA)                        2                         NA  NA                                                                            
adventureworks   column_udt_usage                        udt_name                              character varying (NA)                        3                         NA  NA                                                                            
adventureworks   column_udt_usage                        table_catalog                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   column_udt_usage                        table_schema                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   column_udt_usage                        table_name                            character varying (NA)                        6                         NA  NA                                                                            
adventureworks   column_udt_usage                        column_name                           character varying (NA)                        7                         NA  NA                                                                            
adventureworks   columns                                 table_catalog                         character varying (NA)                        1                         NA  NA                                                                            
adventureworks   columns                                 table_schema                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   columns                                 table_name                            character varying (NA)                        3                         NA  NA                                                                            
adventureworks   columns                                 column_name                           character varying (NA)                        4                         NA  NA                                                                            
adventureworks   columns                                 ordinal_position                      integer                                       5                         NA  NA                                                                            
adventureworks   columns                                 column_default                        character varying (NA)                        6                         NA  NA                                                                            
adventureworks   columns                                 is_nullable                           character varying (3)                         7                          3  NA                                                                            
adventureworks   columns                                 data_type                             character varying (NA)                        8                         NA  NA                                                                            
adventureworks   columns                                 character_maximum_length              integer                                       9                         NA  NA                                                                            
adventureworks   columns                                 character_octet_length                integer                                      10                         NA  NA                                                                            
adventureworks   columns                                 numeric_precision                     integer                                      11                         NA  NA                                                                            
adventureworks   columns                                 numeric_precision_radix               integer                                      12                         NA  NA                                                                            
adventureworks   columns                                 numeric_scale                         integer                                      13                         NA  NA                                                                            
adventureworks   columns                                 datetime_precision                    integer                                      14                         NA  NA                                                                            
adventureworks   columns                                 interval_type                         character varying (NA)                       15                         NA  NA                                                                            
adventureworks   columns                                 interval_precision                    integer                                      16                         NA  NA                                                                            
adventureworks   columns                                 character_set_catalog                 character varying (NA)                       17                         NA  NA                                                                            
adventureworks   columns                                 character_set_schema                  character varying (NA)                       18                         NA  NA                                                                            
adventureworks   columns                                 character_set_name                    character varying (NA)                       19                         NA  NA                                                                            
adventureworks   columns                                 collation_catalog                     character varying (NA)                       20                         NA  NA                                                                            
adventureworks   columns                                 collation_schema                      character varying (NA)                       21                         NA  NA                                                                            
adventureworks   columns                                 collation_name                        character varying (NA)                       22                         NA  NA                                                                            
adventureworks   columns                                 domain_catalog                        character varying (NA)                       23                         NA  NA                                                                            
adventureworks   columns                                 domain_schema                         character varying (NA)                       24                         NA  NA                                                                            
adventureworks   columns                                 domain_name                           character varying (NA)                       25                         NA  NA                                                                            
adventureworks   columns                                 udt_catalog                           character varying (NA)                       26                         NA  NA                                                                            
adventureworks   columns                                 udt_schema                            character varying (NA)                       27                         NA  NA                                                                            
adventureworks   columns                                 udt_name                              character varying (NA)                       28                         NA  NA                                                                            
adventureworks   columns                                 scope_catalog                         character varying (NA)                       29                         NA  NA                                                                            
adventureworks   columns                                 scope_schema                          character varying (NA)                       30                         NA  NA                                                                            
adventureworks   columns                                 scope_name                            character varying (NA)                       31                         NA  NA                                                                            
adventureworks   columns                                 maximum_cardinality                   integer                                      32                         NA  NA                                                                            
adventureworks   columns                                 dtd_identifier                        character varying (NA)                       33                         NA  NA                                                                            
adventureworks   columns                                 is_self_referencing                   character varying (3)                        34                          3  NA                                                                            
adventureworks   columns                                 is_identity                           character varying (3)                        35                          3  NA                                                                            
adventureworks   columns                                 identity_generation                   character varying (NA)                       36                         NA  NA                                                                            
adventureworks   columns                                 identity_start                        character varying (NA)                       37                         NA  NA                                                                            
adventureworks   columns                                 identity_increment                    character varying (NA)                       38                         NA  NA                                                                            
adventureworks   columns                                 identity_maximum                      character varying (NA)                       39                         NA  NA                                                                            
adventureworks   columns                                 identity_minimum                      character varying (NA)                       40                         NA  NA                                                                            
adventureworks   columns                                 identity_cycle                        character varying (3)                        41                          3  NA                                                                            
adventureworks   columns                                 is_generated                          character varying (NA)                       42                         NA  NA                                                                            
adventureworks   columns                                 generation_expression                 character varying (NA)                       43                         NA  NA                                                                            
adventureworks   columns                                 is_updatable                          character varying (3)                        44                          3  NA                                                                            
adventureworks   constraint_column_usage                 table_catalog                         character varying (NA)                        1                         NA  NA                                                                            
adventureworks   constraint_column_usage                 table_schema                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   constraint_column_usage                 table_name                            character varying (NA)                        3                         NA  NA                                                                            
adventureworks   constraint_column_usage                 column_name                           character varying (NA)                        4                         NA  NA                                                                            
adventureworks   constraint_column_usage                 constraint_catalog                    character varying (NA)                        5                         NA  NA                                                                            
adventureworks   constraint_column_usage                 constraint_schema                     character varying (NA)                        6                         NA  NA                                                                            
adventureworks   constraint_column_usage                 constraint_name                       character varying (NA)                        7                         NA  NA                                                                            
adventureworks   constraint_table_usage                  table_catalog                         character varying (NA)                        1                         NA  NA                                                                            
adventureworks   constraint_table_usage                  table_schema                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   constraint_table_usage                  table_name                            character varying (NA)                        3                         NA  NA                                                                            
adventureworks   constraint_table_usage                  constraint_catalog                    character varying (NA)                        4                         NA  NA                                                                            
adventureworks   constraint_table_usage                  constraint_schema                     character varying (NA)                        5                         NA  NA                                                                            
adventureworks   constraint_table_usage                  constraint_name                       character varying (NA)                        6                         NA  NA                                                                            
adventureworks   domain_constraints                      constraint_catalog                    character varying (NA)                        1                         NA  NA                                                                            
adventureworks   domain_constraints                      constraint_schema                     character varying (NA)                        2                         NA  NA                                                                            
adventureworks   domain_constraints                      constraint_name                       character varying (NA)                        3                         NA  NA                                                                            
adventureworks   domain_constraints                      domain_catalog                        character varying (NA)                        4                         NA  NA                                                                            
adventureworks   domain_constraints                      domain_schema                         character varying (NA)                        5                         NA  NA                                                                            
adventureworks   domain_constraints                      domain_name                           character varying (NA)                        6                         NA  NA                                                                            
adventureworks   domain_constraints                      is_deferrable                         character varying (3)                         7                          3  NA                                                                            
adventureworks   domain_constraints                      initially_deferred                    character varying (3)                         8                          3  NA                                                                            
adventureworks   domain_udt_usage                        udt_catalog                           character varying (NA)                        1                         NA  NA                                                                            
adventureworks   domain_udt_usage                        udt_schema                            character varying (NA)                        2                         NA  NA                                                                            
adventureworks   domain_udt_usage                        udt_name                              character varying (NA)                        3                         NA  NA                                                                            
adventureworks   domain_udt_usage                        domain_catalog                        character varying (NA)                        4                         NA  NA                                                                            
adventureworks   domain_udt_usage                        domain_schema                         character varying (NA)                        5                         NA  NA                                                                            
adventureworks   domain_udt_usage                        domain_name                           character varying (NA)                        6                         NA  NA                                                                            
adventureworks   domains                                 domain_catalog                        character varying (NA)                        1                         NA  NA                                                                            
adventureworks   domains                                 domain_schema                         character varying (NA)                        2                         NA  NA                                                                            
adventureworks   domains                                 domain_name                           character varying (NA)                        3                         NA  NA                                                                            
adventureworks   domains                                 data_type                             character varying (NA)                        4                         NA  NA                                                                            
adventureworks   domains                                 character_maximum_length              integer                                       5                         NA  NA                                                                            
adventureworks   domains                                 character_octet_length                integer                                       6                         NA  NA                                                                            
adventureworks   domains                                 character_set_catalog                 character varying (NA)                        7                         NA  NA                                                                            
adventureworks   domains                                 character_set_schema                  character varying (NA)                        8                         NA  NA                                                                            
adventureworks   domains                                 character_set_name                    character varying (NA)                        9                         NA  NA                                                                            
adventureworks   domains                                 collation_catalog                     character varying (NA)                       10                         NA  NA                                                                            
adventureworks   domains                                 collation_schema                      character varying (NA)                       11                         NA  NA                                                                            
adventureworks   domains                                 collation_name                        character varying (NA)                       12                         NA  NA                                                                            
adventureworks   domains                                 numeric_precision                     integer                                      13                         NA  NA                                                                            
adventureworks   domains                                 numeric_precision_radix               integer                                      14                         NA  NA                                                                            
adventureworks   domains                                 numeric_scale                         integer                                      15                         NA  NA                                                                            
adventureworks   domains                                 datetime_precision                    integer                                      16                         NA  NA                                                                            
adventureworks   domains                                 interval_type                         character varying (NA)                       17                         NA  NA                                                                            
adventureworks   domains                                 interval_precision                    integer                                      18                         NA  NA                                                                            
adventureworks   domains                                 domain_default                        character varying (NA)                       19                         NA  NA                                                                            
adventureworks   domains                                 udt_catalog                           character varying (NA)                       20                         NA  NA                                                                            
adventureworks   domains                                 udt_schema                            character varying (NA)                       21                         NA  NA                                                                            
adventureworks   domains                                 udt_name                              character varying (NA)                       22                         NA  NA                                                                            
adventureworks   domains                                 scope_catalog                         character varying (NA)                       23                         NA  NA                                                                            
adventureworks   domains                                 scope_schema                          character varying (NA)                       24                         NA  NA                                                                            
adventureworks   domains                                 scope_name                            character varying (NA)                       25                         NA  NA                                                                            
adventureworks   domains                                 maximum_cardinality                   integer                                      26                         NA  NA                                                                            
adventureworks   domains                                 dtd_identifier                        character varying (NA)                       27                         NA  NA                                                                            
adventureworks   enabled_roles                           role_name                             character varying (NA)                        1                         NA  NA                                                                            
adventureworks   key_column_usage                        constraint_catalog                    character varying (NA)                        1                         NA  NA                                                                            
adventureworks   key_column_usage                        constraint_schema                     character varying (NA)                        2                         NA  NA                                                                            
adventureworks   key_column_usage                        constraint_name                       character varying (NA)                        3                         NA  NA                                                                            
adventureworks   key_column_usage                        table_catalog                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   key_column_usage                        table_schema                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   key_column_usage                        table_name                            character varying (NA)                        6                         NA  NA                                                                            
adventureworks   key_column_usage                        column_name                           character varying (NA)                        7                         NA  NA                                                                            
adventureworks   key_column_usage                        ordinal_position                      integer                                       8                         NA  NA                                                                            
adventureworks   key_column_usage                        position_in_unique_constraint         integer                                       9                         NA  NA                                                                            
adventureworks   parameters                              specific_catalog                      character varying (NA)                        1                         NA  NA                                                                            
adventureworks   parameters                              specific_schema                       character varying (NA)                        2                         NA  NA                                                                            
adventureworks   parameters                              specific_name                         character varying (NA)                        3                         NA  NA                                                                            
adventureworks   parameters                              ordinal_position                      integer                                       4                         NA  NA                                                                            
adventureworks   parameters                              parameter_mode                        character varying (NA)                        5                         NA  NA                                                                            
adventureworks   parameters                              is_result                             character varying (3)                         6                          3  NA                                                                            
adventureworks   parameters                              as_locator                            character varying (3)                         7                          3  NA                                                                            
adventureworks   parameters                              parameter_name                        character varying (NA)                        8                         NA  NA                                                                            
adventureworks   parameters                              data_type                             character varying (NA)                        9                         NA  NA                                                                            
adventureworks   parameters                              character_maximum_length              integer                                      10                         NA  NA                                                                            
adventureworks   parameters                              character_octet_length                integer                                      11                         NA  NA                                                                            
adventureworks   parameters                              character_set_catalog                 character varying (NA)                       12                         NA  NA                                                                            
adventureworks   parameters                              character_set_schema                  character varying (NA)                       13                         NA  NA                                                                            
adventureworks   parameters                              character_set_name                    character varying (NA)                       14                         NA  NA                                                                            
adventureworks   parameters                              collation_catalog                     character varying (NA)                       15                         NA  NA                                                                            
adventureworks   parameters                              collation_schema                      character varying (NA)                       16                         NA  NA                                                                            
adventureworks   parameters                              collation_name                        character varying (NA)                       17                         NA  NA                                                                            
adventureworks   parameters                              numeric_precision                     integer                                      18                         NA  NA                                                                            
adventureworks   parameters                              numeric_precision_radix               integer                                      19                         NA  NA                                                                            
adventureworks   parameters                              numeric_scale                         integer                                      20                         NA  NA                                                                            
adventureworks   parameters                              datetime_precision                    integer                                      21                         NA  NA                                                                            
adventureworks   parameters                              interval_type                         character varying (NA)                       22                         NA  NA                                                                            
adventureworks   parameters                              interval_precision                    integer                                      23                         NA  NA                                                                            
adventureworks   parameters                              udt_catalog                           character varying (NA)                       24                         NA  NA                                                                            
adventureworks   parameters                              udt_schema                            character varying (NA)                       25                         NA  NA                                                                            
adventureworks   parameters                              udt_name                              character varying (NA)                       26                         NA  NA                                                                            
adventureworks   parameters                              scope_catalog                         character varying (NA)                       27                         NA  NA                                                                            
adventureworks   parameters                              scope_schema                          character varying (NA)                       28                         NA  NA                                                                            
adventureworks   parameters                              scope_name                            character varying (NA)                       29                         NA  NA                                                                            
adventureworks   parameters                              maximum_cardinality                   integer                                      30                         NA  NA                                                                            
adventureworks   parameters                              dtd_identifier                        character varying (NA)                       31                         NA  NA                                                                            
adventureworks   parameters                              parameter_default                     character varying (NA)                       32                         NA  NA                                                                            
adventureworks   referential_constraints                 constraint_catalog                    character varying (NA)                        1                         NA  NA                                                                            
adventureworks   referential_constraints                 constraint_schema                     character varying (NA)                        2                         NA  NA                                                                            
adventureworks   referential_constraints                 constraint_name                       character varying (NA)                        3                         NA  NA                                                                            
adventureworks   referential_constraints                 unique_constraint_catalog             character varying (NA)                        4                         NA  NA                                                                            
adventureworks   referential_constraints                 unique_constraint_schema              character varying (NA)                        5                         NA  NA                                                                            
adventureworks   referential_constraints                 unique_constraint_name                character varying (NA)                        6                         NA  NA                                                                            
adventureworks   referential_constraints                 match_option                          character varying (NA)                        7                         NA  NA                                                                            
adventureworks   referential_constraints                 update_rule                           character varying (NA)                        8                         NA  NA                                                                            
adventureworks   referential_constraints                 delete_rule                           character varying (NA)                        9                         NA  NA                                                                            
adventureworks   role_column_grants                      grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   role_column_grants                      grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   role_column_grants                      table_catalog                         character varying (NA)                        3                         NA  NA                                                                            
adventureworks   role_column_grants                      table_schema                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   role_column_grants                      table_name                            character varying (NA)                        5                         NA  NA                                                                            
adventureworks   role_column_grants                      column_name                           character varying (NA)                        6                         NA  NA                                                                            
adventureworks   role_column_grants                      privilege_type                        character varying (NA)                        7                         NA  NA                                                                            
adventureworks   role_column_grants                      is_grantable                          character varying (3)                         8                          3  NA                                                                            
adventureworks   routine_privileges                      grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   routine_privileges                      grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   routine_privileges                      specific_catalog                      character varying (NA)                        3                         NA  NA                                                                            
adventureworks   routine_privileges                      specific_schema                       character varying (NA)                        4                         NA  NA                                                                            
adventureworks   routine_privileges                      specific_name                         character varying (NA)                        5                         NA  NA                                                                            
adventureworks   routine_privileges                      routine_catalog                       character varying (NA)                        6                         NA  NA                                                                            
adventureworks   routine_privileges                      routine_schema                        character varying (NA)                        7                         NA  NA                                                                            
adventureworks   routine_privileges                      routine_name                          character varying (NA)                        8                         NA  NA                                                                            
adventureworks   routine_privileges                      privilege_type                        character varying (NA)                        9                         NA  NA                                                                            
adventureworks   routine_privileges                      is_grantable                          character varying (3)                        10                          3  NA                                                                            
adventureworks   role_routine_grants                     grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   role_routine_grants                     grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   role_routine_grants                     specific_catalog                      character varying (NA)                        3                         NA  NA                                                                            
adventureworks   role_routine_grants                     specific_schema                       character varying (NA)                        4                         NA  NA                                                                            
adventureworks   role_routine_grants                     specific_name                         character varying (NA)                        5                         NA  NA                                                                            
adventureworks   role_routine_grants                     routine_catalog                       character varying (NA)                        6                         NA  NA                                                                            
adventureworks   role_routine_grants                     routine_schema                        character varying (NA)                        7                         NA  NA                                                                            
adventureworks   role_routine_grants                     routine_name                          character varying (NA)                        8                         NA  NA                                                                            
adventureworks   role_routine_grants                     privilege_type                        character varying (NA)                        9                         NA  NA                                                                            
adventureworks   role_routine_grants                     is_grantable                          character varying (3)                        10                          3  NA                                                                            
adventureworks   routines                                specific_catalog                      character varying (NA)                        1                         NA  NA                                                                            
adventureworks   routines                                specific_schema                       character varying (NA)                        2                         NA  NA                                                                            
adventureworks   routines                                specific_name                         character varying (NA)                        3                         NA  NA                                                                            
adventureworks   routines                                routine_catalog                       character varying (NA)                        4                         NA  NA                                                                            
adventureworks   routines                                routine_schema                        character varying (NA)                        5                         NA  NA                                                                            
adventureworks   routines                                routine_name                          character varying (NA)                        6                         NA  NA                                                                            
adventureworks   routines                                routine_type                          character varying (NA)                        7                         NA  NA                                                                            
adventureworks   routines                                module_catalog                        character varying (NA)                        8                         NA  NA                                                                            
adventureworks   routines                                module_schema                         character varying (NA)                        9                         NA  NA                                                                            
adventureworks   routines                                module_name                           character varying (NA)                       10                         NA  NA                                                                            
adventureworks   routines                                udt_catalog                           character varying (NA)                       11                         NA  NA                                                                            
adventureworks   routines                                udt_schema                            character varying (NA)                       12                         NA  NA                                                                            
adventureworks   routines                                udt_name                              character varying (NA)                       13                         NA  NA                                                                            
adventureworks   routines                                data_type                             character varying (NA)                       14                         NA  NA                                                                            
adventureworks   routines                                character_maximum_length              integer                                      15                         NA  NA                                                                            
adventureworks   routines                                character_octet_length                integer                                      16                         NA  NA                                                                            
adventureworks   routines                                character_set_catalog                 character varying (NA)                       17                         NA  NA                                                                            
adventureworks   routines                                character_set_schema                  character varying (NA)                       18                         NA  NA                                                                            
adventureworks   routines                                character_set_name                    character varying (NA)                       19                         NA  NA                                                                            
adventureworks   routines                                collation_catalog                     character varying (NA)                       20                         NA  NA                                                                            
adventureworks   routines                                collation_schema                      character varying (NA)                       21                         NA  NA                                                                            
adventureworks   routines                                collation_name                        character varying (NA)                       22                         NA  NA                                                                            
adventureworks   routines                                numeric_precision                     integer                                      23                         NA  NA                                                                            
adventureworks   routines                                numeric_precision_radix               integer                                      24                         NA  NA                                                                            
adventureworks   routines                                numeric_scale                         integer                                      25                         NA  NA                                                                            
adventureworks   routines                                datetime_precision                    integer                                      26                         NA  NA                                                                            
adventureworks   routines                                interval_type                         character varying (NA)                       27                         NA  NA                                                                            
adventureworks   routines                                interval_precision                    integer                                      28                         NA  NA                                                                            
adventureworks   routines                                type_udt_catalog                      character varying (NA)                       29                         NA  NA                                                                            
adventureworks   routines                                type_udt_schema                       character varying (NA)                       30                         NA  NA                                                                            
adventureworks   routines                                type_udt_name                         character varying (NA)                       31                         NA  NA                                                                            
adventureworks   routines                                scope_catalog                         character varying (NA)                       32                         NA  NA                                                                            
adventureworks   routines                                scope_schema                          character varying (NA)                       33                         NA  NA                                                                            
adventureworks   routines                                scope_name                            character varying (NA)                       34                         NA  NA                                                                            
adventureworks   routines                                maximum_cardinality                   integer                                      35                         NA  NA                                                                            
adventureworks   routines                                dtd_identifier                        character varying (NA)                       36                         NA  NA                                                                            
adventureworks   routines                                routine_body                          character varying (NA)                       37                         NA  NA                                                                            
adventureworks   routines                                routine_definition                    character varying (NA)                       38                         NA  NA                                                                            
adventureworks   routines                                external_name                         character varying (NA)                       39                         NA  NA                                                                            
adventureworks   routines                                external_language                     character varying (NA)                       40                         NA  NA                                                                            
adventureworks   routines                                parameter_style                       character varying (NA)                       41                         NA  NA                                                                            
adventureworks   routines                                is_deterministic                      character varying (3)                        42                          3  NA                                                                            
adventureworks   routines                                sql_data_access                       character varying (NA)                       43                         NA  NA                                                                            
adventureworks   routines                                is_null_call                          character varying (3)                        44                          3  NA                                                                            
adventureworks   routines                                sql_path                              character varying (NA)                       45                         NA  NA                                                                            
adventureworks   routines                                schema_level_routine                  character varying (3)                        46                          3  NA                                                                            
adventureworks   routines                                max_dynamic_result_sets               integer                                      47                         NA  NA                                                                            
adventureworks   routines                                is_user_defined_cast                  character varying (3)                        48                          3  NA                                                                            
adventureworks   routines                                is_implicitly_invocable               character varying (3)                        49                          3  NA                                                                            
adventureworks   routines                                security_type                         character varying (NA)                       50                         NA  NA                                                                            
adventureworks   routines                                to_sql_specific_catalog               character varying (NA)                       51                         NA  NA                                                                            
adventureworks   routines                                to_sql_specific_schema                character varying (NA)                       52                         NA  NA                                                                            
adventureworks   routines                                to_sql_specific_name                  character varying (NA)                       53                         NA  NA                                                                            
adventureworks   routines                                as_locator                            character varying (3)                        54                          3  NA                                                                            
adventureworks   routines                                created                               timestamp with time zone                     55                         NA  NA                                                                            
adventureworks   routines                                last_altered                          timestamp with time zone                     56                         NA  NA                                                                            
adventureworks   routines                                new_savepoint_level                   character varying (3)                        57                          3  NA                                                                            
adventureworks   routines                                is_udt_dependent                      character varying (3)                        58                          3  NA                                                                            
adventureworks   routines                                result_cast_from_data_type            character varying (NA)                       59                         NA  NA                                                                            
adventureworks   routines                                result_cast_as_locator                character varying (3)                        60                          3  NA                                                                            
adventureworks   routines                                result_cast_char_max_length           integer                                      61                         NA  NA                                                                            
adventureworks   routines                                result_cast_char_octet_length         integer                                      62                         NA  NA                                                                            
adventureworks   routines                                result_cast_char_set_catalog          character varying (NA)                       63                         NA  NA                                                                            
adventureworks   routines                                result_cast_char_set_schema           character varying (NA)                       64                         NA  NA                                                                            
adventureworks   routines                                result_cast_char_set_name             character varying (NA)                       65                         NA  NA                                                                            
adventureworks   routines                                result_cast_collation_catalog         character varying (NA)                       66                         NA  NA                                                                            
adventureworks   routines                                result_cast_collation_schema          character varying (NA)                       67                         NA  NA                                                                            
adventureworks   routines                                result_cast_collation_name            character varying (NA)                       68                         NA  NA                                                                            
adventureworks   routines                                result_cast_numeric_precision         integer                                      69                         NA  NA                                                                            
adventureworks   routines                                result_cast_numeric_precision_radix   integer                                      70                         NA  NA                                                                            
adventureworks   routines                                result_cast_numeric_scale             integer                                      71                         NA  NA                                                                            
adventureworks   routines                                result_cast_datetime_precision        integer                                      72                         NA  NA                                                                            
adventureworks   routines                                result_cast_interval_type             character varying (NA)                       73                         NA  NA                                                                            
adventureworks   routines                                result_cast_interval_precision        integer                                      74                         NA  NA                                                                            
adventureworks   routines                                result_cast_type_udt_catalog          character varying (NA)                       75                         NA  NA                                                                            
adventureworks   routines                                result_cast_type_udt_schema           character varying (NA)                       76                         NA  NA                                                                            
adventureworks   routines                                result_cast_type_udt_name             character varying (NA)                       77                         NA  NA                                                                            
adventureworks   routines                                result_cast_scope_catalog             character varying (NA)                       78                         NA  NA                                                                            
adventureworks   routines                                result_cast_scope_schema              character varying (NA)                       79                         NA  NA                                                                            
adventureworks   routines                                result_cast_scope_name                character varying (NA)                       80                         NA  NA                                                                            
adventureworks   routines                                result_cast_maximum_cardinality       integer                                      81                         NA  NA                                                                            
adventureworks   routines                                result_cast_dtd_identifier            character varying (NA)                       82                         NA  NA                                                                            
adventureworks   schemata                                catalog_name                          character varying (NA)                        1                         NA  NA                                                                            
adventureworks   schemata                                schema_name                           character varying (NA)                        2                         NA  NA                                                                            
adventureworks   schemata                                schema_owner                          character varying (NA)                        3                         NA  NA                                                                            
adventureworks   schemata                                default_character_set_catalog         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   schemata                                default_character_set_schema          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   schemata                                default_character_set_name            character varying (NA)                        6                         NA  NA                                                                            
adventureworks   schemata                                sql_path                              character varying (NA)                        7                         NA  NA                                                                            
adventureworks   sequences                               sequence_catalog                      character varying (NA)                        1                         NA  NA                                                                            
adventureworks   sequences                               sequence_schema                       character varying (NA)                        2                         NA  NA                                                                            
adventureworks   sequences                               sequence_name                         character varying (NA)                        3                         NA  NA                                                                            
adventureworks   sequences                               data_type                             character varying (NA)                        4                         NA  NA                                                                            
adventureworks   sequences                               numeric_precision                     integer                                       5                         NA  NA                                                                            
adventureworks   sequences                               numeric_precision_radix               integer                                       6                         NA  NA                                                                            
adventureworks   sequences                               numeric_scale                         integer                                       7                         NA  NA                                                                            
adventureworks   sequences                               start_value                           character varying (NA)                        8                         NA  NA                                                                            
adventureworks   sequences                               minimum_value                         character varying (NA)                        9                         NA  NA                                                                            
adventureworks   sequences                               maximum_value                         character varying (NA)                       10                         NA  NA                                                                            
adventureworks   sequences                               increment                             character varying (NA)                       11                         NA  NA                                                                            
adventureworks   sequences                               cycle_option                          character varying (3)                        12                          3  NA                                                                            
adventureworks   sql_features                            feature_id                            character varying (NA)                        1                         NA  NA                                                                            
adventureworks   sql_features                            feature_name                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   sql_features                            sub_feature_id                        character varying (NA)                        3                         NA  NA                                                                            
adventureworks   sql_features                            sub_feature_name                      character varying (NA)                        4                         NA  NA                                                                            
adventureworks   sql_features                            is_supported                          character varying (3)                         5                          3  NA                                                                            
adventureworks   sql_features                            is_verified_by                        character varying (NA)                        6                         NA  NA                                                                            
adventureworks   sql_features                            comments                              character varying (NA)                        7                         NA  NA                                                                            
adventureworks   sql_implementation_info                 implementation_info_id                character varying (NA)                        1                         NA  NA                                                                            
adventureworks   sql_implementation_info                 implementation_info_name              character varying (NA)                        2                         NA  NA                                                                            
adventureworks   sql_implementation_info                 integer_value                         integer                                       3                         NA  NA                                                                            
adventureworks   sql_implementation_info                 character_value                       character varying (NA)                        4                         NA  NA                                                                            
adventureworks   sql_implementation_info                 comments                              character varying (NA)                        5                         NA  NA                                                                            
adventureworks   sql_languages                           sql_language_source                   character varying (NA)                        1                         NA  NA                                                                            
adventureworks   sql_languages                           sql_language_year                     character varying (NA)                        2                         NA  NA                                                                            
adventureworks   sql_languages                           sql_language_conformance              character varying (NA)                        3                         NA  NA                                                                            
adventureworks   sql_languages                           sql_language_integrity                character varying (NA)                        4                         NA  NA                                                                            
adventureworks   sql_languages                           sql_language_implementation           character varying (NA)                        5                         NA  NA                                                                            
adventureworks   sql_languages                           sql_language_binding_style            character varying (NA)                        6                         NA  NA                                                                            
adventureworks   sql_languages                           sql_language_programming_language     character varying (NA)                        7                         NA  NA                                                                            
adventureworks   sql_packages                            feature_id                            character varying (NA)                        1                         NA  NA                                                                            
adventureworks   sql_packages                            feature_name                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   sql_packages                            is_supported                          character varying (3)                         3                          3  NA                                                                            
adventureworks   sql_packages                            is_verified_by                        character varying (NA)                        4                         NA  NA                                                                            
adventureworks   sql_packages                            comments                              character varying (NA)                        5                         NA  NA                                                                            
adventureworks   sql_parts                               feature_id                            character varying (NA)                        1                         NA  NA                                                                            
adventureworks   sql_parts                               feature_name                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   sql_parts                               is_supported                          character varying (3)                         3                          3  NA                                                                            
adventureworks   sql_parts                               is_verified_by                        character varying (NA)                        4                         NA  NA                                                                            
adventureworks   sql_parts                               comments                              character varying (NA)                        5                         NA  NA                                                                            
adventureworks   sql_sizing                              sizing_id                             integer                                       1                         NA  NA                                                                            
adventureworks   sql_sizing                              sizing_name                           character varying (NA)                        2                         NA  NA                                                                            
adventureworks   sql_sizing                              supported_value                       integer                                       3                         NA  NA                                                                            
adventureworks   sql_sizing                              comments                              character varying (NA)                        4                         NA  NA                                                                            
adventureworks   sql_sizing_profiles                     sizing_id                             integer                                       1                         NA  NA                                                                            
adventureworks   sql_sizing_profiles                     sizing_name                           character varying (NA)                        2                         NA  NA                                                                            
adventureworks   sql_sizing_profiles                     profile_id                            character varying (NA)                        3                         NA  NA                                                                            
adventureworks   sql_sizing_profiles                     required_value                        integer                                       4                         NA  NA                                                                            
adventureworks   sql_sizing_profiles                     comments                              character varying (NA)                        5                         NA  NA                                                                            
adventureworks   table_constraints                       constraint_catalog                    character varying (NA)                        1                         NA  NA                                                                            
adventureworks   table_constraints                       constraint_schema                     character varying (NA)                        2                         NA  NA                                                                            
adventureworks   table_constraints                       constraint_name                       character varying (NA)                        3                         NA  NA                                                                            
adventureworks   table_constraints                       table_catalog                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   table_constraints                       table_schema                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   table_constraints                       table_name                            character varying (NA)                        6                         NA  NA                                                                            
adventureworks   table_constraints                       constraint_type                       character varying (NA)                        7                         NA  NA                                                                            
adventureworks   table_constraints                       is_deferrable                         character varying (3)                         8                          3  NA                                                                            
adventureworks   table_constraints                       initially_deferred                    character varying (3)                         9                          3  NA                                                                            
adventureworks   table_privileges                        grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   table_privileges                        grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   table_privileges                        table_catalog                         character varying (NA)                        3                         NA  NA                                                                            
adventureworks   table_privileges                        table_schema                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   table_privileges                        table_name                            character varying (NA)                        5                         NA  NA                                                                            
adventureworks   table_privileges                        privilege_type                        character varying (NA)                        6                         NA  NA                                                                            
adventureworks   table_privileges                        is_grantable                          character varying (3)                         7                          3  NA                                                                            
adventureworks   table_privileges                        with_hierarchy                        character varying (3)                         8                          3  NA                                                                            
adventureworks   role_table_grants                       grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   role_table_grants                       grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   role_table_grants                       table_catalog                         character varying (NA)                        3                         NA  NA                                                                            
adventureworks   role_table_grants                       table_schema                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   role_table_grants                       table_name                            character varying (NA)                        5                         NA  NA                                                                            
adventureworks   role_table_grants                       privilege_type                        character varying (NA)                        6                         NA  NA                                                                            
adventureworks   role_table_grants                       is_grantable                          character varying (3)                         7                          3  NA                                                                            
adventureworks   role_table_grants                       with_hierarchy                        character varying (3)                         8                          3  NA                                                                            
adventureworks   tables                                  table_catalog                         character varying (NA)                        1                         NA  NA                                                                            
adventureworks   tables                                  table_schema                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   tables                                  table_name                            character varying (NA)                        3                         NA  NA                                                                            
adventureworks   tables                                  table_type                            character varying (NA)                        4                         NA  NA                                                                            
adventureworks   tables                                  self_referencing_column_name          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   tables                                  reference_generation                  character varying (NA)                        6                         NA  NA                                                                            
adventureworks   tables                                  user_defined_type_catalog             character varying (NA)                        7                         NA  NA                                                                            
adventureworks   tables                                  user_defined_type_schema              character varying (NA)                        8                         NA  NA                                                                            
adventureworks   tables                                  user_defined_type_name                character varying (NA)                        9                         NA  NA                                                                            
adventureworks   tables                                  is_insertable_into                    character varying (3)                        10                          3  NA                                                                            
adventureworks   tables                                  is_typed                              character varying (3)                        11                          3  NA                                                                            
adventureworks   tables                                  commit_action                         character varying (NA)                       12                         NA  NA                                                                            
adventureworks   transforms                              udt_catalog                           character varying (NA)                        1                         NA  NA                                                                            
adventureworks   transforms                              udt_schema                            character varying (NA)                        2                         NA  NA                                                                            
adventureworks   transforms                              udt_name                              character varying (NA)                        3                         NA  NA                                                                            
adventureworks   transforms                              specific_catalog                      character varying (NA)                        4                         NA  NA                                                                            
adventureworks   transforms                              specific_schema                       character varying (NA)                        5                         NA  NA                                                                            
adventureworks   transforms                              specific_name                         character varying (NA)                        6                         NA  NA                                                                            
adventureworks   transforms                              group_name                            character varying (NA)                        7                         NA  NA                                                                            
adventureworks   transforms                              transform_type                        character varying (NA)                        8                         NA  NA                                                                            
adventureworks   triggered_update_columns                trigger_catalog                       character varying (NA)                        1                         NA  NA                                                                            
adventureworks   triggered_update_columns                trigger_schema                        character varying (NA)                        2                         NA  NA                                                                            
adventureworks   triggered_update_columns                trigger_name                          character varying (NA)                        3                         NA  NA                                                                            
adventureworks   triggered_update_columns                event_object_catalog                  character varying (NA)                        4                         NA  NA                                                                            
adventureworks   triggered_update_columns                event_object_schema                   character varying (NA)                        5                         NA  NA                                                                            
adventureworks   triggered_update_columns                event_object_table                    character varying (NA)                        6                         NA  NA                                                                            
adventureworks   triggered_update_columns                event_object_column                   character varying (NA)                        7                         NA  NA                                                                            
adventureworks   triggers                                trigger_catalog                       character varying (NA)                        1                         NA  NA                                                                            
adventureworks   triggers                                trigger_schema                        character varying (NA)                        2                         NA  NA                                                                            
adventureworks   triggers                                trigger_name                          character varying (NA)                        3                         NA  NA                                                                            
adventureworks   triggers                                event_manipulation                    character varying (NA)                        4                         NA  NA                                                                            
adventureworks   triggers                                event_object_catalog                  character varying (NA)                        5                         NA  NA                                                                            
adventureworks   triggers                                event_object_schema                   character varying (NA)                        6                         NA  NA                                                                            
adventureworks   triggers                                event_object_table                    character varying (NA)                        7                         NA  NA                                                                            
adventureworks   triggers                                action_order                          integer                                       8                         NA  NA                                                                            
adventureworks   triggers                                action_condition                      character varying (NA)                        9                         NA  NA                                                                            
adventureworks   triggers                                action_statement                      character varying (NA)                       10                         NA  NA                                                                            
adventureworks   triggers                                action_orientation                    character varying (NA)                       11                         NA  NA                                                                            
adventureworks   triggers                                action_timing                         character varying (NA)                       12                         NA  NA                                                                            
adventureworks   triggers                                action_reference_old_table            character varying (NA)                       13                         NA  NA                                                                            
adventureworks   triggers                                action_reference_new_table            character varying (NA)                       14                         NA  NA                                                                            
adventureworks   triggers                                action_reference_old_row              character varying (NA)                       15                         NA  NA                                                                            
adventureworks   triggers                                action_reference_new_row              character varying (NA)                       16                         NA  NA                                                                            
adventureworks   triggers                                created                               timestamp with time zone                     17                         NA  NA                                                                            
adventureworks   udt_privileges                          grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   udt_privileges                          grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   udt_privileges                          udt_catalog                           character varying (NA)                        3                         NA  NA                                                                            
adventureworks   udt_privileges                          udt_schema                            character varying (NA)                        4                         NA  NA                                                                            
adventureworks   udt_privileges                          udt_name                              character varying (NA)                        5                         NA  NA                                                                            
adventureworks   udt_privileges                          privilege_type                        character varying (NA)                        6                         NA  NA                                                                            
adventureworks   udt_privileges                          is_grantable                          character varying (3)                         7                          3  NA                                                                            
adventureworks   role_udt_grants                         grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   role_udt_grants                         grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   role_udt_grants                         udt_catalog                           character varying (NA)                        3                         NA  NA                                                                            
adventureworks   role_udt_grants                         udt_schema                            character varying (NA)                        4                         NA  NA                                                                            
adventureworks   role_udt_grants                         udt_name                              character varying (NA)                        5                         NA  NA                                                                            
adventureworks   role_udt_grants                         privilege_type                        character varying (NA)                        6                         NA  NA                                                                            
adventureworks   role_udt_grants                         is_grantable                          character varying (3)                         7                          3  NA                                                                            
adventureworks   usage_privileges                        grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   usage_privileges                        grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   usage_privileges                        object_catalog                        character varying (NA)                        3                         NA  NA                                                                            
adventureworks   usage_privileges                        object_schema                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   usage_privileges                        object_name                           character varying (NA)                        5                         NA  NA                                                                            
adventureworks   usage_privileges                        object_type                           character varying (NA)                        6                         NA  NA                                                                            
adventureworks   usage_privileges                        privilege_type                        character varying (NA)                        7                         NA  NA                                                                            
adventureworks   usage_privileges                        is_grantable                          character varying (3)                         8                          3  NA                                                                            
adventureworks   role_usage_grants                       grantor                               character varying (NA)                        1                         NA  NA                                                                            
adventureworks   role_usage_grants                       grantee                               character varying (NA)                        2                         NA  NA                                                                            
adventureworks   role_usage_grants                       object_catalog                        character varying (NA)                        3                         NA  NA                                                                            
adventureworks   role_usage_grants                       object_schema                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   role_usage_grants                       object_name                           character varying (NA)                        5                         NA  NA                                                                            
adventureworks   role_usage_grants                       object_type                           character varying (NA)                        6                         NA  NA                                                                            
adventureworks   role_usage_grants                       privilege_type                        character varying (NA)                        7                         NA  NA                                                                            
adventureworks   role_usage_grants                       is_grantable                          character varying (3)                         8                          3  NA                                                                            
adventureworks   user_defined_types                      user_defined_type_catalog             character varying (NA)                        1                         NA  NA                                                                            
adventureworks   user_defined_types                      user_defined_type_schema              character varying (NA)                        2                         NA  NA                                                                            
adventureworks   user_defined_types                      user_defined_type_name                character varying (NA)                        3                         NA  NA                                                                            
adventureworks   user_defined_types                      user_defined_type_category            character varying (NA)                        4                         NA  NA                                                                            
adventureworks   user_defined_types                      is_instantiable                       character varying (3)                         5                          3  NA                                                                            
adventureworks   user_defined_types                      is_final                              character varying (3)                         6                          3  NA                                                                            
adventureworks   user_defined_types                      ordering_form                         character varying (NA)                        7                         NA  NA                                                                            
adventureworks   user_defined_types                      ordering_category                     character varying (NA)                        8                         NA  NA                                                                            
adventureworks   user_defined_types                      ordering_routine_catalog              character varying (NA)                        9                         NA  NA                                                                            
adventureworks   user_defined_types                      ordering_routine_schema               character varying (NA)                       10                         NA  NA                                                                            
adventureworks   user_defined_types                      ordering_routine_name                 character varying (NA)                       11                         NA  NA                                                                            
adventureworks   user_defined_types                      reference_type                        character varying (NA)                       12                         NA  NA                                                                            
adventureworks   user_defined_types                      data_type                             character varying (NA)                       13                         NA  NA                                                                            
adventureworks   user_defined_types                      character_maximum_length              integer                                      14                         NA  NA                                                                            
adventureworks   user_defined_types                      character_octet_length                integer                                      15                         NA  NA                                                                            
adventureworks   user_defined_types                      character_set_catalog                 character varying (NA)                       16                         NA  NA                                                                            
adventureworks   user_defined_types                      character_set_schema                  character varying (NA)                       17                         NA  NA                                                                            
adventureworks   user_defined_types                      character_set_name                    character varying (NA)                       18                         NA  NA                                                                            
adventureworks   user_defined_types                      collation_catalog                     character varying (NA)                       19                         NA  NA                                                                            
adventureworks   user_defined_types                      collation_schema                      character varying (NA)                       20                         NA  NA                                                                            
adventureworks   user_defined_types                      collation_name                        character varying (NA)                       21                         NA  NA                                                                            
adventureworks   user_defined_types                      numeric_precision                     integer                                      22                         NA  NA                                                                            
adventureworks   user_defined_types                      numeric_precision_radix               integer                                      23                         NA  NA                                                                            
adventureworks   user_defined_types                      numeric_scale                         integer                                      24                         NA  NA                                                                            
adventureworks   user_defined_types                      datetime_precision                    integer                                      25                         NA  NA                                                                            
adventureworks   user_defined_types                      interval_type                         character varying (NA)                       26                         NA  NA                                                                            
adventureworks   user_defined_types                      interval_precision                    integer                                      27                         NA  NA                                                                            
adventureworks   user_defined_types                      source_dtd_identifier                 character varying (NA)                       28                         NA  NA                                                                            
adventureworks   user_defined_types                      ref_dtd_identifier                    character varying (NA)                       29                         NA  NA                                                                            
adventureworks   view_column_usage                       view_catalog                          character varying (NA)                        1                         NA  NA                                                                            
adventureworks   view_column_usage                       view_schema                           character varying (NA)                        2                         NA  NA                                                                            
adventureworks   view_column_usage                       view_name                             character varying (NA)                        3                         NA  NA                                                                            
adventureworks   view_column_usage                       table_catalog                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   view_column_usage                       table_schema                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   view_column_usage                       table_name                            character varying (NA)                        6                         NA  NA                                                                            
adventureworks   view_column_usage                       column_name                           character varying (NA)                        7                         NA  NA                                                                            
adventureworks   view_routine_usage                      table_catalog                         character varying (NA)                        1                         NA  NA                                                                            
adventureworks   view_routine_usage                      table_schema                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   view_routine_usage                      table_name                            character varying (NA)                        3                         NA  NA                                                                            
adventureworks   view_routine_usage                      specific_catalog                      character varying (NA)                        4                         NA  NA                                                                            
adventureworks   view_routine_usage                      specific_schema                       character varying (NA)                        5                         NA  NA                                                                            
adventureworks   view_routine_usage                      specific_name                         character varying (NA)                        6                         NA  NA                                                                            
adventureworks   view_table_usage                        view_catalog                          character varying (NA)                        1                         NA  NA                                                                            
adventureworks   view_table_usage                        view_schema                           character varying (NA)                        2                         NA  NA                                                                            
adventureworks   view_table_usage                        view_name                             character varying (NA)                        3                         NA  NA                                                                            
adventureworks   view_table_usage                        table_catalog                         character varying (NA)                        4                         NA  NA                                                                            
adventureworks   view_table_usage                        table_schema                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   view_table_usage                        table_name                            character varying (NA)                        6                         NA  NA                                                                            
adventureworks   views                                   table_catalog                         character varying (NA)                        1                         NA  NA                                                                            
adventureworks   views                                   table_schema                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   views                                   table_name                            character varying (NA)                        3                         NA  NA                                                                            
adventureworks   views                                   view_definition                       character varying (NA)                        4                         NA  NA                                                                            
adventureworks   views                                   check_option                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   views                                   is_updatable                          character varying (3)                         6                          3  NA                                                                            
adventureworks   views                                   is_insertable_into                    character varying (3)                         7                          3  NA                                                                            
adventureworks   views                                   is_trigger_updatable                  character varying (3)                         8                          3  NA                                                                            
adventureworks   views                                   is_trigger_deletable                  character varying (3)                         9                          3  NA                                                                            
adventureworks   views                                   is_trigger_insertable_into            character varying (3)                        10                          3  NA                                                                            
adventureworks   data_type_privileges                    object_catalog                        character varying (NA)                        1                         NA  NA                                                                            
adventureworks   data_type_privileges                    object_schema                         character varying (NA)                        2                         NA  NA                                                                            
adventureworks   data_type_privileges                    object_name                           character varying (NA)                        3                         NA  NA                                                                            
adventureworks   data_type_privileges                    object_type                           character varying (NA)                        4                         NA  NA                                                                            
adventureworks   data_type_privileges                    dtd_identifier                        character varying (NA)                        5                         NA  NA                                                                            
adventureworks   element_types                           object_catalog                        character varying (NA)                        1                         NA  NA                                                                            
adventureworks   element_types                           object_schema                         character varying (NA)                        2                         NA  NA                                                                            
adventureworks   element_types                           object_name                           character varying (NA)                        3                         NA  NA                                                                            
adventureworks   element_types                           object_type                           character varying (NA)                        4                         NA  NA                                                                            
adventureworks   element_types                           collection_type_identifier            character varying (NA)                        5                         NA  NA                                                                            
adventureworks   element_types                           data_type                             character varying (NA)                        6                         NA  NA                                                                            
adventureworks   element_types                           character_maximum_length              integer                                       7                         NA  NA                                                                            
adventureworks   element_types                           character_octet_length                integer                                       8                         NA  NA                                                                            
adventureworks   element_types                           character_set_catalog                 character varying (NA)                        9                         NA  NA                                                                            
adventureworks   element_types                           character_set_schema                  character varying (NA)                       10                         NA  NA                                                                            
adventureworks   element_types                           character_set_name                    character varying (NA)                       11                         NA  NA                                                                            
adventureworks   element_types                           collation_catalog                     character varying (NA)                       12                         NA  NA                                                                            
adventureworks   element_types                           collation_schema                      character varying (NA)                       13                         NA  NA                                                                            
adventureworks   element_types                           collation_name                        character varying (NA)                       14                         NA  NA                                                                            
adventureworks   element_types                           numeric_precision                     integer                                      15                         NA  NA                                                                            
adventureworks   element_types                           numeric_precision_radix               integer                                      16                         NA  NA                                                                            
adventureworks   element_types                           numeric_scale                         integer                                      17                         NA  NA                                                                            
adventureworks   element_types                           datetime_precision                    integer                                      18                         NA  NA                                                                            
adventureworks   element_types                           interval_type                         character varying (NA)                       19                         NA  NA                                                                            
adventureworks   element_types                           interval_precision                    integer                                      20                         NA  NA                                                                            
adventureworks   element_types                           domain_default                        character varying (NA)                       21                         NA  NA                                                                            
adventureworks   element_types                           udt_catalog                           character varying (NA)                       22                         NA  NA                                                                            
adventureworks   element_types                           udt_schema                            character varying (NA)                       23                         NA  NA                                                                            
adventureworks   element_types                           udt_name                              character varying (NA)                       24                         NA  NA                                                                            
adventureworks   element_types                           scope_catalog                         character varying (NA)                       25                         NA  NA                                                                            
adventureworks   element_types                           scope_schema                          character varying (NA)                       26                         NA  NA                                                                            
adventureworks   element_types                           scope_name                            character varying (NA)                       27                         NA  NA                                                                            
adventureworks   element_types                           maximum_cardinality                   integer                                      28                         NA  NA                                                                            
adventureworks   element_types                           dtd_identifier                        character varying (NA)                       29                         NA  NA                                                                            
adventureworks   _pg_foreign_table_columns               nspname                               name                                          1                         NA  NA                                                                            
adventureworks   _pg_foreign_table_columns               relname                               name                                          2                         NA  NA                                                                            
adventureworks   _pg_foreign_table_columns               attname                               name                                          3                         NA  NA                                                                            
adventureworks   _pg_foreign_table_columns               attfdwoptions                         ARRAY                                         4                         NA  NA                                                                            
adventureworks   column_options                          table_catalog                         character varying (NA)                        1                         NA  NA                                                                            
adventureworks   column_options                          table_schema                          character varying (NA)                        2                         NA  NA                                                                            
adventureworks   column_options                          table_name                            character varying (NA)                        3                         NA  NA                                                                            
adventureworks   column_options                          column_name                           character varying (NA)                        4                         NA  NA                                                                            
adventureworks   column_options                          option_name                           character varying (NA)                        5                         NA  NA                                                                            
adventureworks   column_options                          option_value                          character varying (NA)                        6                         NA  NA                                                                            
adventureworks   _pg_foreign_data_wrappers               oid                                   oid                                           1                         NA  NA                                                                            
adventureworks   _pg_foreign_data_wrappers               fdwowner                              oid                                           2                         NA  NA                                                                            
adventureworks   _pg_foreign_data_wrappers               fdwoptions                            ARRAY                                         3                         NA  NA                                                                            
adventureworks   _pg_foreign_data_wrappers               foreign_data_wrapper_catalog          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   _pg_foreign_data_wrappers               foreign_data_wrapper_name             character varying (NA)                        5                         NA  NA                                                                            
adventureworks   _pg_foreign_data_wrappers               authorization_identifier              character varying (NA)                        6                         NA  NA                                                                            
adventureworks   _pg_foreign_data_wrappers               foreign_data_wrapper_language         character varying (NA)                        7                         NA  NA                                                                            
adventureworks   foreign_data_wrapper_options            foreign_data_wrapper_catalog          character varying (NA)                        1                         NA  NA                                                                            
adventureworks   foreign_data_wrapper_options            foreign_data_wrapper_name             character varying (NA)                        2                         NA  NA                                                                            
adventureworks   foreign_data_wrapper_options            option_name                           character varying (NA)                        3                         NA  NA                                                                            
adventureworks   foreign_data_wrapper_options            option_value                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   foreign_data_wrappers                   foreign_data_wrapper_catalog          character varying (NA)                        1                         NA  NA                                                                            
adventureworks   foreign_data_wrappers                   foreign_data_wrapper_name             character varying (NA)                        2                         NA  NA                                                                            
adventureworks   foreign_data_wrappers                   authorization_identifier              character varying (NA)                        3                         NA  NA                                                                            
adventureworks   foreign_data_wrappers                   library_name                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   foreign_data_wrappers                   foreign_data_wrapper_language         character varying (NA)                        5                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     oid                                   oid                                           1                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     srvoptions                            ARRAY                                         2                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     foreign_server_catalog                character varying (NA)                        3                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     foreign_server_name                   character varying (NA)                        4                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     foreign_data_wrapper_catalog          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     foreign_data_wrapper_name             character varying (NA)                        6                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     foreign_server_type                   character varying (NA)                        7                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     foreign_server_version                character varying (NA)                        8                         NA  NA                                                                            
adventureworks   _pg_foreign_servers                     authorization_identifier              character varying (NA)                        9                         NA  NA                                                                            
adventureworks   foreign_server_options                  foreign_server_catalog                character varying (NA)                        1                         NA  NA                                                                            
adventureworks   foreign_server_options                  foreign_server_name                   character varying (NA)                        2                         NA  NA                                                                            
adventureworks   foreign_server_options                  option_name                           character varying (NA)                        3                         NA  NA                                                                            
adventureworks   foreign_server_options                  option_value                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   foreign_servers                         foreign_server_catalog                character varying (NA)                        1                         NA  NA                                                                            
adventureworks   foreign_servers                         foreign_server_name                   character varying (NA)                        2                         NA  NA                                                                            
adventureworks   foreign_servers                         foreign_data_wrapper_catalog          character varying (NA)                        3                         NA  NA                                                                            
adventureworks   foreign_servers                         foreign_data_wrapper_name             character varying (NA)                        4                         NA  NA                                                                            
adventureworks   foreign_servers                         foreign_server_type                   character varying (NA)                        5                         NA  NA                                                                            
adventureworks   foreign_servers                         foreign_server_version                character varying (NA)                        6                         NA  NA                                                                            
adventureworks   foreign_servers                         authorization_identifier              character varying (NA)                        7                         NA  NA                                                                            
adventureworks   _pg_foreign_tables                      foreign_table_catalog                 character varying (NA)                        1                         NA  NA                                                                            
adventureworks   _pg_foreign_tables                      foreign_table_schema                  character varying (NA)                        2                         NA  NA                                                                            
adventureworks   _pg_foreign_tables                      foreign_table_name                    character varying (NA)                        3                         NA  NA                                                                            
adventureworks   _pg_foreign_tables                      ftoptions                             ARRAY                                         4                         NA  NA                                                                            
adventureworks   _pg_foreign_tables                      foreign_server_catalog                character varying (NA)                        5                         NA  NA                                                                            
adventureworks   _pg_foreign_tables                      foreign_server_name                   character varying (NA)                        6                         NA  NA                                                                            
adventureworks   _pg_foreign_tables                      authorization_identifier              character varying (NA)                        7                         NA  NA                                                                            
adventureworks   foreign_table_options                   foreign_table_catalog                 character varying (NA)                        1                         NA  NA                                                                            
adventureworks   foreign_table_options                   foreign_table_schema                  character varying (NA)                        2                         NA  NA                                                                            
adventureworks   foreign_table_options                   foreign_table_name                    character varying (NA)                        3                         NA  NA                                                                            
adventureworks   foreign_table_options                   option_name                           character varying (NA)                        4                         NA  NA                                                                            
adventureworks   foreign_table_options                   option_value                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   foreign_tables                          foreign_table_catalog                 character varying (NA)                        1                         NA  NA                                                                            
adventureworks   foreign_tables                          foreign_table_schema                  character varying (NA)                        2                         NA  NA                                                                            
adventureworks   foreign_tables                          foreign_table_name                    character varying (NA)                        3                         NA  NA                                                                            
adventureworks   foreign_tables                          foreign_server_catalog                character varying (NA)                        4                         NA  NA                                                                            
adventureworks   foreign_tables                          foreign_server_name                   character varying (NA)                        5                         NA  NA                                                                            
adventureworks   _pg_user_mappings                       oid                                   oid                                           1                         NA  NA                                                                            
adventureworks   _pg_user_mappings                       umoptions                             ARRAY                                         2                         NA  NA                                                                            
adventureworks   _pg_user_mappings                       umuser                                oid                                           3                         NA  NA                                                                            
adventureworks   _pg_user_mappings                       authorization_identifier              character varying (NA)                        4                         NA  NA                                                                            
adventureworks   _pg_user_mappings                       foreign_server_catalog                character varying (NA)                        5                         NA  NA                                                                            
adventureworks   _pg_user_mappings                       foreign_server_name                   character varying (NA)                        6                         NA  NA                                                                            
adventureworks   _pg_user_mappings                       srvowner                              character varying (NA)                        7                         NA  NA                                                                            
adventureworks   user_mapping_options                    authorization_identifier              character varying (NA)                        1                         NA  NA                                                                            
adventureworks   user_mapping_options                    foreign_server_catalog                character varying (NA)                        2                         NA  NA                                                                            
adventureworks   user_mapping_options                    foreign_server_name                   character varying (NA)                        3                         NA  NA                                                                            
adventureworks   user_mapping_options                    option_name                           character varying (NA)                        4                         NA  NA                                                                            
adventureworks   user_mapping_options                    option_value                          character varying (NA)                        5                         NA  NA                                                                            
adventureworks   user_mappings                           authorization_identifier              character varying (NA)                        1                         NA  NA                                                                            
adventureworks   user_mappings                           foreign_server_catalog                character varying (NA)                        2                         NA  NA                                                                            
adventureworks   user_mappings                           foreign_server_name                   character varying (NA)                        3                         NA  NA                                                                            
adventureworks   employee                                salariedflag                          boolean                                       9                         NA  true                                                                          
adventureworks   employee                                vacationhours                         smallint                                     10                         NA  0                                                                             
adventureworks   employee                                sickleavehours                        smallint                                     11                         NA  0                                                                             
adventureworks   employee                                currentflag                           boolean                                      12                         NA  true                                                                          
adventureworks   employee                                rowguid                               uuid                                         13                         NA  uuid_generate_v1()                                                            
adventureworks   employee                                modifieddate                          timestamp without time zone                  14                         NA  now()                                                                         
adventureworks   employee                                organizationnode                      character varying (NA)                       15                         NA  '/'::character varying                                                        
adventureworks   e                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   e                                       businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   e                                       nationalidnumber                      character varying (15)                        3                         15  NA                                                                            
adventureworks   e                                       loginid                               character varying (256)                       4                        256  NA                                                                            
adventureworks   e                                       jobtitle                              character varying (50)                        5                         50  NA                                                                            
adventureworks   e                                       birthdate                             date                                          6                         NA  NA                                                                            
adventureworks   e                                       maritalstatus                         character                                     7                          1  NA                                                                            
adventureworks   e                                       gender                                character                                     8                          1  NA                                                                            
adventureworks   e                                       hiredate                              date                                          9                         NA  NA                                                                            
adventureworks   e                                       salariedflag                          boolean                                      10                         NA  NA                                                                            
adventureworks   e                                       vacationhours                         smallint                                     11                         NA  NA                                                                            
adventureworks   e                                       sickleavehours                        smallint                                     12                         NA  NA                                                                            
adventureworks   e                                       currentflag                           boolean                                      13                         NA  NA                                                                            
adventureworks   e                                       rowguid                               uuid                                         14                         NA  NA                                                                            
adventureworks   e                                       modifieddate                          timestamp without time zone                  15                         NA  NA                                                                            
adventureworks   e                                       organizationnode                      character varying (NA)                       16                         NA  NA                                                                            
adventureworks   employeedepartmenthistory               businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   employeedepartmenthistory               departmentid                          smallint                                      2                         NA  NA                                                                            
adventureworks   employeedepartmenthistory               shiftid                               smallint                                      3                         NA  NA                                                                            
adventureworks   employeedepartmenthistory               startdate                             date                                          4                         NA  NA                                                                            
adventureworks   employeedepartmenthistory               enddate                               date                                          5                         NA  NA                                                                            
adventureworks   employeedepartmenthistory               modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   edh                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   edh                                     businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   edh                                     departmentid                          smallint                                      3                         NA  NA                                                                            
adventureworks   edh                                     shiftid                               smallint                                      4                         NA  NA                                                                            
adventureworks   edh                                     startdate                             date                                          5                         NA  NA                                                                            
adventureworks   edh                                     enddate                               date                                          6                         NA  NA                                                                            
adventureworks   edh                                     modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   employeepayhistory                      businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   employeepayhistory                      ratechangedate                        timestamp without time zone                   2                         NA  NA                                                                            
adventureworks   employeepayhistory                      rate                                  numeric                                       3                         NA  NA                                                                            
adventureworks   employeepayhistory                      payfrequency                          smallint                                      4                         NA  NA                                                                            
adventureworks   employeepayhistory                      modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   eph                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   eph                                     businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   eph                                     ratechangedate                        timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   eph                                     rate                                  numeric                                       4                         NA  NA                                                                            
adventureworks   eph                                     payfrequency                          smallint                                      5                         NA  NA                                                                            
adventureworks   eph                                     modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   jobcandidate                            businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   jobcandidate                            resume                                xml                                           3                         NA  NA                                                                            
adventureworks   jobcandidate                            modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   jc                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   jc                                      jobcandidateid                        integer                                       2                         NA  NA                                                                            
adventureworks   jc                                      businessentityid                      integer                                       3                         NA  NA                                                                            
adventureworks   jc                                      resume                                xml                                           4                         NA  NA                                                                            
adventureworks   jc                                      modifieddate                          timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   shift                                   name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   shift                                   starttime                             time without time zone                        3                         NA  NA                                                                            
adventureworks   shift                                   endtime                               time without time zone                        4                         NA  NA                                                                            
adventureworks   shift                                   modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   s                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   s                                       shiftid                               integer                                       2                         NA  NA                                                                            
adventureworks   s                                       name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   s                                       starttime                             time without time zone                        4                         NA  NA                                                                            
adventureworks   s                                       endtime                               time without time zone                        5                         NA  NA                                                                            
adventureworks   s                                       modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   address                                 addressline1                          character varying (60)                        2                         60  NA                                                                            
adventureworks   address                                 addressline2                          character varying (60)                        3                         60  NA                                                                            
adventureworks   address                                 city                                  character varying (30)                        4                         30  NA                                                                            
adventureworks   address                                 stateprovinceid                       integer                                       5                         NA  NA                                                                            
adventureworks   address                                 postalcode                            character varying (15)                        6                         15  NA                                                                            
adventureworks   address                                 spatiallocation                       character varying (44)                        7                         44  NA                                                                            
adventureworks   address                                 rowguid                               uuid                                          8                         NA  uuid_generate_v1()                                                            
adventureworks   address                                 modifieddate                          timestamp without time zone                   9                         NA  now()                                                                         
adventureworks   businessentityaddress                   businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   businessentityaddress                   addressid                             integer                                       2                         NA  NA                                                                            
adventureworks   businessentityaddress                   addresstypeid                         integer                                       3                         NA  NA                                                                            
adventureworks   businessentityaddress                   rowguid                               uuid                                          4                         NA  uuid_generate_v1()                                                            
adventureworks   businessentityaddress                   modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   countryregion                           countryregioncode                     character varying (3)                         1                          3  NA                                                                            
adventureworks   countryregion                           name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   countryregion                           modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   emailaddress                            businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   emailaddress                            emailaddress                          character varying (50)                        3                         50  NA                                                                            
adventureworks   emailaddress                            rowguid                               uuid                                          4                         NA  uuid_generate_v1()                                                            
adventureworks   emailaddress                            modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   emailaddress                            emailaddressid                        integer                                       2                         NA  nextval('person.emailaddress_emailaddressid_seq'::regclass)                   
adventureworks   person                                  businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   person                                  persontype                            character                                     2                          2  NA                                                                            
adventureworks   person                                  title                                 character varying (8)                         4                          8  NA                                                                            
adventureworks   person                                  firstname                             character varying (50)                        5                         50  NA                                                                            
adventureworks   person                                  middlename                            character varying (50)                        6                         50  NA                                                                            
adventureworks   person                                  lastname                              character varying (50)                        7                         50  NA                                                                            
adventureworks   person                                  suffix                                character varying (10)                        8                         10  NA                                                                            
adventureworks   person                                  additionalcontactinfo                 xml                                          10                         NA  NA                                                                            
adventureworks   person                                  demographics                          xml                                          11                         NA  NA                                                                            
adventureworks   person                                  namestyle                             boolean                                       3                         NA  false                                                                         
adventureworks   person                                  emailpromotion                        integer                                       9                         NA  0                                                                             
adventureworks   person                                  rowguid                               uuid                                         12                         NA  uuid_generate_v1()                                                            
adventureworks   person                                  modifieddate                          timestamp without time zone                  13                         NA  now()                                                                         
adventureworks   personphone                             businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   personphone                             phonenumber                           character varying (25)                        2                         25  NA                                                                            
adventureworks   personphone                             phonenumbertypeid                     integer                                       3                         NA  NA                                                                            
adventureworks   personphone                             modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   phonenumbertype                         name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   phonenumbertype                         modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   stateprovince                           stateprovincecode                     character                                     2                          3  NA                                                                            
adventureworks   stateprovince                           countryregioncode                     character varying (3)                         3                          3  NA                                                                            
adventureworks   stateprovince                           name                                  character varying (50)                        5                         50  NA                                                                            
adventureworks   stateprovince                           territoryid                           integer                                       6                         NA  NA                                                                            
adventureworks   stateprovince                           isonlystateprovinceflag               boolean                                       4                         NA  true                                                                          
adventureworks   stateprovince                           rowguid                               uuid                                          7                         NA  uuid_generate_v1()                                                            
adventureworks   stateprovince                           modifieddate                          timestamp without time zone                   8                         NA  now()                                                                         
adventureworks   vemployee                               businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vemployee                               title                                 character varying (8)                         2                          8  NA                                                                            
adventureworks   vemployee                               firstname                             character varying (50)                        3                         50  NA                                                                            
adventureworks   vemployee                               middlename                            character varying (50)                        4                         50  NA                                                                            
adventureworks   vemployee                               lastname                              character varying (50)                        5                         50  NA                                                                            
adventureworks   vemployee                               suffix                                character varying (10)                        6                         10  NA                                                                            
adventureworks   vemployee                               jobtitle                              character varying (50)                        7                         50  NA                                                                            
adventureworks   vemployee                               phonenumber                           character varying (25)                        8                         25  NA                                                                            
adventureworks   vemployee                               phonenumbertype                       character varying (50)                        9                         50  NA                                                                            
adventureworks   vemployee                               emailaddress                          character varying (50)                       10                         50  NA                                                                            
adventureworks   vemployee                               emailpromotion                        integer                                      11                         NA  NA                                                                            
adventureworks   vemployee                               addressline1                          character varying (60)                       12                         60  NA                                                                            
adventureworks   vemployee                               addressline2                          character varying (60)                       13                         60  NA                                                                            
adventureworks   vemployee                               city                                  character varying (30)                       14                         30  NA                                                                            
adventureworks   vemployee                               stateprovincename                     character varying (50)                       15                         50  NA                                                                            
adventureworks   vemployee                               postalcode                            character varying (15)                       16                         15  NA                                                                            
adventureworks   vemployee                               countryregionname                     character varying (50)                       17                         50  NA                                                                            
adventureworks   vemployee                               additionalcontactinfo                 xml                                          18                         NA  NA                                                                            
adventureworks   vemployeedepartment                     businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vemployeedepartment                     title                                 character varying (8)                         2                          8  NA                                                                            
adventureworks   vemployeedepartment                     firstname                             character varying (50)                        3                         50  NA                                                                            
adventureworks   vemployeedepartment                     middlename                            character varying (50)                        4                         50  NA                                                                            
adventureworks   vemployeedepartment                     lastname                              character varying (50)                        5                         50  NA                                                                            
adventureworks   vemployeedepartment                     suffix                                character varying (10)                        6                         10  NA                                                                            
adventureworks   vemployeedepartment                     jobtitle                              character varying (50)                        7                         50  NA                                                                            
adventureworks   vemployeedepartment                     department                            character varying (50)                        8                         50  NA                                                                            
adventureworks   vemployeedepartment                     groupname                             character varying (50)                        9                         50  NA                                                                            
adventureworks   vemployeedepartment                     startdate                             date                                         10                         NA  NA                                                                            
adventureworks   vemployeedepartmenthistory              businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vemployeedepartmenthistory              title                                 character varying (8)                         2                          8  NA                                                                            
adventureworks   vemployeedepartmenthistory              firstname                             character varying (50)                        3                         50  NA                                                                            
adventureworks   vemployeedepartmenthistory              middlename                            character varying (50)                        4                         50  NA                                                                            
adventureworks   vemployeedepartmenthistory              lastname                              character varying (50)                        5                         50  NA                                                                            
adventureworks   vemployeedepartmenthistory              suffix                                character varying (10)                        6                         10  NA                                                                            
adventureworks   vemployeedepartmenthistory              shift                                 character varying (50)                        7                         50  NA                                                                            
adventureworks   vemployeedepartmenthistory              department                            character varying (50)                        8                         50  NA                                                                            
adventureworks   vemployeedepartmenthistory              groupname                             character varying (50)                        9                         50  NA                                                                            
adventureworks   vemployeedepartmenthistory              startdate                             date                                         10                         NA  NA                                                                            
adventureworks   vemployeedepartmenthistory              enddate                               date                                         11                         NA  NA                                                                            
adventureworks   vjobcandidate                           jobcandidateid                        integer                                       1                         NA  NA                                                                            
adventureworks   vjobcandidate                           businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   vjobcandidate                           Name.Prefix                           character varying (30)                        3                         30  NA                                                                            
adventureworks   vjobcandidate                           Name.First                            character varying (30)                        4                         30  NA                                                                            
adventureworks   vjobcandidate                           Name.Middle                           character varying (30)                        5                         30  NA                                                                            
adventureworks   vjobcandidate                           Name.Last                             character varying (30)                        6                         30  NA                                                                            
adventureworks   vjobcandidate                           Name.Suffix                           character varying (30)                        7                         30  NA                                                                            
adventureworks   vjobcandidate                           Skills                                character varying (NA)                        8                         NA  NA                                                                            
adventureworks   vjobcandidate                           Addr.Type                             character varying (30)                        9                         30  NA                                                                            
adventureworks   vjobcandidate                           Addr.Loc.CountryRegion                character varying (100)                      10                        100  NA                                                                            
adventureworks   vjobcandidate                           Addr.Loc.State                        character varying (100)                      11                        100  NA                                                                            
adventureworks   vjobcandidate                           Addr.Loc.City                         character varying (100)                      12                        100  NA                                                                            
adventureworks   vjobcandidate                           Addr.PostalCode                       character varying (20)                       13                         20  NA                                                                            
adventureworks   vjobcandidate                           EMail                                 character varying (NA)                       14                         NA  NA                                                                            
adventureworks   vjobcandidate                           WebSite                               character varying (NA)                       15                         NA  NA                                                                            
adventureworks   vjobcandidate                           modifieddate                          timestamp without time zone                  16                         NA  NA                                                                            
adventureworks   vjobcandidateeducation                  jobcandidateid                        integer                                       1                         NA  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.Level                             character varying (50)                        2                         50  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.StartDate                         date                                          3                         NA  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.EndDate                           date                                          4                         NA  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.Degree                            character varying (50)                        5                         50  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.Major                             character varying (50)                        6                         50  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.Minor                             character varying (50)                        7                         50  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.GPA                               character varying (5)                         8                          5  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.GPAScale                          character varying (5)                         9                          5  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.School                            character varying (100)                      10                        100  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.Loc.CountryRegion                 character varying (100)                      11                        100  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.Loc.State                         character varying (100)                      12                        100  NA                                                                            
adventureworks   vjobcandidateeducation                  Edu.Loc.City                          character varying (100)                      13                        100  NA                                                                            
adventureworks   vjobcandidateemployment                 jobcandidateid                        integer                                       1                         NA  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.StartDate                         date                                          2                         NA  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.EndDate                           date                                          3                         NA  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.OrgName                           character varying (100)                       4                        100  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.JobTitle                          character varying (100)                       5                        100  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.Responsibility                    character varying (NA)                        6                         NA  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.FunctionCategory                  character varying (NA)                        7                         NA  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.IndustryCategory                  character varying (NA)                        8                         NA  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.Loc.CountryRegion                 character varying (NA)                        9                         NA  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.Loc.State                         character varying (NA)                       10                         NA  NA                                                                            
adventureworks   vjobcandidateemployment                 Emp.Loc.City                          character varying (NA)                       11                         NA  NA                                                                            
adventureworks   a                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   a                                       addressid                             integer                                       2                         NA  NA                                                                            
adventureworks   a                                       addressline1                          character varying (60)                        3                         60  NA                                                                            
adventureworks   a                                       addressline2                          character varying (60)                        4                         60  NA                                                                            
adventureworks   a                                       city                                  character varying (30)                        5                         30  NA                                                                            
adventureworks   a                                       stateprovinceid                       integer                                       6                         NA  NA                                                                            
adventureworks   a                                       postalcode                            character varying (15)                        7                         15  NA                                                                            
adventureworks   a                                       spatiallocation                       character varying (44)                        8                         44  NA                                                                            
adventureworks   a                                       rowguid                               uuid                                          9                         NA  NA                                                                            
adventureworks   a                                       modifieddate                          timestamp without time zone                  10                         NA  NA                                                                            
adventureworks   addresstype                             name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   addresstype                             rowguid                               uuid                                          3                         NA  uuid_generate_v1()                                                            
adventureworks   addresstype                             modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   at                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   at                                      addresstypeid                         integer                                       2                         NA  NA                                                                            
adventureworks   at                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   at                                      rowguid                               uuid                                          4                         NA  NA                                                                            
adventureworks   at                                      modifieddate                          timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   addresstype                             addresstypeid                         integer                                       1                         NA  nextval('person.addresstype_addresstypeid_seq'::regclass)                     
adventureworks   businessentity                          businessentityid                      integer                                       1                         NA  nextval('person.businessentity_businessentityid_seq'::regclass)               
adventureworks   businessentity                          rowguid                               uuid                                          2                         NA  uuid_generate_v1()                                                            
adventureworks   businessentity                          modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   be                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   be                                      businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   be                                      rowguid                               uuid                                          3                         NA  NA                                                                            
adventureworks   be                                      modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   bea                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   bea                                     businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   bea                                     addressid                             integer                                       3                         NA  NA                                                                            
adventureworks   bea                                     addresstypeid                         integer                                       4                         NA  NA                                                                            
adventureworks   bea                                     rowguid                               uuid                                          5                         NA  NA                                                                            
adventureworks   bea                                     modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   businessentitycontact                   businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   businessentitycontact                   personid                              integer                                       2                         NA  NA                                                                            
adventureworks   businessentitycontact                   contacttypeid                         integer                                       3                         NA  NA                                                                            
adventureworks   businessentitycontact                   rowguid                               uuid                                          4                         NA  uuid_generate_v1()                                                            
adventureworks   businessentitycontact                   modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   bec                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   bec                                     businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   bec                                     personid                              integer                                       3                         NA  NA                                                                            
adventureworks   bec                                     contacttypeid                         integer                                       4                         NA  NA                                                                            
adventureworks   bec                                     rowguid                               uuid                                          5                         NA  NA                                                                            
adventureworks   bec                                     modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   cr                                      countryregioncode                     character varying (3)                         1                          3  NA                                                                            
adventureworks   cr                                      name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   cr                                      modifieddate                          timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   contacttype                             name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   contacttype                             modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   contacttype                             contacttypeid                         integer                                       1                         NA  nextval('person.contacttype_contacttypeid_seq'::regclass)                     
adventureworks   ct                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   ct                                      contacttypeid                         integer                                       2                         NA  NA                                                                            
adventureworks   ct                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   ct                                      modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   e                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   e                                       businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   e                                       emailaddressid                        integer                                       3                         NA  NA                                                                            
adventureworks   e                                       emailaddress                          character varying (50)                        4                         50  NA                                                                            
adventureworks   e                                       rowguid                               uuid                                          5                         NA  NA                                                                            
adventureworks   e                                       modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   p                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   p                                       businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   p                                       persontype                            character                                     3                          2  NA                                                                            
adventureworks   p                                       namestyle                             boolean                                       4                         NA  NA                                                                            
adventureworks   p                                       title                                 character varying (8)                         5                          8  NA                                                                            
adventureworks   p                                       firstname                             character varying (50)                        6                         50  NA                                                                            
adventureworks   p                                       middlename                            character varying (50)                        7                         50  NA                                                                            
adventureworks   p                                       lastname                              character varying (50)                        8                         50  NA                                                                            
adventureworks   p                                       suffix                                character varying (10)                        9                         10  NA                                                                            
adventureworks   p                                       emailpromotion                        integer                                      10                         NA  NA                                                                            
adventureworks   p                                       additionalcontactinfo                 xml                                          11                         NA  NA                                                                            
adventureworks   p                                       demographics                          xml                                          12                         NA  NA                                                                            
adventureworks   p                                       rowguid                               uuid                                         13                         NA  NA                                                                            
adventureworks   p                                       modifieddate                          timestamp without time zone                  14                         NA  NA                                                                            
adventureworks   password                                businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   password                                passwordhash                          character varying (128)                       2                        128  NA                                                                            
adventureworks   password                                passwordsalt                          character varying (10)                        3                         10  NA                                                                            
adventureworks   password                                rowguid                               uuid                                          4                         NA  uuid_generate_v1()                                                            
adventureworks   password                                modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   pa                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pa                                      businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   pa                                      passwordhash                          character varying (128)                       3                        128  NA                                                                            
adventureworks   pa                                      passwordsalt                          character varying (10)                        4                         10  NA                                                                            
adventureworks   pa                                      rowguid                               uuid                                          5                         NA  NA                                                                            
adventureworks   pa                                      modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   pnt                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pnt                                     phonenumbertypeid                     integer                                       2                         NA  NA                                                                            
adventureworks   pnt                                     name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   pnt                                     modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   pp                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pp                                      businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   pp                                      phonenumber                           character varying (25)                        3                         25  NA                                                                            
adventureworks   pp                                      phonenumbertypeid                     integer                                       4                         NA  NA                                                                            
adventureworks   pp                                      modifieddate                          timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   sp                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sp                                      stateprovinceid                       integer                                       2                         NA  NA                                                                            
adventureworks   sp                                      stateprovincecode                     character                                     3                          3  NA                                                                            
adventureworks   sp                                      countryregioncode                     character varying (3)                         4                          3  NA                                                                            
adventureworks   sp                                      isonlystateprovinceflag               boolean                                       5                         NA  NA                                                                            
adventureworks   sp                                      name                                  character varying (50)                        6                         50  NA                                                                            
adventureworks   sp                                      territoryid                           integer                                       7                         NA  NA                                                                            
adventureworks   sp                                      rowguid                               uuid                                          8                         NA  NA                                                                            
adventureworks   sp                                      modifieddate                          timestamp without time zone                   9                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  firstname                             character varying (50)                        2                         50  NA                                                                            
adventureworks   vadditionalcontactinfo                  middlename                            character varying (50)                        3                         50  NA                                                                            
adventureworks   vadditionalcontactinfo                  lastname                              character varying (50)                        4                         50  NA                                                                            
adventureworks   vadditionalcontactinfo                  telephonenumber                       xml                                           5                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  telephonespecialinstructions          text                                          6                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  street                                xml                                           7                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  city                                  xml                                           8                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  stateprovince                         xml                                           9                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  postalcode                            xml                                          10                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  countryregion                         xml                                          11                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  homeaddressspecialinstructions        xml                                          12                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  emailaddress                          xml                                          13                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  emailspecialinstructions              text                                         14                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  emailtelephonenumber                  xml                                          15                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  rowguid                               uuid                                         16                         NA  NA                                                                            
adventureworks   vadditionalcontactinfo                  modifieddate                          timestamp without time zone                  17                         NA  NA                                                                            
adventureworks   billofmaterials                         productassemblyid                     integer                                       2                         NA  NA                                                                            
adventureworks   billofmaterials                         componentid                           integer                                       3                         NA  NA                                                                            
adventureworks   billofmaterials                         enddate                               timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   billofmaterials                         unitmeasurecode                       character                                     6                          3  NA                                                                            
adventureworks   billofmaterials                         bomlevel                              smallint                                      7                         NA  NA                                                                            
adventureworks   billofmaterials                         startdate                             timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   billofmaterials                         perassemblyqty                        numeric                                       8                         NA  1.00                                                                          
adventureworks   billofmaterials                         modifieddate                          timestamp without time zone                   9                         NA  now()                                                                         
adventureworks   bom                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   bom                                     billofmaterialsid                     integer                                       2                         NA  NA                                                                            
adventureworks   bom                                     productassemblyid                     integer                                       3                         NA  NA                                                                            
adventureworks   bom                                     componentid                           integer                                       4                         NA  NA                                                                            
adventureworks   bom                                     startdate                             timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   bom                                     enddate                               timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   bom                                     unitmeasurecode                       character                                     7                          3  NA                                                                            
adventureworks   bom                                     bomlevel                              smallint                                      8                         NA  NA                                                                            
adventureworks   bom                                     perassemblyqty                        numeric                                       9                         NA  NA                                                                            
adventureworks   bom                                     modifieddate                          timestamp without time zone                  10                         NA  NA                                                                            
adventureworks   culture                                 cultureid                             character                                     1                          6  NA                                                                            
adventureworks   culture                                 name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   culture                                 modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   c                                       id                                    character                                     1                          6  NA                                                                            
adventureworks   c                                       cultureid                             character                                     2                          6  NA                                                                            
adventureworks   c                                       name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   c                                       modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   document                                title                                 character varying (50)                        1                         50  NA                                                                            
adventureworks   document                                owner                                 integer                                       2                         NA  NA                                                                            
adventureworks   document                                filename                              character varying (400)                       4                        400  NA                                                                            
adventureworks   billofmaterials                         billofmaterialsid                     integer                                       1                         NA  nextval('production.billofmaterials_billofmaterialsid_seq'::regclass)         
adventureworks   document                                fileextension                         character varying (8)                         5                          8  NA                                                                            
adventureworks   document                                revision                              character                                     6                          5  NA                                                                            
adventureworks   document                                status                                smallint                                      8                         NA  NA                                                                            
adventureworks   document                                documentsummary                       text                                          9                         NA  NA                                                                            
adventureworks   document                                document                              bytea                                        10                         NA  NA                                                                            
adventureworks   document                                folderflag                            boolean                                       3                         NA  false                                                                         
adventureworks   document                                changenumber                          integer                                       7                         NA  0                                                                             
adventureworks   document                                rowguid                               uuid                                         11                         NA  uuid_generate_v1()                                                            
adventureworks   document                                modifieddate                          timestamp without time zone                  12                         NA  now()                                                                         
adventureworks   document                                documentnode                          character varying (NA)                       13                         NA  '/'::character varying                                                        
adventureworks   d                                       title                                 character varying (50)                        1                         50  NA                                                                            
adventureworks   d                                       owner                                 integer                                       2                         NA  NA                                                                            
adventureworks   d                                       folderflag                            boolean                                       3                         NA  NA                                                                            
adventureworks   d                                       filename                              character varying (400)                       4                        400  NA                                                                            
adventureworks   d                                       fileextension                         character varying (8)                         5                          8  NA                                                                            
adventureworks   d                                       revision                              character                                     6                          5  NA                                                                            
adventureworks   d                                       changenumber                          integer                                       7                         NA  NA                                                                            
adventureworks   d                                       status                                smallint                                      8                         NA  NA                                                                            
adventureworks   d                                       documentsummary                       text                                          9                         NA  NA                                                                            
adventureworks   d                                       document                              bytea                                        10                         NA  NA                                                                            
adventureworks   d                                       rowguid                               uuid                                         11                         NA  NA                                                                            
adventureworks   d                                       modifieddate                          timestamp without time zone                  12                         NA  NA                                                                            
adventureworks   d                                       documentnode                          character varying (NA)                       13                         NA  NA                                                                            
adventureworks   illustration                            diagram                               xml                                           2                         NA  NA                                                                            
adventureworks   illustration                            modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   illustration                            illustrationid                        integer                                       1                         NA  nextval('production.illustration_illustrationid_seq'::regclass)               
adventureworks   i                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   i                                       illustrationid                        integer                                       2                         NA  NA                                                                            
adventureworks   i                                       diagram                               xml                                           3                         NA  NA                                                                            
adventureworks   i                                       modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   location                                name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   location                                costrate                              numeric                                       3                         NA  0.00                                                                          
adventureworks   location                                availability                          numeric                                       4                         NA  0.00                                                                          
adventureworks   location                                modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   l                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   l                                       locationid                            integer                                       2                         NA  NA                                                                            
adventureworks   l                                       name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   l                                       costrate                              numeric                                       4                         NA  NA                                                                            
adventureworks   l                                       availability                          numeric                                       5                         NA  NA                                                                            
adventureworks   l                                       modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   product                                 name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   product                                 productnumber                         character varying (25)                        3                         25  NA                                                                            
adventureworks   product                                 color                                 character varying (15)                        6                         15  NA                                                                            
adventureworks   product                                 safetystocklevel                      smallint                                      7                         NA  NA                                                                            
adventureworks   product                                 reorderpoint                          smallint                                      8                         NA  NA                                                                            
adventureworks   product                                 standardcost                          numeric                                       9                         NA  NA                                                                            
adventureworks   product                                 listprice                             numeric                                      10                         NA  NA                                                                            
adventureworks   product                                 size                                  character varying (5)                        11                          5  NA                                                                            
adventureworks   product                                 sizeunitmeasurecode                   character                                    12                          3  NA                                                                            
adventureworks   product                                 weightunitmeasurecode                 character                                    13                          3  NA                                                                            
adventureworks   product                                 weight                                numeric                                      14                         NA  NA                                                                            
adventureworks   product                                 makeflag                              boolean                                       4                         NA  true                                                                          
adventureworks   product                                 finishedgoodsflag                     boolean                                       5                         NA  true                                                                          
adventureworks   location                                locationid                            integer                                       1                         NA  nextval('production.location_locationid_seq'::regclass)                       
adventureworks   product                                 productid                             integer                                       1                         NA  nextval('production.product_productid_seq'::regclass)                         
adventureworks   product                                 daystomanufacture                     integer                                      15                         NA  NA                                                                            
adventureworks   product                                 productline                           character                                    16                          2  NA                                                                            
adventureworks   product                                 class                                 character                                    17                          2  NA                                                                            
adventureworks   product                                 style                                 character                                    18                          2  NA                                                                            
adventureworks   product                                 productsubcategoryid                  integer                                      19                         NA  NA                                                                            
adventureworks   product                                 productmodelid                        integer                                      20                         NA  NA                                                                            
adventureworks   product                                 sellstartdate                         timestamp without time zone                  21                         NA  NA                                                                            
adventureworks   product                                 sellenddate                           timestamp without time zone                  22                         NA  NA                                                                            
adventureworks   product                                 discontinueddate                      timestamp without time zone                  23                         NA  NA                                                                            
adventureworks   product                                 rowguid                               uuid                                         24                         NA  uuid_generate_v1()                                                            
adventureworks   product                                 modifieddate                          timestamp without time zone                  25                         NA  now()                                                                         
adventureworks   p                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   p                                       productid                             integer                                       2                         NA  NA                                                                            
adventureworks   p                                       name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   p                                       productnumber                         character varying (25)                        4                         25  NA                                                                            
adventureworks   p                                       makeflag                              boolean                                       5                         NA  NA                                                                            
adventureworks   p                                       finishedgoodsflag                     boolean                                       6                         NA  NA                                                                            
adventureworks   p                                       color                                 character varying (15)                        7                         15  NA                                                                            
adventureworks   p                                       safetystocklevel                      smallint                                      8                         NA  NA                                                                            
adventureworks   p                                       reorderpoint                          smallint                                      9                         NA  NA                                                                            
adventureworks   p                                       standardcost                          numeric                                      10                         NA  NA                                                                            
adventureworks   p                                       listprice                             numeric                                      11                         NA  NA                                                                            
adventureworks   p                                       size                                  character varying (5)                        12                          5  NA                                                                            
adventureworks   p                                       sizeunitmeasurecode                   character                                    13                          3  NA                                                                            
adventureworks   p                                       weightunitmeasurecode                 character                                    14                          3  NA                                                                            
adventureworks   p                                       weight                                numeric                                      15                         NA  NA                                                                            
adventureworks   p                                       daystomanufacture                     integer                                      16                         NA  NA                                                                            
adventureworks   p                                       productline                           character                                    17                          2  NA                                                                            
adventureworks   p                                       class                                 character                                    18                          2  NA                                                                            
adventureworks   p                                       style                                 character                                    19                          2  NA                                                                            
adventureworks   p                                       productsubcategoryid                  integer                                      20                         NA  NA                                                                            
adventureworks   p                                       productmodelid                        integer                                      21                         NA  NA                                                                            
adventureworks   p                                       sellstartdate                         timestamp without time zone                  22                         NA  NA                                                                            
adventureworks   p                                       sellenddate                           timestamp without time zone                  23                         NA  NA                                                                            
adventureworks   p                                       discontinueddate                      timestamp without time zone                  24                         NA  NA                                                                            
adventureworks   p                                       rowguid                               uuid                                         25                         NA  NA                                                                            
adventureworks   p                                       modifieddate                          timestamp without time zone                  26                         NA  NA                                                                            
adventureworks   productcategory                         name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   productcategory                         rowguid                               uuid                                          3                         NA  uuid_generate_v1()                                                            
adventureworks   productcategory                         modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   pc                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pc                                      productcategoryid                     integer                                       2                         NA  NA                                                                            
adventureworks   pc                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   pc                                      rowguid                               uuid                                          4                         NA  NA                                                                            
adventureworks   pc                                      modifieddate                          timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   productcosthistory                      productid                             integer                                       1                         NA  NA                                                                            
adventureworks   productcosthistory                      startdate                             timestamp without time zone                   2                         NA  NA                                                                            
adventureworks   productcosthistory                      enddate                               timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   productcosthistory                      standardcost                          numeric                                       4                         NA  NA                                                                            
adventureworks   productcosthistory                      modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   pch                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pch                                     productid                             integer                                       2                         NA  NA                                                                            
adventureworks   pch                                     startdate                             timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   pch                                     enddate                               timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   pch                                     standardcost                          numeric                                       5                         NA  NA                                                                            
adventureworks   pch                                     modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   productdescription                      description                           character varying (400)                       2                        400  NA                                                                            
adventureworks   productdescription                      rowguid                               uuid                                          3                         NA  uuid_generate_v1()                                                            
adventureworks   productdescription                      modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   pd                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pd                                      productdescriptionid                  integer                                       2                         NA  NA                                                                            
adventureworks   pd                                      description                           character varying (400)                       3                        400  NA                                                                            
adventureworks   pd                                      rowguid                               uuid                                          4                         NA  NA                                                                            
adventureworks   pd                                      modifieddate                          timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   productdocument                         productid                             integer                                       1                         NA  NA                                                                            
adventureworks   productdocument                         modifieddate                          timestamp without time zone                   2                         NA  now()                                                                         
adventureworks   productdocument                         documentnode                          character varying (NA)                        3                         NA  '/'::character varying                                                        
adventureworks   pdoc                                    id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pdoc                                    productid                             integer                                       2                         NA  NA                                                                            
adventureworks   pdoc                                    modifieddate                          timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   pdoc                                    documentnode                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   productinventory                        productid                             integer                                       1                         NA  NA                                                                            
adventureworks   productinventory                        locationid                            smallint                                      2                         NA  NA                                                                            
adventureworks   productinventory                        shelf                                 character varying (10)                        3                         10  NA                                                                            
adventureworks   productinventory                        bin                                   smallint                                      4                         NA  NA                                                                            
adventureworks   productinventory                        quantity                              smallint                                      5                         NA  0                                                                             
adventureworks   productinventory                        rowguid                               uuid                                          6                         NA  uuid_generate_v1()                                                            
adventureworks   productinventory                        modifieddate                          timestamp without time zone                   7                         NA  now()                                                                         
adventureworks   productdescription                      productdescriptionid                  integer                                       1                         NA  nextval('production.productdescription_productdescriptionid_seq'::regclass)   
adventureworks   pi                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pi                                      productid                             integer                                       2                         NA  NA                                                                            
adventureworks   pi                                      locationid                            smallint                                      3                         NA  NA                                                                            
adventureworks   pi                                      shelf                                 character varying (10)                        4                         10  NA                                                                            
adventureworks   pi                                      bin                                   smallint                                      5                         NA  NA                                                                            
adventureworks   pi                                      quantity                              smallint                                      6                         NA  NA                                                                            
adventureworks   pi                                      rowguid                               uuid                                          7                         NA  NA                                                                            
adventureworks   pi                                      modifieddate                          timestamp without time zone                   8                         NA  NA                                                                            
adventureworks   productlistpricehistory                 productid                             integer                                       1                         NA  NA                                                                            
adventureworks   productlistpricehistory                 startdate                             timestamp without time zone                   2                         NA  NA                                                                            
adventureworks   productlistpricehistory                 enddate                               timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   productlistpricehistory                 listprice                             numeric                                       4                         NA  NA                                                                            
adventureworks   productlistpricehistory                 modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   plph                                    id                                    integer                                       1                         NA  NA                                                                            
adventureworks   plph                                    productid                             integer                                       2                         NA  NA                                                                            
adventureworks   plph                                    startdate                             timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   plph                                    enddate                               timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   plph                                    listprice                             numeric                                       5                         NA  NA                                                                            
adventureworks   plph                                    modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   productmodel                            name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   productmodel                            catalogdescription                    xml                                           3                         NA  NA                                                                            
adventureworks   productmodel                            instructions                          xml                                           4                         NA  NA                                                                            
adventureworks   productmodel                            rowguid                               uuid                                          5                         NA  uuid_generate_v1()                                                            
adventureworks   productmodel                            modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   productmodel                            productmodelid                        integer                                       1                         NA  nextval('production.productmodel_productmodelid_seq'::regclass)               
adventureworks   pm                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pm                                      productmodelid                        integer                                       2                         NA  NA                                                                            
adventureworks   pm                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   pm                                      catalogdescription                    xml                                           4                         NA  NA                                                                            
adventureworks   pm                                      instructions                          xml                                           5                         NA  NA                                                                            
adventureworks   pm                                      rowguid                               uuid                                          6                         NA  NA                                                                            
adventureworks   pm                                      modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   productmodelillustration                productmodelid                        integer                                       1                         NA  NA                                                                            
adventureworks   productmodelillustration                illustrationid                        integer                                       2                         NA  NA                                                                            
adventureworks   productmodelillustration                modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   pmi                                     productmodelid                        integer                                       1                         NA  NA                                                                            
adventureworks   pmi                                     illustrationid                        integer                                       2                         NA  NA                                                                            
adventureworks   pmi                                     modifieddate                          timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   productmodelproductdescriptionculture   productmodelid                        integer                                       1                         NA  NA                                                                            
adventureworks   productmodelproductdescriptionculture   productdescriptionid                  integer                                       2                         NA  NA                                                                            
adventureworks   productmodelproductdescriptionculture   cultureid                             character                                     3                          6  NA                                                                            
adventureworks   productmodelproductdescriptionculture   modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   pmpdc                                   productmodelid                        integer                                       1                         NA  NA                                                                            
adventureworks   pmpdc                                   productdescriptionid                  integer                                       2                         NA  NA                                                                            
adventureworks   pmpdc                                   cultureid                             character                                     3                          6  NA                                                                            
adventureworks   pmpdc                                   modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   productphoto                            thumbnailphoto                        bytea                                         2                         NA  NA                                                                            
adventureworks   productphoto                            thumbnailphotofilename                character varying (50)                        3                         50  NA                                                                            
adventureworks   productphoto                            largephoto                            bytea                                         4                         NA  NA                                                                            
adventureworks   productphoto                            largephotofilename                    character varying (50)                        5                         50  NA                                                                            
adventureworks   productphoto                            modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   productphoto                            productphotoid                        integer                                       1                         NA  nextval('production.productphoto_productphotoid_seq'::regclass)               
adventureworks   pp                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pp                                      productphotoid                        integer                                       2                         NA  NA                                                                            
adventureworks   pp                                      thumbnailphoto                        bytea                                         3                         NA  NA                                                                            
adventureworks   pp                                      thumbnailphotofilename                character varying (50)                        4                         50  NA                                                                            
adventureworks   pp                                      largephoto                            bytea                                         5                         NA  NA                                                                            
adventureworks   pp                                      largephotofilename                    character varying (50)                        6                         50  NA                                                                            
adventureworks   pp                                      modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   productproductphoto                     productid                             integer                                       1                         NA  NA                                                                            
adventureworks   productproductphoto                     productphotoid                        integer                                       2                         NA  NA                                                                            
adventureworks   productproductphoto                     primary                               boolean                                       3                         NA  false                                                                         
adventureworks   productproductphoto                     modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   ppp                                     productid                             integer                                       1                         NA  NA                                                                            
adventureworks   ppp                                     productphotoid                        integer                                       2                         NA  NA                                                                            
adventureworks   ppp                                     primary                               boolean                                       3                         NA  NA                                                                            
adventureworks   ppp                                     modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   productreview                           productid                             integer                                       2                         NA  NA                                                                            
adventureworks   productreview                           reviewername                          character varying (50)                        3                         50  NA                                                                            
adventureworks   productreview                           emailaddress                          character varying (50)                        5                         50  NA                                                                            
adventureworks   productreview                           rating                                integer                                       6                         NA  NA                                                                            
adventureworks   productreview                           comments                              character varying (3850)                      7                       3850  NA                                                                            
adventureworks   productreview                           reviewdate                            timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   productreview                           modifieddate                          timestamp without time zone                   8                         NA  now()                                                                         
adventureworks   productreview                           productreviewid                       integer                                       1                         NA  nextval('production.productreview_productreviewid_seq'::regclass)             
adventureworks   pr                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pr                                      productreviewid                       integer                                       2                         NA  NA                                                                            
adventureworks   pr                                      productid                             integer                                       3                         NA  NA                                                                            
adventureworks   pr                                      reviewername                          character varying (50)                        4                         50  NA                                                                            
adventureworks   pr                                      reviewdate                            timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   pr                                      emailaddress                          character varying (50)                        6                         50  NA                                                                            
adventureworks   pr                                      rating                                integer                                       7                         NA  NA                                                                            
adventureworks   pr                                      comments                              character varying (3850)                      8                       3850  NA                                                                            
adventureworks   pr                                      modifieddate                          timestamp without time zone                   9                         NA  NA                                                                            
adventureworks   productsubcategory                      productcategoryid                     integer                                       2                         NA  NA                                                                            
adventureworks   productsubcategory                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   productsubcategory                      rowguid                               uuid                                          4                         NA  uuid_generate_v1()                                                            
adventureworks   productsubcategory                      modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   psc                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   psc                                     productsubcategoryid                  integer                                       2                         NA  NA                                                                            
adventureworks   psc                                     productcategoryid                     integer                                       3                         NA  NA                                                                            
adventureworks   psc                                     name                                  character varying (50)                        4                         50  NA                                                                            
adventureworks   psc                                     rowguid                               uuid                                          5                         NA  NA                                                                            
adventureworks   psc                                     modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   scrapreason                             name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   scrapreason                             modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   productsubcategory                      productsubcategoryid                  integer                                       1                         NA  nextval('production.productsubcategory_productsubcategoryid_seq'::regclass)   
adventureworks   sr                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sr                                      scrapreasonid                         integer                                       2                         NA  NA                                                                            
adventureworks   sr                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   sr                                      modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   transactionhistory                      productid                             integer                                       2                         NA  NA                                                                            
adventureworks   transactionhistory                      referenceorderid                      integer                                       3                         NA  NA                                                                            
adventureworks   transactionhistory                      transactiontype                       character                                     6                          1  NA                                                                            
adventureworks   transactionhistory                      quantity                              integer                                       7                         NA  NA                                                                            
adventureworks   transactionhistory                      actualcost                            numeric                                       8                         NA  NA                                                                            
adventureworks   transactionhistory                      referenceorderlineid                  integer                                       4                         NA  0                                                                             
adventureworks   transactionhistory                      transactiondate                       timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   transactionhistory                      modifieddate                          timestamp without time zone                   9                         NA  now()                                                                         
adventureworks   th                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   th                                      transactionid                         integer                                       2                         NA  NA                                                                            
adventureworks   th                                      productid                             integer                                       3                         NA  NA                                                                            
adventureworks   th                                      referenceorderid                      integer                                       4                         NA  NA                                                                            
adventureworks   th                                      referenceorderlineid                  integer                                       5                         NA  NA                                                                            
adventureworks   th                                      transactiondate                       timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   th                                      transactiontype                       character                                     7                          1  NA                                                                            
adventureworks   th                                      quantity                              integer                                       8                         NA  NA                                                                            
adventureworks   th                                      actualcost                            numeric                                       9                         NA  NA                                                                            
adventureworks   th                                      modifieddate                          timestamp without time zone                  10                         NA  NA                                                                            
adventureworks   transactionhistoryarchive               transactionid                         integer                                       1                         NA  NA                                                                            
adventureworks   transactionhistoryarchive               productid                             integer                                       2                         NA  NA                                                                            
adventureworks   transactionhistoryarchive               referenceorderid                      integer                                       3                         NA  NA                                                                            
adventureworks   transactionhistoryarchive               transactiontype                       character                                     6                          1  NA                                                                            
adventureworks   transactionhistoryarchive               quantity                              integer                                       7                         NA  NA                                                                            
adventureworks   transactionhistoryarchive               actualcost                            numeric                                       8                         NA  NA                                                                            
adventureworks   transactionhistory                      transactionid                         integer                                       1                         NA  nextval('production.transactionhistory_transactionid_seq'::regclass)          
adventureworks   transactionhistoryarchive               referenceorderlineid                  integer                                       4                         NA  0                                                                             
adventureworks   transactionhistoryarchive               transactiondate                       timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   transactionhistoryarchive               modifieddate                          timestamp without time zone                   9                         NA  now()                                                                         
adventureworks   tha                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   tha                                     transactionid                         integer                                       2                         NA  NA                                                                            
adventureworks   tha                                     productid                             integer                                       3                         NA  NA                                                                            
adventureworks   tha                                     referenceorderid                      integer                                       4                         NA  NA                                                                            
adventureworks   tha                                     referenceorderlineid                  integer                                       5                         NA  NA                                                                            
adventureworks   tha                                     transactiondate                       timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   tha                                     transactiontype                       character                                     7                          1  NA                                                                            
adventureworks   tha                                     quantity                              integer                                       8                         NA  NA                                                                            
adventureworks   tha                                     actualcost                            numeric                                       9                         NA  NA                                                                            
adventureworks   tha                                     modifieddate                          timestamp without time zone                  10                         NA  NA                                                                            
adventureworks   unitmeasure                             unitmeasurecode                       character                                     1                          3  NA                                                                            
adventureworks   unitmeasure                             name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   unitmeasure                             modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   um                                      id                                    character                                     1                          3  NA                                                                            
adventureworks   um                                      unitmeasurecode                       character                                     2                          3  NA                                                                            
adventureworks   um                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   um                                      modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   workorder                               productid                             integer                                       2                         NA  NA                                                                            
adventureworks   workorder                               orderqty                              integer                                       3                         NA  NA                                                                            
adventureworks   workorder                               scrappedqty                           smallint                                      4                         NA  NA                                                                            
adventureworks   workorder                               startdate                             timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   workorder                               enddate                               timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   workorder                               duedate                               timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   workorder                               scrapreasonid                         smallint                                      8                         NA  NA                                                                            
adventureworks   workorder                               modifieddate                          timestamp without time zone                   9                         NA  now()                                                                         
adventureworks   w                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   w                                       workorderid                           integer                                       2                         NA  NA                                                                            
adventureworks   w                                       productid                             integer                                       3                         NA  NA                                                                            
adventureworks   w                                       orderqty                              integer                                       4                         NA  NA                                                                            
adventureworks   w                                       scrappedqty                           smallint                                      5                         NA  NA                                                                            
adventureworks   w                                       startdate                             timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   w                                       enddate                               timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   w                                       duedate                               timestamp without time zone                   8                         NA  NA                                                                            
adventureworks   w                                       scrapreasonid                         smallint                                      9                         NA  NA                                                                            
adventureworks   w                                       modifieddate                          timestamp without time zone                  10                         NA  NA                                                                            
adventureworks   workorderrouting                        workorderid                           integer                                       1                         NA  NA                                                                            
adventureworks   workorderrouting                        productid                             integer                                       2                         NA  NA                                                                            
adventureworks   workorderrouting                        operationsequence                     smallint                                      3                         NA  NA                                                                            
adventureworks   workorderrouting                        locationid                            smallint                                      4                         NA  NA                                                                            
adventureworks   workorderrouting                        scheduledstartdate                    timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   workorderrouting                        scheduledenddate                      timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   workorderrouting                        actualstartdate                       timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   workorderrouting                        actualenddate                         timestamp without time zone                   8                         NA  NA                                                                            
adventureworks   workorderrouting                        actualresourcehrs                     numeric                                       9                         NA  NA                                                                            
adventureworks   workorderrouting                        plannedcost                           numeric                                      10                         NA  NA                                                                            
adventureworks   workorderrouting                        actualcost                            numeric                                      11                         NA  NA                                                                            
adventureworks   workorderrouting                        modifieddate                          timestamp without time zone                  12                         NA  now()                                                                         
adventureworks   wr                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   wr                                      workorderid                           integer                                       2                         NA  NA                                                                            
adventureworks   wr                                      productid                             integer                                       3                         NA  NA                                                                            
adventureworks   wr                                      operationsequence                     smallint                                      4                         NA  NA                                                                            
adventureworks   wr                                      locationid                            smallint                                      5                         NA  NA                                                                            
adventureworks   wr                                      scheduledstartdate                    timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   wr                                      scheduledenddate                      timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   wr                                      actualstartdate                       timestamp without time zone                   8                         NA  NA                                                                            
adventureworks   wr                                      actualenddate                         timestamp without time zone                   9                         NA  NA                                                                            
adventureworks   wr                                      actualresourcehrs                     numeric                                      10                         NA  NA                                                                            
adventureworks   wr                                      plannedcost                           numeric                                      11                         NA  NA                                                                            
adventureworks   wr                                      actualcost                            numeric                                      12                         NA  NA                                                                            
adventureworks   wr                                      modifieddate                          timestamp without time zone                  13                         NA  NA                                                                            
adventureworks   vproductmodelcatalogdescription         productmodelid                        integer                                       1                         NA  NA                                                                            
adventureworks   vproductmodelcatalogdescription         name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   vproductmodelcatalogdescription         Summary                               character varying (NA)                        3                         NA  NA                                                                            
adventureworks   vproductmodelcatalogdescription         manufacturer                          character varying (NA)                        4                         NA  NA                                                                            
adventureworks   vproductmodelcatalogdescription         copyright                             character varying (30)                        5                         30  NA                                                                            
adventureworks   vproductmodelcatalogdescription         producturl                            character varying (256)                       6                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         warrantyperiod                        character varying (256)                       7                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         warrantydescription                   character varying (256)                       8                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         noofyears                             character varying (256)                       9                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         maintenancedescription                character varying (256)                      10                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         wheel                                 character varying (256)                      11                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         saddle                                character varying (256)                      12                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         pedal                                 character varying (256)                      13                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         bikeframe                             character varying (NA)                       14                         NA  NA                                                                            
adventureworks   vproductmodelcatalogdescription         crankset                              character varying (256)                      15                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         pictureangle                          character varying (256)                      16                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         picturesize                           character varying (256)                      17                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         productphotoid                        character varying (256)                      18                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         material                              character varying (256)                      19                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         color                                 character varying (256)                      20                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         productline                           character varying (256)                      21                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         style                                 character varying (256)                      22                        256  NA                                                                            
adventureworks   vproductmodelcatalogdescription         riderexperience                       character varying (1024)                     23                       1024  NA                                                                            
adventureworks   vproductmodelcatalogdescription         rowguid                               uuid                                         24                         NA  NA                                                                            
adventureworks   vproductmodelcatalogdescription         modifieddate                          timestamp without time zone                  25                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               productmodelid                        integer                                       1                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   vproductmodelinstructions               instructions                          character varying (NA)                        3                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               LocationID                            integer                                       4                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               SetupHours                            numeric                                       5                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               MachineHours                          numeric                                       6                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               LaborHours                            numeric                                       7                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               LotSize                               integer                                       8                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               Step                                  character varying (1024)                      9                       1024  NA                                                                            
adventureworks   vproductmodelinstructions               rowguid                               uuid                                         10                         NA  NA                                                                            
adventureworks   vproductmodelinstructions               modifieddate                          timestamp without time zone                  11                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     purchaseorderid                       integer                                       1                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     duedate                               timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     orderqty                              smallint                                      4                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     productid                             integer                                       5                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     unitprice                             numeric                                       6                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     receivedqty                           numeric                                       7                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     rejectedqty                           numeric                                       8                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     modifieddate                          timestamp without time zone                   9                         NA  now()                                                                         
adventureworks   pod                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pod                                     purchaseorderid                       integer                                       2                         NA  NA                                                                            
adventureworks   pod                                     purchaseorderdetailid                 integer                                       3                         NA  NA                                                                            
adventureworks   pod                                     duedate                               timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   pod                                     orderqty                              smallint                                      5                         NA  NA                                                                            
adventureworks   pod                                     productid                             integer                                       6                         NA  NA                                                                            
adventureworks   pod                                     unitprice                             numeric                                       7                         NA  NA                                                                            
adventureworks   purchaseorderdetail                     purchaseorderdetailid                 integer                                       2                         NA  nextval('purchasing.purchaseorderdetail_purchaseorderdetailid_seq'::regclass) 
adventureworks   pod                                     receivedqty                           numeric                                       8                         NA  NA                                                                            
adventureworks   pod                                     rejectedqty                           numeric                                       9                         NA  NA                                                                            
adventureworks   pod                                     modifieddate                          timestamp without time zone                  10                         NA  NA                                                                            
adventureworks   purchaseorderheader                     employeeid                            integer                                       4                         NA  NA                                                                            
adventureworks   purchaseorderheader                     vendorid                              integer                                       5                         NA  NA                                                                            
adventureworks   purchaseorderheader                     shipmethodid                          integer                                       6                         NA  NA                                                                            
adventureworks   purchaseorderheader                     shipdate                              timestamp without time zone                   8                         NA  NA                                                                            
adventureworks   purchaseorderheader                     revisionnumber                        smallint                                      2                         NA  0                                                                             
adventureworks   purchaseorderheader                     status                                smallint                                      3                         NA  1                                                                             
adventureworks   purchaseorderheader                     orderdate                             timestamp without time zone                   7                         NA  now()                                                                         
adventureworks   purchaseorderheader                     subtotal                              numeric                                       9                         NA  0.00                                                                          
adventureworks   purchaseorderheader                     taxamt                                numeric                                      10                         NA  0.00                                                                          
adventureworks   purchaseorderheader                     freight                               numeric                                      11                         NA  0.00                                                                          
adventureworks   purchaseorderheader                     modifieddate                          timestamp without time zone                  12                         NA  now()                                                                         
adventureworks   poh                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   poh                                     purchaseorderid                       integer                                       2                         NA  NA                                                                            
adventureworks   poh                                     revisionnumber                        smallint                                      3                         NA  NA                                                                            
adventureworks   poh                                     status                                smallint                                      4                         NA  NA                                                                            
adventureworks   poh                                     employeeid                            integer                                       5                         NA  NA                                                                            
adventureworks   poh                                     vendorid                              integer                                       6                         NA  NA                                                                            
adventureworks   poh                                     shipmethodid                          integer                                       7                         NA  NA                                                                            
adventureworks   poh                                     orderdate                             timestamp without time zone                   8                         NA  NA                                                                            
adventureworks   poh                                     shipdate                              timestamp without time zone                   9                         NA  NA                                                                            
adventureworks   poh                                     subtotal                              numeric                                      10                         NA  NA                                                                            
adventureworks   poh                                     taxamt                                numeric                                      11                         NA  NA                                                                            
adventureworks   poh                                     freight                               numeric                                      12                         NA  NA                                                                            
adventureworks   poh                                     modifieddate                          timestamp without time zone                  13                         NA  NA                                                                            
adventureworks   productvendor                           productid                             integer                                       1                         NA  NA                                                                            
adventureworks   productvendor                           businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   productvendor                           averageleadtime                       integer                                       3                         NA  NA                                                                            
adventureworks   productvendor                           standardprice                         numeric                                       4                         NA  NA                                                                            
adventureworks   productvendor                           lastreceiptcost                       numeric                                       5                         NA  NA                                                                            
adventureworks   productvendor                           lastreceiptdate                       timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   productvendor                           minorderqty                           integer                                       7                         NA  NA                                                                            
adventureworks   productvendor                           maxorderqty                           integer                                       8                         NA  NA                                                                            
adventureworks   productvendor                           onorderqty                            integer                                       9                         NA  NA                                                                            
adventureworks   productvendor                           unitmeasurecode                       character                                    10                          3  NA                                                                            
adventureworks   productvendor                           modifieddate                          timestamp without time zone                  11                         NA  now()                                                                         
adventureworks   pv                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pv                                      productid                             integer                                       2                         NA  NA                                                                            
adventureworks   pv                                      businessentityid                      integer                                       3                         NA  NA                                                                            
adventureworks   pv                                      averageleadtime                       integer                                       4                         NA  NA                                                                            
adventureworks   pv                                      standardprice                         numeric                                       5                         NA  NA                                                                            
adventureworks   pv                                      lastreceiptcost                       numeric                                       6                         NA  NA                                                                            
adventureworks   pv                                      lastreceiptdate                       timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   pv                                      minorderqty                           integer                                       8                         NA  NA                                                                            
adventureworks   pv                                      maxorderqty                           integer                                       9                         NA  NA                                                                            
adventureworks   pv                                      onorderqty                            integer                                      10                         NA  NA                                                                            
adventureworks   pv                                      unitmeasurecode                       character                                    11                          3  NA                                                                            
adventureworks   pv                                      modifieddate                          timestamp without time zone                  12                         NA  NA                                                                            
adventureworks   shipmethod                              name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   shipmethod                              shipbase                              numeric                                       3                         NA  0.00                                                                          
adventureworks   shipmethod                              shiprate                              numeric                                       4                         NA  0.00                                                                          
adventureworks   shipmethod                              rowguid                               uuid                                          5                         NA  uuid_generate_v1()                                                            
adventureworks   shipmethod                              modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   shipmethod                              shipmethodid                          integer                                       1                         NA  nextval('purchasing.shipmethod_shipmethodid_seq'::regclass)                   
adventureworks   sm                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sm                                      shipmethodid                          integer                                       2                         NA  NA                                                                            
adventureworks   sm                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   sm                                      shipbase                              numeric                                       4                         NA  NA                                                                            
adventureworks   sm                                      shiprate                              numeric                                       5                         NA  NA                                                                            
adventureworks   sm                                      rowguid                               uuid                                          6                         NA  NA                                                                            
adventureworks   sm                                      modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   vendor                                  businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vendor                                  accountnumber                         character varying (15)                        2                         15  NA                                                                            
adventureworks   vendor                                  name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   vendor                                  creditrating                          smallint                                      4                         NA  NA                                                                            
adventureworks   vendor                                  purchasingwebserviceurl               character varying (1024)                      7                       1024  NA                                                                            
adventureworks   vendor                                  preferredvendorstatus                 boolean                                       5                         NA  true                                                                          
adventureworks   vendor                                  activeflag                            boolean                                       6                         NA  true                                                                          
adventureworks   vendor                                  modifieddate                          timestamp without time zone                   8                         NA  now()                                                                         
adventureworks   v                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   v                                       businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   v                                       accountnumber                         character varying (15)                        3                         15  NA                                                                            
adventureworks   v                                       name                                  character varying (50)                        4                         50  NA                                                                            
adventureworks   v                                       creditrating                          smallint                                      5                         NA  NA                                                                            
adventureworks   v                                       preferredvendorstatus                 boolean                                       6                         NA  NA                                                                            
adventureworks   v                                       activeflag                            boolean                                       7                         NA  NA                                                                            
adventureworks   v                                       purchasingwebserviceurl               character varying (1024)                      8                       1024  NA                                                                            
adventureworks   v                                       modifieddate                          timestamp without time zone                   9                         NA  NA                                                                            
adventureworks   vvendorwithaddresses                    businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vvendorwithaddresses                    name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   vvendorwithaddresses                    addresstype                           character varying (50)                        3                         50  NA                                                                            
adventureworks   vvendorwithaddresses                    addressline1                          character varying (60)                        4                         60  NA                                                                            
adventureworks   vvendorwithaddresses                    addressline2                          character varying (60)                        5                         60  NA                                                                            
adventureworks   vvendorwithaddresses                    city                                  character varying (30)                        6                         30  NA                                                                            
adventureworks   vvendorwithaddresses                    stateprovincename                     character varying (50)                        7                         50  NA                                                                            
adventureworks   vvendorwithaddresses                    postalcode                            character varying (15)                        8                         15  NA                                                                            
adventureworks   vvendorwithaddresses                    countryregionname                     character varying (50)                        9                         50  NA                                                                            
adventureworks   vvendorwithcontacts                     businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vvendorwithcontacts                     name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   vvendorwithcontacts                     contacttype                           character varying (50)                        3                         50  NA                                                                            
adventureworks   vvendorwithcontacts                     title                                 character varying (8)                         4                          8  NA                                                                            
adventureworks   vvendorwithcontacts                     firstname                             character varying (50)                        5                         50  NA                                                                            
adventureworks   vvendorwithcontacts                     middlename                            character varying (50)                        6                         50  NA                                                                            
adventureworks   vvendorwithcontacts                     lastname                              character varying (50)                        7                         50  NA                                                                            
adventureworks   vvendorwithcontacts                     suffix                                character varying (10)                        8                         10  NA                                                                            
adventureworks   vvendorwithcontacts                     phonenumber                           character varying (25)                        9                         25  NA                                                                            
adventureworks   vvendorwithcontacts                     phonenumbertype                       character varying (50)                       10                         50  NA                                                                            
adventureworks   vvendorwithcontacts                     emailaddress                          character varying (50)                       11                         50  NA                                                                            
adventureworks   vvendorwithcontacts                     emailpromotion                        integer                                      12                         NA  NA                                                                            
adventureworks   customer                                personid                              integer                                       2                         NA  NA                                                                            
adventureworks   customer                                storeid                               integer                                       3                         NA  NA                                                                            
adventureworks   customer                                territoryid                           integer                                       4                         NA  NA                                                                            
adventureworks   customer                                rowguid                               uuid                                          5                         NA  uuid_generate_v1()                                                            
adventureworks   customer                                modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   c                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   c                                       customerid                            integer                                       2                         NA  NA                                                                            
adventureworks   c                                       personid                              integer                                       3                         NA  NA                                                                            
adventureworks   c                                       storeid                               integer                                       4                         NA  NA                                                                            
adventureworks   c                                       territoryid                           integer                                       5                         NA  NA                                                                            
adventureworks   c                                       rowguid                               uuid                                          6                         NA  NA                                                                            
adventureworks   c                                       modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   creditcard                              cardtype                              character varying (50)                        2                         50  NA                                                                            
adventureworks   creditcard                              cardnumber                            character varying (25)                        3                         25  NA                                                                            
adventureworks   creditcard                              expmonth                              smallint                                      4                         NA  NA                                                                            
adventureworks   creditcard                              expyear                               smallint                                      5                         NA  NA                                                                            
adventureworks   creditcard                              modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   cc                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   cc                                      creditcardid                          integer                                       2                         NA  NA                                                                            
adventureworks   cc                                      cardtype                              character varying (50)                        3                         50  NA                                                                            
adventureworks   cc                                      cardnumber                            character varying (25)                        4                         25  NA                                                                            
adventureworks   cc                                      expmonth                              smallint                                      5                         NA  NA                                                                            
adventureworks   cc                                      expyear                               smallint                                      6                         NA  NA                                                                            
adventureworks   cc                                      modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   currencyrate                            currencyratedate                      timestamp without time zone                   2                         NA  NA                                                                            
adventureworks   currencyrate                            fromcurrencycode                      character                                     3                          3  NA                                                                            
adventureworks   currencyrate                            tocurrencycode                        character                                     4                          3  NA                                                                            
adventureworks   currencyrate                            averagerate                           numeric                                       5                         NA  NA                                                                            
adventureworks   currencyrate                            endofdayrate                          numeric                                       6                         NA  NA                                                                            
adventureworks   currencyrate                            modifieddate                          timestamp without time zone                   7                         NA  now()                                                                         
adventureworks   cr                                      currencyrateid                        integer                                       1                         NA  NA                                                                            
adventureworks   cr                                      currencyratedate                      timestamp without time zone                   2                         NA  NA                                                                            
adventureworks   cr                                      fromcurrencycode                      character                                     3                          3  NA                                                                            
adventureworks   cr                                      tocurrencycode                        character                                     4                          3  NA                                                                            
adventureworks   cr                                      averagerate                           numeric                                       5                         NA  NA                                                                            
adventureworks   cr                                      endofdayrate                          numeric                                       6                         NA  NA                                                                            
adventureworks   creditcard                              creditcardid                          integer                                       1                         NA  nextval('sales.creditcard_creditcardid_seq'::regclass)                        
adventureworks   currencyrate                            currencyrateid                        integer                                       1                         NA  nextval('sales.currencyrate_currencyrateid_seq'::regclass)                    
adventureworks   cr                                      modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   countryregioncurrency                   countryregioncode                     character varying (3)                         1                          3  NA                                                                            
adventureworks   countryregioncurrency                   currencycode                          character                                     2                          3  NA                                                                            
adventureworks   countryregioncurrency                   modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   crc                                     countryregioncode                     character varying (3)                         1                          3  NA                                                                            
adventureworks   crc                                     currencycode                          character                                     2                          3  NA                                                                            
adventureworks   crc                                     modifieddate                          timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   currency                                currencycode                          character                                     1                          3  NA                                                                            
adventureworks   currency                                name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   currency                                modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   cu                                      id                                    character                                     1                          3  NA                                                                            
adventureworks   cu                                      currencycode                          character                                     2                          3  NA                                                                            
adventureworks   cu                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   cu                                      modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   personcreditcard                        businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   personcreditcard                        creditcardid                          integer                                       2                         NA  NA                                                                            
adventureworks   personcreditcard                        modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   pcc                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   pcc                                     businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   pcc                                     creditcardid                          integer                                       3                         NA  NA                                                                            
adventureworks   pcc                                     modifieddate                          timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   store                                   businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   store                                   name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   store                                   salespersonid                         integer                                       3                         NA  NA                                                                            
adventureworks   store                                   demographics                          xml                                           4                         NA  NA                                                                            
adventureworks   store                                   rowguid                               uuid                                          5                         NA  uuid_generate_v1()                                                            
adventureworks   store                                   modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   s                                       id                                    integer                                       1                         NA  NA                                                                            
adventureworks   s                                       businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   s                                       name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   s                                       salespersonid                         integer                                       4                         NA  NA                                                                            
adventureworks   s                                       demographics                          xml                                           5                         NA  NA                                                                            
adventureworks   s                                       rowguid                               uuid                                          6                         NA  NA                                                                            
adventureworks   s                                       modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   shoppingcartitem                        shoppingcartid                        character varying (50)                        2                         50  NA                                                                            
adventureworks   shoppingcartitem                        productid                             integer                                       4                         NA  NA                                                                            
adventureworks   shoppingcartitem                        quantity                              integer                                       3                         NA  1                                                                             
adventureworks   shoppingcartitem                        datecreated                           timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   shoppingcartitem                        modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   sci                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sci                                     shoppingcartitemid                    integer                                       2                         NA  NA                                                                            
adventureworks   sci                                     shoppingcartid                        character varying (50)                        3                         50  NA                                                                            
adventureworks   sci                                     quantity                              integer                                       4                         NA  NA                                                                            
adventureworks   sci                                     productid                             integer                                       5                         NA  NA                                                                            
adventureworks   sci                                     datecreated                           timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   sci                                     modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   specialoffer                            description                           character varying (255)                       2                        255  NA                                                                            
adventureworks   specialoffer                            type                                  character varying (50)                        4                         50  NA                                                                            
adventureworks   specialoffer                            category                              character varying (50)                        5                         50  NA                                                                            
adventureworks   specialoffer                            startdate                             timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   specialoffer                            discountpct                           numeric                                       3                         NA  0.00                                                                          
adventureworks   shoppingcartitem                        shoppingcartitemid                    integer                                       1                         NA  nextval('sales.shoppingcartitem_shoppingcartitemid_seq'::regclass)            
adventureworks   specialoffer                            specialofferid                        integer                                       1                         NA  nextval('sales.specialoffer_specialofferid_seq'::regclass)                    
adventureworks   specialoffer                            enddate                               timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   specialoffer                            maxqty                                integer                                       9                         NA  NA                                                                            
adventureworks   specialoffer                            minqty                                integer                                       8                         NA  0                                                                             
adventureworks   specialoffer                            rowguid                               uuid                                         10                         NA  uuid_generate_v1()                                                            
adventureworks   specialoffer                            modifieddate                          timestamp without time zone                  11                         NA  now()                                                                         
adventureworks   so                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   so                                      specialofferid                        integer                                       2                         NA  NA                                                                            
adventureworks   so                                      description                           character varying (255)                       3                        255  NA                                                                            
adventureworks   so                                      discountpct                           numeric                                       4                         NA  NA                                                                            
adventureworks   so                                      type                                  character varying (50)                        5                         50  NA                                                                            
adventureworks   so                                      category                              character varying (50)                        6                         50  NA                                                                            
adventureworks   so                                      startdate                             timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   so                                      enddate                               timestamp without time zone                   8                         NA  NA                                                                            
adventureworks   so                                      minqty                                integer                                       9                         NA  NA                                                                            
adventureworks   so                                      maxqty                                integer                                      10                         NA  NA                                                                            
adventureworks   so                                      rowguid                               uuid                                         11                         NA  NA                                                                            
adventureworks   so                                      modifieddate                          timestamp without time zone                  12                         NA  NA                                                                            
adventureworks   salesorderdetail                        salesorderid                          integer                                       1                         NA  NA                                                                            
adventureworks   salesorderdetail                        carriertrackingnumber                 character varying (25)                        3                         25  NA                                                                            
adventureworks   salesorderdetail                        orderqty                              smallint                                      4                         NA  NA                                                                            
adventureworks   salesorderdetail                        productid                             integer                                       5                         NA  NA                                                                            
adventureworks   salesorderdetail                        specialofferid                        integer                                       6                         NA  NA                                                                            
adventureworks   salesorderdetail                        unitprice                             numeric                                       7                         NA  NA                                                                            
adventureworks   salesorderdetail                        unitpricediscount                     numeric                                       8                         NA  0.0                                                                           
adventureworks   salesorderdetail                        rowguid                               uuid                                          9                         NA  uuid_generate_v1()                                                            
adventureworks   salesorderdetail                        modifieddate                          timestamp without time zone                  10                         NA  now()                                                                         
adventureworks   salesorderdetail                        salesorderdetailid                    integer                                       2                         NA  nextval('sales.salesorderdetail_salesorderdetailid_seq'::regclass)            
adventureworks   sod                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sod                                     salesorderid                          integer                                       2                         NA  NA                                                                            
adventureworks   sod                                     salesorderdetailid                    integer                                       3                         NA  NA                                                                            
adventureworks   sod                                     carriertrackingnumber                 character varying (25)                        4                         25  NA                                                                            
adventureworks   sod                                     orderqty                              smallint                                      5                         NA  NA                                                                            
adventureworks   sod                                     productid                             integer                                       6                         NA  NA                                                                            
adventureworks   sod                                     specialofferid                        integer                                       7                         NA  NA                                                                            
adventureworks   sod                                     unitprice                             numeric                                       8                         NA  NA                                                                            
adventureworks   sod                                     unitpricediscount                     numeric                                       9                         NA  NA                                                                            
adventureworks   sod                                     rowguid                               uuid                                         10                         NA  NA                                                                            
adventureworks   sod                                     modifieddate                          timestamp without time zone                  11                         NA  NA                                                                            
adventureworks   salesorderheader                        duedate                               timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   salesorderheader                        shipdate                              timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   salesorderheader                        purchaseordernumber                   character varying (25)                        8                         25  NA                                                                            
adventureworks   salesorderheader                        accountnumber                         character varying (15)                        9                         15  NA                                                                            
adventureworks   salesorderheader                        customerid                            integer                                      10                         NA  NA                                                                            
adventureworks   salesorderheader                        salespersonid                         integer                                      11                         NA  NA                                                                            
adventureworks   salesorderheader                        territoryid                           integer                                      12                         NA  NA                                                                            
adventureworks   salesorderheader                        billtoaddressid                       integer                                      13                         NA  NA                                                                            
adventureworks   salesorderheader                        shiptoaddressid                       integer                                      14                         NA  NA                                                                            
adventureworks   salesorderheader                        shipmethodid                          integer                                      15                         NA  NA                                                                            
adventureworks   salesorderheader                        creditcardid                          integer                                      16                         NA  NA                                                                            
adventureworks   salesorderheader                        creditcardapprovalcode                character varying (15)                       17                         15  NA                                                                            
adventureworks   salesorderheader                        currencyrateid                        integer                                      18                         NA  NA                                                                            
adventureworks   salesorderheader                        totaldue                              numeric                                      22                         NA  NA                                                                            
adventureworks   salesorderheader                        comment                               character varying (128)                      23                        128  NA                                                                            
adventureworks   salesorderheader                        revisionnumber                        smallint                                      2                         NA  0                                                                             
adventureworks   salesorderheader                        orderdate                             timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   salesorderheader                        status                                smallint                                      6                         NA  1                                                                             
adventureworks   salesorderheader                        onlineorderflag                       boolean                                       7                         NA  true                                                                          
adventureworks   salesorderheader                        salesorderid                          integer                                       1                         NA  nextval('sales.salesorderheader_salesorderid_seq'::regclass)                  
adventureworks   salesorderheader                        subtotal                              numeric                                      19                         NA  0.00                                                                          
adventureworks   salesorderheader                        taxamt                                numeric                                      20                         NA  0.00                                                                          
adventureworks   salesorderheader                        freight                               numeric                                      21                         NA  0.00                                                                          
adventureworks   salesorderheader                        rowguid                               uuid                                         24                         NA  uuid_generate_v1()                                                            
adventureworks   salesorderheader                        modifieddate                          timestamp without time zone                  25                         NA  now()                                                                         
adventureworks   soh                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   soh                                     salesorderid                          integer                                       2                         NA  NA                                                                            
adventureworks   soh                                     revisionnumber                        smallint                                      3                         NA  NA                                                                            
adventureworks   soh                                     orderdate                             timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   soh                                     duedate                               timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   soh                                     shipdate                              timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   soh                                     status                                smallint                                      7                         NA  NA                                                                            
adventureworks   soh                                     onlineorderflag                       boolean                                       8                         NA  NA                                                                            
adventureworks   soh                                     purchaseordernumber                   character varying (25)                        9                         25  NA                                                                            
adventureworks   soh                                     accountnumber                         character varying (15)                       10                         15  NA                                                                            
adventureworks   soh                                     customerid                            integer                                      11                         NA  NA                                                                            
adventureworks   soh                                     salespersonid                         integer                                      12                         NA  NA                                                                            
adventureworks   soh                                     territoryid                           integer                                      13                         NA  NA                                                                            
adventureworks   soh                                     billtoaddressid                       integer                                      14                         NA  NA                                                                            
adventureworks   soh                                     shiptoaddressid                       integer                                      15                         NA  NA                                                                            
adventureworks   soh                                     shipmethodid                          integer                                      16                         NA  NA                                                                            
adventureworks   soh                                     creditcardid                          integer                                      17                         NA  NA                                                                            
adventureworks   soh                                     creditcardapprovalcode                character varying (15)                       18                         15  NA                                                                            
adventureworks   soh                                     currencyrateid                        integer                                      19                         NA  NA                                                                            
adventureworks   soh                                     subtotal                              numeric                                      20                         NA  NA                                                                            
adventureworks   soh                                     taxamt                                numeric                                      21                         NA  NA                                                                            
adventureworks   soh                                     freight                               numeric                                      22                         NA  NA                                                                            
adventureworks   soh                                     totaldue                              numeric                                      23                         NA  NA                                                                            
adventureworks   soh                                     comment                               character varying (128)                      24                        128  NA                                                                            
adventureworks   soh                                     rowguid                               uuid                                         25                         NA  NA                                                                            
adventureworks   soh                                     modifieddate                          timestamp without time zone                  26                         NA  NA                                                                            
adventureworks   salesorderheadersalesreason             salesorderid                          integer                                       1                         NA  NA                                                                            
adventureworks   salesorderheadersalesreason             salesreasonid                         integer                                       2                         NA  NA                                                                            
adventureworks   salesorderheadersalesreason             modifieddate                          timestamp without time zone                   3                         NA  now()                                                                         
adventureworks   sohsr                                   salesorderid                          integer                                       1                         NA  NA                                                                            
adventureworks   sohsr                                   salesreasonid                         integer                                       2                         NA  NA                                                                            
adventureworks   sohsr                                   modifieddate                          timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   specialofferproduct                     specialofferid                        integer                                       1                         NA  NA                                                                            
adventureworks   specialofferproduct                     productid                             integer                                       2                         NA  NA                                                                            
adventureworks   specialofferproduct                     rowguid                               uuid                                          3                         NA  uuid_generate_v1()                                                            
adventureworks   specialofferproduct                     modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   sop                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sop                                     specialofferid                        integer                                       2                         NA  NA                                                                            
adventureworks   sop                                     productid                             integer                                       3                         NA  NA                                                                            
adventureworks   sop                                     rowguid                               uuid                                          4                         NA  NA                                                                            
adventureworks   sop                                     modifieddate                          timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   salesperson                             businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   salesperson                             territoryid                           integer                                       2                         NA  NA                                                                            
adventureworks   salesperson                             salesquota                            numeric                                       3                         NA  NA                                                                            
adventureworks   salesperson                             bonus                                 numeric                                       4                         NA  0.00                                                                          
adventureworks   salesperson                             commissionpct                         numeric                                       5                         NA  0.00                                                                          
adventureworks   salesperson                             salesytd                              numeric                                       6                         NA  0.00                                                                          
adventureworks   salesperson                             saleslastyear                         numeric                                       7                         NA  0.00                                                                          
adventureworks   salesperson                             rowguid                               uuid                                          8                         NA  uuid_generate_v1()                                                            
adventureworks   salesperson                             modifieddate                          timestamp without time zone                   9                         NA  now()                                                                         
adventureworks   sp                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sp                                      businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   sp                                      territoryid                           integer                                       3                         NA  NA                                                                            
adventureworks   sp                                      salesquota                            numeric                                       4                         NA  NA                                                                            
adventureworks   sp                                      bonus                                 numeric                                       5                         NA  NA                                                                            
adventureworks   sp                                      commissionpct                         numeric                                       6                         NA  NA                                                                            
adventureworks   sp                                      salesytd                              numeric                                       7                         NA  NA                                                                            
adventureworks   sp                                      saleslastyear                         numeric                                       8                         NA  NA                                                                            
adventureworks   sp                                      rowguid                               uuid                                          9                         NA  NA                                                                            
adventureworks   sp                                      modifieddate                          timestamp without time zone                  10                         NA  NA                                                                            
adventureworks   salespersonquotahistory                 businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   salespersonquotahistory                 quotadate                             timestamp without time zone                   2                         NA  NA                                                                            
adventureworks   salespersonquotahistory                 salesquota                            numeric                                       3                         NA  NA                                                                            
adventureworks   salespersonquotahistory                 rowguid                               uuid                                          4                         NA  uuid_generate_v1()                                                            
adventureworks   salespersonquotahistory                 modifieddate                          timestamp without time zone                   5                         NA  now()                                                                         
adventureworks   spqh                                    id                                    integer                                       1                         NA  NA                                                                            
adventureworks   spqh                                    businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   spqh                                    quotadate                             timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   spqh                                    salesquota                            numeric                                       4                         NA  NA                                                                            
adventureworks   spqh                                    rowguid                               uuid                                          5                         NA  NA                                                                            
adventureworks   spqh                                    modifieddate                          timestamp without time zone                   6                         NA  NA                                                                            
adventureworks   salesreason                             name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   salesreason                             reasontype                            character varying (50)                        3                         50  NA                                                                            
adventureworks   salesreason                             modifieddate                          timestamp without time zone                   4                         NA  now()                                                                         
adventureworks   sr                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sr                                      salesreasonid                         integer                                       2                         NA  NA                                                                            
adventureworks   sr                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   sr                                      reasontype                            character varying (50)                        4                         50  NA                                                                            
adventureworks   sr                                      modifieddate                          timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   salesterritory                          name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   salesterritory                          countryregioncode                     character varying (3)                         3                          3  NA                                                                            
adventureworks   salesterritory                          group                                 character varying (50)                        4                         50  NA                                                                            
adventureworks   salesterritory                          salesytd                              numeric                                       5                         NA  0.00                                                                          
adventureworks   salesterritory                          saleslastyear                         numeric                                       6                         NA  0.00                                                                          
adventureworks   salesterritory                          costytd                               numeric                                       7                         NA  0.00                                                                          
adventureworks   salesterritory                          costlastyear                          numeric                                       8                         NA  0.00                                                                          
adventureworks   salesterritory                          rowguid                               uuid                                          9                         NA  uuid_generate_v1()                                                            
adventureworks   salesterritory                          modifieddate                          timestamp without time zone                  10                         NA  now()                                                                         
adventureworks   st                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   st                                      territoryid                           integer                                       2                         NA  NA                                                                            
adventureworks   st                                      name                                  character varying (50)                        3                         50  NA                                                                            
adventureworks   st                                      countryregioncode                     character varying (3)                         4                          3  NA                                                                            
adventureworks   st                                      group                                 character varying (50)                        5                         50  NA                                                                            
adventureworks   st                                      salesytd                              numeric                                       6                         NA  NA                                                                            
adventureworks   st                                      saleslastyear                         numeric                                       7                         NA  NA                                                                            
adventureworks   st                                      costytd                               numeric                                       8                         NA  NA                                                                            
adventureworks   st                                      costlastyear                          numeric                                       9                         NA  NA                                                                            
adventureworks   st                                      rowguid                               uuid                                         10                         NA  NA                                                                            
adventureworks   st                                      modifieddate                          timestamp without time zone                  11                         NA  NA                                                                            
adventureworks   salesterritoryhistory                   businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   salesterritoryhistory                   territoryid                           integer                                       2                         NA  NA                                                                            
adventureworks   salesterritoryhistory                   startdate                             timestamp without time zone                   3                         NA  NA                                                                            
adventureworks   salesterritoryhistory                   enddate                               timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   salesterritoryhistory                   rowguid                               uuid                                          5                         NA  uuid_generate_v1()                                                            
adventureworks   salesterritoryhistory                   modifieddate                          timestamp without time zone                   6                         NA  now()                                                                         
adventureworks   salesterritory                          territoryid                           integer                                       1                         NA  nextval('sales.salesterritory_territoryid_seq'::regclass)                     
adventureworks   sth                                     id                                    integer                                       1                         NA  NA                                                                            
adventureworks   sth                                     businessentityid                      integer                                       2                         NA  NA                                                                            
adventureworks   sth                                     territoryid                           integer                                       3                         NA  NA                                                                            
adventureworks   sth                                     startdate                             timestamp without time zone                   4                         NA  NA                                                                            
adventureworks   sth                                     enddate                               timestamp without time zone                   5                         NA  NA                                                                            
adventureworks   sth                                     rowguid                               uuid                                          6                         NA  NA                                                                            
adventureworks   sth                                     modifieddate                          timestamp without time zone                   7                         NA  NA                                                                            
adventureworks   salestaxrate                            stateprovinceid                       integer                                       2                         NA  NA                                                                            
adventureworks   salestaxrate                            taxtype                               smallint                                      3                         NA  NA                                                                            
adventureworks   salestaxrate                            name                                  character varying (50)                        5                         50  NA                                                                            
adventureworks   salestaxrate                            taxrate                               numeric                                       4                         NA  0.00                                                                          
adventureworks   salestaxrate                            rowguid                               uuid                                          6                         NA  uuid_generate_v1()                                                            
adventureworks   salestaxrate                            modifieddate                          timestamp without time zone                   7                         NA  now()                                                                         
adventureworks   tr                                      id                                    integer                                       1                         NA  NA                                                                            
adventureworks   tr                                      salestaxrateid                        integer                                       2                         NA  NA                                                                            
adventureworks   tr                                      stateprovinceid                       integer                                       3                         NA  NA                                                                            
adventureworks   tr                                      taxtype                               smallint                                      4                         NA  NA                                                                            
adventureworks   tr                                      taxrate                               numeric                                       5                         NA  NA                                                                            
adventureworks   tr                                      name                                  character varying (50)                        6                         50  NA                                                                            
adventureworks   tr                                      rowguid                               uuid                                          7                         NA  NA                                                                            
adventureworks   tr                                      modifieddate                          timestamp without time zone                   8                         NA  NA                                                                            
adventureworks   vindividualcustomer                     businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vindividualcustomer                     title                                 character varying (8)                         2                          8  NA                                                                            
adventureworks   vindividualcustomer                     firstname                             character varying (50)                        3                         50  NA                                                                            
adventureworks   vindividualcustomer                     middlename                            character varying (50)                        4                         50  NA                                                                            
adventureworks   vindividualcustomer                     lastname                              character varying (50)                        5                         50  NA                                                                            
adventureworks   vindividualcustomer                     suffix                                character varying (10)                        6                         10  NA                                                                            
adventureworks   vindividualcustomer                     phonenumber                           character varying (25)                        7                         25  NA                                                                            
adventureworks   vindividualcustomer                     phonenumbertype                       character varying (50)                        8                         50  NA                                                                            
adventureworks   vindividualcustomer                     emailaddress                          character varying (50)                        9                         50  NA                                                                            
adventureworks   vindividualcustomer                     emailpromotion                        integer                                      10                         NA  NA                                                                            
adventureworks   vindividualcustomer                     addresstype                           character varying (50)                       11                         50  NA                                                                            
adventureworks   vindividualcustomer                     addressline1                          character varying (60)                       12                         60  NA                                                                            
adventureworks   vindividualcustomer                     addressline2                          character varying (60)                       13                         60  NA                                                                            
adventureworks   vindividualcustomer                     city                                  character varying (30)                       14                         30  NA                                                                            
adventureworks   vindividualcustomer                     stateprovincename                     character varying (50)                       15                         50  NA                                                                            
adventureworks   vindividualcustomer                     postalcode                            character varying (15)                       16                         15  NA                                                                            
adventureworks   vindividualcustomer                     countryregionname                     character varying (50)                       17                         50  NA                                                                            
adventureworks   vindividualcustomer                     demographics                          xml                                          18                         NA  NA                                                                            
adventureworks   vpersondemographics                     businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vpersondemographics                     totalpurchaseytd                      money                                         2                         NA  NA                                                                            
adventureworks   vpersondemographics                     datefirstpurchase                     date                                          3                         NA  NA                                                                            
adventureworks   vpersondemographics                     birthdate                             date                                          4                         NA  NA                                                                            
adventureworks   vpersondemographics                     maritalstatus                         character varying (1)                         5                          1  NA                                                                            
adventureworks   vpersondemographics                     yearlyincome                          character varying (30)                        6                         30  NA                                                                            
adventureworks   vpersondemographics                     gender                                character varying (1)                         7                          1  NA                                                                            
adventureworks   vpersondemographics                     totalchildren                         integer                                       8                         NA  NA                                                                            
adventureworks   vpersondemographics                     numberchildrenathome                  integer                                       9                         NA  NA                                                                            
adventureworks   vpersondemographics                     education                             character varying (30)                       10                         30  NA                                                                            
adventureworks   vpersondemographics                     occupation                            character varying (30)                       11                         30  NA                                                                            
adventureworks   vpersondemographics                     homeownerflag                         boolean                                      12                         NA  NA                                                                            
adventureworks   vpersondemographics                     numbercarsowned                       integer                                      13                         NA  NA                                                                            
adventureworks   vsalesperson                            businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vsalesperson                            title                                 character varying (8)                         2                          8  NA                                                                            
adventureworks   vsalesperson                            firstname                             character varying (50)                        3                         50  NA                                                                            
adventureworks   vsalesperson                            middlename                            character varying (50)                        4                         50  NA                                                                            
adventureworks   vsalesperson                            lastname                              character varying (50)                        5                         50  NA                                                                            
adventureworks   vsalesperson                            suffix                                character varying (10)                        6                         10  NA                                                                            
adventureworks   vsalesperson                            jobtitle                              character varying (50)                        7                         50  NA                                                                            
adventureworks   vsalesperson                            phonenumber                           character varying (25)                        8                         25  NA                                                                            
adventureworks   vsalesperson                            phonenumbertype                       character varying (50)                        9                         50  NA                                                                            
adventureworks   vsalesperson                            emailaddress                          character varying (50)                       10                         50  NA                                                                            
adventureworks   vsalesperson                            emailpromotion                        integer                                      11                         NA  NA                                                                            
adventureworks   vsalesperson                            addressline1                          character varying (60)                       12                         60  NA                                                                            
adventureworks   vsalesperson                            addressline2                          character varying (60)                       13                         60  NA                                                                            
adventureworks   vsalesperson                            city                                  character varying (30)                       14                         30  NA                                                                            
adventureworks   vsalesperson                            stateprovincename                     character varying (50)                       15                         50  NA                                                                            
adventureworks   vsalesperson                            postalcode                            character varying (15)                       16                         15  NA                                                                            
adventureworks   vsalesperson                            countryregionname                     character varying (50)                       17                         50  NA                                                                            
adventureworks   vsalesperson                            territoryname                         character varying (50)                       18                         50  NA                                                                            
adventureworks   vsalesperson                            territorygroup                        character varying (50)                       19                         50  NA                                                                            
adventureworks   vsalesperson                            salesquota                            numeric                                      20                         NA  NA                                                                            
adventureworks   vsalesperson                            salesytd                              numeric                                      21                         NA  NA                                                                            
adventureworks   vsalesperson                            saleslastyear                         numeric                                      22                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyears          SalesPersonID                         integer                                       1                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyears          FullName                              text                                          2                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyears          JobTitle                              text                                          3                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyears          SalesTerritory                        text                                          4                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyears          2012                                  numeric                                       5                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyears          2013                                  numeric                                       6                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyears          2014                                  numeric                                       7                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyearsdata      salespersonid                         integer                                       1                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyearsdata      fullname                              text                                          2                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyearsdata      jobtitle                              character varying (50)                        3                         50  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyearsdata      salesterritory                        character varying (50)                        4                         50  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyearsdata      salestotal                            numeric                                       5                         NA  NA                                                                            
adventureworks   vsalespersonsalesbyfiscalyearsdata      fiscalyear                            double precision                              6                         NA  NA                                                                            
adventureworks   vstorewithaddresses                     businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vstorewithaddresses                     name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   vstorewithaddresses                     addresstype                           character varying (50)                        3                         50  NA                                                                            
adventureworks   vstorewithaddresses                     addressline1                          character varying (60)                        4                         60  NA                                                                            
adventureworks   vstorewithaddresses                     addressline2                          character varying (60)                        5                         60  NA                                                                            
adventureworks   vstorewithaddresses                     city                                  character varying (30)                        6                         30  NA                                                                            
adventureworks   vstorewithaddresses                     stateprovincename                     character varying (50)                        7                         50  NA                                                                            
adventureworks   vstorewithaddresses                     postalcode                            character varying (15)                        8                         15  NA                                                                            
adventureworks   vstorewithaddresses                     countryregionname                     character varying (50)                        9                         50  NA                                                                            
adventureworks   vstorewithcontacts                      businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vstorewithcontacts                      name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   vstorewithcontacts                      contacttype                           character varying (50)                        3                         50  NA                                                                            
adventureworks   vstorewithcontacts                      title                                 character varying (8)                         4                          8  NA                                                                            
adventureworks   vstorewithcontacts                      firstname                             character varying (50)                        5                         50  NA                                                                            
adventureworks   vstorewithcontacts                      middlename                            character varying (50)                        6                         50  NA                                                                            
adventureworks   vstorewithcontacts                      lastname                              character varying (50)                        7                         50  NA                                                                            
adventureworks   vstorewithcontacts                      suffix                                character varying (10)                        8                         10  NA                                                                            
adventureworks   vstorewithcontacts                      phonenumber                           character varying (25)                        9                         25  NA                                                                            
adventureworks   vstorewithcontacts                      phonenumbertype                       character varying (50)                       10                         50  NA                                                                            
adventureworks   vstorewithcontacts                      emailaddress                          character varying (50)                       11                         50  NA                                                                            
adventureworks   vstorewithcontacts                      emailpromotion                        integer                                      12                         NA  NA                                                                            
adventureworks   vstorewithdemographics                  businessentityid                      integer                                       1                         NA  NA                                                                            
adventureworks   vstorewithdemographics                  name                                  character varying (50)                        2                         50  NA                                                                            
adventureworks   vstorewithdemographics                  AnnualSales                           money                                         3                         NA  NA                                                                            
adventureworks   vstorewithdemographics                  AnnualRevenue                         money                                         4                         NA  NA                                                                            
adventureworks   vstorewithdemographics                  BankName                              character varying (50)                        5                         50  NA                                                                            
adventureworks   vstorewithdemographics                  BusinessType                          character varying (5)                         6                          5  NA                                                                            
adventureworks   vstorewithdemographics                  YearOpened                            integer                                       7                         NA  NA                                                                            
adventureworks   vstorewithdemographics                  Specialty                             character varying (50)                        8                         50  NA                                                                            
adventureworks   vstorewithdemographics                  SquareFeet                            integer                                       9                         NA  NA                                                                            
adventureworks   vstorewithdemographics                  Brands                                character varying (30)                       10                         30  NA                                                                            
adventureworks   vstorewithdemographics                  Internet                              character varying (30)                       11                         30  NA                                                                            
adventureworks   vstorewithdemographics                  NumberEmployees                       integer                                      12                         NA  NA                                                                            
adventureworks   jobcandidate                            jobcandidateid                        integer                                       1                         NA  nextval('humanresources.jobcandidate_jobcandidateid_seq'::regclass)           
adventureworks   shift                                   shiftid                               integer                                       1                         NA  nextval('humanresources.shift_shiftid_seq'::regclass)                         
adventureworks   address                                 addressid                             integer                                       1                         NA  nextval('person.address_addressid_seq'::regclass)                             
adventureworks   phonenumbertype                         phonenumbertypeid                     integer                                       1                         NA  nextval('person.phonenumbertype_phonenumbertypeid_seq'::regclass)             
adventureworks   stateprovince                           stateprovinceid                       integer                                       1                         NA  nextval('person.stateprovince_stateprovinceid_seq'::regclass)                 
adventureworks   productcategory                         productcategoryid                     integer                                       1                         NA  nextval('production.productcategory_productcategoryid_seq'::regclass)         
adventureworks   scrapreason                             scrapreasonid                         integer                                       1                         NA  nextval('production.scrapreason_scrapreasonid_seq'::regclass)                 
adventureworks   workorder                               workorderid                           integer                                       1                         NA  nextval('production.workorder_workorderid_seq'::regclass)                     
adventureworks   purchaseorderheader                     purchaseorderid                       integer                                       1                         NA  nextval('purchasing.purchaseorderheader_purchaseorderid_seq'::regclass)       
adventureworks   customer                                customerid                            integer                                       1                         NA  nextval('sales.customer_customerid_seq'::regclass)                            
adventureworks   salesreason                             salesreasonid                         integer                                       1                         NA  nextval('sales.salesreason_salesreasonid_seq'::regclass)                      
adventureworks   salestaxrate                            salestaxrateid                        integer                                       1                         NA  nextval('sales.salestaxrate_salestaxrateid_seq'::regclass)                    

### What is the difference between a `VIEW` and a `BASE TABLE`?

The `BASE TABLE` has the underlying data in the database

```r
table_info_schema_table %>%
  filter( table_type == "BASE TABLE") %>%
  # filter(table_schema == "public" & table_type == "BASE TABLE") %>%
  select(table_name, table_type) %>%
  left_join(columns_info_schema_table, by = c("table_name" = "table_name")) %>%
  select(
    table_type, table_name, column_name, data_type, ordinal_position,
    column_default
  ) %>%
  collect(n = Inf) %>%
  filter(str_detect(table_name, "cust")) %>%
  kable()
```



table_type   table_name   column_name    data_type                      ordinal_position  column_default                                     
-----------  -----------  -------------  ----------------------------  -----------------  ---------------------------------------------------
BASE TABLE   customer     personid       integer                                       2  NA                                                 
BASE TABLE   customer     storeid        integer                                       3  NA                                                 
BASE TABLE   customer     territoryid    integer                                       4  NA                                                 
BASE TABLE   customer     rowguid        uuid                                          5  uuid_generate_v1()                                 
BASE TABLE   customer     modifieddate   timestamp without time zone                   6  now()                                              
BASE TABLE   customer     customerid     integer                                       1  nextval('sales.customer_customerid_seq'::regclass) 

Probably should explore how the `VIEW` is made up of data from BASE TABLEs.

```r
table_info_schema_table %>%
  filter( table_type == "VIEW") %>%
  # filter(table_schema == "public" & table_type == "VIEW") %>%
  select(table_name, table_type) %>%
  left_join(columns_info_schema_table, by = c("table_name" = "table_name")) %>%
  select(
    table_type, table_name, column_name, data_type, ordinal_position,
    column_default
  ) %>%
  collect(n = Inf) %>%
  filter(str_detect(table_name, "cust")) %>%
  kable()
```



table_type   table_name            column_name         data_type            ordinal_position  column_default 
-----------  --------------------  ------------------  ------------------  -----------------  ---------------
VIEW         vindividualcustomer   businessentityid    integer                             1  NA             
VIEW         vindividualcustomer   title               character varying                   2  NA             
VIEW         vindividualcustomer   firstname           character varying                   3  NA             
VIEW         vindividualcustomer   middlename          character varying                   4  NA             
VIEW         vindividualcustomer   lastname            character varying                   5  NA             
VIEW         vindividualcustomer   suffix              character varying                   6  NA             
VIEW         vindividualcustomer   phonenumber         character varying                   7  NA             
VIEW         vindividualcustomer   phonenumbertype     character varying                   8  NA             
VIEW         vindividualcustomer   emailaddress        character varying                   9  NA             
VIEW         vindividualcustomer   emailpromotion      integer                            10  NA             
VIEW         vindividualcustomer   addresstype         character varying                  11  NA             
VIEW         vindividualcustomer   addressline1        character varying                  12  NA             
VIEW         vindividualcustomer   addressline2        character varying                  13  NA             
VIEW         vindividualcustomer   city                character varying                  14  NA             
VIEW         vindividualcustomer   stateprovincename   character varying                  15  NA             
VIEW         vindividualcustomer   postalcode          character varying                  16  NA             
VIEW         vindividualcustomer   countryregionname   character varying                  17  NA             
VIEW         vindividualcustomer   demographics        xml                                18  NA             

### What data types are found in the database?

```r
columns_info_schema_info %>% count(data_type) %>% kable()
```



data_type                        n
----------------------------  ----
"char"                          35
abstime                          2
anyarray                         8
ARRAY                           75
bigint                         161
boolean                        137
bytea                            8
character                       45
character varying (1)            2
character varying (10)          13
character varying (100)          9
character varying (1024)         4
character varying (128)          4
character varying (15)          17
character varying (20)           1
character varying (25)          15
character varying (255)          2
character varying (256)         18
character varying (3)           57
character varying (30)          19
character varying (3850)         2
character varying (400)          4
character varying (44)           2
character varying (5)            5
character varying (50)         152
character varying (60)          14
character varying (8)           11
character varying (NA)         549
date                            17
double precision                 9
inet                             2
integer                        482
interval                         5
money                            3
name                           140
numeric                         98
oid                            218
pg_dependencies                  1
pg_lsn                          14
pg_ndistinct                     1
pg_node_tree                    13
real (24,2)                      9
regproc                         34
regtype                          1
smallint                        75
text                           113
time without time zone           4
timestamp with time zone        36
timestamp without time zone    208
uuid                            61
xid                             11
xml                             25

## Characterizing how things are named

Names are the handle for accessing the data.  Tables and columns may or may not be named consistently or in a way that makes sense to you.  You should look at these names *as data*.

### Counting columns and name reuse
Pull out some rough-and-ready but useful statistics about your database.  Since we are in SQL-land we talk about variables as `columns`.

*this is wrong!*


```r
public_tables <- columns_info_schema_table %>%
  # filter(str_detect(table_name, "pg_") == FALSE) %>%
  # filter(table_schema == "public") %>%
  collect()

public_tables %>%
  count(table_name, sort = TRUE) %>% head(n = 15) %>% 
  kable()
```



table_name             n
-------------------  ---
routines              82
columns               44
p                     40
pg_class              33
parameters            32
attributes            31
pg_type               30
element_types         29
pg_proc               29
user_defined_types    29
domains               27
pg_statistic          26
soh                   26
product               25
salesorderheader      25

How many *column names* are shared across tables (or duplicated)?

```r
public_tables %>% count(column_name, sort = TRUE) %>% filter(n > 1)
```

```
## # A tibble: 434 x 2
##    column_name          n
##    <chr>            <int>
##  1 modifieddate       140
##  2 rowguid             61
##  3 id                  60
##  4 name                59
##  5 businessentityid    49
##  6 productid           32
##  7 schemaname          29
##  8 relid               20
##  9 relname             20
## 10 table_catalog       17
## # … with 424 more rows
```

How many column names are unique?

```r
public_tables %>% count(column_name) %>% filter(n == 1) %>% count()
```

```
## # A tibble: 1 x 1
##       n
##   <int>
## 1   872
```

## Database keys

### Direct SQL

How do we use this output?  Could it be generated by dplyr?

```r
rs <- dbGetQuery(
  con,
  "
--SELECT conrelid::regclass as table_from
select table_catalog||'.'||table_schema||'.'||table_name table_name
, conname, pg_catalog.pg_get_constraintdef(r.oid, true) as condef
FROM information_schema.columns c,pg_catalog.pg_constraint r
WHERE 1 = 1 --r.conrelid = '16485' 
  AND r.contype  in ('f','p') ORDER BY 1
;"
)
glimpse(rs)
```

```
## Observations: 466,258
## Variables: 3
## $ table_name <chr> "adventureworks.hr.d", "adventureworks.hr.d", "advent…
## $ conname    <chr> "FK_SalesOrderHeader_CreditCard_CreditCardID", "FK_Sa…
## $ condef     <chr> "FOREIGN KEY (creditcardid) REFERENCES sales.creditca…
```

```r
kable(head(rs))
```



table_name            conname                                         condef                                                                     
--------------------  ----------------------------------------------  ---------------------------------------------------------------------------
adventureworks.hr.d   FK_SalesOrderHeader_CreditCard_CreditCardID     FOREIGN KEY (creditcardid) REFERENCES sales.creditcard(creditcardid)       
adventureworks.hr.d   FK_SalesOrderHeader_SalesPerson_SalesPersonID   FOREIGN KEY (salespersonid) REFERENCES sales.salesperson(businessentityid) 
adventureworks.hr.d   FK_SalesOrderHeader_Address_ShipToAddressID     FOREIGN KEY (shiptoaddressid) REFERENCES person.address(addressid)         
adventureworks.hr.d   FK_SalesOrderHeader_CreditCard_CreditCardID     FOREIGN KEY (creditcardid) REFERENCES sales.creditcard(creditcardid)       
adventureworks.hr.d   FK_SalesOrderHeader_CreditCard_CreditCardID     FOREIGN KEY (creditcardid) REFERENCES sales.creditcard(creditcardid)       
adventureworks.hr.d   FK_SalesOrderHeader_SalesPerson_SalesPersonID   FOREIGN KEY (salespersonid) REFERENCES sales.salesperson(businessentityid) 
The following is more compact and looks more useful.  What is the difference between the two?

```r
rs <- dbGetQuery(
  con,
  "select conrelid::regclass as table_from
      ,c.conname
      ,pg_get_constraintdef(c.oid)
  from pg_constraint c
  join pg_namespace n on n.oid = c.connamespace
 where c.contype in ('f','p')
   and n.nspname = 'public'
order by conrelid::regclass::text, contype DESC;
"
)
glimpse(rs)
```

```
## Observations: 0
## Variables: 3
## $ table_from           <chr> 
## $ conname              <chr> 
## $ pg_get_constraintdef <chr>
```

```r
kable(head(rs))
```



|table_from |conname |pg_get_constraintdef |
|:----------|:-------|:--------------------|

```r
dim(rs)[1]
```

```
## [1] 0
```

### Database keys with dplyr

This query shows the primary and foreign keys in the database.

```r
tables <- tbl(con, dbplyr::in_schema("information_schema", "tables"))
table_constraints <- tbl(con, dbplyr::in_schema("information_schema", "table_constraints"))
key_column_usage <- tbl(con, dbplyr::in_schema("information_schema", "key_column_usage"))
referential_constraints <- tbl(con, dbplyr::in_schema("information_schema", "referential_constraints"))
constraint_column_usage <- tbl(con, dbplyr::in_schema("information_schema", "constraint_column_usage"))

keys <- tables %>%
  left_join(table_constraints, by = c(
    "table_catalog" = "table_catalog",
    "table_schema" = "table_schema",
    "table_name" = "table_name"
  )) %>%
  # table_constraints %>%
  filter(constraint_type %in% c("FOREIGN KEY", "PRIMARY KEY")) %>%
  left_join(key_column_usage,
    by = c(
      "table_catalog" = "table_catalog",
      "constraint_catalog" = "constraint_catalog",
      "constraint_schema" = "constraint_schema",
      "table_name" = "table_name",
      "table_schema" = "table_schema",
      "constraint_name" = "constraint_name"
    )
  ) %>%
  # left_join(constraint_column_usage) %>% # does this table add anything useful?
  select(table_name, table_type, constraint_name, constraint_type, column_name, ordinal_position) %>%
  arrange(table_name) %>%
  collect()
glimpse(keys)
```

```
## Observations: 190
## Variables: 6
## $ table_name       <chr> "address", "address", "addresstype", "billofmat…
## $ table_type       <chr> "BASE TABLE", "BASE TABLE", "BASE TABLE", "BASE…
## $ constraint_name  <chr> "FK_Address_StateProvince_StateProvinceID", "PK…
## $ constraint_type  <chr> "FOREIGN KEY", "PRIMARY KEY", "PRIMARY KEY", "F…
## $ column_name      <chr> "stateprovinceid", "addressid", "addresstypeid"…
## $ ordinal_position <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 3, 1, 1,…
```

```r
kable(keys)
```



table_name                              table_type   constraint_name                                                   constraint_type   column_name              ordinal_position
--------------------------------------  -----------  ----------------------------------------------------------------  ----------------  ----------------------  -----------------
address                                 BASE TABLE   FK_Address_StateProvince_StateProvinceID                          FOREIGN KEY       stateprovinceid                         1
address                                 BASE TABLE   PK_Address_AddressID                                              PRIMARY KEY       addressid                               1
addresstype                             BASE TABLE   PK_AddressType_AddressTypeID                                      PRIMARY KEY       addresstypeid                           1
billofmaterials                         BASE TABLE   FK_BillOfMaterials_Product_ComponentID                            FOREIGN KEY       componentid                             1
billofmaterials                         BASE TABLE   FK_BillOfMaterials_Product_ProductAssemblyID                      FOREIGN KEY       productassemblyid                       1
billofmaterials                         BASE TABLE   FK_BillOfMaterials_UnitMeasure_UnitMeasureCode                    FOREIGN KEY       unitmeasurecode                         1
billofmaterials                         BASE TABLE   PK_BillOfMaterials_BillOfMaterialsID                              PRIMARY KEY       billofmaterialsid                       1
businessentity                          BASE TABLE   PK_BusinessEntity_BusinessEntityID                                PRIMARY KEY       businessentityid                        1
businessentityaddress                   BASE TABLE   FK_BusinessEntityAddress_Address_AddressID                        FOREIGN KEY       addressid                               1
businessentityaddress                   BASE TABLE   FK_BusinessEntityAddress_AddressType_AddressTypeID                FOREIGN KEY       addresstypeid                           1
businessentityaddress                   BASE TABLE   FK_BusinessEntityAddress_BusinessEntity_BusinessEntityID          FOREIGN KEY       businessentityid                        1
businessentityaddress                   BASE TABLE   PK_BusinessEntityAddress_BusinessEntityID_AddressID_AddressType   PRIMARY KEY       addressid                               2
businessentityaddress                   BASE TABLE   PK_BusinessEntityAddress_BusinessEntityID_AddressID_AddressType   PRIMARY KEY       businessentityid                        1
businessentityaddress                   BASE TABLE   PK_BusinessEntityAddress_BusinessEntityID_AddressID_AddressType   PRIMARY KEY       addresstypeid                           3
businessentitycontact                   BASE TABLE   FK_BusinessEntityContact_BusinessEntity_BusinessEntityID          FOREIGN KEY       businessentityid                        1
businessentitycontact                   BASE TABLE   FK_BusinessEntityContact_ContactType_ContactTypeID                FOREIGN KEY       contacttypeid                           1
businessentitycontact                   BASE TABLE   FK_BusinessEntityContact_Person_PersonID                          FOREIGN KEY       personid                                1
businessentitycontact                   BASE TABLE   PK_BusinessEntityContact_BusinessEntityID_PersonID_ContactTypeI   PRIMARY KEY       contacttypeid                           3
businessentitycontact                   BASE TABLE   PK_BusinessEntityContact_BusinessEntityID_PersonID_ContactTypeI   PRIMARY KEY       personid                                2
businessentitycontact                   BASE TABLE   PK_BusinessEntityContact_BusinessEntityID_PersonID_ContactTypeI   PRIMARY KEY       businessentityid                        1
contacttype                             BASE TABLE   PK_ContactType_ContactTypeID                                      PRIMARY KEY       contacttypeid                           1
countryregion                           BASE TABLE   PK_CountryRegion_CountryRegionCode                                PRIMARY KEY       countryregioncode                       1
countryregioncurrency                   BASE TABLE   FK_CountryRegionCurrency_CountryRegion_CountryRegionCode          FOREIGN KEY       countryregioncode                       1
countryregioncurrency                   BASE TABLE   FK_CountryRegionCurrency_Currency_CurrencyCode                    FOREIGN KEY       currencycode                            1
countryregioncurrency                   BASE TABLE   PK_CountryRegionCurrency_CountryRegionCode_CurrencyCode           PRIMARY KEY       countryregioncode                       1
countryregioncurrency                   BASE TABLE   PK_CountryRegionCurrency_CountryRegionCode_CurrencyCode           PRIMARY KEY       currencycode                            2
creditcard                              BASE TABLE   PK_CreditCard_CreditCardID                                        PRIMARY KEY       creditcardid                            1
culture                                 BASE TABLE   PK_Culture_CultureID                                              PRIMARY KEY       cultureid                               1
currency                                BASE TABLE   PK_Currency_CurrencyCode                                          PRIMARY KEY       currencycode                            1
currencyrate                            BASE TABLE   FK_CurrencyRate_Currency_FromCurrencyCode                         FOREIGN KEY       fromcurrencycode                        1
currencyrate                            BASE TABLE   FK_CurrencyRate_Currency_ToCurrencyCode                           FOREIGN KEY       tocurrencycode                          1
currencyrate                            BASE TABLE   PK_CurrencyRate_CurrencyRateID                                    PRIMARY KEY       currencyrateid                          1
customer                                BASE TABLE   FK_Customer_Person_PersonID                                       FOREIGN KEY       personid                                1
customer                                BASE TABLE   FK_Customer_SalesTerritory_TerritoryID                            FOREIGN KEY       territoryid                             1
customer                                BASE TABLE   FK_Customer_Store_StoreID                                         FOREIGN KEY       storeid                                 1
customer                                BASE TABLE   PK_Customer_CustomerID                                            PRIMARY KEY       customerid                              1
department                              BASE TABLE   PK_Department_DepartmentID                                        PRIMARY KEY       departmentid                            1
document                                BASE TABLE   FK_Document_Employee_Owner                                        FOREIGN KEY       owner                                   1
document                                BASE TABLE   PK_Document_DocumentNode                                          PRIMARY KEY       documentnode                            1
emailaddress                            BASE TABLE   FK_EmailAddress_Person_BusinessEntityID                           FOREIGN KEY       businessentityid                        1
emailaddress                            BASE TABLE   PK_EmailAddress_BusinessEntityID_EmailAddressID                   PRIMARY KEY       emailaddressid                          2
emailaddress                            BASE TABLE   PK_EmailAddress_BusinessEntityID_EmailAddressID                   PRIMARY KEY       businessentityid                        1
employee                                BASE TABLE   FK_Employee_Person_BusinessEntityID                               FOREIGN KEY       businessentityid                        1
employee                                BASE TABLE   PK_Employee_BusinessEntityID                                      PRIMARY KEY       businessentityid                        1
employeedepartmenthistory               BASE TABLE   FK_EmployeeDepartmentHistory_Department_DepartmentID              FOREIGN KEY       departmentid                            1
employeedepartmenthistory               BASE TABLE   FK_EmployeeDepartmentHistory_Employee_BusinessEntityID            FOREIGN KEY       businessentityid                        1
employeedepartmenthistory               BASE TABLE   FK_EmployeeDepartmentHistory_Shift_ShiftID                        FOREIGN KEY       shiftid                                 1
employeedepartmenthistory               BASE TABLE   PK_EmployeeDepartmentHistory_BusinessEntityID_StartDate_Departm   PRIMARY KEY       businessentityid                        1
employeedepartmenthistory               BASE TABLE   PK_EmployeeDepartmentHistory_BusinessEntityID_StartDate_Departm   PRIMARY KEY       startdate                               2
employeedepartmenthistory               BASE TABLE   PK_EmployeeDepartmentHistory_BusinessEntityID_StartDate_Departm   PRIMARY KEY       departmentid                            3
employeedepartmenthistory               BASE TABLE   PK_EmployeeDepartmentHistory_BusinessEntityID_StartDate_Departm   PRIMARY KEY       shiftid                                 4
employeepayhistory                      BASE TABLE   FK_EmployeePayHistory_Employee_BusinessEntityID                   FOREIGN KEY       businessentityid                        1
employeepayhistory                      BASE TABLE   PK_EmployeePayHistory_BusinessEntityID_RateChangeDate             PRIMARY KEY       ratechangedate                          2
employeepayhistory                      BASE TABLE   PK_EmployeePayHistory_BusinessEntityID_RateChangeDate             PRIMARY KEY       businessentityid                        1
illustration                            BASE TABLE   PK_Illustration_IllustrationID                                    PRIMARY KEY       illustrationid                          1
jobcandidate                            BASE TABLE   FK_JobCandidate_Employee_BusinessEntityID                         FOREIGN KEY       businessentityid                        1
jobcandidate                            BASE TABLE   PK_JobCandidate_JobCandidateID                                    PRIMARY KEY       jobcandidateid                          1
location                                BASE TABLE   PK_Location_LocationID                                            PRIMARY KEY       locationid                              1
password                                BASE TABLE   FK_Password_Person_BusinessEntityID                               FOREIGN KEY       businessentityid                        1
password                                BASE TABLE   PK_Password_BusinessEntityID                                      PRIMARY KEY       businessentityid                        1
person                                  BASE TABLE   FK_Person_BusinessEntity_BusinessEntityID                         FOREIGN KEY       businessentityid                        1
person                                  BASE TABLE   PK_Person_BusinessEntityID                                        PRIMARY KEY       businessentityid                        1
personcreditcard                        BASE TABLE   FK_PersonCreditCard_CreditCard_CreditCardID                       FOREIGN KEY       creditcardid                            1
personcreditcard                        BASE TABLE   FK_PersonCreditCard_Person_BusinessEntityID                       FOREIGN KEY       businessentityid                        1
personcreditcard                        BASE TABLE   PK_PersonCreditCard_BusinessEntityID_CreditCardID                 PRIMARY KEY       businessentityid                        1
personcreditcard                        BASE TABLE   PK_PersonCreditCard_BusinessEntityID_CreditCardID                 PRIMARY KEY       creditcardid                            2
personphone                             BASE TABLE   FK_PersonPhone_Person_BusinessEntityID                            FOREIGN KEY       businessentityid                        1
personphone                             BASE TABLE   FK_PersonPhone_PhoneNumberType_PhoneNumberTypeID                  FOREIGN KEY       phonenumbertypeid                       1
personphone                             BASE TABLE   PK_PersonPhone_BusinessEntityID_PhoneNumber_PhoneNumberTypeID     PRIMARY KEY       phonenumber                             2
personphone                             BASE TABLE   PK_PersonPhone_BusinessEntityID_PhoneNumber_PhoneNumberTypeID     PRIMARY KEY       phonenumbertypeid                       3
personphone                             BASE TABLE   PK_PersonPhone_BusinessEntityID_PhoneNumber_PhoneNumberTypeID     PRIMARY KEY       businessentityid                        1
phonenumbertype                         BASE TABLE   PK_PhoneNumberType_PhoneNumberTypeID                              PRIMARY KEY       phonenumbertypeid                       1
product                                 BASE TABLE   FK_Product_ProductModel_ProductModelID                            FOREIGN KEY       productmodelid                          1
product                                 BASE TABLE   FK_Product_ProductSubcategory_ProductSubcategoryID                FOREIGN KEY       productsubcategoryid                    1
product                                 BASE TABLE   FK_Product_UnitMeasure_SizeUnitMeasureCode                        FOREIGN KEY       sizeunitmeasurecode                     1
product                                 BASE TABLE   FK_Product_UnitMeasure_WeightUnitMeasureCode                      FOREIGN KEY       weightunitmeasurecode                   1
product                                 BASE TABLE   PK_Product_ProductID                                              PRIMARY KEY       productid                               1
productcategory                         BASE TABLE   PK_ProductCategory_ProductCategoryID                              PRIMARY KEY       productcategoryid                       1
productcosthistory                      BASE TABLE   FK_ProductCostHistory_Product_ProductID                           FOREIGN KEY       productid                               1
productcosthistory                      BASE TABLE   PK_ProductCostHistory_ProductID_StartDate                         PRIMARY KEY       startdate                               2
productcosthistory                      BASE TABLE   PK_ProductCostHistory_ProductID_StartDate                         PRIMARY KEY       productid                               1
productdescription                      BASE TABLE   PK_ProductDescription_ProductDescriptionID                        PRIMARY KEY       productdescriptionid                    1
productdocument                         BASE TABLE   FK_ProductDocument_Document_DocumentNode                          FOREIGN KEY       documentnode                            1
productdocument                         BASE TABLE   FK_ProductDocument_Product_ProductID                              FOREIGN KEY       productid                               1
productdocument                         BASE TABLE   PK_ProductDocument_ProductID_DocumentNode                         PRIMARY KEY       documentnode                            2
productdocument                         BASE TABLE   PK_ProductDocument_ProductID_DocumentNode                         PRIMARY KEY       productid                               1
productinventory                        BASE TABLE   FK_ProductInventory_Location_LocationID                           FOREIGN KEY       locationid                              1
productinventory                        BASE TABLE   FK_ProductInventory_Product_ProductID                             FOREIGN KEY       productid                               1
productinventory                        BASE TABLE   PK_ProductInventory_ProductID_LocationID                          PRIMARY KEY       locationid                              2
productinventory                        BASE TABLE   PK_ProductInventory_ProductID_LocationID                          PRIMARY KEY       productid                               1
productlistpricehistory                 BASE TABLE   FK_ProductListPriceHistory_Product_ProductID                      FOREIGN KEY       productid                               1
productlistpricehistory                 BASE TABLE   PK_ProductListPriceHistory_ProductID_StartDate                    PRIMARY KEY       startdate                               2
productlistpricehistory                 BASE TABLE   PK_ProductListPriceHistory_ProductID_StartDate                    PRIMARY KEY       productid                               1
productmodel                            BASE TABLE   PK_ProductModel_ProductModelID                                    PRIMARY KEY       productmodelid                          1
productmodelillustration                BASE TABLE   FK_ProductModelIllustration_Illustration_IllustrationID           FOREIGN KEY       illustrationid                          1
productmodelillustration                BASE TABLE   FK_ProductModelIllustration_ProductModel_ProductModelID           FOREIGN KEY       productmodelid                          1
productmodelillustration                BASE TABLE   PK_ProductModelIllustration_ProductModelID_IllustrationID         PRIMARY KEY       illustrationid                          2
productmodelillustration                BASE TABLE   PK_ProductModelIllustration_ProductModelID_IllustrationID         PRIMARY KEY       productmodelid                          1
productmodelproductdescriptionculture   BASE TABLE   FK_ProductModelProductDescriptionCulture_Culture_CultureID        FOREIGN KEY       cultureid                               1
productmodelproductdescriptionculture   BASE TABLE   FK_ProductModelProductDescriptionCulture_ProductDescription_Pro   FOREIGN KEY       productdescriptionid                    1
productmodelproductdescriptionculture   BASE TABLE   FK_ProductModelProductDescriptionCulture_ProductModel_ProductMo   FOREIGN KEY       productmodelid                          1
productmodelproductdescriptionculture   BASE TABLE   PK_ProductModelProductDescriptionCulture_ProductModelID_Product   PRIMARY KEY       productmodelid                          1
productmodelproductdescriptionculture   BASE TABLE   PK_ProductModelProductDescriptionCulture_ProductModelID_Product   PRIMARY KEY       cultureid                               3
productmodelproductdescriptionculture   BASE TABLE   PK_ProductModelProductDescriptionCulture_ProductModelID_Product   PRIMARY KEY       productdescriptionid                    2
productphoto                            BASE TABLE   PK_ProductPhoto_ProductPhotoID                                    PRIMARY KEY       productphotoid                          1
productproductphoto                     BASE TABLE   FK_ProductProductPhoto_ProductPhoto_ProductPhotoID                FOREIGN KEY       productphotoid                          1
productproductphoto                     BASE TABLE   FK_ProductProductPhoto_Product_ProductID                          FOREIGN KEY       productid                               1
productproductphoto                     BASE TABLE   PK_ProductProductPhoto_ProductID_ProductPhotoID                   PRIMARY KEY       productid                               1
productproductphoto                     BASE TABLE   PK_ProductProductPhoto_ProductID_ProductPhotoID                   PRIMARY KEY       productphotoid                          2
productreview                           BASE TABLE   FK_ProductReview_Product_ProductID                                FOREIGN KEY       productid                               1
productreview                           BASE TABLE   PK_ProductReview_ProductReviewID                                  PRIMARY KEY       productreviewid                         1
productsubcategory                      BASE TABLE   FK_ProductSubcategory_ProductCategory_ProductCategoryID           FOREIGN KEY       productcategoryid                       1
productsubcategory                      BASE TABLE   PK_ProductSubcategory_ProductSubcategoryID                        PRIMARY KEY       productsubcategoryid                    1
productvendor                           BASE TABLE   FK_ProductVendor_Product_ProductID                                FOREIGN KEY       productid                               1
productvendor                           BASE TABLE   FK_ProductVendor_UnitMeasure_UnitMeasureCode                      FOREIGN KEY       unitmeasurecode                         1
productvendor                           BASE TABLE   FK_ProductVendor_Vendor_BusinessEntityID                          FOREIGN KEY       businessentityid                        1
productvendor                           BASE TABLE   PK_ProductVendor_ProductID_BusinessEntityID                       PRIMARY KEY       productid                               1
productvendor                           BASE TABLE   PK_ProductVendor_ProductID_BusinessEntityID                       PRIMARY KEY       businessentityid                        2
purchaseorderdetail                     BASE TABLE   FK_PurchaseOrderDetail_Product_ProductID                          FOREIGN KEY       productid                               1
purchaseorderdetail                     BASE TABLE   FK_PurchaseOrderDetail_PurchaseOrderHeader_PurchaseOrderID        FOREIGN KEY       purchaseorderid                         1
purchaseorderdetail                     BASE TABLE   PK_PurchaseOrderDetail_PurchaseOrderID_PurchaseOrderDetailID      PRIMARY KEY       purchaseorderdetailid                   2
purchaseorderdetail                     BASE TABLE   PK_PurchaseOrderDetail_PurchaseOrderID_PurchaseOrderDetailID      PRIMARY KEY       purchaseorderid                         1
purchaseorderheader                     BASE TABLE   FK_PurchaseOrderHeader_Employee_EmployeeID                        FOREIGN KEY       employeeid                              1
purchaseorderheader                     BASE TABLE   FK_PurchaseOrderHeader_ShipMethod_ShipMethodID                    FOREIGN KEY       shipmethodid                            1
purchaseorderheader                     BASE TABLE   FK_PurchaseOrderHeader_Vendor_VendorID                            FOREIGN KEY       vendorid                                1
purchaseorderheader                     BASE TABLE   PK_PurchaseOrderHeader_PurchaseOrderID                            PRIMARY KEY       purchaseorderid                         1
salesorderdetail                        BASE TABLE   FK_SalesOrderDetail_SalesOrderHeader_SalesOrderID                 FOREIGN KEY       salesorderid                            1
salesorderdetail                        BASE TABLE   FK_SalesOrderDetail_SpecialOfferProduct_SpecialOfferIDProductID   FOREIGN KEY       productid                               2
salesorderdetail                        BASE TABLE   FK_SalesOrderDetail_SpecialOfferProduct_SpecialOfferIDProductID   FOREIGN KEY       specialofferid                          1
salesorderdetail                        BASE TABLE   PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID               PRIMARY KEY       salesorderid                            1
salesorderdetail                        BASE TABLE   PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID               PRIMARY KEY       salesorderdetailid                      2
salesorderheader                        BASE TABLE   FK_SalesOrderHeader_Address_BillToAddressID                       FOREIGN KEY       billtoaddressid                         1
salesorderheader                        BASE TABLE   FK_SalesOrderHeader_Address_ShipToAddressID                       FOREIGN KEY       shiptoaddressid                         1
salesorderheader                        BASE TABLE   FK_SalesOrderHeader_CreditCard_CreditCardID                       FOREIGN KEY       creditcardid                            1
salesorderheader                        BASE TABLE   FK_SalesOrderHeader_CurrencyRate_CurrencyRateID                   FOREIGN KEY       currencyrateid                          1
salesorderheader                        BASE TABLE   FK_SalesOrderHeader_Customer_CustomerID                           FOREIGN KEY       customerid                              1
salesorderheader                        BASE TABLE   FK_SalesOrderHeader_SalesPerson_SalesPersonID                     FOREIGN KEY       salespersonid                           1
salesorderheader                        BASE TABLE   FK_SalesOrderHeader_SalesTerritory_TerritoryID                    FOREIGN KEY       territoryid                             1
salesorderheader                        BASE TABLE   FK_SalesOrderHeader_ShipMethod_ShipMethodID                       FOREIGN KEY       shipmethodid                            1
salesorderheader                        BASE TABLE   PK_SalesOrderHeader_SalesOrderID                                  PRIMARY KEY       salesorderid                            1
salesorderheadersalesreason             BASE TABLE   FK_SalesOrderHeaderSalesReason_SalesOrderHeader_SalesOrderID      FOREIGN KEY       salesorderid                            1
salesorderheadersalesreason             BASE TABLE   FK_SalesOrderHeaderSalesReason_SalesReason_SalesReasonID          FOREIGN KEY       salesreasonid                           1
salesorderheadersalesreason             BASE TABLE   PK_SalesOrderHeaderSalesReason_SalesOrderID_SalesReasonID         PRIMARY KEY       salesreasonid                           2
salesorderheadersalesreason             BASE TABLE   PK_SalesOrderHeaderSalesReason_SalesOrderID_SalesReasonID         PRIMARY KEY       salesorderid                            1
salesperson                             BASE TABLE   FK_SalesPerson_Employee_BusinessEntityID                          FOREIGN KEY       businessentityid                        1
salesperson                             BASE TABLE   FK_SalesPerson_SalesTerritory_TerritoryID                         FOREIGN KEY       territoryid                             1
salesperson                             BASE TABLE   PK_SalesPerson_BusinessEntityID                                   PRIMARY KEY       businessentityid                        1
salespersonquotahistory                 BASE TABLE   FK_SalesPersonQuotaHistory_SalesPerson_BusinessEntityID           FOREIGN KEY       businessentityid                        1
salespersonquotahistory                 BASE TABLE   PK_SalesPersonQuotaHistory_BusinessEntityID_QuotaDate             PRIMARY KEY       businessentityid                        1
salespersonquotahistory                 BASE TABLE   PK_SalesPersonQuotaHistory_BusinessEntityID_QuotaDate             PRIMARY KEY       quotadate                               2
salesreason                             BASE TABLE   PK_SalesReason_SalesReasonID                                      PRIMARY KEY       salesreasonid                           1
salestaxrate                            BASE TABLE   FK_SalesTaxRate_StateProvince_StateProvinceID                     FOREIGN KEY       stateprovinceid                         1
salestaxrate                            BASE TABLE   PK_SalesTaxRate_SalesTaxRateID                                    PRIMARY KEY       salestaxrateid                          1
salesterritory                          BASE TABLE   FK_SalesTerritory_CountryRegion_CountryRegionCode                 FOREIGN KEY       countryregioncode                       1
salesterritory                          BASE TABLE   PK_SalesTerritory_TerritoryID                                     PRIMARY KEY       territoryid                             1
salesterritoryhistory                   BASE TABLE   FK_SalesTerritoryHistory_SalesPerson_BusinessEntityID             FOREIGN KEY       businessentityid                        1
salesterritoryhistory                   BASE TABLE   FK_SalesTerritoryHistory_SalesTerritory_TerritoryID               FOREIGN KEY       territoryid                             1
salesterritoryhistory                   BASE TABLE   PK_SalesTerritoryHistory_BusinessEntityID_StartDate_TerritoryID   PRIMARY KEY       territoryid                             3
salesterritoryhistory                   BASE TABLE   PK_SalesTerritoryHistory_BusinessEntityID_StartDate_TerritoryID   PRIMARY KEY       startdate                               2
salesterritoryhistory                   BASE TABLE   PK_SalesTerritoryHistory_BusinessEntityID_StartDate_TerritoryID   PRIMARY KEY       businessentityid                        1
scrapreason                             BASE TABLE   PK_ScrapReason_ScrapReasonID                                      PRIMARY KEY       scrapreasonid                           1
shift                                   BASE TABLE   PK_Shift_ShiftID                                                  PRIMARY KEY       shiftid                                 1
shipmethod                              BASE TABLE   PK_ShipMethod_ShipMethodID                                        PRIMARY KEY       shipmethodid                            1
shoppingcartitem                        BASE TABLE   FK_ShoppingCartItem_Product_ProductID                             FOREIGN KEY       productid                               1
shoppingcartitem                        BASE TABLE   PK_ShoppingCartItem_ShoppingCartItemID                            PRIMARY KEY       shoppingcartitemid                      1
specialoffer                            BASE TABLE   PK_SpecialOffer_SpecialOfferID                                    PRIMARY KEY       specialofferid                          1
specialofferproduct                     BASE TABLE   FK_SpecialOfferProduct_Product_ProductID                          FOREIGN KEY       productid                               1
specialofferproduct                     BASE TABLE   FK_SpecialOfferProduct_SpecialOffer_SpecialOfferID                FOREIGN KEY       specialofferid                          1
specialofferproduct                     BASE TABLE   PK_SpecialOfferProduct_SpecialOfferID_ProductID                   PRIMARY KEY       specialofferid                          1
specialofferproduct                     BASE TABLE   PK_SpecialOfferProduct_SpecialOfferID_ProductID                   PRIMARY KEY       productid                               2
stateprovince                           BASE TABLE   FK_StateProvince_CountryRegion_CountryRegionCode                  FOREIGN KEY       countryregioncode                       1
stateprovince                           BASE TABLE   FK_StateProvince_SalesTerritory_TerritoryID                       FOREIGN KEY       territoryid                             1
stateprovince                           BASE TABLE   PK_StateProvince_StateProvinceID                                  PRIMARY KEY       stateprovinceid                         1
store                                   BASE TABLE   FK_Store_BusinessEntity_BusinessEntityID                          FOREIGN KEY       businessentityid                        1
store                                   BASE TABLE   FK_Store_SalesPerson_SalesPersonID                                FOREIGN KEY       salespersonid                           1
store                                   BASE TABLE   PK_Store_BusinessEntityID                                         PRIMARY KEY       businessentityid                        1
transactionhistory                      BASE TABLE   FK_TransactionHistory_Product_ProductID                           FOREIGN KEY       productid                               1
transactionhistory                      BASE TABLE   PK_TransactionHistory_TransactionID                               PRIMARY KEY       transactionid                           1
transactionhistoryarchive               BASE TABLE   PK_TransactionHistoryArchive_TransactionID                        PRIMARY KEY       transactionid                           1
unitmeasure                             BASE TABLE   PK_UnitMeasure_UnitMeasureCode                                    PRIMARY KEY       unitmeasurecode                         1
vendor                                  BASE TABLE   FK_Vendor_BusinessEntity_BusinessEntityID                         FOREIGN KEY       businessentityid                        1
vendor                                  BASE TABLE   PK_Vendor_BusinessEntityID                                        PRIMARY KEY       businessentityid                        1
workorder                               BASE TABLE   FK_WorkOrder_Product_ProductID                                    FOREIGN KEY       productid                               1
workorder                               BASE TABLE   FK_WorkOrder_ScrapReason_ScrapReasonID                            FOREIGN KEY       scrapreasonid                           1
workorder                               BASE TABLE   PK_WorkOrder_WorkOrderID                                          PRIMARY KEY       workorderid                             1
workorderrouting                        BASE TABLE   FK_WorkOrderRouting_Location_LocationID                           FOREIGN KEY       locationid                              1
workorderrouting                        BASE TABLE   FK_WorkOrderRouting_WorkOrder_WorkOrderID                         FOREIGN KEY       workorderid                             1
workorderrouting                        BASE TABLE   PK_WorkOrderRouting_WorkOrderID_ProductID_OperationSequence       PRIMARY KEY       workorderid                             1
workorderrouting                        BASE TABLE   PK_WorkOrderRouting_WorkOrderID_ProductID_OperationSequence       PRIMARY KEY       productid                               2
workorderrouting                        BASE TABLE   PK_WorkOrderRouting_WorkOrderID_ProductID_OperationSequence       PRIMARY KEY       operationsequence                       3

What do we learn from the following query?  How is it useful? 

```r
rs <- dbGetQuery(
  con,
  "SELECT r.*,
  pg_catalog.pg_get_constraintdef(r.oid, true) as condef
  FROM pg_catalog.pg_constraint r
  WHERE 1=1 --r.conrelid = '16485' AND r.contype = 'f' ORDER BY 1;
  "
)

head(rs)
```

```
##                        conname connamespace contype condeferrable
## 1 cardinal_number_domain_check        12703       c         FALSE
## 2              yes_or_no_check        12703       c         FALSE
## 3        CK_Employee_BirthDate        16386       c         FALSE
## 4           CK_Employee_Gender        16386       c         FALSE
## 5         CK_Employee_HireDate        16386       c         FALSE
## 6    CK_Employee_MaritalStatus        16386       c         FALSE
##   condeferred convalidated conrelid contypid conindid confrelid
## 1       FALSE         TRUE        0    12716        0         0
## 2       FALSE         TRUE        0    12724        0         0
## 3       FALSE         TRUE    16444        0        0         0
## 4       FALSE         TRUE    16444        0        0         0
## 5       FALSE         TRUE    16444        0        0         0
## 6       FALSE         TRUE    16444        0        0         0
##   confupdtype confdeltype confmatchtype conislocal coninhcount
## 1                                             TRUE           0
## 2                                             TRUE           0
## 3                                             TRUE           0
## 4                                             TRUE           0
## 5                                             TRUE           0
## 6                                             TRUE           0
##   connoinherit conkey confkey conpfeqop conppeqop conffeqop conexclop
## 1        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 2        FALSE   <NA>    <NA>      <NA>      <NA>      <NA>      <NA>
## 3        FALSE    {5}    <NA>      <NA>      <NA>      <NA>      <NA>
## 4        FALSE    {7}    <NA>      <NA>      <NA>      <NA>      <NA>
## 5        FALSE    {8}    <NA>      <NA>      <NA>      <NA>      <NA>
## 6        FALSE    {6}    <NA>      <NA>      <NA>      <NA>      <NA>
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                conbin
## 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     {OPEXPR :opno 525 :opfuncid 150 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({COERCETODOMAINVALUE :typeId 23 :typeMod -1 :collation 0 :location 195} {CONST :consttype 23 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 204 :constvalue 4 [ 0 0 0 0 0 0 0 0 ]}) :location 201}
## 2                                                                                                                                                                                                                                                                                                               {SCALARARRAYOPEXPR :opno 98 :opfuncid 67 :useOr true :inputcollid 100 :args ({RELABELTYPE :arg {COERCETODOMAINVALUE :typeId 1043 :typeMod 7 :collation 100 :location 121} :resulttype 25 :resulttypmod -1 :resultcollid 100 :relabelformat 2 :location -1} {ARRAYCOERCEEXPR :arg {ARRAY :array_typeid 1015 :array_collid 100 :element_typeid 1043 :elements ({CONST :consttype 1043 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 131 :constvalue 7 [ 28 0 0 0 89 69 83 ]} {CONST :consttype 1043 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 138 :constvalue 6 [ 24 0 0 0 78 79 ]}) :multidims false :location -1} :elemfuncid 0 :resulttype 1009 :resulttypmod -1 :resultcollid 100 :isExplicit false :coerceformat 2 :location -1}) :location 127}
## 3     {BOOLEXPR :boolop and :args ({OPEXPR :opno 1098 :opfuncid 1090 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({VAR :varno 1 :varattno 5 :vartype 1082 :vartypmod -1 :varcollid 0 :varlevelsup 0 :varnoold 1 :varoattno 5 :location 804} {CONST :consttype 1082 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 817 :constvalue 4 [ 33 -100 -1 -1 0 0 0 0 ]}) :location 814} {OPEXPR :opno 2359 :opfuncid 2352 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({VAR :varno 1 :varattno 5 :vartype 1082 :vartypmod -1 :varcollid 0 :varlevelsup 0 :varnoold 1 :varoattno 5 :location 842} {OPEXPR :opno 1329 :opfuncid 1190 :opresulttype 1184 :opretset false :opcollid 0 :inputcollid 0 :args ({FUNCEXPR :funcid 1299 :funcresulttype 1184 :funcretset false :funcvariadic false :funcformat 0 :funccollid 0 :inputcollid 0 :args <> :location 856} {CONST :consttype 1186 :consttypmod -1 :constcollid 0 :constlen 16 :constbyval false :constisnull false :location 864 :constvalue 16 [ 0 0 0 0 0 0 0 0 0 0 0 0 -40 0 0 0 ]}) :location 862}) :location 852}) :location 837}
## 4                                                                                                                                                                                                              {SCALARARRAYOPEXPR :opno 98 :opfuncid 67 :useOr true :inputcollid 100 :args ({FUNCEXPR :funcid 871 :funcresulttype 25 :funcretset false :funcvariadic false :funcformat 0 :funccollid 100 :inputcollid 100 :args ({FUNCEXPR :funcid 401 :funcresulttype 25 :funcretset false :funcvariadic false :funcformat 1 :funccollid 100 :inputcollid 100 :args ({VAR :varno 1 :varattno 7 :vartype 1042 :vartypmod 5 :varcollid 100 :varlevelsup 0 :varnoold 1 :varoattno 7 :location 941}) :location 948}) :location 934} {ARRAY :array_typeid 1009 :array_collid 100 :element_typeid 25 :elements ({CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 969 :constvalue 5 [ 20 0 0 0 77 ]} {CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 980 :constvalue 5 [ 20 0 0 0 70 ]}) :multidims false :location 963}) :location 956}
## 5 {BOOLEXPR :boolop and :args ({OPEXPR :opno 1098 :opfuncid 1090 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({VAR :varno 1 :varattno 8 :vartype 1082 :vartypmod -1 :varcollid 0 :varlevelsup 0 :varnoold 1 :varoattno 8 :location 1042} {CONST :consttype 1082 :consttypmod -1 :constcollid 0 :constlen 4 :constbyval true :constisnull false :location 1054 :constvalue 4 [ 1 -5 -1 -1 0 0 0 0 ]}) :location 1051} {OPEXPR :opno 2359 :opfuncid 2352 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 0 :args ({VAR :varno 1 :varattno 8 :vartype 1082 :vartypmod -1 :varcollid 0 :varlevelsup 0 :varnoold 1 :varoattno 8 :location 1079} {OPEXPR :opno 1327 :opfuncid 1189 :opresulttype 1184 :opretset false :opcollid 0 :inputcollid 0 :args ({FUNCEXPR :funcid 1299 :funcresulttype 1184 :funcretset false :funcvariadic false :funcformat 0 :funccollid 0 :inputcollid 0 :args <> :location 1092} {CONST :consttype 1186 :consttypmod -1 :constcollid 0 :constlen 16 :constbyval false :constisnull false :location 1100 :constvalue 16 [ 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 ]}) :location 1098}) :location 1088}) :location 1074}
## 6                                                                                                                                                                                                       {SCALARARRAYOPEXPR :opno 98 :opfuncid 67 :useOr true :inputcollid 100 :args ({FUNCEXPR :funcid 871 :funcresulttype 25 :funcretset false :funcvariadic false :funcformat 0 :funccollid 100 :inputcollid 100 :args ({FUNCEXPR :funcid 401 :funcresulttype 25 :funcretset false :funcvariadic false :funcformat 1 :funccollid 100 :inputcollid 100 :args ({VAR :varno 1 :varattno 6 :vartype 1042 :vartypmod 5 :varcollid 100 :varlevelsup 0 :varnoold 1 :varoattno 6 :location 1181}) :location 1195}) :location 1174} {ARRAY :array_typeid 1009 :array_collid 100 :element_typeid 25 :elements ({CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 1216 :constvalue 5 [ 20 0 0 0 77 ]} {CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :constbyval false :constisnull false :location 1227 :constvalue 5 [ 20 0 0 0 83 ]}) :multidims false :location 1210}) :location 1203}
##                                                                                       consrc
## 1                                                                               (VALUE >= 0)
## 2 ((VALUE)::text = ANY ((ARRAY['YES'::character varying, 'NO'::character varying])::text[]))
## 3      ((birthdate >= '1930-01-01'::date) AND (birthdate <= (now() - '18 years'::interval)))
## 4                                (upper((gender)::text) = ANY (ARRAY['M'::text, 'F'::text]))
## 5           ((hiredate >= '1996-07-01'::date) AND (hiredate <= (now() + '1 day'::interval)))
## 6                         (upper((maritalstatus)::text) = ANY (ARRAY['M'::text, 'S'::text]))
##                                                                                         condef
## 1                                                                           CHECK (VALUE >= 0)
## 2 CHECK (VALUE::text = ANY (ARRAY['YES'::character varying, 'NO'::character varying]::text[]))
## 3      CHECK (birthdate >= '1930-01-01'::date AND birthdate <= (now() - '18 years'::interval))
## 4                              CHECK (upper(gender::text) = ANY (ARRAY['M'::text, 'F'::text]))
## 5           CHECK (hiredate >= '1996-07-01'::date AND hiredate <= (now() + '1 day'::interval))
## 6                       CHECK (upper(maritalstatus::text) = ANY (ARRAY['M'::text, 'S'::text]))
```

## Creating your own data dictionary

If you are going to work with a database for an extended period it can be useful to create your own data dictionary. This can take the form of [keeping detaild notes](https://caitlinhudon.com/2018/10/30/data-dictionaries/) as well as extracting metadata from the dbms. Here is an illustration of the idea.

*This probably doens't work anymore*

```r
# some_tables <- c("rental", "city", "store")
# 
# all_meta <- map_df(some_tables, sp_get_dbms_data_dictionary, con = con)
# 
# all_meta
# 
# glimpse(all_meta)
# 
# kable(head(all_meta))
```
## Save your work!

The work you do to understand the structure and contents of a database can be useful for others (including future-you).  So at the end of a session, you might look at all the data frames you want to save.  Consider saving them in a form where you can add notes at the appropriate level (as in a Google Doc representing table or columns that you annotate over time).

```r
ls()
```

```
##  [1] "columns_info_schema_info"  "columns_info_schema_table"
##  [3] "con"                       "constraint_column_usage"  
##  [5] "cranex"                    "key_column_usage"         
##  [7] "keys"                      "public_tables"            
##  [9] "referential_constraints"   "rs"                       
## [11] "schema_list"               "table_constraints"        
## [13] "table_info"                "table_info_schema_table"  
## [15] "tables"
```


