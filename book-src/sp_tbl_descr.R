sp_tbl_descr <- function (table_name) {
  dbGetQuery(
    con,
    "select btrim(c.table_name) table_name, c.ordinal_position seq
    , c.column_name COL_NAME
    , case when c.udt_name = 'varchar'
    then c.udt_name ||
    case when c.character_maximum_length is not null
    then '('||cast(c.character_maximum_length as varchar)||')'
    else ''
    end
    when c.udt_name like ('int%')
    then c.udt_name ||'-'||cast(c.numeric_precision as varchar)
    else c.udt_name
    end COL_TYPE
    , c.is_nullable is_null
    --             , c.column_default
    --             , t.table_catalog
    ,t.table_schema
    from dvdrental.information_schema.columns c
    join information_schema.tables t on c.table_name = t.table_name
    where 1 = 1
    and c.table_catalog = 'dvdrental'
    and c.table_name = $1"
       ,table_name
       )
}
