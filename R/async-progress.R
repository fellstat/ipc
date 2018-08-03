
#' A progress bar object where inc and set are usable within other processes
#' @export
AsyncProgress <- R6Class(
  "AsyncProgress",
  private = list(
    queue=NULL,
    progress=NULL
  ),
  public = list(
    initialize = function(..., millis=400){
      private$queue <- shinyQueue()
      private$progress <- Progress$new(...)
      private$queue$consumer$start()
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
