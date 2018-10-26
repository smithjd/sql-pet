# Explain queries (11)




```r
# library(knitr)
dplyr_summary_df <-
    read.delim(here(
    "11_dplyr_sql_summary_table.rmd"),
    header = TRUE,
    sep = '|',
    as.is = TRUE
    )

if (MODE == 'DEMO') {
    View(dplyr_summary_df)
} else {
    kable(dplyr_summary_df)
}    
```


\begin{tabular}{l|l|l|l|l|l}
\hline
In & Dplyr.Function & description & SQL.Clause & Notes & Category\\
\hline
-- & -------------------------------------- & ------------------------------------------- & -------------------------------- & ------------------------- & -------------\\
\hline
Y & arrange() & Arrange rows by variables & ORDER BY &  & Basic single-table verbs\\
\hline
Y? & distinct() & Return rows with matching conditions & SELECT distinct * &  & Basic single-table verbs\\
\hline
Y & select() rename() & Select/rename variables by name & SELECT column\_name alias\_name &  & Basic single-table verbs\\
\hline
N & pull() & Pull out a single variable & SELECT column\_name; &  & Basic single-table verbs\\
\hline
Y & mutate() transmute() & Add new variables & SELECT computed\_value computed\_name &  & Basic single-table verbs\\
\hline
Y & summarise() summarize() & Reduces multiple values down to a single value & SELECT aggregate\_functions GROUP BY &  & Basic single-table verbs\\
\hline
N & group\_by() ungroup() & Objects exported from other packages & GROUP BY no ungroup &  & Basic single-table verbs\\
\hline
N & distinct() & Select distinct/unique rows & SELECT distinct \{colname1,...colnamen\} &  & Basic single-table verbs\\
\hline
N & do() & Do anything & NA &  & Basic single-table verbs\\
\hline
N & sample\_n() sample\_frac() & Sample n rows from a table & ORDER BY RANDOM() LIMIT 10 &  & Basic single-table verbs\\
\hline
N & slice() & Select rows by position & SELECT row\_number() over (partition by expression(s) order\_by exp) &  & Basic single-table verbs\\
\hline
Y & tally() count() add\_tally() add\_count() & Count/tally observations by group & GROUP BY &  & Single-table helpers\\
\hline
Y & top\_n() & Select top (or bottom) n rows (by value) & ORDER BY VALUE \{DESC\} LIMIT 10 &  & Single-table helpers\\
\hline
N & arrange\_all() arrange\_at() arrange\_if() & Arrange rows by a selection of variables & ORDER BY &  & scoped-Operate on a selection of variables\\
\hline
N & filter\_all() filter\_if() filter\_at() & Filter within a selection of variables &  &  & scoped-Operate on a selection of variables\\
\hline
N & group\_by\_all() group\_by\_at() group\_by\_if() & Group by a selection of variables &  &  & scoped-Operate on a selection of variables\\
\hline
N & select\_all() rename\_all() select\_if() rename\_if() select\_at() rename\_at() & Select and rename a selection of variables &  &  & scoped-Operate on a selection of variables\\
\hline
N & summarise\_all() summarise\_if() summarise\_at() summarize\_all() summarize\_if() summarize\_at() mutate\_all() mutate\_if() mutate\_at() transmute\_all() transmute\_if() transmute\_at() & Summarise and mutate multiple columns. &  &  & scoped-Operate on a selection of variables\\
\hline
N & all\_vars() any\_vars() & Apply predicate to all variables &  &  & scoped-Operate on a selection of variables\\
\hline
N & vars() & Select variables &  &  & scoped-Operate on a selection of variables\\
\hline
N & funs() & Create a list of functions calls. &  &  & scoped-Operate on a selection of variables\\
\hline
N & all\_equal() all.equal(<tbl\_df>) & Flexible equality comparison for data frames &  &  & Two-table verbs\\
\hline
N & bind\_rows() bind\_cols() combine() & Efficiently bind multiple data frames by row and column &  &  & Two-table verbs\\
\hline
N & intersect() union() union\_all() setdiff() setequal() & Set operations &  &  & Two-table verbs\\
\hline
N & inner\_join() left\_join() right\_join() full\_join() semi\_join() anti\_join() & Join two tbls together &  &  & Two-table verbs\\
\hline
N & inner\_join(<tbl\_df>) left\_join(<tbl\_df>) right\_join(<tbl\_df>) full\_join(<tbl\_df>) semi\_join(<tbl\_df>) anti\_join(<tbl\_df>) & Join data frame tbls &  &  & Two-table verbs\\
\hline
N & auto\_copy() & Copy tables to same source, if necessary &  &  & Remote tables\\
\hline
N & compute() collect() collapse() & Force computation of a database query &  &  & Remote tables\\
\hline
N & copy\_to() & Copy a local data frame to a remote src &  &  & Remote tables\\
\hline
N & ident() & Flag a character vector as SQL identifiers &  &  & Remote tables\\
\hline
N & explain() show\_query() & Explain details of a tbl &  &  & Remote tables\\
\hline
N & tbl() is.tbl() as.tbl() & Create a table from a data source &  &  & Remote tables\\
\hline
N & src\_mysql() src\_postgres() src\_sqlite() & Source for database backends &  &  & Remote tables\\
\hline
N & sql() & SQL escaping. &  &  & Remote tables\\
\hline
N & groups() group\_vars() & Return grouping variables &  &  & Metadata\\
\hline
N & between() & Do values in a numeric vector fall in specified range? &  &  & Vector functions\\
\hline
N & case\_when() & A general vectorised if &  &  & Vector functions\\
\hline
N & coalesce() & Find first non-missing element &  &  & Vector functions\\
\hline
N & cumall() cumany() cummean() & Cumulativate versions of any, all, and mean &  &  & Vector functions\\
\hline
N & desc() & Descending order &  &  & Vector functions\\
\hline
N & if\_else() & Vectorised if &  &  & Vector functions\\
\hline
N & lead() lag() & Lead and lag. &  &  & Vector functions\\
\hline
N & order\_by() & A helper function for ordering window function output &  &  & Vector functions\\
\hline
N & n() & The number of observations in the current group. &  &  & Vector functions\\
\hline
N & n\_distinct() & Efficiently count the number of unique values in a set of vector &  &  & Vector functions\\
\hline
N & na\_if() & Convert values to NA &  &  & Vector functions\\
\hline
N & near() & Compare two numeric vectors &  &  & Vector functions\\
\hline
N & nth() first() last() & Extract the first, last or nth value from a vector &  &  & Vector functions\\
\hline
N & row\_number() ntile() min\_rank() dense\_rank() percent\_rank() cume\_dist() & Windowed rank functions. &  &  & Vector functions\\
\hline
N & recode() recode\_factor() & Recode values &  &  & Vector functions\\
\hline
N & band\_members band\_instruments band\_instruments2 & Band membership &  &  & Data\\
\hline
N & nasa & NASA spatio-temporal data &  &  & Data\\
\hline
N & starwars & Starwars characters &  &  & Data\\
\hline
N & storms & Storm tracks data &  &  & Data\\
\hline
N & tbl\_cube() & A data cube tbl &  &  & Other backends\\
\hline
N & as.table(<tbl\_cube>) as.data.frame(<tbl\_cube>) as\_data\_frame(<tbl\_cube>) & Coerce a tbl\_cube to other data structures &  &  & Other backends\\
\hline
N & as.tbl\_cube() & Coerce an existing data structure into a tbl\_cube &  &  & Other backends\\
\hline
N & rowwise() & Group input by rows &  &  & Other backends\\
\hline
\end{tabular}

