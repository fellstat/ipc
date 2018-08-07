# ShinyAsyncTools

This package provides tools that let you update a shiny UI from within a child process (e.g. future). Examples are procided showing how to perform useful tasks such as: updating reactive values from within future, progress bars for long running async tasks, and inturrupting async tasks based on user input.

## Installation

To install the latest development version from the github repo run:
```
# If devtools is not installed:
# install.packages("devtools")

devtools::install_github("fellstat/ShinyAsyncTools")
```

## Resources


* For a more detailed description of what can be done with the ``ShinyAsyncTools`` package, **[see the introductory vignette](inst/doc/shinymp.html)**.

To run an example application locally use:
```
library(ShinyAsyncTools)
shinyExample()
```
