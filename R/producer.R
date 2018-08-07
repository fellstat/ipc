#' A Class for sending signals to a source
#'
#'
#' \strong{Methods}
#'   \describe{
#'     \item{\code{initialize(source, ...)}}{
#'       Creates a Producer object linked to the \code{source}.
#'     }
#'     \item{\code{fire(signal, obj=NA)}}{
#'       Sends a signal to the source with associates object \code{obj}.
#'     }
#'     \item{\code{fireEval(expr, env)}}{
#'       Signals for execution of the expression \code{obj} with values from
#'       the environment (or list) \code{env} substituted in.
#'     }
#'     \item{\code{fireFunction(name, param)}}{
#'       Signals for execution of the function whose string value is \code{obj}
#'       with the parameters in list \code{param}.
#'     }
#'  }
#'
#'     @param obj The object to associate with the signal.
#'     @param signal A string signal to send.
#'     @param env An environment or list for substitution
#'     @param param A list of function parameters.
#'     @param expr An expression to evaluate.
#'     @param name the name of the fucntion
#' @format NULL
#' @usage NULL
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
    },

    fireEval = function(expr, env){
      obj <- substitute(expr)
      if(!missing(env))
        obj <- do.call('substitute', list(obj, env=env))
      self$fire("eval", obj=obj)
    },

    fireFunction = function(name, param){
      self$fire("function", obj=list(name, param))
    }
  )
)

#' A Producer with methods specific for Shiny
#'
#' A Producer object with additional methods for firing interrupts, shiny notifications,
#' and reactive value assignments.
#'
#' \strong{Methods}
#'   \describe{
#'     \item{\code{fireInterrupt(msg="Interrupt")}}{
#'       Sends an error with message \code{msg}.
#'     }
#'     \item{\code{fireNotify(msg="Interrupt")}}{
#'       Sends a signal to create a shiy Notifiction with message \code{msg}.
#'     }
#'     \item{\code{fireAssignReactive(name, value)}}{
#'       Signals for assignment for reactive \code{name}  to \code{value}.
#'     }
#'
#'     @param msg A string
#'     @param name The name of the reactive value.
#'     @param value The value to assign the reactive to.
#'  }
#' @format NULL
#' @usage NULL
#' @export
ShinyProducer <- R6Class(
  "ShinyProducer",
  inherit=Producer,
  public=list(
    fireInterrupt = function(msg="Interrupt"){
      self$fire("Interrupt", obj=msg)
    },

    fireNotify = function(msg="Notification"){
      self$fire("Notify", obj=msg)
    },

    fireAssignReactive = function(name, value){
      self$fire("function", obj=list(name, list(x=value)))
    }
  )
)
