#' A Class for sending tasks to a source
#' @export
Producer <- R6Class(
  "Producer",
  private = list(
    source = NULL
  ),
  public = list(

    initialize = function(source, ...){
      private$source <- source
    },

    fire = function(signal, obj=NA){
      private$source$push(signal, obj)
    }
  )
)

#' A Producer with methods specific for Shiny
#' @export
ShinyProducer <- R6Class(
  "ShinyProducer",
  inherit=Producer,
  public=list(
    fireInterrupt = function(obj="Interrupt"){
      self$fire("Interrupt", obj=obj)
    },

    fireNotify = function(obj="Notification"){
      self$fire("Notify", obj=obj)
    },

    fireEval = function(obj, env){
      obj <- substitute(obj)
      if(!missing(env))
        obj <- do.call('substitute', list(obj, env=env))
      self$fire("eval", obj=obj)
    },

    fireFunctor = function(funcName, param){
      self$fire("functor", obj=list(funcName, param))
    },

    fireAssignReactive = function(funcName, param){
      self$fire("functor", obj=list(funcName, param))
    }
  )
)
