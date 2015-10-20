
# This is thee user interface definitions for the Shiny Application portion of
# the course project for Johns Hopkins' (via Coursera) Developing Data Products.

library(shiny)

shinyUI(fluidPage(
    tabsetPanel
    (
        type = "tabs",
        tabPanel
        (
            'RStudio Default Application',
            # Application title
            titlePanel("Old Faithful Geyser Data"),

            # Sidebar with a slider input for number of bins
            sidebarLayout
            (
                sidebarPanel
                (
                    sliderInput("bins",
                    "Number of bins:",
                    min = 1,
                    max = 50,
                    value = 30)
                ),
                # Show a plot of the generated distribution
                mainPanel
                (
                    plotOutput("distPlot")
                )
            )
        ) # tabPanel
    ) # tabsetPanel
)) # shinyUI(fluidPage
