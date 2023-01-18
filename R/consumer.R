#' A Class for reading and executing tasks from a source
#'
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
    #' @field handlers A list of handlers
    handlers = list(),

    #' @field stopped Is currently stopped.
    stopped = FALSE,

    #' @field laterHandle A callback handle.
    laterHandle = NULL,

    #' @description Creates the object.
    #' @param source A source, e.g. TextFileSource.
    initialize = function(source){
      private$source <- source
      self$initHandlers()
    },

    #' @description Sets the source.
    #' @param source A source, e.g. TextFileSource.
    setSource = function(source){
      private$source <- source
    },

    #' @description Gets the source.
    getSource = function(){
      private$source
    },

    #' @description Executes all (unprocessed) signals fired to source from a Producer.
    #'       if \code{throwErrors} is TRUE, the first error encountered is thrown
    #'       after executing all signals. Signals are executed in the \code{env} environment.
    #'       If \code{env} is NULL, the environment set at initialization is used.
    #' @param throwErrors Should errors be thrown or caught.
    #' @param env The execution environment.
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

    #' @description Starts executing \code{consume} every \code{millis} milliseconds. \code{throwErrors}
    #'       and \code{env} are passed down to \code{consume}
    #' @param millis milliseconds.
    #' @param env The execution environment.
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

    #' @description Stops the periodic execution of \code{consume}.
    stop = function(){
      self$stopped <- TRUE
      if(!is.null(self$laterHandle))
        self$laterHandle()
      self$laterHandle <- NULL
    },

    #' @description Adds a handler for 'signal'. func
    #' @param func The function which takes three parameters: 1. the signal, 2. the message object, and 3. the evaluation environment.
    #' @param signal A string to bind the function to.
    addHandler = function(func, signal){
      if(is.null(self$handlers[[signal]]))
        self$handlers[[signal]] <- list()
      index <- length(self$handlers[[signal]]) + 1
      self$handlers[[signal]][[index]] <- func
      index
    },

    #' @description Removes all handler.s
    clearHandlers = function(){
      self$handlers <- list()
    },

    #' @description Removes a single handler.
    #' @param signal The signal of the handler.
    #' @param index The index of the handler to remove from the signal.
    removeHandler = function(signal, index){
      self$handlers[[signal]][[index]] <- NULL
    },

    #' @description Adds default handlers.
    initHandlers = function(){
      private$addfunctionHandler()
      private$addEvalHandler()
    },

    #' @description cleans up object.
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

    #' @description Adds default handlers
    initHandlers = function(){
      super$initHandlers()
      private$addNotifyHandler()
      private$addInterruptHandler()
    }
  )
)
