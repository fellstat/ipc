
#' A progress bar object where inc and set are usable within other processes
#' @export
AsyncProgress <- R6Class(
  "AsyncProgress",
  private = list(
    queue=NULL,
    progress=NULL
  ),
  public = list(
    initialize = function(..., queue=shinyQueue(), millis=250, value=NULL, message=NULL, detail=NULL){
      private$queue <- queue
      private$progress <- Progress$new(...)
      if(!(is.null(value) && is.null(message) && is.null(detail)))
        private$progress$set(value=value, message=message, detail=detail)
      private$queue$consumer$start(millis)
    },

    getMax = function() private$progress$getMax(),

    getMin = function() private$progress$getMin(),

    close = function(){
      private$queue$destroy()
      private$progress$close()
      private$queue <- NULL
      private$progress <- NULL
    },

    set = function(value = NULL, message = NULL, detail = NULL){
      args <- list(value = value, message = message, detail = detail)
      private$queue$producer$fireEval({
        do.call(private$progress$set, args)
      }, list(args=args))
    },

    inc = function(amount = 0.1, message = NULL, detail = NULL){
      args <- list(amount = amount, message = message, detail = detail)
      private$queue$producer$fireEval({
        do.call(private$progress$inc, args)
      }, list(args=args))
    }
  )
)
