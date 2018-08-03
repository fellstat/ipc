.globals <- new.env(parent = emptyenv())

#' Get/set the location for temporary files
#' @param tempfile a function generating working file path (e.g. tempfile())
#' @export
tempFileGenerator <- function(tempfile){
  if(missing(tempfile))
    return(.globals$tempfile)
  .globals$tempfile <- tempfile
}

#' Get/set the class used to sink/read from the file system
#' @param sourceClass An R6 object
#' @export
defaultSource <- function(sourceClass){
  if(missing(sourceClass))
    return(.globals$defaultSource)
  .globals$defaultSource <- sourceClass
}

