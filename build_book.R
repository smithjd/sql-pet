#! /usr/bin/env Rscript

# Adding `new_session = TRUE` according to
#   https://bookdown.org/yihui/bookdown/new-session.html
# so that we can run docker and other code within the book in separate chapters, separately.
# JDS: let's try this and see if it is too cumbersome

# clear the directory
bookdown::clean_book(TRUE)

# PDF
bookdown::render_book(
  input = "index.Rmd",
  new_session = TRUE,
  output_format = "bookdown::pdf_book",
  output_dir = "docs"
)

# "GitBook" website

bookdown::render_book(
  input = "index.Rmd",
  new_session = TRUE,
  output_format = "bookdown::gitbook",
  output_dir = "docs"
)

# flag this as a non-Jekyll site for GitHub Pages
file.create("docs/.nojekyll")
