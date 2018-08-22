#' Run Example Shiny Apps
#' @param application The example to run
#' @details
#' 'progress' is an example application with a long running analysis that is cancelable and has a progress bar.
#' 'changeReaction' is the old faithful example, but with the histogram colors changing over time.
#' 'cancel' is an example with a cancelable long running process.
#' @export
shinyExample <- function(application=c("progress","changeReactive", "cancel")) {
  application <- match.arg(application)
  appDir <- system.file("apps", application, package = "ipc")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `ipc`.", call. = FALSE)
  }

  shiny::runApp(appDir, display.mode = "normal")
}
