library(shiny)
library(ipc)
library(future)
plan(multiprocess)

# Define UI for application that draws a histogram
ui <- fluidPage(

  # Application title
  titlePanel("Old Faithful Geyser Data: Now With Rainbow Action!!!"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("bins",
                  "Number of bins:",
                  min = 1,
                  max = 50,
                  value = 30)
    ),

    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("distPlot")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  queue <- shinyQueue()
  queue$consumer$start()

  color <- reactiveVal("grey")

  # Watch for a change in the slider to start colors changing
  observeEvent(input$bins, {
    # Don't do anything if in the process of cycling through colors
    if(color() != "grey")
      return(NULL)
    color("black")

    #Cycle through colors and then back to grey
    future({
      queue$producer$fireEval(print("Cycling Through The Rainbow!!!"))
      cols <- c(rainbow(10), "grey")
      for(i in 1:11){
        Sys.sleep(1)
        queue$producer$fireNotify(paste("Changing color to", cols[i]))
        queue$producer$fireAssignReactive("color", cols[i])
      }
    })

    #Return something other than the future so we don't block the UI
    NULL
  })


  output$distPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    x    <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = input$bins + 1)

    # draw the histogram with the specified color and number of bins
    hist(x, breaks = bins, col = color(), border = 'white')
  })

}

# Run the application
shinyApp(ui = ui, server = server)

