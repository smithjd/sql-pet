Maintaing the Bookdown Site
================

## Introduction

The documentation for this project is hosted as a
[bookdown](https://bookdown.org/) site. The site lives on GitHub Pages
at <https://smithjd.github.io/sql-pet/>. Our process is collaborative
via GitHub.

## Setup

You will need RStudio. The recommended release is RStudio 1.2, currently
in late preview. Also, you will need to install the `bookdown` package.

## Editing

1.  If you don’t have this repository, clone it. If you do have it, do
    
        git checkout master
        git pull
    
    to get the latest updates.

2.  Open the RStudio project for the book. Note that this is a
    ***separate*** project file,
    `r-database-docker/r-database-docker.Rproj`.

3.  Create a branch for your edits. For example,
    
        git checkout -b add-chapter-seven
        git push --upstream origin add-chapter-seven

### Editing notes

  - All the R Markdown / knitr / pandoc tools should be working. If
    something doesn’t work for you, open an issue at
    <https://github.com/smithjd/sql-pet/issues/new/choose>. Assign it to
    the `Documentation` project so it will show up in my ToDo list.

  - File references, for example images you’re inserting from somewhere
    other than R code, are ***relative to the directory where the
    document resides***, For example, an R Markdown document file in the
    `r-database-docker` directory would reference an image in
    `r-database-docker/screenshots` as `screenshots/<file-name>`.

  - Use a code chunk like the following to insert an image:
    
        {r echo=FALSE, fig.align='center', out.width='90%'}
        knitr::include_graphics("screenshots/2018-08-26_15_16_51-Shared_Drives.png")
    
    The `out.width='90%'` sets the image width to 90% of the document
    width.

  - To view the document you’re working on, press the “Knit” button.

## Building the book

1.  Go to the “Build” tab. In the `More` dropdown, select `Clean All` to
    clear the target book directory.
2.  Rebuild the whole book by pressing `Build Book`. If it crashes, open
    an issue\!
3.  If it didn’t crash, the whole book should open up in your browser.
    You should be able to page through it.
4.  Rebuild the book for publishing. Open the file `build_book.R` and
    `Source` it.

## Publishing

Once you’ve got everything in the book the way you want it, there’s one
final step - updating the GitHub repository for your branch. In theory,
you can do this from the `Git` tab in RStudio, but that involves
checking a box for every file that’s changed, and there are probably
going to be many of them.

### Pushing the changes to GitHub

Go to the `Git` tab, and under the “gear” icon select `Shell`. This will
open a shell window in the project. To verify where you are, type

    git status

You will see what branch you’re on and the files that have changed. Type

    git add .
    git add ../docs
    git commit -m "What you did"
    git push

and your branch will be sent to GitHub.

### Opening a pull request

1.  Browse to the GitHub repository
    <https://github.com/smithjd/sql-pet>.
2.  In the `Branch` dropdown, select the branch you just pushed.
3.  Select the `Pull Request` button on the right and fill out the form.
