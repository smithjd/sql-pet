# This code is copied from:
#   https://apps.fishandwhistle.net/archives/1503

library(tidyverse)
library(dbplyr)

translate_sql_(
  list(call("%in%", quote(arg1), quote(arg2))),
  con = simulate_dbi()
)
test_call <- function(fun_name, n_args = 1) {
  args <- map(seq_len(n_args), ~ sym(paste0("arg", .x))) %>%
    map(enquote)
  do.call(call, c(list(fun_name), args))
}

test_translate <- function(call, con = simulate_dbi()) {
  translate_sql_(
    list(call),
    con = con
  )
}

sql_variants <- tibble(
  variant = getNamespace("dbplyr") %>%
    names() %>%
    str_subset("^simulate_") %>%
    str_remove("^simulate_"),
  test_connection = map(
    variant,
    ~ getNamespace("dbplyr")[[paste0("simulate_", .x)]]()
  ),
  fun_name = map(test_connection, ~ unique(names(sql_translate_env(.x)))),
)
translations <- crossing(
  tibble(
    n_args = c(0:3, 50)
  ),
  sql_variants
) %>%
  unnest(fun_name, .drop = FALSE) %>%
  mutate(
    call = map2(fun_name, n_args, test_call),
    translation = map2(
      call, test_connection,
      quietly(safely(test_translate))
    ),
    r = map_chr(call, ~ paste(format(.x), collapse = "")),
    sql = map_chr(translation, ~ first(as.character(.x$result$result))),
    messages = map_chr(translation, ~ paste(.x$messages, collapse = "; ") %>% na_if("")),
    warnings = map_chr(translation, ~ paste(.x$warnings, collapse = "; ") %>% na_if("")),
    errors = map_chr(translation, ~ first(as.character(.x$result$error)))
  )

translations %>%
  filter(!is.na(sql), n_args == 1) %>%
  select(variant, n_args, r, sql)
