library(shiny)
library(ipc)
library(future)
library(promises)
plan(multisession)


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

  interruptor <- AsyncInterruptor$new()    # To signal STOP to the future

  result_val <- reactiveVal()
  running <- reactiveVal(FALSE)
  observeEvent(input$run,{

    #Don't do anything if in the middle of a run
    if(running())
      return(NULL)
    running(TRUE)

    # Create new progress bar
    progress <- AsyncProgress$new(message="Complex analysis")

    result_val(NULL)


    fut <- future({
      for(i in 1:N){
        # Some important computation
        Sys.sleep(.5)

        # Increment progress bar
        progress$inc(1/N)

        # throw errors that were signal (if Cancel was clicked)
        interruptor$execInterrupts()
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
      interruptor$interrupt("User Interrupt")
  })


  output$result <- renderTable({
    req(result_val())
  })
}

# Run the application
shinyApp(ui = ui, server = server)
