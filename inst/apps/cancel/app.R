library(shiny)
library(ipc)
library(future)
library(promises)
plan(multicore)    # This will only work with multicore, which is unavailable on Windows

# Define UI for application that draws a histogram
ui <- fluidPage(

  # Application title
  titlePanel("Cancelable Async Task"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      actionButton('run', 'Run'),
      actionButton('cancel', 'Cancel')
    ),

    # Show a plot of the generated distribution
    mainPanel(
      tableOutput("result")
    )
  )
)

server <- function(input, output) {
  N <- 10

  fut <- NULL

  result_val <- reactiveVal()
  running <- reactiveVal(FALSE)
  observeEvent(input$run,{

    #Don't do anything if in the middle of a run
    if(running())
      return(NULL)
    running(TRUE)

    print("Starting Run")
    result_val(NULL)
    fut <<- future({
      Sys.sleep(6) # Some important operation
      result <- data.frame(result="Insightful analysis")
    })
    prom <- fut %...>% result_val
    prom <- catch(fut,
                 function(e){
                   result_val(NULL)
                   print(e$message)
                   showNotification("Task Stopped")
                 })
    prom <- finally(prom, function(){
      print("Done")
      running(FALSE) #declare done with run
    })


    #Return something other than the future so we don't block the UI
    NULL
  })


  # Kill future
  observeEvent(input$cancel,{
    #
    # Use this method of stopping only if you don't have access to the
    # internals of the long running process. If you are able, it is
    # recommended to use AsyncInterruptor instead.
    #
    stopMulticoreFuture(fut)
  })


  output$result <- renderTable({
    req(result_val())
  })
}

# Run the application
shinyApp(ui = ui, server = server)
