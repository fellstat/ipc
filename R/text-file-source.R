objectToString <- function(obj){
  tf <- tempfile()
  on.exit(unlink(tf))
  saveRDS(obj, tf, ascii = TRUE)
  paste0(readLines(tf), collapse="\n")
}

stringToObject <- function(strg){
  on.exit(close(con))
  con <- textConnection(strg,"r")
  readRDS(con)
}

.TxTQ <- R6Class(
  ".TxTQ",
  inherit=txtq:::R6_txtq,
  public=list(
    maxRows= 100,
    pop = function(n = 1){
      private$txtq_exclusive({
        result <- private$txtq_pop(n = n)
        if(nrow(result) != 0){
          total <- private$txtq_get_total()
          if(total > self$maxRows){
            head <- private$txtq_get_head()
            if(head == total){
              file.create(private$db_file)
              private$txtq_set_head(0)
              private$txtq_set_total(0)
            }
          }
        }
        result
      })
    },
    mr = function(mrr){
      if(missing(mrr))
        return(self$maxRows)
      self$maxRows <- mrr
    }
  )
)

#' Reads and writes the queue to a text file
#'
#' A wrapper around \code{txtq}. This object saves signals
#' and associated objects to and queue, and retrieves them
#' for processing.
#'
#' @param filePath The path to the file
#' @param n The number of records to pop (-1 indicates all available).
#' @param msg A string indicating the signal.
#' @param obj The object to associate with the signal.
#' @format NULL
#' @usage NULL
#' @export
TextFileSource <- R6Class(
  "TextFileSource",
  private = list(
    file = NULL,

    q = NULL,

    destroyed = FALSE,

    isDestroyed = function(){
      private$destroyed || !file.exists(private$file)
    }
  ),
  public = list(

    initialize = function(filePath=tempFileGenerator()()){
      private$file <- filePath
      private$q <- .TxTQ$new(private$file)
    },

    pop = function(n=-1){
      if(private$isDestroyed())
        stop("Cannot pop from destroyed TextFileSource")
      l <- private$q$pop(n)
      result <- list()
      if(nrow(l) == 0)
        return(list())
      for(i in 1:nrow(l)){
        result[[i]] <- stringToObject(l[i,2])
        names(result)[i] <- l[i,1]
      }
      result
    },

    push = function(msg, obj){
      if(private$isDestroyed())
        stop("Cannot push to a destroyed TextFileSource")
      s <- objectToString(obj)
      private$q$push(msg, s)
    },

    destroy = function(){
      if(!private$destroyed){
        private$destroyed <- TRUE
        private$q$destroy()
      }
    }
  )
)


