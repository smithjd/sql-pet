# Dplyr functions and SQL cross-walk {#chapter_appendix-dplyr-functions}

Where are these covered and should they be included?

| Dplyr Function    | description    | SQL Clause    | Where | Category    |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ----- | ------------------------------------------ |
| all_equal() <br />all.equal(<tbl_df>)    | Flexible equality comparison for data frames    |    |    | Two-table verbs    |
| all_vars() <br />any_vars()    | Apply predicate to all variables    |    |    | scoped-Operate on a selection of variables |
| arrange()    | Arrange rows by variables    | ORDER BY    | 13.1.4 (21) | Basic single-table verbs    |
| arrange_all() <br />arrange_at() <br />arrange_if()    | Arrange rows by a selection of variables    | ORDER BY    |    | scoped-Operate on a selection of variables |
| auto_copy()    | Copy tables to same source, if necessary    |    |    | Remote tables    |
| between()    | Do values in a numeric vector fall in specified range?    |    |    | Vector functions    |
| bind_rows() <br />bind_cols() <br />combine()    | Efficiently bind multiple data frames by row and column    |    |    | Two-table verbs    |
| case_when()    | A general vectorised if    |    |    | Vector functions    |
| coalesce()    | Find first non-missing element    |    |    | Vector functions    |
| compute() <br />collect() <br />collapse()    | Force computation of a database query    |    |    | Remote tables    |
| copy_to()    | Copy a local data frame to a remote src    |    |    | Remote tables    |
| cumall() <br />cumany() <br />cummean()    | Cumulativate versions of any, all, and mean    |    |    | Vector functions    |
| desc()    | Descending order    |    |    | Vector functions    |
| distinct()    | Return rows with matching conditions    | SELECT distinct *    |    | Basic single-table verbs    |
| distinct()    | Select distinct/unique rows    | SELECT distinct {colname1,...colnamen}    |    | Basic single-table verbs    |
| do()    | Do anything    | NA    |    | Basic single-table verbs    |
| explain() <br />show_query()    | Explain details of a tbl    |    |    | Remote tables    |
| filter_all() <br />filter_if() <br />filter_at()    | Filter within a selection of variables    |    |    | scoped-Operate on a selection of variables |
| funs()    | Create a list of functions calls.    |    |    | scoped-Operate on a selection of variables |
| group_by() <br />ungroup()    | Objects exported from other packages    | GROUP BY no ungroup    |    | Basic single-table verbs    |
| group_by_all() group_by_at() group_by_if()    | Group by a selection of variables    |    |    | scoped-Operate on a selection of variables |
| groups() <br />group_vars()    | Return grouping variables    |    |    | Metadata    |
| ident()    | Flag a character vector as SQL identifiers    |    |    | Remote tables    |
| if_else()    | Vectorised if    |    |    | Vector functions    |
| inner_join() <br />left_join() <br />right_join() <br />full_join() <br />semi_join() <br />anti_join() | Join two tbls together    |    |    | Two-table verbs    |
| inner_join(<tbl_df>)<br />left_join(<tbl_df>) <br />right_join(<tbl_df>) <br />full_join(<tbl_df>) <br />semi_join(<tbl_df>) <br />anti_join(<tbl_df>) | Join data frame tbls    |    |    | Two-table verbs    |
| intersect() <br />union() <br />union_all() <br />setdiff() <br />setequal() | Set operations    |    |    | Two-table verbs    |
| lead() lag()    | Lead and lag.    |    |    | Vector functions    |
| mutate() <br />transmute()    | Add new variables    | SELECT computed_value computed_name    | 11.5.2 (13) | Basic single-table verbs    |
| n()    | The number of observations in the current group.    |    |    | Vector functions    |
| n_distinct()    | Efficiently count the number of unique values in a set of vector |    |    | Vector functions    |
| na_if()    | Convert values to NA    |    |    | Vector functions    |
| near()    | Compare two numeric vectors    |    |    | Vector functions    |
| nth() <br />first() <br />last()    | Extract the first, last or nth value from a vector    |    |    | Vector functions    |
| order_by()    | A helper function for ordering window function output    |    |    | Vector functions    |
| pull()    | Pull out a single variable    | SELECT column_name;    |    | Basic single-table verbs    |
| recode() <br />recode_factor()    | Recode values    |    |    | Vector functions    |
| row_number() <br />ntile() <br />min_rank() <br />dense_rank() percent_rank() <br />cume_dist() | Windowed rank functions.    |    |    | Vector functions    |
| rowwise()    | Group input by rows    |    |    | Other backends    |
| sample_n() <br />sample_frac()    | Sample n rows from a table    | ORDER BY RANDOM() LIMIT 10    |    | Basic single-table verbs    |
| select() <br />rename()    | Select/rename variables by name    | SELECT column_name alias_name    | 9.1.8 (11)  | Basic single-table verbs    |
| select_all() <br />rename_all() <br />select_if() <br />rename_if() <br />select_at() <br />rename_at() | Select and rename a selection of variables    |    |    | scoped-Operate on a selection of variables |
| slice()    | Select rows by position    | SELECT row_number() over (partition by expression(s) order_by exp) |    | Basic single-table verbs    |
| sql()    | SQL escaping.    |    |    | Remote tables    |
| src_mysql() <br />src_postgres() <br />src_sqlite()    | Source for database backends    |    |    | Remote tables    |
| summarise_all() summarise_if() summarise_at() summarize_all() summarize_if() summarize_at() mutate_all() <br />mutate_if() <br />mutate_at() transmute_all() transmute_if() transmute_at() | Summarise and mutate multiple columns.    |    |    | scoped-Operate on a selection of variables |
| summarize()    | Reduces multiple values down to a single value    | SELECT aggregate_functions GROUP BY    | 11.5.1 (13) | Basic single-table verbs    |
| tally()<br /> count()<br />add_tally() <br />add_count()    | Count/tally observations by group    | GROUP BY    | 9.1.6 (11)    | Single-table helpers    |
| tbl() <br />is.tbl() <br />as.tbl()    | Create a table from a data source    |    |    | Remote tables    |
| top_n()    | Select top (or bottom) n rows (by value)    | ORDER BY VALUE {DESC} LIMIT 10    |    | Single-table helpers    |
| vars()    | Select variables    |    |    | scoped-Operate on a selection of variables |
