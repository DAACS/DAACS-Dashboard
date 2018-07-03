output$srlTab <- renderUI({
	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]

	if(nrow(srl) == 0) {
		return(mainPanel(p("No self-regulated learning assessments have been completed.")))
	}

	fluidRow(column(width = 12,
			  fluidRow(
			  	column(6, uiOutput('srlTakenDate')),
			  	column(6, uiOutput('srlDomain'))
			  ),
			  tabsetPanel(
			  	tabPanel('Results', plotOutput('srlPlot')),
			  	tabPanel('Resources', htmlOutput('srlFeedback'))
			  )
	))
})

output$srlTakenDate <- renderUI({
	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]
	srl <- srl[order(srl$takenDate, decreasing = TRUE),]
	completions <- seq_len(nrow(srl))
	names(completions) <- format(srl$takenDate, format = '%B %d, %Y, %H:%M')
	selectInput('srlTakenDate', label = 'Completion', choices = completions)
})

output$srlDomain <- renderUI({
	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]
	srl <- srl[order(srl$takenDate, decreasing = TRUE),]
	srl.result <- srl[as.integer(input$srlTakenDate), ]

	domains <- c('All')

	if(nrow(srl.result) > 0) {
		tmp <- lapply(srl.result$domainScores[[1]]$subDomainScores, FUN = function(x) {
			return(x[,c('domainId', 'rubricScore')])
		})
		domain.scores <- data.frame()
		for(i in seq_along(tmp)) {
			domain.scores <- rbind(domain.scores, tmp[[i]])
		}

		domains <- c(domains, domain.scores$domainId)
	}

	selectInput('srlDomain', label = 'SRL Domain', choices = domains)
})

output$srlLongitudinalPlot <- renderPlot({
	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]

	if(nrow(srl) < 2) { return() }

	scores <- data.frame()
	for(i in seq_len(nrow(srl))) {
		items <- getStudentResponses(srl, i)
		items <- aggregate(items$score, by = list(items$domain), FUN = mean)
		items$date <- srl[i,]$takenDate
		scores <- rbind(scores, items)
	}
	names(scores) <- c('Domain', 'Mean', 'Date')

	if(input$Domain == All) {

	} else {
		ggplot(scores, aes(x = Date, y = Mean, group = Domain)) +
			geom_path() +
			facet_wrap(~ Domain)
	}
})

output$srlPlot <- renderPlot({
	req(input$srlDomain)

	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]
	srl <- srl[order(srl$takenDate, decreasing = TRUE),]
	srl.result <- srl[as.integer(input$srlTakenDate), ]

	if(nrow(srl.result) == 0) { return() }

	tmp <- lapply(srl.result$domainScores[[1]]$subDomainScores, FUN = function(x) {
		return(x[,c('domainId', 'rubricScore')])
	})
	domain.scores <- data.frame()
	for(i in seq_along(tmp)) {
		domain.scores <- rbind(domain.scores, tmp[[i]])
	}
	domain.scores$rubricScore <- factor(domain.scores$rubricScore,
										levels = c('LOW', 'MEDIUM', 'HIGH'),
										labels = c('Developing', 'Emerging', 'Mastering'))

	items <- getStudentResponses(srl.result, 1)

	if(input$srlDomain == 'All') {
		tab <- describeBy(items$score, group = items$domain, mat = TRUE, skew = FALSE)
		tab <- merge(tab, domain.scores, all.x = TRUE,
					 by.x = 'group1', by.y = 'domainId')

		ggplot(tab, aes(x = group1, y = mean, color = rubricScore)) +
			geom_point(size = 4) +
			coord_flip() +
			xlab('') + ylab('Mean Response') +
			ylim(c(0, 4)) +
			scale_color_manual('Student Score',
							   values = c('red', 'orange', 'green'),
							   limits = c('Developing', 'Emerging', 'Mastering'),
							   na.value = 'grey') +
			theme_minimal() +
			theme(axis.text.y = element_text(size=12))
	} else {
		items <- items[items$domain == input$srlDomain,]
		items$hjust <- ifelse(items$score > 2, 1.2, -0.2)
		ggplot(items, aes(x = question, y = score, label = answer)) +
			geom_point(size = 4) +
			geom_text(aes(hjust = hjust)) +
			coord_flip() +
			scale_x_discrete(labels = function(x) str_wrap(x, width = 30)) +
			# scale_color_gradient(low = 'red', high = 'green') +
			ylim(c(0, 4)) +
			xlab('') + ylab('Response') +
			theme_minimal() +
			theme(axis.text.y = element_text(size=12))
	}
})

output$srlFeedback <- renderText({
	req(input$srlDomain)
	if(input$srlDomain == 'All') {
		thefile <- paste0('resources/srl/all.md')
	} else {
		thefile <- paste0('resources/srl/', input$srlDomain, '.md')
	}
	markdownToHTML(file = thefile, options = c('fragment_only'))
})
