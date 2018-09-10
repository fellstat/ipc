---
title: 'ipc: An R Package for Inter-process Communication'
authors:
- affiliation: '1'
  name: Ian E. Fellows
  orcid: 0000-0003-1261-0925
date: "4 September 2018"
output: pdf_document
bibliography: paper.bib
tags:
- R
- High Performance Computing
- Interactive Visualization
affiliations:
- index: 1
  name: Fellows Statistics
---

Introduction
-----------

In computer science, asynchronous processing is critical for performing a wide array of tasks, from high performance computing to web services. Communication between these disparate asynchronous processes is often required. Currently the statistical computing language R provides no built in features to handle interprocess communication. Several packages have been written to handle the passing of text or binary data between processes (e.g. [@txtq], [@liteq], and [@rzmq]).

What is lacking is a framework to easily pass R objects between processes along with an associated signal, and have handler functions automatically execute them in the receiving process. Additionally, it is desirable to have a system that can be backed flexibly either through the file system or a database connection The `ipc` R package aims to fill this void.

For example, one might signal for the execution of an expression in one thread to set a variable `a`.

```
q <- queue()
q$producer$fireEval(a <- 1)
```

Then in another thread, this signal can be processed, resulting in the value `a` being set to 1 in the receiving thread after calling the `consume` method.

```
q$consumer$consume()
```

This package can be applied to high performance computing environments, easily allowing parallel worker processes to communicate partial results or progress to the main thread. Another major use case is to support asynchronous web based user interfaces ([@shiny]) to long running statistical algorithms.


Quick Start
-----------

Perhaps the most important use of this package is to communicate with a
parent thread from a child thread executed using the `future` package.
This is very easy to do. Simply create and start a `Queue` in the parent
thread. The child thread can then send messages and evaluate R code on
the main thread.

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

    ## [1] "Hello world"

    # Remove temporary files
    q$destroy()

A `Queue` object has a `producer` field that is used to send signals
onto the `Queue` and a `consumer` field that is used to read from the
queue, and process any signals written to the `Queue`.

Messages can be consumed by calling the consumer's `consume` method and
will be handled by default using the environment that consume is called
in. The consumer's `start` method will execute consume at regular
intervals provided the R process is idle.

By default, a `Consumer` object knows how to handle two signals. The
`"eval"` handler will execute the signal's data as an expression in the
evaluation environment (i.e. where `consume` is called. The `"doCall"`
handler will call the function defined by the first element of the data
with parameters equal to the second element. Functions to handle various
signals can be added to the consumer using the `addHandler` method.

`Producer` objects has a built in method to signal for evaluation.
`fireEval(expr, env)` will signal for `expr` to be evaluated,
substituting in any value in `env`. For example, the following code will
set the variable val to 2 in the environment in which it is consumed.

    variable <- 2
    q$producer$fireEval(val <- j, env=list(j=variable))

### Signaling a child process

Signals can also be sent from the main thread to a child. Here we will
cause the child process to throw an error.

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

    ## Error in eval(obj, envir = env) : Stop that child

    q$destroy()

If errors occur during the consumption, all messages are processed, and
then the first error encountered is then thrown. Alternatively, errors
can be switched to warnings using
`q$consumer$consume(throwErrors=FALSE)`.

### Continuous consumption

A consumer's `start` method can be used to execute `comsume` at regular
intervals (provided the R process is idle).

    library(future)
    library(promises)
    plan(multiprocess)

    q <- queue()

    fut <- future({
      for(i in 1:100){
        Sys.sleep(.1)
        q$producer$fireEval(print(index), list(index=i))
     }
    })

    q$consumer$start()

    # ... Later, stop consumption and clean up
    # q$destroy()

Sources
-------

By default, `ipc` communication is backed by text files (using
`TextFileSource` class, which wraps the `txtq` package). The files'
location is, again by default, generated by the `tempfile` function.
These global defaults can be overridden using the `tempFileGenerator`
and `defaultSource` functions.

For communication between processes on the same machine, the defaults
will generally suffice. If processes are running on multiple machines,
two strategies for sources may be used. First, if all machines have
access to a single file system, override the `tempFileGenerator` to
point to generate files in the shared file system. Alternately, `ipc`
provides the `RedisSource` class to back queues using a redis database.

    q <- queue(RedisSource$new())

Use in Shiny
------------

A major use case for this package is to support Shiny applications. You
can view three example applications using the `shinyExample` function.
Taking advantage of inter-process communication allows for more dynamic
applications that are more responsive to the user.

In Shiny apps, it is recommended that queues be created with the
`shinyQueue` function. This will ensure that the queue is properly
destroyed on session end.

### Changing a reactive value from a future

Reactive values can not be changed directly from within a future. Queues
make it easy to signal the main thread to assign a reactive value from
within the body of a future.

The application below creates a future every time countdown is clicked,
which assigns a value to the reactive value every second, counting down
from 10 to 0. If you click the button multiple times, each future will
compete to set the value, and the numbers will jump around.

    library(shiny)
    library(ipc)
    library(future)
    plan(multiprocess)

    ui <- fluidPage(

      titlePanel("Countdown"),

      sidebarLayout(
        sidebarPanel(
          actionButton('run', 'count down')
        ),

        mainPanel(
          tableOutput("result")
        )
      )
    )

    server <- function(input, output) {

      queue <- shinyQueue()
      queue$consumer$start(100) # Execute signals every 100 milliseconds

      # A reactive value to hold output
      result_val <- reactiveVal()
      
      # Handle button click
      observeEvent(input$run,{
        future({
          for(i in 10:0){
            Sys.sleep(1)
            result <- data.frame(count=i)
            # change value
            queue$producer$fireAssignReactive("result_val",result)
          }
        })

        #Return something other than the future so we don't block the UI
        NULL
      })

      # set output to reactive value
      output$result <- renderTable({
        req(result_val())
      })
    }

    # Run the application
    shinyApp(ui = ui, server = server)

### Adding a progress bar to an async operation

`AsyncProgress` is a drop in replacement for Shiny's `Progress` class
that allows you to update progress bars within a future. The example
below shows a minimal example of this. Note how you can click run
multiple times and get multiple progress bars.

    library(shiny)
    library(ipc)
    library(future)
    plan(multiprocess)

    ui <- fluidPage(

      titlePanel("Countdown"),

      sidebarLayout(
        sidebarPanel(
          actionButton('run', 'Run')
        ),

        mainPanel(
          tableOutput("result")
        )
      )
    )

    server <- function(input, output) {
      
      # A reactive value to hold output
      result_val <- reactiveVal()
      
      # Handle button click
      observeEvent(input$run,{
        result_val(NULL)
        
        # Create a progress bar
        progress <- AsyncProgress$new(message="Complex analysis")
        future({
          for(i in 1:10){
            Sys.sleep(1)
            progress$inc(1/10) # Increment progress bar
          }
          progress$close() # Close the progress bar
          data.frame(result="Insightful result")
        }) %...>% result_val  # Assign result of future to result_val

        # Return something other than the future so we don't block the UI
        NULL
      })

      # Set output to reactive value
      output$result <- renderTable({
        req(result_val())
      })
    }

    # Run the application
    shinyApp(ui = ui, server = server)

### Killing a long running process

When creating a UI with a process that take a significant amount of
times it is critical to provide the user a mechanism to cancel the
operation. The recommended mechanism to do this is to send a kill
message. The `AsyncInterruptor` is an easy to use wrapper around a
`Queue` object for this common use case.

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

    ## Error : Stop that future

    inter$destroy()

There are times where the Shiny developer does not have access to the
long running code in such a way that `execInterrupts` can be called as
the computation progresses. In these cases, the only way to terminate a
running future is to kill it at the OS level.

The function `stopMulticoreFuture` kills a future, provided it is
executed in a multicore plan. For mac and linux machines, both
plan(multiprocess) and plan(multicore) result in multicore execution
plans. In windows it is not possible to use a multicore execution plan.

The behavior of the execution plan after a kill signal has been sent is
technically undefined, but currently there are no large unintended
consequences of killing child processes. This may change in the future
however, which is why `AsyncInterruptor` is strongly preferred if at all
possible.

    library(shiny)
    library(ipc)
    library(future)
    library(promises)
    plan(multicore)    # This will only work with multicore, which is unavailable on Windows

    inaccessableAnalysisFunction <- function(){
      Sys.sleep(10)
      data.frame(result="Insightful analysis")
    }

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
          result <- inaccessableAnalysisFunction()
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


# Acknowledgements

We acknowledge the Center for Disease Control, and in particular Ray Shiraishi for their support in the development of the `ipc` package.

# References
