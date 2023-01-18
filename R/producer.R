#' A Class for sending signals to a source
#'
#'
#' @export
Producer <- R6Class(
  "Producer",
  private = list(
    source = NULL
  ),
  public = list(

    #' @description Creates a Producer object linked to the \code{source}.
    #' @param source A source.
    initialize = function(source){
      private$source <- source
    },

    #' @description Setter for source.
    #' @param source A source.
    setSource = function(source){
      private$source <- source
    },

    #' @description Getter for source.
    getSource = function(){
      private$source
    },

    #' @description Sends a signal to the source with associates object \code{obj}.
    #' @param signal A string signal to send.
    #' @param obj The object to associate with the signal.
    fire = function(signal, obj=NA){
      private$source$push(signal, obj)
    },

    #' @description Signals for execution of the expression \code{obj} with values from
    #'       the environment (or list) \code{env} substituted in.
    #' @param expr An expression to evaluate.
    #' @param env An environment or list for substitution
    fireEval = function(expr, env){
      obj <- substitute(expr)
      if(!missing(env))
        obj <- do.call('substitute', list(as.call(obj), env=env))
      self$fire("eval", obj=obj)
    },

    #' @description  Signals for execution of the function whose string value is \code{name}
    #'       with the parameters in list \code{param}.
    #' @param name the name of the function
    #' @param param A list of function parameters.
    fireDoCall = function(name, param){
      self$fire("doCall", obj=list(name, param))
    },

    #' @description Signals for execution of the function whose string value is \code{name}
    #'       with the parameters \code{...}.
    #' @param name the name of the function
    #' @param ... The arguments to the function.
    fireCall = function(name, ...){
      self$fireDoCall(name, list(...))
    }
  )
)

#' A Producer with methods specific for Shiny
#'
#' A Producer object with additional methods for firing interrupts, shiny notifications,
#' and reactive value assignments.
#'
#' @export
ShinyProducer <- R6Class(
  "ShinyProducer",
  inherit=Producer,
  public=list(

    #' @description  Sends an error with message \code{msg}.
    #' @param msg A string
    fireInterrupt = function(msg="Interrupt"){
      self$fire("Interrupt", obj=msg)
    },

    #' @description Sends a signal to create a shiny Notification with message \code{msg}.
    #' @param msg A string
    fireNotify = function(msg="Notification"){
      self$fire("Notify", obj=msg)
    },

    #' @description Signals for assignment for reactive \code{name}  to \code{value}.
    #' @param name The name of the reactive value.
    #' @param value The value to assign the reactive to.
    fireAssignReactive = function(name, value){
      self$fire("doCall", obj=list(name, list(x=value)))
    }
  )
)
