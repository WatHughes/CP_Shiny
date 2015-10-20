
# This is thee user interface definitions for the Shiny Application portion of
# the course project for Johns Hopkins' (via Coursera) Developing Data Products.

library(utils)
library(data.table)
library(rvest) # XML/HTML handling
library(rdrop2) # Dropbox wrapper
library(shiny)

library(shinyTree)

source('MakeCodeTree.R')
source('CondLoadDataTable.R')

CondLoadDataTable('SeriesYearIndustryCounts')

shinyServer(function(input, output)
{
    # Injury Predictions by Industry
    datasetInputP = reactive({
        CondLoadDataTable(input$datasetP)
    })

    output$plot1P = renderPlot({
        ds = datasetInputP() # For the reactivity
        selTxtP = SelectionDisplayText()
        selCodeP = sub(':.*','',selTxtP)
        selData = SeriesYearIndustryCounts[industry_code==selCodeP]
        if (nrow(selData) > 0)
        {
            selMod = lm(N~year,data=selData)
            predCount = input$yearsP
            predYears = data.frame(year=c(1:predCount))
            predYears$year = predYears$year + 2013
            selPred = predict(selMod,predYears)
            df=data.frame(year=c(selData$year,predYears$year),SeriesCount=c(selData$N,selPred),DataOrPrediction=as.factor(c(rep(1,3),rep(2,predCount))))
            plot(SeriesCount~year,data=df,col=DataOrPrediction,pch=9,cex=2,xlab='Year. BLS data in black and predictions in red.',ylab='Series Count')
        }
    })
    output$treeP <- renderTree({
        ds = datasetInputP() # For the reactivity
        datasetname = input$datasetP
        ct = FNsP[[datasetname]]
        if (!is.list(ct))
        {
            ct = MakeCodeTree(get(datasetname),4) # display_level >= 4 will be ignored
            FNsP[[datasetname]] <<- ct
        }
        DisplayTree = ct$GetDisplayTree()
        # browser() # Breakpoints seem flaky in Shiny
        DisplayTree
    })
    SelectionDisplayText = reactive({
        ds = datasetInputP() # For the reactivity
        datasetname = input$datasetP
        tree = input$treeP
        if (is.null(tree))
        {
            'None'
        } else
        {
            sel = get_selected(tree,format='slices')
            # List of 1 # Slices Format: all lists, no attributes.
            #  $ :List of 1
            #   ..$ All workers:List of 1
            #   .. ..$ Service-providing:List of 1
            #   .. .. ..$ Professional and business services: num 0
            ct = FNsP[[datasetname]]
            CodeDef = ct$GetSelectedCodeDef(sel)
            DisplayTextColumn = ct$GetDisplayTextColumn()
            CodeColumn = ct$GetCodeColumn()
            if (is.null(CodeDef))
            {
                selTxtP = 'Nothing selected'
            }
            else
            {
                selTxtP = paste0(CodeDef[1,CodeColumn,with=F],':  ',CodeDef[1,DisplayTextColumn,with=F])
            }
            selTxtP
        }
    })
    output$selTxtP <- renderText({
        selTxtP = SelectionDisplayText()
    })

    # RStudio default application server code
    output$distPlot <- renderPlot({

        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white')

    })

}) # shinyServer(function

