
# This is thee user interface definitions for the Shiny Application portion of
# the course project for Johns Hopkins' (via Coursera) Developing Data Products.

library(shiny)

shinyServer(function(input, output)
{

    output$distPlot <- renderPlot({

        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white')

    })

}) # shinyServer(function
