#' A Class containing a producer and consumer
#'
#' @export
Queue <- R6Class(
  "Queue",
  private = list(

    source=NULL

  ),
  public = list(

    #' @field producer A Producer object
    producer=NULL,

    #' @field consumer a Consumer object.
    consumer=NULL,

    #' @description Create a Queue object
    #' @param source The source to use for communication.
    #' @param prod A Producer object.
    #' @param cons A Consumer object.
    initialize = function(source, prod, cons){
      private$source <- source
      self$producer <- prod
      self$consumer <- cons
    },

    #' @description clean up object after use.
    destroy = function(){
      self$consumer$stop()
      private$source$destroy()
    }
  )
)

#' Create a Queue object
#' @aliases Queue
#' @rdname Queue
#' @description Creates a Queue object for inter-process communication.
#' Its members \code{producer} and \code{consumer} are the main entry points for
#' sending and receiving messages respectively.
#' @param source The source for reading and writing the queue
#' @param producer The producer for the source
#' @param consumer The consumer of the source
#' @details
#' This function creates a queue object for communication between different R processes,
#' including forks of the same process.  By default, it uses \code{txtq} backage as its backend.
#' Technically, the information is sent through temporary files, created in a new directory
#' inside the session-specific temporary folder (see \code{\link{tempfile}}).
#' This requires that the new directory is writeable, this is normally the case but
#' if \code{\link{Sys.umask}} forbids writing, the communication fails with an error.
#' @examples
#' \dontrun{
#' library(parallel)
#' library(future)
#' library(promises)
#' plan(multisession)
#'
#' q <- queue()
#'
#' # communicate from main session to child
#' fut <- future({
#'   for(i in 1:1000){
#'     Sys.sleep(.1)
#'     q$consumer$consume()
#'   }
#' })
#'
#' q$producer$fireEval(stop("Stop that child"))
#' cat(try(value(fut)))
#'
#' # Communicate from child to main session
#' j <- 0
#' fut <- future({
#'   for(i in 1:10){
#'     Sys.sleep(.2)
#'
#'     # set j in the main thread substituting i into the expression
#'     q$producer$fireEval(j <- i, env=list(i=i))
#'   }
#' })
#'
#' while(j < 10){
#'  q$consumer$consume() # collect and execute assignments
#'  cat("j = ", j, "\n")
#'  Sys.sleep(.1)
#' }
#'
#' fut <- future({
#'   for(i in 1:10){
#'     Sys.sleep(.2)
#'
#'     # set j in the main thread substituting i into the expression
#'     q$producer$fireEval(print(i), env=list(i=i))
#'   }
#' })
#'
#' q$consumer$start() # execute `comsume` at regular intervals
#'
#' # clean up
#' q$destroy()
#'
#' }
#' @export
queue  <- function(source = defaultSource()$new(),
                        producer = Producer$new(source),
                        consumer = Consumer$new(source)){
  Queue$new(source, producer, consumer)
}


#' Create a Queue object
#' @param source The source for reading and writing the queue
#' @param producer The producer for the source
#' @param consumer The consumer of the source
#' @param session A Shiny session
#' @details
#' Creates a Queue object for use with shiny, backed by
#' ShinyTextSource, ShiyProducer and ShinyConsumer objects
#' by default. The object will be cleaned up and destroyed on
#' session end.
#' @export
shinyQueue  <- function(source = defaultSource()$new(),
                        producer = ShinyProducer$new(source),
                        consumer = ShinyConsumer$new(source),
                        session=shiny::getDefaultReactiveDomain()){
  q <- Queue$new(source, producer, consumer)
  if(!is.null(session))
    session$onEnded(q$destroy)
  q
}
