#' A Class containing a producer and consumer
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
      private$source <- NULL
      self$producer <- NULL
      self$consumer <- NULL
    }
  )
)

#' Create a Queue object
#' @param source The source for reading and writing the queue
#' @param producer The producer for the source
#' @param consumer The consumer of the source
#' @export
shinyQueue  <- function(source = defaultSource()$new(),
                        producer = ShinyProducer$new(source),
                        consumer = ShinyConsumer$new(source)){
  Queue$new(source, producer, consumer)
}
