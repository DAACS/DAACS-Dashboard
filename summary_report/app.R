library(shiny)
library(shinyjs)
library(shinyWidgets)
library(mongolite)
library(rmarkdown)
# library(shinycookie) # remotes::install_github("colearendt/shinycookie")

source('../config.R')

# Test ID: my:   586d5bdee4b0a08f591fbf87
#          UMGC: 62fcdd19409ae41ba6ed9fec
# https://my.daacs.net/summaryreport/?userid=586d5bdee4b0a08f591fbf87
# https://umgc.daacs.net/summaryreport/?userid=62fcdd19409ae41ba6ed9fec

user_fields <- c('_id', 'username',
                 'firstName', 'lastName',
                 'assessmentType', 'assessmentCategory', 'assessmentLabel',
                 'createdDate')
user_fields <- paste0("{", paste0('"', user_fields, '":', 1:length(user_fields), collapse = ', '), "}")


ui <- shiny::fluidPage(
    shinyjs::useShinyjs(),
    # shinycookie::initShinyCookie("myid"),
    # p(strong("URL Parameters: "), shiny::textOutput('url_parameters')),
    conditionalPanel(
        "false", # always hide the download button
        downloadButton("downloadData")
    ),
    actionButton("check", "Download Summary Report")
)

server <- function(input, output, session) {
    getUserId <- reactive({
        query <- shiny::parseQueryString(session$clientData$url_search)
        names(query) <- tolower(names(query))
        return(query[['userid']])
    })

    getUserData <- reactive({
        source('../config.R', local = TRUE)
        URI <- paste0('mongodb://', mongo.user, ':', mongo.pass, '@',
                      mongo.host, ':', mongo.port, '/', mongo.db)
        m.users <- mongo(url = URI,
                         collection = mongo.collection.users)
        # userId <- '586d5bdee4b0a08f591fbf87'
        userId <- getUserId()
        if(is.null(userId)) {
            return(NULL)
        }
        user <- m.users$find(paste0('{"_id":"', userId, '"}'), fields = user_fields)
        if(nrow(user) == 0) {
            user <- m.users$find(paste0('{"_id":{"$oid":"', userId, '"}}'), fields = user_fields)
        }
        if(nrow(user) == 0) {
            return(NULL)
        }
        return(user)
    })

    getUsername <- reactive({
        username <- NULL
        user <- getUserData()
        if(!is.null(user)) {
            username <- user[1,]$username
        }
        return(username)
    })

    getName <- reactive({
        name <- NULL
        user <- getUserData()
        if(!is.null(user)) {
            name <- paste0(user[1,]$firstName, '_', user[1,]$lastName)
        }
        return(name)
    })

    output$url_parameters <- shiny::renderText({
        query <- shiny::parseQueryString(session$clientData$url_search)
        return(unlist(query))
    })

    observeEvent(input$check, {
        username <- getUsername()

        if(!is.null(username)) {
            runjs("$('#downloadData')[0].click();")
        } else {
            shinyWidgets::sendSweetAlert(
                session,
                title = 'DAACS Summary Report',
                text = paste0('A DAACS summary report could not be found for ',
                              ". Please email admin@daacs.net ",
                              ' if you think this is an error.'),
                html = TRUE)
        }
    })

    output$downloadData <- shiny::downloadHandler(
        filename = function() {
            paste0('DAACS_', getName(), '.pdf')
        },
        content = function(file) {
            showModal(modalDialog("Generating your summary report. Please wait...", footer = NULL))
            on.exit(removeModal())

            config.file <- 'config.R'
            username <- getUsername()
            name <- getName()
            outfile <- paste0('DAACS_', name, '.pdf')
            outdir <- 'generated/'

            rmarkdown::render(paste0('summary_report/', report_rmd_file),
                              output_dir = outdir,
                              output_file = outfile,
                              params = list(user = username,
                                            config = paste0('../../', config.file),
                                            tips_rmd = tips_rmd_file),
                              output_format = 'pdf_document',
                              runtime = 'static',
                              run_pandoc = TRUE,
                              clean = TRUE,
                              quiet = TRUE)
            rawfile <- readBin(
                con = paste0(outdir, outfile),
                what = "raw",
                n = file.info(paste0(outdir, outfile))[, "size"])
            writeBin(rawfile, con = file)
        }
    )

    runjs("$('#check')[0].click();")
}

shiny::shinyApp(ui = ui, server = server)
