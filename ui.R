
# This is thee user interface definitions for the Shiny Application portion of
# the course project for Johns Hopkins' (via Coursera) Developing Data Products.

library(shiny)

library(shinyTree)

# Globals are first computed or just plain set to parameterize behavior.

hostname = system('hostname', intern=T)

if (hostname == 'AJ')
{
    MaxRowsToRead <<- 10000 # data max is less than 50M
    DDLRoot = 'E:/wat/misc/DDL'
    DataDir = paste0(DDLRoot,'/Data')
} else
{
    MaxRowsToRead <<- 100000000 # data max is less than 50M so this gets all
}
if (hostname == 'VM-EP-3')
{
    DDLRoot = 'd:/RProjects' # Oops
    DataDir = paste0(DDLRoot,'/RedLineData')
}
ForceListRLFilesFromDropBox = F # T to locally test DropBox connectivity
if (!ForceListRLFilesFromDropBox & (hostname == 'VM-EP-3' | hostname == 'AJ'))
{
    ListRLFilesFromDropBox = FALSE # Local only
    QuietDownload <<- FALSE
} else
{
    DataDir = 'Data'
    ListRLFilesFromDropBox = TRUE # Any local cache is still used for the actual data
    QuietDownload <<- TRUE
}
OrigDataDir <<- paste0(DataDir,'/BLSOrig')
CompressedRDataDir <<- paste0(DataDir,'/CompressedRDA')
dir.create(OrigDataDir,recursive=T,showWarnings=F)
dir.create(CompressedRDataDir,recursive=T,showWarnings=F)

# If we don't have the data locally, check DropBox using these globals.

DropBoxDataDir = '/Data'
DropBoxCompressedRDataDir <<- paste0(DropBoxDataDir,'/CompressedRDA')
# This works around an apparent limitation of publishing to shinyapps.io:
if (!file.exists('.httr-oauth') & file.exists('httr-oauth')) {file.rename('httr-oauth','.httr-oauth')}

# Cache the filelist from BLS into FNsB

BLSDataURL <<- 'http://download.bls.gov/pub/time.series/cs'

FNsP <<- list(
    rl.industry4=''
)

shinyUI(fluidPage(
    tabsetPanel
    (
        type = "tabs",
        tabPanel
        (
            'Injury Predictions by Industry',
            sidebarLayout
            (
                sidebarPanel
                (
                    conditionalPanel
                    (
                        condition='false',
                        selectInput
                        (
                            'datasetP',
                            'Choose a data.table:',
                            choices = names(FNsP)
                        )
                    ),
                    numericInput('yearsP','Number of years to predict:',3,min=1,max=9)
                ),
                mainPanel
                (
                    h3('Injuries (Series) by Year for the Selected Industry'),
                    plotOutput('plot1P'),
                    h3('Currently Selected:'),
                    verbatimTextOutput('selTxtP'),
                    hr(),
                    shinyTree('treeP')
                )
            )
        ), # tabPanel
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

