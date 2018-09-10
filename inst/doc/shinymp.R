## ----echo=TRUE-----------------------------------------------------------
library(ipc)
library(future)
plan(multiprocess)
q <- queue()

value <- ""

f <- future({
  # set value in the main thread
  q$producer$fireEval({
    value <- "Hello world"
  })
})

Sys.sleep(.5)
# Evaluate signals
cons <- q$consumer$consume()
print(value)


# Remove temporary files
q$destroy()

## ---- eval=FALSE---------------------------------------------------------
#  variable <- 2
#  q$producer$fireEval(val <- j, env=list(j=variable))

## ----echo=TRUE-----------------------------------------------------------
library(future)
library(promises)
plan(multiprocess)

q <- queue()

fut <- future({
  for(i in 1:1000){
    Sys.sleep(.1)
    q$consumer$consume()
 }
})

q$producer$fireEval(stop("Stop that child"))
cat(try(value(fut)))

q$destroy()

## ----eval=FALSE----------------------------------------------------------
#  library(future)
#  library(promises)
#  plan(multiprocess)
#  
#  q <- queue()
#  
#  fut <- future({
#    for(i in 1:100){
#      Sys.sleep(.1)
#      q$producer$fireEval(print(index), list(index=i))
#   }
#  })
#  
#  q$consumer$start()
#  
#  # ... Later, stop consumption and clean up
#  # q$destroy()

## ---- eval=FALSE---------------------------------------------------------
#  q <- queue(RedisSource$new())

## ---- eval=FALSE---------------------------------------------------------
#  library(shiny)
#  library(ipc)
#  library(future)
#  plan(multiprocess)
#  
#  ui <- fluidPage(
#  
#    titlePanel("Countdown"),
#  
#    sidebarLayout(
#      sidebarPanel(
#        actionButton('run', 'count down')
#      ),
#  
#      mainPanel(
#        tableOutput("result")
#      )
#    )
#  )
#  
#  server <- function(input, output) {
#  
#    queue <- shinyQueue()
#    queue$consumer$start(100) # Execute signals every 100 milliseconds
#  
#    # A reactive value to hold output
#    result_val <- reactiveVal()
#  
#    # Handle button click
#    observeEvent(input$run,{
#      future({
#        for(i in 10:0){
#          Sys.sleep(1)
#          result <- data.frame(count=i)
#          # change value
#          queue$producer$fireAssignReactive("result_val",result)
#        }
#      })
#  
#      #Return something other than the future so we don't block the UI
#      NULL
#    })
#  
#    # set output to reactive value
#    output$result <- renderTable({
#      req(result_val())
#    })
#  }
#  
#  # Run the application
#  shinyApp(ui = ui, server = server)

## ---- eval=FALSE---------------------------------------------------------
#  library(shiny)
#  library(ipc)
#  library(future)
#  plan(multiprocess)
#  
#  ui <- fluidPage(
#  
#    titlePanel("Countdown"),
#  
#    sidebarLayout(
#      sidebarPanel(
#        actionButton('run', 'Run')
#      ),
#  
#      mainPanel(
#        tableOutput("result")
#      )
#    )
#  )
#  
#  server <- function(input, output) {
#  
#    # A reactive value to hold output
#    result_val <- reactiveVal()
#  
#    # Handle button click
#    observeEvent(input$run,{
#      result_val(NULL)
#  
#      # Create a progress bar
#      progress <- AsyncProgress$new(message="Complex analysis")
#      future({
#        for(i in 1:10){
#          Sys.sleep(1)
#          progress$inc(1/10) # Increment progress bar
#        }
#        progress$close() # Close the progress bar
#        data.frame(result="Insightful result")
#      }) %...>% result_val  # Assign result of future to result_val
#  
#      # Return something other than the future so we don't block the UI
#      NULL
#    })
#  
#    # Set output to reactive value
#    output$result <- renderTable({
#      req(result_val())
#    })
#  }
#  
#  # Run the application
#  shinyApp(ui = ui, server = server)

## ----echo=TRUE-----------------------------------------------------------
library(future)
library(promises)
plan(multiprocess)

# A long running function. Having a callback (progressMonitor) is a way to
# allow for interrupts to be checked for without adding a dependency
# to the analysis function.
accessableAnalysisFunction <- function(progressMonitor=function(i) cat(".")){
  for(i in 1:1000){
    Sys.sleep(.1)
    progressMonitor(i)
  }
  data.frame(result="Insightful analysis")
}

inter <- AsyncInterruptor$new()
fut <- future({
  accessableAnalysisFunction(progressMonitor = function(i) inter$execInterrupts())
})
inter$interrupt("Stop that future")
cat(try(value(fut)))
inter$destroy()

## ----eval=FALSE----------------------------------------------------------
#  library(shiny)
#  library(ipc)
#  library(future)
#  library(promises)
#  plan(multicore)    # This will only work with multicore, which is unavailable on Windows
#  
#  inaccessableAnalysisFunction <- function(){
#    Sys.sleep(10)
#    data.frame(result="Insightful analysis")
#  }
#  
#  # Define UI for application that draws a histogram
#  ui <- fluidPage(
#  
#    # Application title
#    titlePanel("Cancelable Async Task"),
#  
#    # Sidebar with a slider input for number of bins
#    sidebarLayout(
#      sidebarPanel(
#        actionButton('run', 'Run'),
#        actionButton('cancel', 'Cancel')
#      ),
#  
#      # Show a plot of the generated distribution
#      mainPanel(
#        tableOutput("result")
#      )
#    )
#  )
#  
#  server <- function(input, output) {
#  
#    fut <- NULL
#  
#    result_val <- reactiveVal()
#    running <- reactiveVal(FALSE)
#    observeEvent(input$run,{
#  
#      #Don't do anything if in the middle of a run
#      if(running())
#        return(NULL)
#      running(TRUE)
#  
#      print("Starting Run")
#      result_val(NULL)
#      fut <<- future({
#        result <- inaccessableAnalysisFunction()
#      })
#      prom <- fut %...>% result_val
#      prom <- catch(fut,
#                   function(e){
#                     result_val(NULL)
#                     print(e$message)
#                     showNotification("Task Stopped")
#                   })
#      prom <- finally(prom, function(){
#        print("Done")
#        running(FALSE) #declare done with run
#      })
#  
#  
#      #Return something other than the future so we don't block the UI
#      NULL
#    })
#  
#  
#    # Kill future
#    observeEvent(input$cancel,{
#      #
#      # Use this method of stopping only if you don't have access to the
#      # internals of the long running process. If you are able, it is
#      # recommended to use AsyncInterruptor instead.
#      #
#      stopMulticoreFuture(fut)
#    })
#  
#  
#    output$result <- renderTable({
#      req(result_val())
#    })
#  }
#  
#  # Run the application
#  shinyApp(ui = ui, server = server)

## ----echo=FALSE----------------------------------------------------------
plan(sequential)

