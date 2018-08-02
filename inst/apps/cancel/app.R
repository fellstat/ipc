library(shiny)
library(ShinyAsyncTools)
library(future)
library(promises)
plan(multicore)


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

  interruptQueue <- shinyQueue()
  queue <- shinyQueue()
  queue$consumer$start()

  result_val <- reactiveVal()
  running <- reactiveVal(FALSE)
  observeEvent(input$run,{

    #Don't do anything if in the iddle of a run
    if(running())
      return(NULL)
    running(TRUE)

    print("Starting Run")
    result_val(NULL)
    fut <- future({
      for(i in 1:N){
        queue$producer$fireEval(cat("."))
        interruptQueue$consumer$consume() # Evaluates interrupt signal (if cancel is clicked)
        Sys.sleep(.5)
      }
      result <- data.frame(result="Insightfull analysis")
      queue$producer$fireAssignReactive("result_val",result)
    })
    fut <- catch(fut,
                 function(e){
                   result_val(NULL)
                   print(e$message)
                   showNotification(e$message)
                 })
    fut <- finally(fut, function(){
      print("Done")
      running(FALSE) #decalre done with run
    })

    #Return something other than the future so we don't block the UI
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
