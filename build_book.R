#! /usr/bin/env Rscript

# clear the directory
bookdown::clean_book(TRUE)

# "GitBook" website

bookdown::render_book(
  input = "index.Rmd",
  new_session = TRUE,
  output_format = "bookdown::gitbook",
  output_dir = "docs"
)

# flag this as a non-Jekyll site for GitHub Pages
file.create("docs/.nojekyll")
