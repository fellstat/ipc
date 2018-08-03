library(shiny)
library(ShinyAsyncTools)
library(future)
library(promises)
plan(multicore)


# Define UI for application that draws a histogram
ui <- fluidPage(

  # Application title
  titlePanel("Async With Progress Bar"),

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

  interruptQueue <- shinyQueue()    # A Queue for the main thread to signal to the future
  queue <- shinyQueue()             # A Queue for the future to signal to the main thread
  queue$consumer$start()

  # progress variable must exist in the environment that "queue"
  # was instantiated in, because that is the environment in which
  # signals will be evaulated.
  progress <- NULL

  result_val <- reactiveVal()
  running <- reactiveVal(FALSE)
  observeEvent(input$run,{

    #Don't do anything if in the middle of a run
    if(running())
      return(NULL)
    running(TRUE)

    # Create new progress bar
    progress <<- Progress$new()
    progress$set(message="Complex computation",value=0)

    result_val(NULL)


    fut <- future({
      for(i in 1:N){
        # Increment progress bar using N from this environment
        queue$producer$fireEval({
          cat(".")
          progress$inc(1/N)
        }, list(N=N))

        # Some important computation
        Sys.sleep(.5)

        # Evaluate interrupt signal (if Cancel is clicked)
        interruptQueue$consumer$consume()
      }

      data.frame(result="Insightful analysis")
    }) %...>% result_val

    # Show notification on error or user interrupt
    fut <- catch(fut,
                 function(e){
                   result_val(NULL)
                   print(e$message)
                   showNotification(e$message)
                 })

    # When done with analysis, remove progress bar
    fut <- finally(fut, function(){
      progress$close()
      running(FALSE) # Declare done with run
    })

    # Return something other than the future so we don't block the UI
    NULL
  })


  # Send interrupt signal to future
  observeEvent(input$cancel,{
    if(running())
      interruptQueue$producer$fireInterrupt("User Interrupt")
  })


  output$result <- renderTable({
    req(result_val())
  })
}

# Run the application
shinyApp(ui = ui, server = server)
