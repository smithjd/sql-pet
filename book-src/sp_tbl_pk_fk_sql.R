sp_tbl_pk_fk_sql <- function(table_name) {
  dbGetQuery(con
             ,"SELECT c.table_name
             ,kcu.column_name
             ,c.constraint_name
             ,c.constraint_type
             ,coalesce(c2.table_name, '') ref_table
             ,coalesce(kcu2.column_name, '') ref_table_col
             FROM information_schema.tables t
             LEFT JOIN information_schema.table_constraints c
             ON t.table_catalog = c.table_catalog
             AND t.table_schema = c.table_schema
             AND t.table_name = c.table_name
             LEFT JOIN information_schema.key_column_usage kcu
             ON c.constraint_schema = kcu.constraint_schema
             AND c.constraint_name = kcu.constraint_name
             LEFT JOIN information_schema.referential_constraints rc
             ON c.constraint_schema = rc.constraint_schema
             AND c.constraint_name = rc.constraint_name
             LEFT JOIN information_schema.table_constraints c2
             ON rc.unique_constraint_schema = c2.constraint_schema
             AND rc.unique_constraint_name = c2.constraint_name
             LEFT JOIN information_schema.key_column_usage kcu2
             ON c2.constraint_schema = kcu2.constraint_schema
             AND c2.constraint_name = kcu2.constraint_name
             AND kcu.ordinal_position = kcu2.ordinal_position
             WHERE c.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
             AND c.table_catalog = 'dvdrental'
             AND c.table_schema = 'public'
             AND (c.table_name = $1 or coalesce(c2.table_name, '') = $1)
             ORDER BY c.table_name,c.constraint_type desc"
             ,param = list(table_name)
  )
}
