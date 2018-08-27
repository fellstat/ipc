
#' A progress bar object where inc and set are usable within other processes
#'
#' An async compatible wrapper around Shiny's progress bar. It should be instatiated
#' from the main thread, but may be closed, set and incremented from any thread.
#'
#' \strong{Methods}
#'   \describe{
#'     \item{\code{initialize(..., queue=shinyQueue(), millis=250, value=NULL, message=NULL, detail=NULL)}}{
#'       Creates a new progress panel and displays it.
#'     }
#'     \item{\code{set(value = NULL, message = NULL, detail = NULL)}}{
#'       Updates the progress panel. When called the first time, the
#'       progress panel is displayed.
#'     }
#'     \item{\code{inc(amount = 0.1, message = NULL, detail = NULL)}}{
#'       Like \code{set}, this updates the progress panel. The difference is
#'       that \code{inc} increases the progress bar by \code{amount}, instead
#'       of setting it to a specific value.
#'     }
#'     \item{\code{sequentialClose()}}{
#'       Removes the progress panel and destroys the queue. Must be called from main thread.
#'     }
#'     \item{\code{close()}}{
#'       Fires a close signal and may be used from any thread.
#'     }
#'   }
#'
#' @param session The Shiny session object, as provided by
#'   \code{shinyServer} to the server function.
#' @param min The value that represents the starting point of the
#'   progress bar. Must be less tham \code{max}.
#' @param max The value that represents the end of the progress bar.
#'   Must be greater than \code{min}.
#' @param message A single-element character vector; the message to be
#'   displayed to the user, or \code{NULL} to hide the current message
#'   (if any).
#' @param detail A single-element character vector; the detail message
#'   to be displayed to the user, or \code{NULL} to hide the current
#'   detail message (if any). The detail message will be shown with a
#'   de-emphasized appearance relative to \code{message}.
#' @param value A numeric value at which to set
#'   the progress bar, relative to \code{min} and \code{max}.
#' @param queue A Queue object for message passing
#' @param millis How often in milliseconds should updates to the progress bar be checked for.
#' @examples
#' ## Only run examples in interactive R sessions
#' if (interactive()) {
#' library(shiny)
#' library(future)
#' plan(multiprocess)
#' ui <- fluidPage(
#'   actionButton("run","Run"),
#'   tableOutput("dataset")
#' )
#'
#' server <- function(input, output, session) {
#'
#'   dat <- reactiveVal()
#'   observeEvent(input$run, {
#'     progress <- AsyncProgress$new(session, min=1, max=15)
#'     future({
#'       for (i in 1:15) {
#'         progress$set(value = i)
#'         Sys.sleep(0.5)
#'       }
#'       progress$close()
#'       cars
#'     }) %...>% dat
#'     NULL
#'   })
#'
#'   output$dataset <- renderTable({
#'     req(dat())
#'   })
#' }
#'
#' shinyApp(ui, server)
#' }
#' @format NULL
#' @usage NULL
#' @export
AsyncProgress <- R6Class(
  "AsyncProgress",
  private = list(
    queue=NULL,
    progress=NULL
  ),
  public = list(
    initialize = function(..., queue=shinyQueue(), millis=250, value=NULL, message=NULL, detail=NULL){
      private$queue <- queue
      private$progress <- Progress$new(...)
      if(!(is.null(value) && is.null(message) && is.null(detail)))
        private$progress$set(value=value, message=message, detail=detail)
      private$queue$consumer$start(millis)
    },

    getMax = function() private$progress$getMax(),

    getMin = function() private$progress$getMin(),

    sequentialClose = function(){
      private$queue$destroy()
      private$progress$close()
      private$queue <- NULL
      private$progress <- NULL
    },

    set = function(value = NULL, message = NULL, detail = NULL){
      args <- list(value = value, message = message, detail = detail)
      private$queue$producer$fireEval({
        do.call(private$progress$set, args)
      }, list(args=args))
    },

    inc = function(amount = 0.1, message = NULL, detail = NULL){
      args <- list(amount = amount, message = message, detail = detail)
      private$queue$producer$fireEval({
        do.call(private$progress$inc, args)
      }, list(args=args))
    },

    close = function(){
      private$queue$producer$fireEval({
        self$sequentialClose()
      })
    }
  )
)
