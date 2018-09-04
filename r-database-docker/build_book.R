#! /usr/bin/env Rscript

unlink("../docs", recursive = TRUE)
bookdown::render_book(
  input = "index.Rmd",
  output_format = "bookdown::gitbook",
  output_dir = "../docs"
)
bookdown::render_book(
  input = "index.Rmd",
  output_format = "bookdown::pdf_book",
  output_dir = "../docs"
)
bookdown::render_book(
  input = "index.Rmd",
  output_format = "bookdown::epub_book",
  output_dir = "../docs"
)
file.create("../docs/.nojekyll")
