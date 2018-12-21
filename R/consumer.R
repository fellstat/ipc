#' A Class for reading and executing tasks from a source
#'
#' \strong{Methods}
#'   \describe{
#'     \item{\code{initialize(source, env=parent.frame(2))}}{
#'       Creates a Consumer object linked to the \code{source}.
#'     }
#'     \item{\code{setSource(source)}}{
#'       Sets the \code{Source} for this consumer.
#'     }
#'     \item{\code{getSource(source)}}{
#'       Gets the \code{Source} of this consumer.
#'     }
#'     \item{\code{consume(throwErrors=TRUE, env=parent.frame())}}{
#'       Executes all (unprocessed) signals fired to source from a Producer.
#'       if \code{throwErrors} is TRUE, the first error encountered is thrown
#'       after executing all signals. Signals are executed in the \code{env} environment.
#'       If \code{env} is NULL, the enviroment set at initialization is used.
#'     }
#'     \item{\code{start(millis=250, throwErrors=TRUE, env=parent.frame())}}{
#'       Starts executing \code{consume} every \code{millis} milliseconds. \code{throwErrors}
#'       and \code{env} are passed down to \code{consume}
#'     }
#'     \item{\code{stop()}}{
#'       Stops the periodic execution of \code{consume}.
#'     }
#'     \item{\code{clearHandlers()}}{
#'       Removes all handlers
#'     }
#'     \item{\code{removeHandler(signal, index)}}{
#'       Removes handler from 'signal' with position index
#'     }
#'     \item{\code{addHandler(func, signal)}}{
#'       Adds a handler for 'signal'. func should take three parameters: 1. the signal, 2. the message object, and 3. the evaluation environment.
#'     }
#'     \item{\code{initHandlers()}}{
#'       Adds the two default executeors.
#'     }
#'     \item{\code{finalize()}}{
#'       runs stop on object distruction
#'     }
#'   }
#'
#' @param source a source, e.g. TextFileSource.
#' @param millis milliseconds.
#' @param env An enviroment specifying where to execute signals.
#' @param signal A string.
#' @param index A position.
#'
#' @format NULL
#' @usage NULL
#' @export
Consumer <- R6Class(
  "Consumer",
  private = list(
    source=NULL,

    addEvalHandler = function(){
      func <- function(signal, obj, env){
        eval(obj, envir = env)
      }
      self$addHandler(func, "eval")
    },

    addfunctionHandler = function(){
      func <- function(signal, obj, env){
        f <- get(obj[[1]], envir = env)
        do.call(f, obj[[2]], envir = env)
      }
      self$addHandler(func, "doCall")
    }
  ),
  public=list(
    handlers = list(),

    stopped = FALSE,

    laterHandle = NULL,

    initialize = function(source){
      private$source <- source
      self$initHandlers()
    },

    setSource = function(source){
      private$source <- source
    },

    getSource = function(){
      private$source
    },

    consume = function(throwErrors=TRUE, env=parent.frame()){
      contents <- private$source$pop()
      if(length(contents) == 0)
        return(list())
      signals <- names(contents)
      result <- list()
      for(i in 1:length(signals)){
        result[[i]] <- list()
        exec <- self$handlers[[signals[i]]]
        if(!is.null(exec)){
          for(j in 1:length(exec)){
            func <- exec[[j]]
            result[[i]][[j]] <- try(func(signals[i], contents[[i]], env))
          }
        }else
          warning(paste("No handler for signal", signals[i]))
      }
      for(a in result){
        for(r in a){
          if(inherits(r,"try-error")){
            if(throwErrors)
              stop(attr(r,"condition"))
            else
              warning(attr(r,"condition"))
          }
        }
      }
      names(result) <- signals
      result
    },

    start = function(millis=250, env=parent.frame()){
      self$stopped <- FALSE

      # Needed otherwise env changes every callback
      envir <- env

      callback <- function(){
        if (self$stopped) return()
        on.exit(self$laterHandle <- later::later(callback, millis / 1000))
        tryCatch({
          result <- self$consume(throwErrors=FALSE, env=envir)
          if(!is.null(result)){
            for( i in seq_along(result)){
              for(j in seq_along(result[[i]])){
                if(inherits(result[[i]][[j]], "try-error")){
                  stop(result[[i]][[j]]$message)
                }
              }
            }
          }
        })

      }
      callback()
    },

    stop = function(){
      self$stopped <- TRUE
      if(!is.null(self$laterHandle))
        self$laterHandle()
      self$laterHandle <- NULL
    },

    addHandler = function(func, signal){
      if(is.null(self$handlers[[signal]]))
        self$handlers[[signal]] <- list()
      index <- length(self$handlers[[signal]]) + 1
      self$handlers[[signal]][[index]] <- func
      index
    },

    clearHandlers = function(){
      self$handlers <- list()
    },

    removeHandler = function(signal, index){
      self$handlers[[signal]][[index]] <- NULL
    },


    initHandlers = function(){
      private$addfunctionHandler()
      private$addEvalHandler()
    },

    finalize = function() {
      self$stop()
    }
  )
)

#' A Consumer class with common task handlers useful in Shiny apps
#'
#' In addtion to 'eval' and 'function' signals, ShinyConsumer object
#' process 'interrupt' and 'notify' signals for throwing errors and
#' displying Shiny notifictions.
#' @format NULL
#' @usage NULL
#' @export
ShinyConsumer <- R6Class(
  "ShinyConsumer",
  inherit=Consumer,
  private = list(
    addInterruptHandler = function(){
      func <- function(signal, obj, env){
        if(is.null(obj))
          msg <- "Triggered Inturrupt"
        else{
          msg <- try(as.character(obj))
          if(inherits(msg, "try-error"))
            msg <- "Triggered Inturrupt"

        }
        stop(msg, call.=FALSE)
      }
      self$addHandler(func, "Interrupt")
    },

    addNotifyHandler = function(){
      session <- shiny::getDefaultReactiveDomain()
      func <- function(signal, obj, env){
        if(is.null(obj))
          msg <- list(ui="")
        else if(is.character(obj)){
          msg <- list(ui=obj)
        }else
          msg <- obj
        msg$session <- session
        do.call(shiny::showNotification, msg)
      }
      self$addHandler(func, "Notify")
    }
  ),
  public = list(

    initHandlers = function(){
      super$initHandlers()
      private$addNotifyHandler()
      private$addInterruptHandler()
    }
  )
)
