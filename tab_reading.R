output$readTab <- renderUI({
	results <- getResults()
	read <- results[results$assessmentCategory == 'READING',]

	if(nrow(read) == 0) {
		return(mainPanel(p("No reading assessments have been completed.")))
	}

	fluidRow(column(width = 12,
			  fluidRow(
			  	column(4, uiOutput('readTakenDate')),
			  	column(4, uiOutput('readPassages')),
			  	column(4, uiOutput('readDomain'))
			  ),
			  tabsetPanel(
			  	tabPanel('Results', plotOutput('readPlot')),
			  	tabPanel('Passage', htmlOutput('readPassage', inline = TRUE)),
			  	tabPanel('Resources', htmlOutput('readFeedback'))
			  )
	))
})

output$readTakenDate <- renderUI({
	results <- getResults()
	read <- results[results$assessmentCategory == 'READING',]
	read <- read[order(read$takenDate, decreasing = TRUE),]
	completions <- seq_len(nrow(read))
	names(completions) <- format(read$takenDate, format = '%B %d, %Y, %H:%M')
	selectInput('readTakenDate', label = 'Completion', choices = completions)
})

output$readDomain <- renderUI({
	results <- getResults()
	read <- results[results$assessmentCategory == 'READING',]
	read <- read[order(read$takenDate, decreasing = TRUE),]
	read.result <- read[as.integer(input$readTakenDate), ]

	if(nrow(read.result) == 0) { return() }

	domain.scores <- read.result$domainScores[[1]]
	domains <- c('All', domain.scores$domainId)

	selectInput('readDomain', label = 'Reading Domain', choices = domains)
})

output$readPassages <- renderUI({
	req(input$readTakenDate)
	results <- getResults()
	read <- results[results$assessmentCategory == 'READING',]
	read <- read[order(read$takenDate, decreasing = TRUE),]
	read.result <- read[as.integer(input$readTakenDate), ]
	nPassages <- nrow(read.result$itemGroups[[1]])
	choices <- seq_len(nPassages)
	names(choices) <- paste0('Passage ', seq_len(nPassages))
	selectInput('readPassage', label = 'Passage', choices = choices)
})

output$readPassage <- renderText({
	req(input$readPassage)
	results <- getResults()
	read <- results[results$assessmentCategory == 'READING',]
	read <- read[order(read$takenDate, decreasing = TRUE),]
	read.result <- read[as.integer(input$readTakenDate), ]
	passage <- read.result$itemGroups[[1]]$items[[as.integer(input$readPassage)]]$itemContent$question[1,2]
	# TODO: need to format with line numbers like in DAACS
	passage <- gsub('\n', '<br />', passage)
	return(passage)
})

output$readPlot <- renderPlot({
	req(input$readDomain)

	results <- getResults()
	read <- results[results$assessmentCategory == 'READING',]
	read <- read[order(read$takenDate, decreasing = TRUE),]
	read.result <- read[as.integer(input$readTakenDate), ]

	if(nrow(read.result) == 0) { return() }

	domain.scores <- read.result$domainScores[[1]]
	domain.scores$rubricScore <- factor(domain.scores$rubricScore,
										levels = c('LOW', 'MEDIUM', 'HIGH'),
										labels = c('Developing', 'Emerging', 'Mastering'))

	ggplot(domain.scores, aes(x = domainId, y = rawScore, color = rubricScore)) +
		geom_point(size = 4) +
		coord_flip() +
		xlab('') + ylab('Mean') +
		ylim(c(0, 1)) +
		scale_color_manual('Student Score',
						   values = c('red', 'orange', 'green'),
						   limits = c('Developing', 'Emerging', 'Mastering'),
						   na.value = 'grey') +
		theme_minimal() +
		theme(axis.text.y = element_text(size=12))
})

output$readFeedback <- renderText({
	if(input$readDomain == 'All') {
		thefile <- paste0('resources/reading/all.md')
	} else {
		thefile <- paste0('resources/reading/', input$readDomain, '.md')
	}
	markdownToHTML(file = thefile, options = c('fragment_only'))
})
