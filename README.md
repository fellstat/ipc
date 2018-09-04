# ipc

This package provides tools for inter-process communication. There is particular focus on supporting asynchronous evaluation in Shiny applications. Examples are provided showing how to perform useful tasks such as: updating reactive values from within future, progress bars for long running async tasks, and interrupting async tasks based on user input.

## Installation

To install the latest development version from the github repo run:
```
# If devtools is not installed:
# install.packages("devtools")

devtools::install_github("fellstat/ipc")
```

## Resources


* For a more detailed description of what can be done with the ``ipc`` package, **[see the introductory vignette](http://htmlpreview.github.io/?https://github.com/fellstat/ipc/blob/master/inst/doc/shinymp.html)**.

To run an example application locally use:
```
library(ipc)
shinyExample()
```
