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
    }
  )
)


shinyQueue  <- function(source = defaultSource()$new(),
                        producer = ShinyProducer$new(source),
                        consumer = ShinyConsumer$new(source, envir),
                        envir = parent.frame()){
  Queue$new(source, producer, consumer)
}
