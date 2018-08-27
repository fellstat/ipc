.globals$tempfile <- tempfile

.globals$redisGenerator <- function(){
  paste0(as.character(runif(1)), as.character(runif(1)))
}

.globals$redisConfig <- list()

.globals$defaultSource <- TextFileSource
