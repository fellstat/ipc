#' An interruptor useful for stopping child processes
#' @export
AsyncInterruptor <- R6Class(
  "AsyncInterruptor",
  private = list(
    queue=NULL
  ),
  public = list(
    initialize = function(queue=shinyQueue()){
      private$queue <- queue
    },

    interrupt = function(msg="Signaled Interrupt"){
      private$queue$producer$fireInterrupt(msg)
    },

    execInterrupts = function(){
      private$queue$consumer$consume()
    },

    getInterrupts = function(){
      private$queue$consumer$consume(safe=TRUE)
    }
  )
)


#' Stops a future run in a multicore plan
#' @param x The MulticoreFuture
#' @export
stopMulticoreFuture <- function(x){
  if(!inherits(x,"MulticoreFuture")){
    stop("stopMulticoreFuture only works on multicore futures")
  }
  if(x$state == "finished")
    return(FALSE)
  tools::pskill(x$job$pid,signal = tools::SIGTERM)
  tools::pskill(x$job$pid,signal = tools::SIGKILL)
  TRUE
}
