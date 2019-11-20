# Appendix _ Dplyr to SQL translations {#chapter_appendix-dplyr-to-postres-translation}

> You may be interested in exactly how the DBI package translates R functions into their SQL quivalents -- and in which functions are translated and which are not.  
This Appendix answers those questions.  It is based on the work of Dewey Dunnington ([\@paleolimbot](http://twitter.com/paleolimbot)) which he published here: 
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

```
## Warning: The `.drop` argument of `unnest()` is deprecated as of tidyr 1.0.0.
## All list-columns are now preserved.
## This warning is displayed once per session.
## Call `lifecycle::last_warnings()` to see where this warning was generated.
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
##  3 hive       187
##  4 impala     190
##  5 mssql      196
##  6 mysql      194
##  7 odbc       186
##  8 oracle     184
##  9 postgres   204
## 10 sqlite     183
## 11 teradata   196
```
Only one postgres translation produces an output:

```r
psql <- translations %>%
  filter(!is.na(sql), variant == "postgres") %>%
  select(r, n_args, sql) %>%
  arrange(r)

# sp_print_df(head(psql, n = 40))
sp_print_df(psql)
```

<!--html_preserve--><div id="htmlwidget-5054982f87516f94d57c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5054982f87516f94d57c">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200","201","202","203","204"],["-arg1","!arg1","!arg1","!arg1","!arg1","!NULL","(arg1)","{    arg1}","abs(arg1)","acos(arg1)","all(arg1, arg2)","all(arg1)","any(arg1, arg2)","any(arg1)","arg1 - arg2","arg1 != arg2","arg1 * arg2","arg1 &amp; arg2","arg1 &amp;&amp; arg2","arg1 %in% arg2","arg1 + arg2","arg1 &lt; arg2","arg1 &lt;= arg2","arg1 == arg2","arg1 &gt; arg2","arg1 &gt;= arg2","arg1 | arg2","arg1 || arg2","arg1[arg2]","arg1/arg2","arg1%%arg2","arg1^arg2","arg1$arg2","as_date(arg1)","as_datetime(arg1)","as.character(arg1)","as.Date(arg1)","as.double(arg1)","as.integer(arg1)","as.integer64(arg1)","as.logical(arg1)","as.numeric(arg1)","as.POSIXct(arg1)","asin(arg1)","atan(arg1)","atan2(arg1, arg2)","between(arg1, arg2, arg3)","bitwAnd(arg1, arg2)","bitwNot(arg1)","bitwOr(arg1, arg2)","bitwShiftL(arg1, arg2)","bitwShiftR(arg1, arg2)","bitwXor(arg1, arg2)","c()","c(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)","c(arg1, arg2, arg3)","c(arg1, arg2)","c(arg1)","ceil(arg1)","ceiling(arg1)","coalesce()","coalesce(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9,     arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18,     arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27,     arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36,     arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45,     arg46, arg47, arg48, arg49, arg50)","coalesce(arg1, arg2, arg3)","coalesce(arg1, arg2)","coalesce(arg1)","cor(arg1, arg2)","cos(arg1)","cosh(arg1)","cot(arg1)","coth(arg1)","cov(arg1, arg2)","cume_dist()","cume_dist(arg1)","cummax(arg1, arg2)","cummax(arg1)","cummean(arg1, arg2)","cummean(arg1)","cummin(arg1, arg2)","cummin(arg1)","cumsum(arg1, arg2)","cumsum(arg1)","day(arg1)","dense_rank()","dense_rank(arg1)","desc(arg1)","exp(arg1)","first(arg1, arg2)","first(arg1)","floor(arg1)","grepl(arg1, arg2)","hour(arg1)","if (arg1) arg2","if (arg1) arg2 else arg3","if_else(arg1, arg2, arg3)","ifelse(arg1, arg2, arg3)","is.na(arg1)","is.null(arg1)","lag(arg1, arg2, arg3)","lag(arg1, arg2)","lag(arg1)","last(arg1, arg2)","last(arg1)","lead(arg1, arg2, arg3)","lead(arg1, arg2)","lead(arg1)","log(arg1, arg2)","log(arg1)","log10(arg1)","max(arg1, arg2)","max(arg1)","mday(arg1)","mean(arg1, arg2)","mean(arg1)","median(arg1)","min_rank()","min_rank(arg1)","min(arg1, arg2)","min(arg1)","minute(arg1)","month(arg1)","n_distinct(arg1)","n()","na_if(arg1, arg2)","nchar(arg1)","now()","nth(arg1, arg2, arg3)","nth(arg1, arg2)","ntile(arg1, arg2)","order_by(arg1, arg2)","paste()","paste(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)","paste(arg1, arg2, arg3)","paste(arg1, arg2)","paste(arg1)","paste0()","paste0(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9,     arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18,     arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27,     arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36,     arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45,     arg46, arg47, arg48, arg49, arg50)","paste0(arg1, arg2, arg3)","paste0(arg1, arg2)","paste0(arg1)","percent_rank()","percent_rank(arg1)","pmax()","pmax(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)","pmax(arg1, arg2, arg3)","pmax(arg1, arg2)","pmax(arg1)","pmin()","pmin(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)","pmin(arg1, arg2, arg3)","pmin(arg1, arg2)","pmin(arg1)","quarter(arg1)","rank()","rank(arg1)","round(arg1, arg2)","round(arg1)","row_number()","row_number(arg1)","sd(arg1, arg2)","sd(arg1)","second(arg1)","sign(arg1)","sin(arg1)","sinh(arg1)","sql(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)","sql(arg1, arg2, arg3)","sql(arg1, arg2)","sql(arg1)","sqrt(arg1)","str_c()","str_c(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,     arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,     arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28,     arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37,     arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46,     arg47, arg48, arg49, arg50)","str_c(arg1, arg2, arg3)","str_c(arg1, arg2)","str_c(arg1)","str_detect(arg1, arg2)","str_flatten(arg1, arg2)","str_length(arg1)","str_locate(arg1, arg2)","str_replace_all(arg1, arg2, arg3)","str_sub(arg1, arg2)","str_sub(arg1)","str_to_lower(arg1)","str_to_title(arg1)","str_to_upper(arg1)","str_trim(arg1)","substr(arg1, arg2, arg3)","sum(arg1, arg2)","sum(arg1)","switch(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9,     arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18,     arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27,     arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36,     arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45,     arg46, arg47, arg48, arg49, arg50)","switch(arg1, arg2, arg3)","switch(arg1, arg2)","switch(arg1)","tan(arg1)","tanh(arg1)","today()","tolower(arg1)","toupper(arg1)","trimws(arg1)","var(arg1, arg2)","var(arg1)","wday(arg1)","xor(arg1, arg2)","yday(arg1)","year(arg1)"],[1,1,2,3,50,0,1,1,1,1,2,1,2,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,2,3,2,1,2,2,2,2,0,50,3,2,1,1,1,0,50,3,2,1,2,1,1,1,1,2,0,1,2,1,2,1,2,1,2,1,1,0,1,1,1,2,1,1,2,1,2,3,3,3,1,1,3,2,1,2,1,3,2,1,2,1,1,2,1,1,2,1,1,0,1,2,1,1,1,1,0,2,1,0,3,2,2,2,0,50,3,2,1,0,50,3,2,1,0,1,0,50,3,2,1,0,50,3,2,1,1,0,1,2,1,0,1,2,1,1,1,1,1,50,3,2,1,1,0,50,3,2,1,2,2,1,2,3,2,1,1,1,1,1,3,2,1,50,3,2,1,1,1,0,1,1,1,2,1,1,2,1,1],["-`arg1`","NOT(`arg1`)","NOT(`arg1`, `arg2`)","NOT(`arg1`, `arg2`, `arg3`)","NOT(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)","NOT()","(`arg1`)","(`arg1`)","ABS(`arg1`)","ACOS(`arg1`)","BOOL_AND(`arg1`) OVER ()","BOOL_AND(`arg1`) OVER ()","BOOL_OR(`arg1`) OVER ()","BOOL_OR(`arg1`) OVER ()","`arg1` - `arg2`","`arg1` != `arg2`","`arg1` * `arg2`","`arg1` AND `arg2`","`arg1` AND `arg2`","`arg1` IN `arg2`","`arg1` + `arg2`","`arg1` &lt; `arg2`","`arg1` &lt;= `arg2`","`arg1` = `arg2`","`arg1` &gt; `arg2`","`arg1` &gt;= `arg2`","`arg1` OR `arg2`","`arg1` OR `arg2`","CASE WHEN (`arg2`) THEN (`arg1`) END","`arg1` / `arg2`","`arg1` % `arg2`","POWER(`arg1`, `arg2`)","`arg1`.`arg2`","CAST(`arg1` AS DATE)","CAST(`arg1` AS TIMESTAMP)","CAST(`arg1` AS TEXT)","CAST(`arg1` AS DATE)","CAST(`arg1` AS NUMERIC)","CAST(`arg1` AS INTEGER)","CAST(`arg1` AS BIGINT)","CAST(`arg1` AS BOOLEAN)","CAST(`arg1` AS NUMERIC)","CAST(`arg1` AS TIMESTAMP)","ASIN(`arg1`)","ATAN(`arg1`)","ATAN2(`arg1`, `arg2`)","`arg1` BETWEEN `arg2` AND `arg3`","`arg1` &amp; `arg2`","~(`arg1`)","`arg1` | `arg2`","`arg1` &lt;&lt; `arg2`","`arg1` &gt;&gt; `arg2`","`arg1` # `arg2`","NULL","`arg1`","`arg1`","`arg1`","`arg1`","CEIL(`arg1`)","CEIL(`arg1`)","COALESCE()","COALESCE(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)","COALESCE(`arg1`, `arg2`, `arg3`)","COALESCE(`arg1`, `arg2`)","COALESCE(`arg1`)","CORR(`arg1`, `arg2`) OVER ()","COS(`arg1`)","(EXP(`arg1`) + EXP(-(`arg1`))) / 2","1 / TAN(`arg1`)","(EXP(2 * (`arg1`)) + 1) / (EXP(2 * (`arg1`)) - 1)","COVAR_SAMP(`arg1`, `arg2`) OVER ()","CUME_DIST() OVER ()","CUME_DIST() OVER (ORDER BY `arg1`)","MAX(`arg1`) OVER (ORDER BY `arg2` ROWS UNBOUNDED PRECEDING)","MAX(`arg1`) OVER (ROWS UNBOUNDED PRECEDING)","AVG(`arg1`) OVER (ORDER BY `arg2` ROWS UNBOUNDED PRECEDING)","AVG(`arg1`) OVER (ROWS UNBOUNDED PRECEDING)","MIN(`arg1`) OVER (ORDER BY `arg2` ROWS UNBOUNDED PRECEDING)","MIN(`arg1`) OVER (ROWS UNBOUNDED PRECEDING)","SUM(`arg1`) OVER (ORDER BY `arg2` ROWS UNBOUNDED PRECEDING)","SUM(`arg1`) OVER (ROWS UNBOUNDED PRECEDING)","EXTRACT(day FROM `arg1`)","DENSE_RANK() OVER ()","DENSE_RANK() OVER (ORDER BY `arg1`)","`arg1` DESC","EXP(`arg1`)","FIRST_VALUE(`arg1`) OVER (ORDER BY `arg2`)","FIRST_VALUE(`arg1`) OVER ()","FLOOR(`arg1`)","(`arg2`) ~ (`arg1`)","EXTRACT(hour FROM `arg1`)","CASE WHEN (`arg1`) THEN (`arg2`) END","CASE WHEN (`arg1`) THEN (`arg2`) WHEN NOT(`arg1`) THEN (`arg3`) END","CASE WHEN (`arg1`) THEN (`arg2`) WHEN NOT(`arg1`) THEN (`arg3`) END","CASE WHEN (`arg1`) THEN (`arg2`) WHEN NOT(`arg1`) THEN (`arg3`) END","((`arg1`) IS NULL)","((`arg1`) IS NULL)","LAG(`arg1`, NULL, `arg3`) OVER ()","LAG(`arg1`, NULL, NULL) OVER ()","LAG(`arg1`, 1, NULL) OVER ()","LAST_VALUE(`arg1`) OVER (ORDER BY `arg2`)","LAST_VALUE(`arg1`) OVER ()","LEAD(`arg1`, `arg2`, `arg3`) OVER ()","LEAD(`arg1`, `arg2`, NULL) OVER ()","LEAD(`arg1`, 1, NULL) OVER ()","LOG(`arg1`) / LOG(`arg2`)","LN(`arg1`)","LOG(`arg1`)","MAX(`arg1`) OVER ()","MAX(`arg1`) OVER ()","EXTRACT(day FROM `arg1`)","AVG(`arg1`) OVER ()","AVG(`arg1`) OVER ()","PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY `arg1`) OVER ()","RANK() OVER ()","RANK() OVER (ORDER BY `arg1`)","MIN(`arg1`) OVER ()","MIN(`arg1`) OVER ()","EXTRACT(minute FROM `arg1`)","EXTRACT(MONTH FROM `arg1`)","COUNT(DISTINCT `arg1`) OVER ()","COUNT(*) OVER ()","NULLIF(`arg1`, `arg2`)","LENGTH(`arg1`)","CURRENT_TIMESTAMP","NTH_VALUE(`arg1`, NULL) OVER (ORDER BY `arg3`)","NTH_VALUE(`arg1`, NULL) OVER ()","NTILE(NULL) OVER (ORDER BY `arg1`)","`arg2`","CONCAT_WS(' ')","CONCAT_WS(' ', `arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)","CONCAT_WS(' ', `arg1`, `arg2`, `arg3`)","CONCAT_WS(' ', `arg1`, `arg2`)","CONCAT_WS(' ', `arg1`)","CONCAT_WS('')","CONCAT_WS('', `arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)","CONCAT_WS('', `arg1`, `arg2`, `arg3`)","CONCAT_WS('', `arg1`, `arg2`)","CONCAT_WS('', `arg1`)","PERCENT_RANK() OVER ()","PERCENT_RANK() OVER (ORDER BY `arg1`)","GREATEST()","GREATEST(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)","GREATEST(`arg1`, `arg2`, `arg3`)","GREATEST(`arg1`, `arg2`)","GREATEST(`arg1`)","LEAST()","LEAST(`arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)","LEAST(`arg1`, `arg2`, `arg3`)","LEAST(`arg1`, `arg2`)","LEAST(`arg1`)","EXTRACT(QUARTER FROM `arg1`)","RANK() OVER ()","RANK() OVER (ORDER BY `arg1`)","ROUND((`arg1`) :: numeric, NULL)","ROUND((`arg1`) :: numeric, 0)","ROW_NUMBER() OVER ()","ROW_NUMBER() OVER (ORDER BY `arg1`)","STDDEV_SAMP(`arg1`) OVER ()","STDDEV_SAMP(`arg1`) OVER ()","EXTRACT(second FROM `arg1`)","SIGN(`arg1`)","SIN(`arg1`)","(EXP(`arg1`) - EXP(-(`arg1`))) / 2","`arg1`","`arg1`","`arg1`","`arg1`","SQRT(`arg1`)","CONCAT_WS('')","CONCAT_WS('', `arg1`, `arg2`, `arg3`, `arg4`, `arg5`, `arg6`, `arg7`, `arg8`, `arg9`, `arg10`, `arg11`, `arg12`, `arg13`, `arg14`, `arg15`, `arg16`, `arg17`, `arg18`, `arg19`, `arg20`, `arg21`, `arg22`, `arg23`, `arg24`, `arg25`, `arg26`, `arg27`, `arg28`, `arg29`, `arg30`, `arg31`, `arg32`, `arg33`, `arg34`, `arg35`, `arg36`, `arg37`, `arg38`, `arg39`, `arg40`, `arg41`, `arg42`, `arg43`, `arg44`, `arg45`, `arg46`, `arg47`, `arg48`, `arg49`, `arg50`)","CONCAT_WS('', `arg1`, `arg2`, `arg3`)","CONCAT_WS('', `arg1`, `arg2`)","CONCAT_WS('', `arg1`)","STRPOS(`arg1`, `arg2`) &gt; 0","STRING_AGG(`arg1`, `arg2`) OVER ()","LENGTH(`arg1`)","STRPOS(`arg1`, `arg2`)","REGEXP_REPLACE(`arg1`, `arg2`, `arg3`)","SUBSTR(`arg1`, NULL)","SUBSTR(`arg1`, 1)","LOWER(`arg1`)","INITCAP(`arg1`)","UPPER(`arg1`)","LTRIM(RTRIM(`arg1`))","SUBSTR(`arg1`, NULL, NULL)","SUM(`arg1`) OVER ()","SUM(`arg1`) OVER ()","CASE `arg1` END","CASE `arg1` END","CASE `arg1` END","CASE `arg1` END","TAN(`arg1`)","(EXP(2 * (`arg1`)) - 1) / (EXP(2 * (`arg1`)) + 1)","CURRENT_DATE","LOWER(`arg1`)","UPPER(`arg1`)","LTRIM(RTRIM(`arg1`))","VAR_SAMP(`arg1`) OVER ()","VAR_SAMP(`arg1`) OVER ()","EXTRACT('dow' FROM DATE(`arg1`) + 0) + 1.0","`arg1` OR `arg2` AND NOT (`arg1` AND `arg2`)","EXTRACT(DOY FROM `arg1`)","EXTRACT(year FROM `arg1`)"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>r<\/th>\n      <th>n_args<\/th>\n      <th>sql<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

