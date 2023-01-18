
#' A progress bar object where inc and set are usable within other processes
#'
#' An async compatible wrapper around Shiny's progress bar. It should be instatiated
#' from the main process, but may be closed, set and incremented from any process.
#'
#' @examples
#' ## Only run examples in interactive R sessions
#' if (interactive()) {
#' library(shiny)
#' library(future)
#' plan(multisession)
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
#'     NULL #return something other than the future so the UI is not blocked
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

    #' @description Creates a new progress panel and displays it.
    #' @param ... Additional parameters to be passed to Shiny::Progress
    #' @param queue A Queue object for message passing
    #' @param millis  How often in milliseconds should updates to the progress bar be checked for.
    #' @param value A numeric value at which to set
    #' the progress bar, relative to \code{min} and \code{max}.
    #' @param message A single-element character vector; the message to be
    #'   displayed to the user, or \code{NULL} to hide the current message
    #'   (if any).
    #' @param detail A single-element character vector; the detail message
    #'   to be displayed to the user, or \code{NULL} to hide the current
    #'   detail message (if any). The detail message will be shown with a
    #'   de-emphasized appearance relative to \code{message}.
    initialize = function(..., queue=shinyQueue(), millis=250, value=NULL, message=NULL, detail=NULL){
      private$queue <- queue
      private$progress <- Progress$new(...)
      if(!(is.null(value) && is.null(message) && is.null(detail)))
        private$progress$set(value=value, message=message, detail=detail)
      private$queue$consumer$start(millis)
    },

    #' @description Returns the maximum
    getMax = function() private$progress$getMax(),

    #' @description Returns the minimum
    getMin = function() private$progress$getMin(),

    #' @description  Removes the progress panel and destroys the queue. Must be called from main process.
    sequentialClose = function(){
      private$queue$destroy()
      private$progress$close()
      private$queue <- NULL
      private$progress <- NULL
    },

    #' @description Updates the progress panel. When called the first time, the
    #'       progress panel is displayed.
    #' @param value A numeric value at which to set
    #' @param message A single-element character vector; the message to be
    #'   displayed to the user, or \code{NULL} to hide the current message
    #'   (if any).
    #' @param detail A single-element character vector; the detail message
    #'   to be displayed to the user, or \code{NULL} to hide the current
    #'   detail message (if any). The detail message will be shown with a
    #'   de-emphasized appearance relative to \code{message}.
    set = function(value = NULL, message = NULL, detail = NULL){
      args <- list(value = value, message = message, detail = detail)
      private$queue$producer$fireEval({
        do.call(private$progress$set, args)
      }, list(args=args))
    },

    #' @description Like \code{set}, this updates the progress panel. The difference is
    #'       that \code{inc} increases the progress bar by \code{amount}, instead
    #'       of setting it to a specific value.
    #' @param amount the size of the increment.
    #' @param message A single-element character vector; the message to be
    #'   displayed to the user, or \code{NULL} to hide the current message
    #'   (if any).
    #' @param detail A single-element character vector; the detail message
    #'   to be displayed to the user, or \code{NULL} to hide the current
    #'   detail message (if any). The detail message will be shown with a
    #'   de-emphasized appearance relative to \code{message}.
    inc = function(amount = 0.1, message = NULL, detail = NULL){
      args <- list(amount = amount, message = message, detail = detail)
      private$queue$producer$fireEval({
        do.call(private$progress$inc, args)
      }, list(args=args))
    },

    #' @description Fires a close signal and may be used from any process.
    close = function(){
      private$queue$producer$fireEval({
        self$sequentialClose()
      })
    }
  )
)
