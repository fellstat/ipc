#' A Class containing a producer and consumer
#'
#' @format NULL
#' @usage NULL
#' @export
Queue <- R6Class(
  "Queue",
  private = list(

    source=NULL

  ),
  public = list(

    producer=NULL,

    consumer=NULL,

    initialize = function(source, prod, cons){
      private$source <- source
      self$producer <- prod
      self$consumer <- cons
    },

    destroy = function(){
      self$consumer$stop()
      private$source$destroy()
    }
  )
)

#' Create a Queue object
#' @description Creates a Queue object for inter-process communication.
#' Its members \code{producer} and \code{consumer} are the main entry points for
#' sending and receiving messages respectively.
#' @param source The source for reading and writing the queue
#' @param producer The producer for the source
#' @param consumer The consumer of the source
#' @aliases Queue
#' @details 
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
