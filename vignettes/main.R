library(knitr)
library(rmarkdown)
rmarkdown::render("vignette.Rmd")

fs <- list.files(pattern = ".Rmd$")
for (f in setdiff(fs, "Installation.Rmd")) { 
    print(f)
    rmarkdown::render(f, "md_document")
    knit(f) 
}
system("git add *.md")
system("git add figure/*")
system("git add *.Rmd")
system("git commit -a -m'markdown update'")
system("git push origin master")

