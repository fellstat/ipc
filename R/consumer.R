Consumer <- R6Class(
  "Consumer",
  private = list(
    source=NULL
  ),
  public=list(
    executors = list(),

    stopped = FALSE,

    env = NULL,

    laterHandle = NULL,

    initialize = function(source, env=parent.frame(2), ...){
      self$env <- env
      private$source <- source
      self$initExecutors()
    },

    initExecutors = function(){},

    consume = function(safe=FALSE){
      contents <- private$source$pop()
      if(length(contents) == 0)
        return(NULL)
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
      result
    },

    start = function(millis=400){
      self$stopped <- FALSE
      callback <- function(){
        if (self$stopped) return()
        tryCatch({
          result <- self$consume(safe=TRUE)
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
      f <- func
      #environment(f) <- self$env
      if(is.null(self$executors[[signal]]))
        self$executors[[signal]] <- list()
      index <- length(self$executors[[signal]]) + 1
      self$executors[[signal]][[index]] <- f
      index
    },

    clearExecutors = function(){
      self$executors <- list()
    },

    removeExecutor = function(signal, index){
      self$executors[[signal]][[index]] <- NULL
    },

    finalize = function() {
      self$stop()
    }
  )
)


ShinyConsumer <- R6Class(
  "ShinyConsumer",
  inherit=Consumer,
  public = list(
    session=NULL,
    initialize = function(source,
                          env=parent.frame(2),
                          session=shiny::getDefaultReactiveDomain(),
                          ...){
      super$initialize(source, env, ...)
      self$session <- session
    },
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
    },


    addEvalExecutor = function(){
      func <- function(signal, obj){
        eval(obj, env=self$env)
      }
      self$addExecutor(func, "eval")
    },

    addfunctorExecutor = function(){
      func <- function(signal, obj){
        f <- get(obj[[1]], envir = self$env)
        f(obj[[2]])
      }
      self$addExecutor(func, "functor")
    },

    start = function(session = shiny::getDefaultReactiveDomain(), millis=400){
      session$onEnded(self$stop)
      super$start(millis)
    },

    initExecutors = function(){
      self$addNotifyExecutor()
      self$addInterruptExecutor()
      self$addEvalExecutor()
      self$addfunctorExecutor()
    }
  )
)
