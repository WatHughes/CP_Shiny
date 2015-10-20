
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
                    numericInput('yearsP','Number of years to predict:',3,min=1,max=9),
                    p(),
                    'The plot shows the Bureau of Labor Statistics (BLS) count of injury series',
                    "for the selected industries' workers in black and",
                    'a prediction for the count for the following few years in red. Use the text',
                    'box (above) to enter or select',
                    'the number of years to predict (between 1 and 9, default 3) and the tree control',
                    "(to the bottom right) to select which industries' injuries to plot (to the right).",
                    br(),br()
                ),
                mainPanel
                (
                    'For background on this data and more detailed application documentation,',
                    '(left) click on the',
                    tags$b('More Documentation'),'tab above.',
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
            'More Documentation',
            titlePanel('Application Documentation and Background'),
            br(),
            'Each year, the United States Bureau of Labor Statistics (BLS) makes available',
            'scores of GB of data on occupational injuries.',
            'The data is available at',
            tags$a(href='http://download.bls.gov/pub/time.series/cs',target='_blank','download.bls.gov/pub/time.series/cs'),
            'and data documentation',
            'is available in the file cs.txt at that location. Even more documentation is at',
            tags$a(href='http://www.bls.gov/iif/oiics_manual_2010.pdf',target='_blank','www.bls.gov/iif/oiics_manual_2010.pdf'),
            '. Briefly, injury series are recorded with many',
            'dimensions such as year(s), age (range), and industry, to name a few.',
            br(),br(),
            'This application lets the user explore injuries by year for a chosen industry',
            'or industry group. The application',
            'displays a plot of the chosen data to help elucidate the trend in the chosen data.',
            'To make the trend clear, the plot shows both the actual BLS data and a linear prediction',
            'for the years following those available in the BLS data.',
            'The actual BLS injury series counts are in black and the predicted injury series counts are in red.',
            br(),br(),
            'There are two user controls. The first is a text entry box that lets the user choose how',
            'many years forward to predict.',
            'The supported number of years to predict is between 1 and 9 inclusive.',
            'The second lets the user choose a focus industry',
            'or industry group by walking',
            'a hierarchy that starts with all injured workers and gets more specific as the user',
            tags$i('walks'),'towards',
            'the leaves of the industry hierarchy tree.',
            br(),br(),
            'The industry hierarchy tree can be opened or closed by clicking on the triangle to left of each industry (category).',
            'The user indicates a selection for plotting by clicking on the text of the industry (group) itself.',
            'To provide adequate performance to the user, the depth of the industry hierarchy has been',
            'limited and the summary counts have been precalculated by year and industry.',
            br(),br(),
            'When walking the tree, the user can click a white triangle to open its',
            'respective node and view deeper hierarchy levels. When',
            'a node is open, click the black triangle to close it.',
            'Nodes without triangles have no deeper hierarchy levels.',
            'These are leaf nodes and may correspond to an industry or a BLS grouping of',
            'of industries. The non leaf nodes always correspond to industry groups.',
            br(),br(),
            '(Left) click on the', tags$b('Injury Predictions by Industry'),'tab in the upper left to return to the application.',
            br(),br(),
            'The source code for this application is available for review at that',
            tags$a(href='https://github.com/WatHughes/CP_Shiny',target='_blank','GitHub Repo'),
            'for this application.',
            br(),br(),
            'To calculate the predictions, first the selected data points (specified by',
            'the tree control)',
            "are fed to R's lm()",
            'function. The resulting model is then fed to predict() along with the list of years',
            'that the user specified (indirectly, with the text input control).',
            br(),br()
        ), # tabPanel
        conditionalPanel
        (
            condition='false',
            tabPanel
            (
                'RStudio Default Application',
                # Application title
                titlePanel('Old Faithful Geyser Data'),

                # Sidebar with a slider input for number of bins
                sidebarLayout
                (
                    sidebarPanel
                    (
                        sliderInput('bins',
                        'Number of bins:',
                        min = 1,
                        max = 50,
                        value = 30)
                    ),
                    # Show a plot of the generated distribution
                    mainPanel
                    (
                        plotOutput('distPlot')
                    )
                )
            ) # tabPanel
        ) # conditionalPanel
    ) # tabsetPanel
)) # shinyUI(fluidPage

