objectToString <- function(obj){
  on.exit(function() close(con))
  con <- textConnection(NULL,"w")
  saveRDS(obj, con, ascii = TRUE)
  paste0(textConnectionValue(con), collapse="\n")
}

stringToObject <- function(strg){
  on.exit(function() close(con))
  #value <- NULL
  con <- textConnection(strg,"r")
  readRDS(con)
}

.TxTQ <- R6Class(
  ".TxTQ",
  inherit=txtq:::R6_txtq,
  public=list(
    maxRows= 1000,
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
#' @details
#' A thin wrapper around \code{txtq}
#' @export
TextFileSource <- R6Class(
  "TextFileSource",
  public = list(
    file = NULL,

    q = NULL,

    initialize = function(filePath=tempFileGenerator()(), ...){
      self$file <- filePath
      self$q <- .TxTQ$new(self$file)#txtq::txtq(self$file)
    },

    pop = function(n=-1){
      l <- self$q$pop(n)
      result <- list()
      if(nrow(l) == 0)
        return(list())
      for(i in 1:nrow(l)){
        v <- l[i,2]
        result[[l[i,1]]] <- stringToObject(l[i,2])
      }
      result
    },

    push = function(msg, obj){
      s <- objectToString(obj)
      self$q$push(msg, s)
    }
  )
)
