
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

    initialize = function(id=redisIdGenerator()(), config=redisConfig()){
      private$id <- id
      private$config <- config
    },

    getRedisConnection = function(){
      con <- redisConnection(private$id)
      if(is.null(con)){
        con <- do.call(redux::hiredis, private$config)
        setRedisConnection(private$id, con)
      }
      con
    },

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

    push = function(msg, obj){
      s <- objectToString(list(msg=msg,obj=obj))
      con <- self$getRedisConnection()
      con$LPUSH(private$id, s)
    },

    destroy = function(){
      con <- self$getRedisConnection()
      con$DEL(private$id)
      setRedisConnection(private$id, NULL)
    },

    finalize = function() {
      setRedisConnection(private$id, NULL)
    }
  )
)
