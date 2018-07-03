output$mathTab <- renderUI({
	results <- getResults()
	math <- results[results$assessmentCategory == 'MATHEMATICS',]

	if(nrow(math) == 0) {
		return(mainPanel(p("No mathematics assessments have been completed.")))
	}

	fluidRow(column(width = 12,
			  fluidRow(
			  	column(6, uiOutput('mathTakenDate')),
			  	column(6, uiOutput('mathDomain'))
			  ),
			  tabsetPanel(
			  	tabPanel('Results', plotOutput('mathPlot')),
			  	tabPanel('Resources', htmlOutput('mathFeedback'))
			  )
	))
})

output$mathTakenDate <- renderUI({
	results <- getResults()
	math <- results[results$assessmentCategory == 'MATHEMATICS',]
	math <- math[order(math$takenDate, decreasing = TRUE),]
	completions <- seq_len(nrow(math))
	names(completions) <- format(math$takenDate, format = '%B %d, %Y, %H:%M')
	selectInput('mathTakenDate', label = 'Completion', choices = completions)
})

output$mathDomain <- renderUI({
	results <- getResults()
	math <- results[results$assessmentCategory == 'MATHEMATICS',]
	math <- math[order(math$takenDate, decreasing = TRUE),]
	math.result <- math[as.integer(input$mathTakenDate), ]

	if(nrow(math.result) == 0) { return() }

	domain.scores <- math.result$domainScores[[1]]
	domains <- c('All', domain.scores$domainId)

	selectInput('mathDomain', label = 'Mathematics Domain', choices = domains)
})

output$mathPlot <- renderPlot({
	req(input$mathDomain)

	results <- getResults()
	math <- results[results$assessmentCategory == 'MATHEMATICS',]
	math <- math[order(math$takenDate, decreasing = TRUE),]
	math.result <- math[as.integer(input$mathTakenDate), ]

	if(nrow(math.result) == 0) { return() }

	domain.scores <- math.result$domainScores[[1]]
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

output$mathFeedback <- renderText({
	if(input$mathDomain == 'All') {
		thefile <- paste0('resources/mathematics/all.md')
	} else {
		thefile <- paste0('resources/mathematics/', input$mathDomain, '.md')
	}
	markdownToHTML(file = thefile, options = c('fragment_only'))
})
