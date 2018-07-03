output$writingTab <- renderUI({
	results <- getResults()
	writing <- results[results$assessmentCategory == 'WRITING' &
					   	results$status == 'GRADED',]

	if(nrow(writing) == 0) {
		return(mainPanel(p("No writing assessments have been completed.")))
	}

	fluidRow(column(width = 12,
			  fluidRow(
			  	column(6, uiOutput('writingTakenDate')),
			  	column(6, uiOutput('writingDomain'))
			  ),
			  tabsetPanel(
			  	tabPanel('Rubric', htmlOutput('writingRubric')),
			  	tabPanel('Essay', htmlOutput('writingEssay')),
			  	tabPanel('Resources', htmlOutput('writingFeedback'))
			  )
	))
})

output$writingDomain <- renderUI({
	results <- getResults()
	writing <- results[results$assessmentCategory == 'WRITING' &
					   	results$status == 'GRADED',]
	writing <- writing[order(writing$takenDate, decreasing = TRUE),]
	writing.result <- writing[as.integer(input$writingTakenDate), ]

	if(nrow(writing.result) == 0) { return() }

	domain.scores <- data.frame()
	for(i in 1:nrow(writing.result$domainScores[[1]])) {
		if(nrow(writing.result$domainScores[[1]][i,]$subDomainScores[[1]]) == 0) {
			domain.scores <- rbind(domain.scores,
								   writing.result$domainScores[[1]][i,c('domainId', 'rubricScore')])
		} else {
			domain.scores <- rbind(domain.scores,
								   writing.result$domainScores[[1]][i,]$subDomainScores[[1]][,c('domainId', 'rubricScore')])
		}
	}

	domains <- c('All', domain.scores$domainId)

	selectInput('writingDomain', label = 'Writing Domain', choices = domains)
})

output$writingTakenDate <- renderUI({
	results <- getResults()
	writing <- results[results$assessmentCategory == 'WRITING' &
					   	results$status == 'GRADED',]
	writing <- writing[order(writing$takenDate, decreasing = TRUE),]
	completions <- seq_len(nrow(writing))
	names(completions) <- format(writing$takenDate, format = '%B %d, %Y, %H:%M')
	selectInput('writingTakenDate', label = 'Completion', choices = completions)
})

output$writingRubric <- renderUI({
	req(input$writingDomain)

	results <- getResults()
	writing <- results[results$assessmentCategory == 'WRITING' &
					   	results$status == 'GRADED',]
	writing <- writing[order(writing$takenDate, decreasing = TRUE),]
	writing.result <- writing[as.integer(input$writingTakenDate), ]

	if(nrow(writing.result) == 0) { return() }

	domain.scores <- data.frame()
	for(i in 1:nrow(writing.result$domainScores[[1]])) {
		if(nrow(writing.result$domainScores[[1]][i,]$subDomainScores[[1]]) == 0) {
			domain.scores <- rbind(domain.scores,
								   writing.result$domainScores[[1]][i,c('domainId', 'rubricScore')])
		} else {
			domain.scores <- rbind(domain.scores,
								   writing.result$domainScores[[1]][i,]$subDomainScores[[1]][,c('domainId', 'rubricScore')])
		}
	}
	domain.scores$rubricScore <- as.character(
		factor(domain.scores$rubricScore,
			   labels = c('Developing', 'Emerging', 'Mastering'),
			   levels = c('LOW', 'MEDIUM', 'HIGH')))

	student.rubric <- writing.rubric
	row.names(student.rubric) <- student.rubric$SubCriteria
	student.rubric <- student.rubric[,2:ncol(student.rubric)]
	for(i in seq_len(nrow(domain.scores))) {
		student.rubric[domain.scores[i,]$domainId, domain.scores[i,]$rubricScore] <- paste0(
			student.rubric[domain.scores[i,]$domainId, domain.scores[i,]$rubricScore],
			' #bgyellow'
		)
	}
	student.rubric$SubCriteria <- NULL

	if(input$writingDomain != 'All') {
		student.rubric <- student.rubric[input$writingDomain,]
	}

	htmltab <- markdownToHTML(
		text = pandoc.table.return(
			student.rubric, style="rmarkdown", split.tables=Inf
		),
		fragment.only=TRUE
	)
	colortable(htmltab, css)
})

output$writingEssay <- renderText({
	results <- getResults()
	writing <- results[results$assessmentCategory == 'WRITING' &
					   	results$status == 'GRADED',]
	writing <- writing[order(writing$takenDate, decreasing = TRUE),]
	writing.result <- writing[as.integer(input$writingTakenDate), ]
	essay <- writing.result$writingPrompt$sample
	essay <- gsub('\n', '<br />', essay)
	essay <- paste0('Scoring Type: ', writing.result$scoringType, '<br /><br />', essay)
	return(essay)
})

output$writingFeedback <- renderText({
	if(input$writingDomain == 'All') {
		thefile <- paste0('resources/writing/all.md')
	} else {
		thefile <- paste0('resources/writing/', input$writingDomain, '.md')
	}
	markdownToHTML(file = thefile, options = c('fragment_only'))
})
