#' A Class for reading and executing tasks from a source
#'
#' \strong{Methods}
#'   \describe{
#'     \item{\code{initialize(source, env=parent.frame(2), ...)}}{
#'       Creates a Consumer object linked to the \code{source}. Signals will be
#'       executed in the \code{env} environment.
#'     }
#'     \item{\code{consume(safe=FALSE, env=parent.frame())}}{
#'       Executes all (unprocessed) signals fired to source from a Producer.
#'       if \code{safe} evaluation is wrapped with \code{try}. Signals are
#'       executed in the \code{env} environment.
#'     }
#'     \item{\code{start(millis=250, env=parent.frame())}}{
#'       Starts executing \code{consume} every \code{millis} milliseconds. Signals are
#'       executed in the \code{env} environment.
#'     }
#'     \item{\code{stop()}}{
#'       Stops the periodic execution of \code{consume}.
#'     }
#'     \item{\code{clearExecutors()}}{
#'       Removes all executors
#'     }
#'     \item{\code{removeExecutor(signal, index)()}}{
#'       Removes executor from 'signal' with position index
#'     }
#'     \item{\code{initExecutors()}}{
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
    env = NULL,

    addEvalExecutor = function(){
      func <- function(signal, obj){
        eval(obj, env=private$env)
      }
      self$addExecutor(func, "eval")
    },

    addfunctionExecutor = function(){
      func <- function(signal, obj){
        f <- get(obj[[1]], envir = private$env)
        do.call(f, obj[[2]])
      }
      self$addExecutor(func, "function")
    }
  ),
  public=list(
    executors = list(),

    stopped = FALSE,

    laterHandle = NULL,

    initialize = function(source, env=parent.frame(2), ...){
      private$env <- env
      private$source <- source
      self$initExecutors()
    },

    consume = function(safe=FALSE, env=parent.frame()){
      #if(private$source$isDestroyed()){
      #  warning("Consumer has been destroyed")
      #  return(list())
      #}
      oldenv <- private$env
      on.exit(function() private$env <- oldenv)
      private$env <- env
      contents <- private$source$pop()
      if(length(contents) == 0)
        return(list())
      signals <- names(contents)
      result <- list()
      for(i in 1:length(signals)){
        result[[i]] <- list()
        exec <- self$executors[[signals[i]]]
        if(!is.null(exec)){
          for(j in 1:length(exec)){
            func <- exec[[j]]
            if(safe)
              result[[i]][[j]] <- try(func(signals[i], contents[[i]]))
            else
              result[[i]][[j]] <- func(signals[i], contents[[i]])
          }
        }
      }
      names(result) <- signals
      result
    },

    start = function(millis=250, env=parent.frame()){
      self$stopped <- FALSE
      callback <- function(){
        if (self$stopped) return()
        tryCatch({
          result <- self$consume(safe=TRUE, env=env)
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
        self$laterHandle <- later::later(callback, millis / 1000)
      }
      callback()
    },

    stop = function(){
      self$stopped <- TRUE
      if(!is.null(self$laterHandle))
        self$laterHandle()
      self$laterHandle <- NULL
    },

    addExecutor = function(func, signal){
      if(is.null(self$executors[[signal]]))
        self$executors[[signal]] <- list()
      index <- length(self$executors[[signal]]) + 1
      self$executors[[signal]][[index]] <- func
      index
    },

    clearExecutors = function(){
      self$executors <- list()
    },

    removeExecutor = function(signal, index){
      self$executors[[signal]][[index]] <- NULL
    },


    initExecutors = function(){
      private$addfunctionExecutor()
      private$addEvalExecutor()
    },

    finalize = function() {
      self$stop()
    }
  )
)

#' A Consumer class with common task executors useful in Shiny apps
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
    addInterruptExecutor = function(){
      func <- function(signal, obj){
        if(is.null(obj))
          msg <- "Triggered Inturrupt"
        else{
          msg <- try(as.character(obj))
          if(inherits(msg, "try-error"))
            msg <- "Triggered Inturrupt"

        }
        stop(msg)
      }
      self$addExecutor(func, "Interrupt")
    },

    addNotifyExecutor = function(){
      func <- function(signal, obj){
        if(is.null(obj))
          msg <- list(ui="")
        else if(is.character(obj)){
          msg <- list(ui=obj)
        }else
          msg <- obj
        msg$session <- self$session
        do.call(shiny::showNotification, msg)
      }
      self$addExecutor(func, "Notify")
    }
  ),
  public = list(
    session=NULL,

    initialize = function(source,
                          env=parent.frame(2),
                          session=shiny::getDefaultReactiveDomain(),
                          ...){
      super$initialize(source, env, ...)
      self$session <- session
    },

    start = function(millis=250, env=parent.frame(), session = shiny::getDefaultReactiveDomain()){
      if(!is.null(session))
        session$onEnded(self$stop)
      super$start(millis, env)
    },

    initExecutors = function(){
      super$initExecutors()
      private$addNotifyExecutor()
      private$addInterruptExecutor()
    }
  )
)
