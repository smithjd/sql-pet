# Dplyr to SQL translations 

> This Appendix is based on the work of Dewey Dunnington ([@paleolimbot](http://twitter.com/paleolimbot)) which he published here: 
> 
> https://apps.fishandwhistle.net/archives/1503 
>
>  https://rud.is/b/2019/04/10/lost-in-sql-translation-charting-dbplyr-mapped-sql-function-support-across-all-backends/

## Overview

These packages are called in this Appendix:

```r
library(tidyverse)
library(dbplyr)
library(gt)
library(here)
```
list the DBI functions that are available:

```r
names(sql_translate_env(simulate_dbi()))
```

```
##   [1] "-"               ":"               "!"              
##   [4] "!="              "("               "{"              
##   [7] "*"               "/"               "&"              
##  [10] "&&"              "%%"              "%>%"            
##  [13] "%in%"            "^"               "+"              
##  [16] "<"               "<="              "=="             
##  [19] ">"               ">="              "|"              
##  [22] "||"              "abs"             "acos"           
##  [25] "acosh"           "as.character"    "as.double"      
##  [28] "as.integer"      "as.numeric"      "asin"           
##  [31] "asinh"           "atan"            "atan2"          
##  [34] "atanh"           "between"         "c"              
##  [37] "case_when"       "ceil"            "ceiling"        
##  [40] "coalesce"        "cos"             "cosh"           
##  [43] "cot"             "coth"            "desc"           
##  [46] "exp"             "floor"           "if"             
##  [49] "if_else"         "ifelse"          "is.na"          
##  [52] "is.null"         "log"             "log10"          
##  [55] "na_if"           "nchar"           "pmax"           
##  [58] "pmin"            "round"           "sign"           
##  [61] "sin"             "sinh"            "sql"            
##  [64] "sqrt"            "str_detect"      "str_length"     
##  [67] "str_replace_all" "str_to_lower"    "str_to_upper"   
##  [70] "str_trim"        "substr"          "tan"            
##  [73] "tanh"            "tolower"         "toupper"        
##  [76] "trimws"          "xor"             "max"            
##  [79] "mean"            "min"             "n"              
##  [82] "n_distinct"      "sum"             "var"            
##  [85] "cume_dist"       "cummax"          "cummean"        
##  [88] "cummin"          "cumsum"          "dense_rank"     
##  [91] "first"           "lag"             "last"           
##  [94] "lead"            "max"             "mean"           
##  [97] "min"             "min_rank"        "n"              
## [100] "n_distinct"      "nth"             "ntile"          
## [103] "order_by"        "percent_rank"    "rank"           
## [106] "row_number"      "sum"             "var"
```

```r
sql_translate_env(simulate_dbi())
```

```
## <sql_variant>
## scalar:    -, :, !, !=, (, {, *, /, &, &&, %%, %>%, %in%, ^, +, <,
## scalar:    <=, ==, >, >=, |, ||, abs, acos, acosh, as.character,
## scalar:    as.double, as.integer, as.numeric, asin, asinh, atan,
## scalar:    atan2, atanh, between, c, case_when, ceil, ceiling,
## scalar:    coalesce, cos, cosh, cot, coth, desc, exp, floor, if,
## scalar:    if_else, ifelse, is.na, is.null, log, log10, na_if,
## scalar:    nchar, pmax, pmin, round, sign, sin, sinh, sql, sqrt,
## scalar:    str_detect, str_length, str_replace_all, str_to_lower,
## scalar:    str_to_upper, str_trim, substr, tan, tanh, tolower,
## scalar:    toupper, trimws, xor
## aggregate: max, mean, min, n, n_distinct, sum, var
## window:    cume_dist, cummax, cummean, cummin, cumsum, dense_rank,
## window:    first, lag, last, lead, max, mean, min, min_rank, n,
## window:    n_distinct, nth, ntile, order_by, percent_rank, rank,
## window:    row_number, sum, var
```


```r
source(here("book-src", "dbplyr-sql-function-translation.R"))
```

Each of the following dbplyr back ends may have a slightly different translation:


```r
translations %>%
  filter(!is.na(sql)) %>% count(variant)
```

```
## # A tibble: 13 x 2
##    variant             n
##    <chr>           <int>
##  1 dbi               163
##  2 hive              180
##  3 impala            184
##  4 mssql             192
##  5 mysql             113
##  6 odbc              163
##  7 odbc_access       186
##  8 odbc_postgresql   184
##  9 oracle            180
## 10 postgres            1
## 11 sqlite            120
## 12 teradata          190
## 13 test              163
```
Only one postgres translation produces an output:

```r
psql <- translations %>%
  filter(!is.na(sql), variant == "postgres") %>%
  select(r, n_args, sql) %>%
  arrange(r)

psql %>% gt
```

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Fira Sans', 'Droid Sans', 'Helvetica Neue', Arial, sans-serif;
}

#cqpqwqagrn .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #000000;
  font-size: 16px;
  background-color: #FFFFFF;
  /* table.background.color */
  width: auto;
  /* table.width */
  border-top-style: solid;
  /* table.border.top.style */
  border-top-width: 2px;
  /* table.border.top.width */
  border-top-color: #A8A8A8;
  /* table.border.top.color */
}

#cqpqwqagrn .gt_heading {
  background-color: #FFFFFF;
  /* heading.background.color */
  border-bottom-color: #FFFFFF;
}

#cqpqwqagrn .gt_title {
  color: #000000;
  font-size: 125%;
  /* heading.title.font.size */
  padding-top: 4px;
  /* heading.top.padding */
  padding-bottom: 1px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#cqpqwqagrn .gt_subtitle {
  color: #000000;
  font-size: 85%;
  /* heading.subtitle.font.size */
  padding-top: 1px;
  padding-bottom: 4px;
  /* heading.bottom.padding */
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#cqpqwqagrn .gt_bottom_border {
  border-bottom-style: solid;
  /* heading.border.bottom.style */
  border-bottom-width: 2px;
  /* heading.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* heading.border.bottom.color */
}

#cqpqwqagrn .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  padding-top: 4px;
  padding-bottom: 4px;
}

#cqpqwqagrn .gt_col_heading {
  color: #000000;
  background-color: #FFFFFF;
  /* column_labels.background.color */
  font-size: 16px;
  /* column_labels.font.size */
  font-weight: initial;
  /* column_labels.font.weight */
  vertical-align: middle;
  padding: 10px;
  margin: 10px;
}

#cqpqwqagrn .gt_sep_right {
  border-right: 5px solid #FFFFFF;
}

#cqpqwqagrn .gt_group_heading {
  padding: 8px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#cqpqwqagrn .gt_empty_group_heading {
  padding: 0.5px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#cqpqwqagrn .gt_striped tr:nth-child(even) {
  background-color: #f2f2f2;
}

#cqpqwqagrn .gt_row {
  padding: 10px;
  /* row.padding */
  margin: 10px;
  vertical-align: middle;
}

#cqpqwqagrn .gt_stub {
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #A8A8A8;
  padding-left: 12px;
}

#cqpqwqagrn .gt_stub.gt_row {
  background-color: #FFFFFF;
}

#cqpqwqagrn .gt_summary_row {
  background-color: #FFFFFF;
  /* summary_row.background.color */
  padding: 6px;
  /* summary_row.padding */
  text-transform: inherit;
  /* summary_row.text_transform */
}

#cqpqwqagrn .gt_first_summary_row {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
}

#cqpqwqagrn .gt_table_body {
  border-top-style: solid;
  /* field.border.top.style */
  border-top-width: 2px;
  /* field.border.top.width */
  border-top-color: #A8A8A8;
  /* field.border.top.color */
  border-bottom-style: solid;
  /* field.border.bottom.style */
  border-bottom-width: 2px;
  /* field.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* field.border.bottom.color */
}

#cqpqwqagrn .gt_footnote {
  font-size: 90%;
  /* footnote.font.size */
  padding: 4px;
  /* footnote.padding */
}

#cqpqwqagrn .gt_sourcenote {
  font-size: 90%;
  /* sourcenote.font.size */
  padding: 4px;
  /* sourcenote.padding */
}

#cqpqwqagrn .gt_center {
  text-align: center;
}

#cqpqwqagrn .gt_left {
  text-align: left;
}

#cqpqwqagrn .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#cqpqwqagrn .gt_font_normal {
  font-weight: normal;
}

#cqpqwqagrn .gt_font_bold {
  font-weight: bold;
}

#cqpqwqagrn .gt_font_italic {
  font-style: italic;
}

#cqpqwqagrn .gt_super {
  font-size: 65%;
}

#cqpqwqagrn .gt_footnote_glyph {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="cqpqwqagrn" style="overflow-x:auto;"><!--gt table start-->
<table class='gt_table'>
<tr>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>r</th>
<th class='gt_col_heading gt_right' rowspan='1' colspan='1'>n_args</th>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>sql</th>
</tr>
<tbody class='gt_table_body gt_striped'>
<tr>
<td class='gt_row gt_left'>c()</td>
<td class='gt_row gt_right'>0</td>
<td class='gt_row gt_left'>NULL</td>
</tr>
</tbody>
</table>
<!--gt table end-->
</div><!--/html_preserve-->

the `postgres` variant fails for various reasons:

```r
psql_errors <-  translations %>%
  filter(variant == "postgres") 

error_list <- tibble(
  function_name = psql_errors$fun_name, 
  r = psql_errors$r,
  errors = psql_errors %>% pluck("errors"))

nrow(error_list)
```

```
## [1] 555
```

```r
gt(head(error_list, n = 15))
```

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Fira Sans', 'Droid Sans', 'Helvetica Neue', Arial, sans-serif;
}

#sohyhvhgeg .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #000000;
  font-size: 16px;
  background-color: #FFFFFF;
  /* table.background.color */
  width: auto;
  /* table.width */
  border-top-style: solid;
  /* table.border.top.style */
  border-top-width: 2px;
  /* table.border.top.width */
  border-top-color: #A8A8A8;
  /* table.border.top.color */
}

#sohyhvhgeg .gt_heading {
  background-color: #FFFFFF;
  /* heading.background.color */
  border-bottom-color: #FFFFFF;
}

#sohyhvhgeg .gt_title {
  color: #000000;
  font-size: 125%;
  /* heading.title.font.size */
  padding-top: 4px;
  /* heading.top.padding */
  padding-bottom: 1px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#sohyhvhgeg .gt_subtitle {
  color: #000000;
  font-size: 85%;
  /* heading.subtitle.font.size */
  padding-top: 1px;
  padding-bottom: 4px;
  /* heading.bottom.padding */
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#sohyhvhgeg .gt_bottom_border {
  border-bottom-style: solid;
  /* heading.border.bottom.style */
  border-bottom-width: 2px;
  /* heading.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* heading.border.bottom.color */
}

#sohyhvhgeg .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  padding-top: 4px;
  padding-bottom: 4px;
}

#sohyhvhgeg .gt_col_heading {
  color: #000000;
  background-color: #FFFFFF;
  /* column_labels.background.color */
  font-size: 16px;
  /* column_labels.font.size */
  font-weight: initial;
  /* column_labels.font.weight */
  vertical-align: middle;
  padding: 10px;
  margin: 10px;
}

#sohyhvhgeg .gt_sep_right {
  border-right: 5px solid #FFFFFF;
}

#sohyhvhgeg .gt_group_heading {
  padding: 8px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#sohyhvhgeg .gt_empty_group_heading {
  padding: 0.5px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#sohyhvhgeg .gt_striped tr:nth-child(even) {
  background-color: #f2f2f2;
}

#sohyhvhgeg .gt_row {
  padding: 10px;
  /* row.padding */
  margin: 10px;
  vertical-align: middle;
}

#sohyhvhgeg .gt_stub {
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #A8A8A8;
  padding-left: 12px;
}

#sohyhvhgeg .gt_stub.gt_row {
  background-color: #FFFFFF;
}

#sohyhvhgeg .gt_summary_row {
  background-color: #FFFFFF;
  /* summary_row.background.color */
  padding: 6px;
  /* summary_row.padding */
  text-transform: inherit;
  /* summary_row.text_transform */
}

#sohyhvhgeg .gt_first_summary_row {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
}

#sohyhvhgeg .gt_table_body {
  border-top-style: solid;
  /* field.border.top.style */
  border-top-width: 2px;
  /* field.border.top.width */
  border-top-color: #A8A8A8;
  /* field.border.top.color */
  border-bottom-style: solid;
  /* field.border.bottom.style */
  border-bottom-width: 2px;
  /* field.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* field.border.bottom.color */
}

#sohyhvhgeg .gt_footnote {
  font-size: 90%;
  /* footnote.font.size */
  padding: 4px;
  /* footnote.padding */
}

#sohyhvhgeg .gt_sourcenote {
  font-size: 90%;
  /* sourcenote.font.size */
  padding: 4px;
  /* sourcenote.padding */
}

#sohyhvhgeg .gt_center {
  text-align: center;
}

#sohyhvhgeg .gt_left {
  text-align: left;
}

#sohyhvhgeg .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#sohyhvhgeg .gt_font_normal {
  font-weight: normal;
}

#sohyhvhgeg .gt_font_bold {
  font-weight: bold;
}

#sohyhvhgeg .gt_font_italic {
  font-style: italic;
}

#sohyhvhgeg .gt_super {
  font-size: 65%;
}

#sohyhvhgeg .gt_footnote_glyph {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="sohyhvhgeg" style="overflow-x:auto;"><!--gt table start-->
<table class='gt_table'>
<tr>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>function_name</th>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>r</th>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>errors</th>
</tr>
<tbody class='gt_table_body gt_striped'>
<tr>
<td class='gt_row gt_left'>-   </td>
<td class='gt_row gt_left'>`-`()   </td>
<td class='gt_row gt_left'>Error in `-`(): argument "x" is missing, with no default
                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>:   </td>
<td class='gt_row gt_left'>`:`()   </td>
<td class='gt_row gt_left'>Error in `:`(): argument "from" is missing, with no default
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>!   </td>
<td class='gt_row gt_left'>!NULL   </td>
<td class='gt_row gt_left'>Error in (function (classes, fdef, mtable) : unable to find an inherited method for function 'dbQuoteIdentifier' for signature '"PostgreSQLConnection", "character"'
</td>
</tr>
<tr>
<td class='gt_row gt_left'>!=  </td>
<td class='gt_row gt_left'>`!=`()  </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>(   </td>
<td class='gt_row gt_left'>(NULL)  </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>{   </td>
<td class='gt_row gt_left'>{}      </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>*   </td>
<td class='gt_row gt_left'>`*`()   </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>/   </td>
<td class='gt_row gt_left'>`/`()   </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>&amp;   </td>
<td class='gt_row gt_left'>`&amp;`()   </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>&amp;&amp;  </td>
<td class='gt_row gt_left'>`&amp;&amp;`()  </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>%%  </td>
<td class='gt_row gt_left'>`%%`()  </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>%&gt;% </td>
<td class='gt_row gt_left'>`%&gt;%`() </td>
<td class='gt_row gt_left'>Error in expr[[3L]]: subscript out of bounds
                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>%in%</td>
<td class='gt_row gt_left'>`%in%`()</td>
<td class='gt_row gt_left'>Error in is.sql(table): argument "table" is missing, with no default
                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>^   </td>
<td class='gt_row gt_left'>`^`()   </td>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL POWER. Expecting 2
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>+   </td>
<td class='gt_row gt_left'>`+`()   </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
</tbody>
</table>
<!--gt table end-->
</div><!--/html_preserve-->

```r
unique_error_list <- unique(error_list$errors) %>% as_tibble()
```

```
## Warning: Calling `as_tibble()` on a vector is discouraged, because the behavior is likely to change in the future. Use `tibble::enframe(name = NULL)` instead.
## This warning is displayed once per session.
```

```r
gt(unique_error_list)
```

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Fira Sans', 'Droid Sans', 'Helvetica Neue', Arial, sans-serif;
}

#ihebfvnxvb .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #000000;
  font-size: 16px;
  background-color: #FFFFFF;
  /* table.background.color */
  width: auto;
  /* table.width */
  border-top-style: solid;
  /* table.border.top.style */
  border-top-width: 2px;
  /* table.border.top.width */
  border-top-color: #A8A8A8;
  /* table.border.top.color */
}

#ihebfvnxvb .gt_heading {
  background-color: #FFFFFF;
  /* heading.background.color */
  border-bottom-color: #FFFFFF;
}

#ihebfvnxvb .gt_title {
  color: #000000;
  font-size: 125%;
  /* heading.title.font.size */
  padding-top: 4px;
  /* heading.top.padding */
  padding-bottom: 1px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#ihebfvnxvb .gt_subtitle {
  color: #000000;
  font-size: 85%;
  /* heading.subtitle.font.size */
  padding-top: 1px;
  padding-bottom: 4px;
  /* heading.bottom.padding */
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#ihebfvnxvb .gt_bottom_border {
  border-bottom-style: solid;
  /* heading.border.bottom.style */
  border-bottom-width: 2px;
  /* heading.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* heading.border.bottom.color */
}

#ihebfvnxvb .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  padding-top: 4px;
  padding-bottom: 4px;
}

#ihebfvnxvb .gt_col_heading {
  color: #000000;
  background-color: #FFFFFF;
  /* column_labels.background.color */
  font-size: 16px;
  /* column_labels.font.size */
  font-weight: initial;
  /* column_labels.font.weight */
  vertical-align: middle;
  padding: 10px;
  margin: 10px;
}

#ihebfvnxvb .gt_sep_right {
  border-right: 5px solid #FFFFFF;
}

#ihebfvnxvb .gt_group_heading {
  padding: 8px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#ihebfvnxvb .gt_empty_group_heading {
  padding: 0.5px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#ihebfvnxvb .gt_striped tr:nth-child(even) {
  background-color: #f2f2f2;
}

#ihebfvnxvb .gt_row {
  padding: 10px;
  /* row.padding */
  margin: 10px;
  vertical-align: middle;
}

#ihebfvnxvb .gt_stub {
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #A8A8A8;
  padding-left: 12px;
}

#ihebfvnxvb .gt_stub.gt_row {
  background-color: #FFFFFF;
}

#ihebfvnxvb .gt_summary_row {
  background-color: #FFFFFF;
  /* summary_row.background.color */
  padding: 6px;
  /* summary_row.padding */
  text-transform: inherit;
  /* summary_row.text_transform */
}

#ihebfvnxvb .gt_first_summary_row {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
}

#ihebfvnxvb .gt_table_body {
  border-top-style: solid;
  /* field.border.top.style */
  border-top-width: 2px;
  /* field.border.top.width */
  border-top-color: #A8A8A8;
  /* field.border.top.color */
  border-bottom-style: solid;
  /* field.border.bottom.style */
  border-bottom-width: 2px;
  /* field.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* field.border.bottom.color */
}

#ihebfvnxvb .gt_footnote {
  font-size: 90%;
  /* footnote.font.size */
  padding: 4px;
  /* footnote.padding */
}

#ihebfvnxvb .gt_sourcenote {
  font-size: 90%;
  /* sourcenote.font.size */
  padding: 4px;
  /* sourcenote.padding */
}

#ihebfvnxvb .gt_center {
  text-align: center;
}

#ihebfvnxvb .gt_left {
  text-align: left;
}

#ihebfvnxvb .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#ihebfvnxvb .gt_font_normal {
  font-weight: normal;
}

#ihebfvnxvb .gt_font_bold {
  font-weight: bold;
}

#ihebfvnxvb .gt_font_italic {
  font-style: italic;
}

#ihebfvnxvb .gt_super {
  font-size: 65%;
}

#ihebfvnxvb .gt_footnote_glyph {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="ihebfvnxvb" style="overflow-x:auto;"><!--gt table start-->
<table class='gt_table'>
<tr>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>value</th>
</tr>
<tbody class='gt_table_body gt_striped'>
<tr>
<td class='gt_row gt_left'>Error in `-`(): argument "x" is missing, with no default
                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in `:`(): argument "from" is missing, with no default
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in (function (classes, fdef, mtable) : unable to find an inherited method for function 'dbQuoteIdentifier' for signature '"PostgreSQLConnection", "character"'
</td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "x" is missing, with no default
                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in expr[[3L]]: subscript out of bounds
                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in is.sql(table): argument "table" is missing, with no default
                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL POWER. Expecting 2
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL ABS. Expecting 1
                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL ACOS. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL ACOSH. Expecting 1
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in enexpr(x): argument "x" is missing, with no default
                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL ASIN. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL ASINH. Expecting 1
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL ATAN. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL ATAN2. Expecting 2
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL ATANH. Expecting 1
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>NA                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>No cases provided                                                                                                                                                     </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL CEIL. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL COS. Expecting 1
                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL COSH. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL COTH. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL EXP. Expecting 1
                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL FLOOR. Expecting 1
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "cond" is missing, with no default
                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in sql_if(condition, true, false): argument "condition" is missing, with no default
                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in sql_if(test, yes, no): argument "test" is missing, with no default
                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL NULL_IF. Expecting 2
                                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL LENGTH. Expecting 1
                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in (function (classes, fdef, mtable) : unable to find an inherited method for function 'dbQuoteString' for signature '"PostgreSQLConnection", "character"'
    </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL SIGN. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL SIN. Expecting 1
                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL SINH. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL SQRT. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in enexpr(x): argument "string" is missing, with no default
                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "string" is missing, with no default
                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in substr(): argument "stop" is missing, with no default
                                                                                                      </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL TAN. Expecting 1
                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL TANH. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL LOWER. Expecting 1
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL UPPER. Expecting 1
                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error: Invalid number of args to SQL TRIM. Expecting 1
                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in escape(x): argument "x" is missing, with no default
                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in order_by %||% win_current_order(): argument "order_by" is missing, with no default
                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in is.null(vars) || is.character(vars): argument "order_by" is missing, with no default
                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>Error in (function (classes, fdef, mtable) : unable to find an inherited method for function 'dbQuoteIdentifier' for signature '"PostgreSQLConnection", "ident"'
    </td>
</tr>
</tbody>
</table>
<!--gt table end-->
</div><!--/html_preserve-->
The `==` function across variant dbplyr backends

```r
equal = translations %>% 
  filter(fun_name == "==") 

equal_list <-  tibble(
  variant = equal$variant, 
  n_args = equal$n_args,
  r = equal$r,
  sql = equal$sql,
  errors = equal %>% pluck("errors")) %>% 
  arrange(variant, n_args) %>% 
  filter(between(n_args,1,3))

equal_list %>% gt()
```

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Fira Sans', 'Droid Sans', 'Helvetica Neue', Arial, sans-serif;
}

#lghnetfgzu .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #000000;
  font-size: 16px;
  background-color: #FFFFFF;
  /* table.background.color */
  width: auto;
  /* table.width */
  border-top-style: solid;
  /* table.border.top.style */
  border-top-width: 2px;
  /* table.border.top.width */
  border-top-color: #A8A8A8;
  /* table.border.top.color */
}

#lghnetfgzu .gt_heading {
  background-color: #FFFFFF;
  /* heading.background.color */
  border-bottom-color: #FFFFFF;
}

#lghnetfgzu .gt_title {
  color: #000000;
  font-size: 125%;
  /* heading.title.font.size */
  padding-top: 4px;
  /* heading.top.padding */
  padding-bottom: 1px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#lghnetfgzu .gt_subtitle {
  color: #000000;
  font-size: 85%;
  /* heading.subtitle.font.size */
  padding-top: 1px;
  padding-bottom: 4px;
  /* heading.bottom.padding */
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#lghnetfgzu .gt_bottom_border {
  border-bottom-style: solid;
  /* heading.border.bottom.style */
  border-bottom-width: 2px;
  /* heading.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* heading.border.bottom.color */
}

#lghnetfgzu .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  padding-top: 4px;
  padding-bottom: 4px;
}

#lghnetfgzu .gt_col_heading {
  color: #000000;
  background-color: #FFFFFF;
  /* column_labels.background.color */
  font-size: 16px;
  /* column_labels.font.size */
  font-weight: initial;
  /* column_labels.font.weight */
  vertical-align: middle;
  padding: 10px;
  margin: 10px;
}

#lghnetfgzu .gt_sep_right {
  border-right: 5px solid #FFFFFF;
}

#lghnetfgzu .gt_group_heading {
  padding: 8px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#lghnetfgzu .gt_empty_group_heading {
  padding: 0.5px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#lghnetfgzu .gt_striped tr:nth-child(even) {
  background-color: #f2f2f2;
}

#lghnetfgzu .gt_row {
  padding: 10px;
  /* row.padding */
  margin: 10px;
  vertical-align: middle;
}

#lghnetfgzu .gt_stub {
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #A8A8A8;
  padding-left: 12px;
}

#lghnetfgzu .gt_stub.gt_row {
  background-color: #FFFFFF;
}

#lghnetfgzu .gt_summary_row {
  background-color: #FFFFFF;
  /* summary_row.background.color */
  padding: 6px;
  /* summary_row.padding */
  text-transform: inherit;
  /* summary_row.text_transform */
}

#lghnetfgzu .gt_first_summary_row {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
}

#lghnetfgzu .gt_table_body {
  border-top-style: solid;
  /* field.border.top.style */
  border-top-width: 2px;
  /* field.border.top.width */
  border-top-color: #A8A8A8;
  /* field.border.top.color */
  border-bottom-style: solid;
  /* field.border.bottom.style */
  border-bottom-width: 2px;
  /* field.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* field.border.bottom.color */
}

#lghnetfgzu .gt_footnote {
  font-size: 90%;
  /* footnote.font.size */
  padding: 4px;
  /* footnote.padding */
}

#lghnetfgzu .gt_sourcenote {
  font-size: 90%;
  /* sourcenote.font.size */
  padding: 4px;
  /* sourcenote.padding */
}

#lghnetfgzu .gt_center {
  text-align: center;
}

#lghnetfgzu .gt_left {
  text-align: left;
}

#lghnetfgzu .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#lghnetfgzu .gt_font_normal {
  font-weight: normal;
}

#lghnetfgzu .gt_font_bold {
  font-weight: bold;
}

#lghnetfgzu .gt_font_italic {
  font-style: italic;
}

#lghnetfgzu .gt_super {
  font-size: 65%;
}

#lghnetfgzu .gt_footnote_glyph {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="lghnetfgzu" style="overflow-x:auto;"><!--gt table start-->
<table class='gt_table'>
<tr>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>variant</th>
<th class='gt_col_heading gt_right' rowspan='1' colspan='1'>n_args</th>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>r</th>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>sql</th>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>errors</th>
</tr>
<tbody class='gt_table_body gt_striped'>
<tr>
<td class='gt_row gt_left'>dbi            </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>dbi            </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>"arg1" = "arg2"</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>dbi            </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>hive           </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>hive           </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>hive           </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>impala         </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>impala         </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>impala         </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>mssql          </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>mssql          </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>mssql          </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>mysql          </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>mysql          </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>mysql          </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc           </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc           </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc           </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc_access    </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc_access    </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc_access    </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc_postgresql</td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc_postgresql</td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>odbc_postgresql</td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>oracle         </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>oracle         </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>oracle         </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>postgres       </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in (function (classes, fdef, mtable) : unable to find an inherited method for function 'dbQuoteIdentifier' for signature '"PostgreSQLConnection", "ident"'
</td>
</tr>
<tr>
<td class='gt_row gt_left'>postgres       </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in (function (classes, fdef, mtable) : unable to find an inherited method for function 'dbQuoteIdentifier' for signature '"PostgreSQLConnection", "ident"'
</td>
</tr>
<tr>
<td class='gt_row gt_left'>postgres       </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in (function (classes, fdef, mtable) : unable to find an inherited method for function 'dbQuoteIdentifier' for signature '"PostgreSQLConnection", "ident"'
</td>
</tr>
<tr>
<td class='gt_row gt_left'>sqlite         </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>sqlite         </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>sqlite         </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>teradata       </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>teradata       </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>teradata       </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>test           </td>
<td class='gt_row gt_right'>1</td>
<td class='gt_row gt_left'>==arg1                </td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in eval_bare(x, .env): argument "y" is missing, with no default
                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>test           </td>
<td class='gt_row gt_right'>2</td>
<td class='gt_row gt_left'>arg1 == arg2          </td>
<td class='gt_row gt_left'>`arg1` = `arg2`</td>
<td class='gt_row gt_left'>NA                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>test           </td>
<td class='gt_row gt_right'>3</td>
<td class='gt_row gt_left'>`==`(arg1, arg2, arg3)</td>
<td class='gt_row gt_left'>NA             </td>
<td class='gt_row gt_left'>Error in `==`(arg1, arg2, arg3): unused argument (arg3)
                                                                                                         </td>
</tr>
</tbody>
</table>
<!--gt table end-->
</div><!--/html_preserve-->
odbc_postgres works on the whole list of SQL functions

```r
psql <- translations %>%
  filter(!is.na(sql), variant == "odbc_postgresql") %>%
  select(r, n_args, sql) %>%
  arrange(r)

psql %>% gt
```

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Fira Sans', 'Droid Sans', 'Helvetica Neue', Arial, sans-serif;
}

#oqiqinrmgt .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #000000;
  font-size: 16px;
  background-color: #FFFFFF;
  /* table.background.color */
  width: auto;
  /* table.width */
  border-top-style: solid;
  /* table.border.top.style */
  border-top-width: 2px;
  /* table.border.top.width */
  border-top-color: #A8A8A8;
  /* table.border.top.color */
}

#oqiqinrmgt .gt_heading {
  background-color: #FFFFFF;
  /* heading.background.color */
  border-bottom-color: #FFFFFF;
}

#oqiqinrmgt .gt_title {
  color: #000000;
  font-size: 125%;
  /* heading.title.font.size */
  padding-top: 4px;
  /* heading.top.padding */
  padding-bottom: 1px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#oqiqinrmgt .gt_subtitle {
  color: #000000;
  font-size: 85%;
  /* heading.subtitle.font.size */
  padding-top: 1px;
  padding-bottom: 4px;
  /* heading.bottom.padding */
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#oqiqinrmgt .gt_bottom_border {
  border-bottom-style: solid;
  /* heading.border.bottom.style */
  border-bottom-width: 2px;
  /* heading.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* heading.border.bottom.color */
}

#oqiqinrmgt .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  padding-top: 4px;
  padding-bottom: 4px;
}

#oqiqinrmgt .gt_col_heading {
  color: #000000;
  background-color: #FFFFFF;
  /* column_labels.background.color */
  font-size: 16px;
  /* column_labels.font.size */
  font-weight: initial;
  /* column_labels.font.weight */
  vertical-align: middle;
  padding: 10px;
  margin: 10px;
}

#oqiqinrmgt .gt_sep_right {
  border-right: 5px solid #FFFFFF;
}

#oqiqinrmgt .gt_group_heading {
  padding: 8px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#oqiqinrmgt .gt_empty_group_heading {
  padding: 0.5px;
  color: #000000;
  background-color: #FFFFFF;
  /* stub_group.background.color */
  font-size: 16px;
  /* stub_group.font.size */
  font-weight: initial;
  /* stub_group.font.weight */
  border-top-style: solid;
  /* stub_group.border.top.style */
  border-top-width: 2px;
  /* stub_group.border.top.width */
  border-top-color: #A8A8A8;
  /* stub_group.border.top.color */
  border-bottom-style: solid;
  /* stub_group.border.bottom.style */
  border-bottom-width: 2px;
  /* stub_group.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* stub_group.border.bottom.color */
  vertical-align: middle;
}

#oqiqinrmgt .gt_striped tr:nth-child(even) {
  background-color: #f2f2f2;
}

#oqiqinrmgt .gt_row {
  padding: 10px;
  /* row.padding */
  margin: 10px;
  vertical-align: middle;
}

#oqiqinrmgt .gt_stub {
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #A8A8A8;
  padding-left: 12px;
}

#oqiqinrmgt .gt_stub.gt_row {
  background-color: #FFFFFF;
}

#oqiqinrmgt .gt_summary_row {
  background-color: #FFFFFF;
  /* summary_row.background.color */
  padding: 6px;
  /* summary_row.padding */
  text-transform: inherit;
  /* summary_row.text_transform */
}

#oqiqinrmgt .gt_first_summary_row {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
}

#oqiqinrmgt .gt_table_body {
  border-top-style: solid;
  /* field.border.top.style */
  border-top-width: 2px;
  /* field.border.top.width */
  border-top-color: #A8A8A8;
  /* field.border.top.color */
  border-bottom-style: solid;
  /* field.border.bottom.style */
  border-bottom-width: 2px;
  /* field.border.bottom.width */
  border-bottom-color: #A8A8A8;
  /* field.border.bottom.color */
}

#oqiqinrmgt .gt_footnote {
  font-size: 90%;
  /* footnote.font.size */
  padding: 4px;
  /* footnote.padding */
}

#oqiqinrmgt .gt_sourcenote {
  font-size: 90%;
  /* sourcenote.font.size */
  padding: 4px;
  /* sourcenote.padding */
}

#oqiqinrmgt .gt_center {
  text-align: center;
}

#oqiqinrmgt .gt_left {
  text-align: left;
}

#oqiqinrmgt .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#oqiqinrmgt .gt_font_normal {
  font-weight: normal;
}

#oqiqinrmgt .gt_font_bold {
  font-weight: bold;
}

#oqiqinrmgt .gt_font_italic {
  font-style: italic;
}

#oqiqinrmgt .gt_super {
  font-size: 65%;
}

#oqiqinrmgt .gt_footnote_glyph {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="oqiqinrmgt" style="overflow-x:auto;"><!--gt table start-->
<table class='gt_table'>
<tr>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>r</th>
<th class='gt_col_heading gt_right' rowspan='1' colspan='1'>n_args</th>
<th class='gt_col_heading gt_left' rowspan='1' colspan='1'>sql</th>
</tr>
<tbody class='gt_table_body gt_striped'>
<tr>
<td class='gt_row gt_left'>-arg1                                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>-`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>!arg1                                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>NOT(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>!arg1                                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>NOT(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>!arg1                                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>NOT(`arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>!arg1                                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>NOT(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>!NULL                                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>NOT()                                                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>(arg1)                                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>{    arg1}                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>abs(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>ABS(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>acos(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>ACOS(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>acosh(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>ACOSH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>all(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>bool_and(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>all(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>bool_and(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>any(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>bool_or(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>any(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>bool_or(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 - arg2                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` - `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 != arg2                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` != `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 * arg2                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` * `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 &amp; arg2                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` AND `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 &amp;&amp; arg2                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` AND `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 %in% arg2                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` IN `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 + arg2                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` + `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 &lt; arg2                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` &lt; `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 &lt;= arg2                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` &lt;= `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 == arg2                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` = `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 &gt; arg2                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` &gt; `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 &gt;= arg2                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` &gt;= `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 | arg2                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` OR `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1 || arg2                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` OR `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1/arg2                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` / `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1%%arg2                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` % `arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>arg1^arg2                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>POWER(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>as.character(arg1)                                                                                                                                                                                                                                                                                                                                                                   </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>CAST(`arg1` AS TEXT)                                                                                                                                                                                                                                                                                                                                                                                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>as.double(arg1)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>CAST(`arg1` AS NUMERIC)                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>as.integer(arg1)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>CAST(`arg1` AS INTEGER)                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>as.numeric(arg1)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>CAST(`arg1` AS NUMERIC)                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>asin(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>ASIN(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>asinh(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>ASINH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>atan(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>ATAN(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>atan2(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                    </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>ATAN2(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>atanh(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>ATANH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>between(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>`arg1` BETWEEN `arg2` AND `arg3`                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>c()                                                                                                                                                                                                                                                                                                                                                                                  </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>NULL                                                                                                                                                                                                                                                                                                                                                                                                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>c(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)           </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>c(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                                  </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>c(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                        </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>c(arg1)                                                                                                                                                                                                                                                                                                                                                                              </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>ceil(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>CEIL(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>ceiling(arg1)                                                                                                                                                                                                                                                                                                                                                                        </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>CEIL(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>coalesce()                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>COALESCE()                                                                                                                                                                                                                                                                                                                                                                                                                                                                     </td>
</tr>
<tr>
<td class='gt_row gt_left'>coalesce(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9,     arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18,     arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27,     arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36,     arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45,     arg46, arg47, arg48, arg49, arg50)    </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>COALESCE(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)              </td>
</tr>
<tr>
<td class='gt_row gt_left'>coalesce(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>COALESCE(`arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>coalesce(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                 </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>COALESCE(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>coalesce(arg1)                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>COALESCE(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>cor(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>CORR(`arg1`, `arg2`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>cos(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>COS(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>cosh(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>COSH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>cot(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>1 / TAN(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>coth(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>COTH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>cov(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>COVAR_SAMP(`arg1`, `arg2`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>cume_dist()                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>cume_dist() OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>cume_dist(arg1)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>cume_dist() OVER (ORDER BY `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>cummax(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                   </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>max(`arg1`) OVER (ORDER BY `arg2` ROWS UNBOUNDED PRECEDING)                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>cummax(arg1)                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>max(`arg1`) OVER (ROWS UNBOUNDED PRECEDING)                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>cummean(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                  </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>avg(`arg1`) OVER (ORDER BY `arg2` ROWS UNBOUNDED PRECEDING)                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>cummean(arg1)                                                                                                                                                                                                                                                                                                                                                                        </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>avg(`arg1`) OVER (ROWS UNBOUNDED PRECEDING)                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>cummin(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                   </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>min(`arg1`) OVER (ORDER BY `arg2` ROWS UNBOUNDED PRECEDING)                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>cummin(arg1)                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>min(`arg1`) OVER (ROWS UNBOUNDED PRECEDING)                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>cumsum(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                   </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>sum(`arg1`) OVER (ORDER BY `arg2` ROWS UNBOUNDED PRECEDING)                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>cumsum(arg1)                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>sum(`arg1`) OVER (ROWS UNBOUNDED PRECEDING)                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>dense_rank()                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>dense_rank() OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>dense_rank(arg1)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>dense_rank() OVER (ORDER BY `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>desc(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>`arg1` DESC                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>exp(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>EXP(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>first(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                    </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>first_value(`arg1`) OVER (ORDER BY `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                     </td>
</tr>
<tr>
<td class='gt_row gt_left'>first(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>first_value(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>floor(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>FLOOR(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>grepl(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                    </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>(`arg2`) ~ (`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>if (arg1) arg2                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>CASE WHEN (`arg1`) THEN (`arg2`) END                                                                                                                                                                                                                                                                                                                                                                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>if (arg1) arg2 else arg3                                                                                                                                                                                                                                                                                                                                                             </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>CASE WHEN (`arg1`) THEN (`arg2`) WHEN NOT(`arg1`) THEN (`arg3`) END                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>if_else(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>CASE WHEN (`arg1`) THEN (`arg2`) WHEN NOT(`arg1`) THEN (`arg3`) END                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>ifelse(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                             </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>CASE WHEN (`arg1`) THEN (`arg2`) WHEN NOT(`arg1`) THEN (`arg3`) END                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>is.na(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>((`arg1`) IS NULL)                                                                                                                                                                                                                                                                                                                                                                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>is.null(arg1)                                                                                                                                                                                                                                                                                                                                                                        </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>((`arg1`) IS NULL)                                                                                                                                                                                                                                                                                                                                                                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>lag(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>LAG(`arg1`, NULL, `arg3`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                              </td>
</tr>
<tr>
<td class='gt_row gt_left'>lag(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>LAG(`arg1`, NULL, NULL) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>lag(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LAG(`arg1`, 1, NULL) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>last(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>last_value(`arg1`) OVER (ORDER BY `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                      </td>
</tr>
<tr>
<td class='gt_row gt_left'>last(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>last_value(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                     </td>
</tr>
<tr>
<td class='gt_row gt_left'>lead(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>LEAD(`arg1`, `arg2`, `arg3`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>lead(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>LEAD(`arg1`, `arg2`, NULL) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>lead(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LEAD(`arg1`, 1, NULL) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>log(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>LOG(`arg1`) / LOG(`arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                      </td>
</tr>
<tr>
<td class='gt_row gt_left'>log(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LN(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                     </td>
</tr>
<tr>
<td class='gt_row gt_left'>log10(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LOG(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>max(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>max(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>max(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>max(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>mean(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>avg(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>mean(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>avg(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>min_rank()                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>rank() OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>min_rank(arg1)                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>rank() OVER (ORDER BY `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>min(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>min(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>min(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>min(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>n_distinct()                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>COUNT(DISTINCT ) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>n_distinct(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9,     arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18,     arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27,     arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36,     arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45,     arg46, arg47, arg48, arg49, arg50)  </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>COUNT(DISTINCT `arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`) OVER ()</td>
</tr>
<tr>
<td class='gt_row gt_left'>n_distinct(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>COUNT(DISTINCT `arg1`, `arg2`, `arg3`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>n_distinct(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>COUNT(DISTINCT `arg1`, `arg2`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>n_distinct(arg1)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>COUNT(DISTINCT `arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>n()                                                                                                                                                                                                                                                                                                                                                                                  </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>COUNT(*) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>na_if(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                    </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>NULL_IF(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>nchar(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LENGTH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>nth(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>nth_value(`arg1`, NULL) OVER (ORDER BY `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>nth(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>nth_value(`arg1`, NULL) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>ntile(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                    </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>NTILE(NULL) OVER (ORDER BY `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>order_by(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                 </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste()                                                                                                                                                                                                                                                                                                                                                                              </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>CONCAT_WS(' ')                                                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)       </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>CONCAT_WS(' ', `arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)        </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                              </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>CONCAT_WS(' ', `arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                    </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>CONCAT_WS(' ', `arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>CONCAT_WS(' ', `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste0()                                                                                                                                                                                                                                                                                                                                                                             </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>CONCAT_WS('')                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste0(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9,     arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18,     arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27,     arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36,     arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45,     arg46, arg47, arg48, arg49, arg50)      </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>CONCAT_WS('', `arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)         </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste0(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                             </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>CONCAT_WS('', `arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste0(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                   </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>CONCAT_WS('', `arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>paste0(arg1)                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>CONCAT_WS('', `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>percent_rank()                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>percent_rank() OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>percent_rank(arg1)                                                                                                                                                                                                                                                                                                                                                                   </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>percent_rank() OVER (ORDER BY `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmax()                                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>MAX()                                                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmax(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)        </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>MAX(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmax(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>MAX(`arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmax(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>MAX(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmax(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>MAX(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmin()                                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>MIN()                                                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmin(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)        </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>MIN(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmin(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>MIN(`arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmin(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>MIN(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>pmin(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>MIN(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>rank()                                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>rank() OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>rank(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>rank() OVER (ORDER BY `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>round(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                    </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>ROUND((`arg1`) :: numeric, NULL)                                                                                                                                                                                                                                                                                                                                                                                                                                               </td>
</tr>
<tr>
<td class='gt_row gt_left'>round(arg1)                                                                                                                                                                                                                                                                                                                                                                          </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>ROUND((`arg1`) :: numeric, 0)                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>row_number()                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>row_number() OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>row_number(arg1)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>row_number() OVER (ORDER BY `arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>sd(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>stddev_samp(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>sd(arg1)                                                                                                                                                                                                                                                                                                                                                                             </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>stddev_samp(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>sign(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>SIGN(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>sin(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>SIN(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>sinh(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>SINH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>sql(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)         </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>sql(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                                </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>sql(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>sql(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>`arg1`                                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>sqrt(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>SQRT(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_detect(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>STRPOS(`arg1`, `arg2`) &gt; 0                                                                                                                                                                                                                                                                                                                                                                                                                                                     </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_flatten(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                              </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>STRING_AGG(`arg1`, `arg2`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                             </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_length()                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>LENGTH()                                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_length(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9,     arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18,     arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27,     arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36,     arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45,     arg46, arg47, arg48, arg49, arg50)  </td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>LENGTH(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)                </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_length(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>LENGTH(`arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_length(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>LENGTH(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_length(arg1)                                                                                                                                                                                                                                                                                                                                                                     </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LENGTH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_locate(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                               </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>STRPOS(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                         </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_replace_all(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                    </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>REPLACE(`arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                                </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_lower()                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>LOWER()                                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_lower(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8,     arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17,     arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26,     arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35,     arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44,     arg45, arg46, arg47, arg48, arg49, arg50)</td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>LOWER(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_lower(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>LOWER(`arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_lower(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                             </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>LOWER(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_lower(arg1)                                                                                                                                                                                                                                                                                                                                                                   </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LOWER(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_upper()                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 0</td>
<td class='gt_row gt_left'>UPPER()                                                                                                                                                                                                                                                                                                                                                                                                                                                                        </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_upper(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8,     arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17,     arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26,     arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35,     arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44,     arg45, arg46, arg47, arg48, arg49, arg50)</td>
<td class='gt_row gt_right'>50</td>
<td class='gt_row gt_left'>UPPER(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)                 </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_upper(arg1, arg2, arg3)                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 3</td>
<td class='gt_row gt_left'>UPPER(`arg1`, `arg2`, `arg3`)                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_upper(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                             </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>UPPER(`arg1`, `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                                          </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_to_upper(arg1)                                                                                                                                                                                                                                                                                                                                                                   </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>UPPER(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_trim(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                 </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>((`arg1`))                                                                                                                                                                                                                                                                                                                                                                                                                                                                     </td>
</tr>
<tr>
<td class='gt_row gt_left'>str_trim(arg1)                                                                                                                                                                                                                                                                                                                                                                       </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LTRIM(RTRIM(`arg1`))                                                                                                                                                                                                                                                                                                                                                                                                                                                           </td>
</tr>
<tr>
<td class='gt_row gt_left'>sum(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>sum(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>sum(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>sum(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                            </td>
</tr>
<tr>
<td class='gt_row gt_left'>tan(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>TAN(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </td>
</tr>
<tr>
<td class='gt_row gt_left'>tanh(arg1)                                                                                                                                                                                                                                                                                                                                                                           </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>TANH(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>tolower(arg1)                                                                                                                                                                                                                                                                                                                                                                        </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>LOWER(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>toupper(arg1)                                                                                                                                                                                                                                                                                                                                                                        </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>UPPER(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  </td>
</tr>
<tr>
<td class='gt_row gt_left'>trimws(arg1)                                                                                                                                                                                                                                                                                                                                                                         </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>TRIM(`arg1`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
<tr>
<td class='gt_row gt_left'>var(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>var_samp(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>var(arg1)                                                                                                                                                                                                                                                                                                                                                                            </td>
<td class='gt_row gt_right'> 1</td>
<td class='gt_row gt_left'>var_samp(`arg1`) OVER ()                                                                                                                                                                                                                                                                                                                                                                                                                                                       </td>
</tr>
<tr>
<td class='gt_row gt_left'>xor(arg1, arg2)                                                                                                                                                                                                                                                                                                                                                                      </td>
<td class='gt_row gt_right'> 2</td>
<td class='gt_row gt_left'>`arg1` OR `arg2` AND NOT (`arg1` AND `arg2`)                                                                                                                                                                                                                                                                                                                                                                                                                                   </td>
</tr>
</tbody>
</table>
<!--gt table end-->
</div><!--/html_preserve-->

