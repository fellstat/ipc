
.redisConnections <-  new.env(parent = emptyenv())

redisConnection <- function(id){
  .redisConnections[[id]]
}

setRedisConnection <- function(id, con){
  .redisConnections[[id]] <- con
}

destroyRedisConnection <- function(id){
  .redisConnections[[id]] <- NULL
}






#' Reads and writes the queue to a redis db
#'
#'
#' @param id An identifier to use for the queue
#' @param config A configuration list for redux::hiredis
#' @param n The number of records to pop (-1 indicates all available).
#' @param msg A string indicating the signal.
#' @param obj The object to associate with the signal.
#' @format NULL
#' @usage NULL
#' @export
RedisSource <- R6Class(
  "RedisSource",
  private = list(
    config = NULL,

    id = NULL
  ),

  public = list(

    #' @description Creates a redis source object.
    #' @param id An identifier to use for the queue
    #' @param config A configuration list for redux::hiredis
    initialize = function(id=redisIdGenerator()(), config=redisConfig()){
      if (!requireNamespace("redux", quietly = TRUE)) {
        stop("Package \"redux\" needed for RedisSource to work. Please install it.",
             call. = FALSE)
      }
      private$id <- id
      private$config <- config
    },

    #' @description Returns the underlying redis connection.
    getRedisConnection = function(){
      con <- redisConnection(private$id)
      if(is.null(con)){
        con <- do.call(redux::hiredis, private$config)
        setRedisConnection(private$id, con)
      }
      con
    },

    #' @description removes n items from the source and returns them
    #' @param n The number of records to pop (-1 indicates all available).
    pop = function(n=-1){
      if(n == 0)
        return(list())
      con <- self$getRedisConnection()
      if(n == -1){
        l <- con$pipeline(redux::redis$LRANGE(private$id,0,-1),
                          redux::redis$DEL(private$id))[[1]]
        l <- rev(l)
      }else{
        l <- list()
        for(i in 1:n){
          r <- con$LPOP(private$id)
          if(is.null(r))
            break
          l[[i]] <- r
        }
      }
      if(length(l) == 0)
        return(list())
      result <- list()
      for(i in 1:length(l)){
        r <- stringToObject(l[[i]])
        result[[i]] <- r[[2]]
        names(result)[i] <- r[[1]]
      }
      result
    },

    #' @description Adds an item to the source.
    #' @param msg A string indicating the signal.
    #' @param obj The object to associate with the signal.
    push = function(msg, obj){
      s <- objectToString(list(msg=msg,obj=obj))
      con <- self$getRedisConnection()
      con$LPUSH(private$id, s)
    },

    #' @description Cleans up source after use.
    destroy = function(){
      con <- self$getRedisConnection()
      con$DEL(private$id)
      setRedisConnection(private$id, NULL)
    },

    #' @description finalize
    finalize = function() {
      setRedisConnection(private$id, NULL)
    }
  )
)
