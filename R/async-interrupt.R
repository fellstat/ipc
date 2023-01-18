#' An interruptor useful for stopping child processes.
#'
#' This class is a simple wrapper around a Queue object
#' making adding interrupt checking to future code easy
#' to implement and read.
#'
#' \strong{Methods}
#'   \describe{
#'     \item{\code{initialize(queue=shinyQueue())}}{
#'       Creates a new interruptor.
#'     }
#'     \item{\code{interrupt(msg="Signaled Interrupt")}}{
#'       Signals an interrupt
#'     }
#'     \item{\code{execInterrupts()}}{
#'       Executes anything pushed to the queue, including interrupts.
#'     }
#'     \item{\code{getInterrupts()}}{
#'       Gets the result of the queue's executing, not throwing the interrupts.
#'     }
#'   }
#' @param queue a shiny queue
#' @param msg An error message string.
#'
#' @examples
#' library(future)
#' strategy <- "future::multisession"
#' plan(strategy)
#' inter <- AsyncInterruptor$new()
#' fut <- future({
#'   for(i in 1:100){
#'     Sys.sleep(.01)
#'     inter$execInterrupts()
#'   }
#' })
#' inter$interrupt("Error: Stop Future")
#' try(value(fut))
#' inter$destroy()
#'
#' # Clean up multisession cluster
#' plan(sequential)
#'
#' @format NULL
#' @usage NULL
#' @export
AsyncInterruptor <- R6Class(
  "AsyncInterruptor",
  private = list(
    queue=NULL
  ),
  public = list(
    #' @description Create the object
    #' @param queue The underlying queue object to use for interruption
    initialize = function(queue=shinyQueue()){
      private$queue <- queue
    },

    #' @description signal an error
    #' @param msg The error message
    interrupt = function(msg="Signaled Interrupt"){
      private$queue$producer$fireInterrupt(msg)
    },

    #' @description Execute any interruptions that have been signaled
    execInterrupts = function(){
      private$queue$consumer$consume()
    },

    #' @description Get any interruptions that have been signaled without throwing them as errors
    getInterrupts = function(){
      private$queue$consumer$consume(throwErrors=FALSE)
    },

    #' @description Cleans up object after use
    destroy = function(){
      private$queue$destroy()
    }
  )
)


#' Stops a future run in a multicore plan
#'
#' @param x The MulticoreFuture
#'
#' @details
#' This function sends terminate and kill signals to the process running the future,
#' and will only work for futures run on a multicore plan. This approach is not
#' recommended for cases where you can listen for interrupts within the future
#' (with \code{AsyncInterruptor}). However, for cases where long running code is
#' in an external library for which you don't have control, this can be the only way
#' to terminate the execution.
#'
#' Note that multicore is not supported on Windows machines or within RStudio.
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
