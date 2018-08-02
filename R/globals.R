.globals <- new.env(parent = emptyenv())

tempFileGenerator <- function(tempfile){
  if(missing(tempfile))
    return(.globals$tempfile)
  .globals$tempfile <- tempfile
}

defaultSource <- function(sourceClass){
  if(missing(sourceClass))
    return(.globals$defaultSource)
  .globals$defaultSource <- sourceClass
}

