# Appendix _ Dplyr to SQL translations {#chapter_appendix-dplyr-to-postres-translation}

> You may be interested in exactly how the DBI package translates R functions into their SQL quivalents -- and in which functions are translated and which are not.  
This Appendix answers those questions.  It is based on the work of Dewey Dunnington ([@paleolimbot](http://twitter.com/paleolimbot)) which he published here: 
> 
> https://apps.fishandwhistle.net/archives/1503 
>
>  https://rud.is/b/2019/04/10/lost-in-sql-translation-charting-dbplyr-mapped-sql-function-support-across-all-backends/

## Overview

These packages are called below:

```r
library(tidyverse)
library(dbplyr)
library(gt)
library(here)
library(sqlpetr)
```
list the DBI functions that are available:

```r
names(sql_translate_env(simulate_dbi()))
```

```
##   [1] "-"               ":"               "!"              
##   [4] "!="              "("               "["              
##   [7] "[["              "{"               "*"              
##  [10] "/"               "&"               "&&"             
##  [13] "%%"              "%>%"             "%in%"           
##  [16] "^"               "+"               "<"              
##  [19] "<="              "=="              ">"              
##  [22] ">="              "|"               "||"             
##  [25] "$"               "abs"             "acos"           
##  [28] "as_date"         "as_datetime"     "as.character"   
##  [31] "as.Date"         "as.double"       "as.integer"     
##  [34] "as.integer64"    "as.logical"      "as.numeric"     
##  [37] "as.POSIXct"      "asin"            "atan"           
##  [40] "atan2"           "between"         "bitwAnd"        
##  [43] "bitwNot"         "bitwOr"          "bitwShiftL"     
##  [46] "bitwShiftR"      "bitwXor"         "c"              
##  [49] "case_when"       "ceil"            "ceiling"        
##  [52] "coalesce"        "cos"             "cosh"           
##  [55] "cot"             "coth"            "day"            
##  [58] "desc"            "exp"             "floor"          
##  [61] "hour"            "if"              "if_else"        
##  [64] "ifelse"          "is.na"           "is.null"        
##  [67] "log"             "log10"           "mday"           
##  [70] "minute"          "month"           "na_if"          
##  [73] "nchar"           "now"             "paste"          
##  [76] "paste0"          "pmax"            "pmin"           
##  [79] "qday"            "round"           "second"         
##  [82] "sign"            "sin"             "sinh"           
##  [85] "sql"             "sqrt"            "str_c"          
##  [88] "str_conv"        "str_count"       "str_detect"     
##  [91] "str_dup"         "str_extract"     "str_extract_all"
##  [94] "str_flatten"     "str_glue"        "str_glue_data"  
##  [97] "str_interp"      "str_length"      "str_locate"     
## [100] "str_locate_all"  "str_match"       "str_match_all"  
## [103] "str_order"       "str_pad"         "str_remove"     
## [106] "str_remove_all"  "str_replace"     "str_replace_all"
## [109] "str_replace_na"  "str_sort"        "str_split"      
## [112] "str_split_fixed" "str_squish"      "str_sub"        
## [115] "str_subset"      "str_to_lower"    "str_to_title"   
## [118] "str_to_upper"    "str_trim"        "str_trunc"      
## [121] "str_view"        "str_view_all"    "str_which"      
## [124] "str_wrap"        "substr"          "switch"         
## [127] "tan"             "tanh"            "today"          
## [130] "tolower"         "toupper"         "trimws"         
## [133] "wday"            "xor"             "yday"           
## [136] "year"            "cume_dist"       "cummax"         
## [139] "cummean"         "cummin"          "cumsum"         
## [142] "dense_rank"      "first"           "lag"            
## [145] "last"            "lead"            "max"            
## [148] "mean"            "median"          "min"            
## [151] "min_rank"        "n"               "n_distinct"     
## [154] "nth"             "ntile"           "order_by"       
## [157] "percent_rank"    "quantile"        "rank"           
## [160] "row_number"      "sum"             "var"            
## [163] "cume_dist"       "cummax"          "cummean"        
## [166] "cummin"          "cumsum"          "dense_rank"     
## [169] "first"           "lag"             "last"           
## [172] "lead"            "max"             "mean"           
## [175] "median"          "min"             "min_rank"       
## [178] "n"               "n_distinct"      "nth"            
## [181] "ntile"           "order_by"        "percent_rank"   
## [184] "quantile"        "rank"            "row_number"     
## [187] "sum"             "var"
```

```r
sql_translate_env(simulate_dbi())
```

```
## <sql_variant>
## scalar:    -, :, !, !=, (, [, [[, {, *, /, &, &&, %%, %>%, %in%,
## scalar:    ^, +, <, <=, ==, >, >=, |, ||, $, abs, acos, as_date,
## scalar:    as_datetime, as.character, as.Date, as.double,
## scalar:    as.integer, as.integer64, as.logical, as.numeric,
## scalar:    as.POSIXct, asin, atan, atan2, between, bitwAnd,
## scalar:    bitwNot, bitwOr, bitwShiftL, bitwShiftR, bitwXor, c,
## scalar:    case_when, ceil, ceiling, coalesce, cos, cosh, cot,
## scalar:    coth, day, desc, exp, floor, hour, if, if_else, ifelse,
## scalar:    is.na, is.null, log, log10, mday, minute, month, na_if,
## scalar:    nchar, now, paste, paste0, pmax, pmin, qday, round,
## scalar:    second, sign, sin, sinh, sql, sqrt, str_c, str_conv,
## scalar:    str_count, str_detect, str_dup, str_extract,
## scalar:    str_extract_all, str_flatten, str_glue, str_glue_data,
## scalar:    str_interp, str_length, str_locate, str_locate_all,
## scalar:    str_match, str_match_all, str_order, str_pad,
## scalar:    str_remove, str_remove_all, str_replace,
## scalar:    str_replace_all, str_replace_na, str_sort, str_split,
## scalar:    str_split_fixed, str_squish, str_sub, str_subset,
## scalar:    str_to_lower, str_to_title, str_to_upper, str_trim,
## scalar:    str_trunc, str_view, str_view_all, str_which, str_wrap,
## scalar:    substr, switch, tan, tanh, today, tolower, toupper,
## scalar:    trimws, wday, xor, yday, year
## aggregate: cume_dist, cummax, cummean, cummin, cumsum, dense_rank,
## aggregate: first, lag, last, lead, max, mean, median, min,
## aggregate: min_rank, n, n_distinct, nth, ntile, order_by,
## aggregate: percent_rank, quantile, rank, row_number, sum, var
## window:    cume_dist, cummax, cummean, cummin, cumsum, dense_rank,
## window:    first, lag, last, lead, max, mean, median, min,
## window:    min_rank, n, n_distinct, nth, ntile, order_by,
## window:    percent_rank, quantile, rank, row_number, sum, var
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
## # A tibble: 11 x 2
##    variant      n
##    <chr>    <int>
##  1 access     193
##  2 dbi        183
##  3 hive       156
##  4 impala     190
##  5 mssql      194
##  6 mysql      194
##  7 odbc       186
##  8 oracle     184
##  9 postgres   204
## 10 sqlite     134
## 11 teradata   196
```
Only one postgres translation produces an output:

```r
psql <- translations %>%
  filter(!is.na(sql), variant == "postgres") %>%
  select(r, n_args, sql) %>%
  arrange(r)

sp_print_df(head(psql, n = 40))
```

<!--html_preserve--><div id="htmlwidget-1d9f9b9fdca3023baa83" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-1d9f9b9fdca3023baa83">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40"],["-arg1","!arg1","!arg1","!arg1","!arg1","!NULL","(arg1)","{    arg1}","abs(arg1)","acos(arg1)","all(arg1, arg2)","all(arg1)","any(arg1, arg2)","any(arg1)","arg1 - arg2","arg1 != arg2","arg1 * arg2","arg1 &amp; arg2","arg1 &amp;&amp; arg2","arg1 %in% arg2","arg1 + arg2","arg1 &lt; arg2","arg1 &lt;= arg2","arg1 == arg2","arg1 &gt; arg2","arg1 &gt;= arg2","arg1 | arg2","arg1 || arg2","arg1[arg2]","arg1/arg2","arg1%%arg2","arg1^arg2","arg1$arg2","as_date(arg1)","as_datetime(arg1)","as.character(arg1)","as.Date(arg1)","as.double(arg1)","as.integer(arg1)","as.integer64(arg1)"],[1,1,2,3,50,0,1,1,1,1,2,1,2,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1],["-`arg1`","NOT(`arg1`)","NOT(`arg1`, `arg2`)","NOT(`arg1`, `arg2`, `arg3`)","NOT(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)","NOT()","(`arg1`)","(`arg1`)","ABS(`arg1`)","ACOS(`arg1`)","BOOL_AND(`arg1`) OVER ()","BOOL_AND(`arg1`) OVER ()","BOOL_OR(`arg1`) OVER ()","BOOL_OR(`arg1`) OVER ()","`arg1` - `arg2`","`arg1` != `arg2`","`arg1` * `arg2`","`arg1` AND `arg2`","`arg1` AND `arg2`","`arg1` IN `arg2`","`arg1` + `arg2`","`arg1` &lt; `arg2`","`arg1` &lt;= `arg2`","`arg1` = `arg2`","`arg1` &gt; `arg2`","`arg1` &gt;= `arg2`","`arg1` OR `arg2`","`arg1` OR `arg2`","CASE WHEN (`arg2`) THEN (`arg1`) END","`arg1` / `arg2`","`arg1` % `arg2`","POWER(`arg1`, `arg2`)","`arg1`.`arg2`","CAST(`arg1` AS DATE)","CAST(`arg1` AS TIMESTAMP)","CAST(`arg1` AS TEXT)","CAST(`arg1` AS DATE)","CAST(`arg1` AS NUMERIC)","CAST(`arg1` AS INTEGER)","CAST(`arg1` AS BIGINT)"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>r<\/th>\n      <th>n_args<\/th>\n      <th>sql<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

