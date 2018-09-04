#! /usr/bin/env Rscript

# clear the directory
unlink("../docs", recursive = TRUE)

# make the web book
bookdown::render_book(
  input = "index.Rmd",
  output_format = "bookdown::gitbook",
  output_dir = "../docs"
)

# PDF and epub
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

# flag this as a non-Jekyll site for GitHub Pages
file.create("../docs/.nojekyll")
