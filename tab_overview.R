output$overviewTab <- renderUI({mainPanel(width = 12,
	# {if(USER$Role == 'ROLE_ADMIN') {
	# 	sidebarSearchForm(textId = "student",
	# 					  buttonId = "searchButton",
	# 					  label = "Search...")
	# }},
	# h3(textOutput('name')),
	# h6(htmlOutput('daacsLink')),
	fluidRow(
	  column(gaugeOutput('srlResult.gauge', height = '150px'), width = 3),
	  column(gaugeOutput('mathResult.gauge', height = '150px'), width = 3),
	  column(gaugeOutput('readingResult.gauge', height = '150px'), width = 3),
	  column(gaugeOutput('writingResult.gauge', height = '150px'), width = 3)
	),
	box(title = 'Challenges', width = 12, tableOutput('challenges')),
	box(title = 'Strengths', width = 12, tableOutput('strengths'))
)})

output$srlResult.gauge <- renderGauge({
	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]
	srl <- srl[srl$status == 'GRADED',]
	overall.score <- NA
	score <- NA
	if(nrow(srl) > 1) {
		scores <- getStudentResponses(srl, 1)
		score <- round( 100 * sum(scores$score) / (nrow(scores) * 4) )
		overall.score <- srl[1,]$overallScore
	}
	gauge(value = score, min = 0, max = 100, symbol = '%', label = 'SRL',
		  sectors = gaugeSectors(success = c(80, 100), warning = c(40, 80), danger = c(0, 40)))
})

output$srlResult <- renderValueBox({
	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]
	score <- NA
	if(nrow(srl) > 1) {
		score <- srl[1,]$overallScore
	}
	valueBox(value = "SRL",
			 subtitle = scoreLabel(score),
			 icon = icon("compass"),
			 width = 3,
			 color = scoreColor(score))
})

output$mathResult.gauge <- renderGauge({
	results <- getResults()
	math <- results[results$assessmentCategory == 'MATHEMATICS',]
	math <- math[math$status == 'GRADED',]
	score <- NA
	if(nrow(math) > 1) {
		scores <- getStudentResponses(math, 1)
		score <- round( 100 * sum(scores$score) / nrow(scores) )
		overall.score <- math[1,]$overallScore
	}
	gauge(value = score, min = 0, max = 100, symbol = '%', label = 'Math',
		  sectors = gaugeSectors(success = c(85, 100), warning = c(65, 85), danger = c(0, 65)))
})

output$mathResult <- renderValueBox({
	results <- getResults()
	math <- results[results$assessmentCategory == 'MATHEMATICS',]
	score <- NA
	if(nrow(math) > 1) {
		score <- math[1,]$overallScore
	}
	shinydashboard::valueBox(value = "Math",
							 subtitle = scoreLabel(score),
							 icon = icon("compass"),
							 width = 3,
							 color = scoreColor(score))
})

output$readingResult.gauge <- renderGauge({
	results <- getResults()
	reading <- results[results$assessmentCategory == 'READING',]
	reading <- reading[reading$status == 'GRADED',]
	score <- NA
	if(nrow(reading) > 1) {
		scores <- getStudentResponses(reading, 1)
		score <- round( 100 * sum(scores$score) / nrow(scores) )
		overall.score <- reading[1,]$overallScore
	}
	gauge(value = score, min = 0, max = 100, symbol = '%', label = 'Reading',
		  sectors = gaugeSectors(success = c(85, 100), warning = c(65, 85), danger = c(0, 65)))
})

output$readingResult <- renderValueBox({
	results <- getResults()
	reading <- results[results$assessmentCategory == 'READING',]
	score <- NA
	if(nrow(reading) > 1) {
		score <- reading[1,]$overallScore
	}
	shinydashboard::valueBox(value = "Reading",
							 subtitle = scoreLabel(score),
							 icon = icon("compass"),
							 width = 3,
							 color = scoreColor(score))
})

output$writingResult.gauge <- renderGauge({
	results <- getResults()
	writing <- results[results$assessmentCategory == 'WRITING',]
	writing <- writing[writing$status == 'GRADED',]
	score <- NA
	if(nrow(writing) > 1) {
		scores <- data.frame()
		domainScores <- writing[1,]$domainScores[[1]]
		for(i in 1:nrow(domainScores)) {
			if(!is.null(domainScores[i,]$subDomainScores) &
						nrow(domainScores[i,]$subDomainScores[[1]]) > 0 ) {
				scores <- rbind(scores,
								domainScores[i,]$subDomainScores[[1]][,c('domainId','rubricScore')],
								stringsAsFactors = FALSE)
			} else {
				scores <- rbind(scores,
								domainScores[i,c('domainId', 'rubricScore')],
								stringsAsFactors = FALSE)
			}
		}
		scores$rubricScore <- factor(scores$rubricScore,
									 levels = c('LOW', 'MEDIUM', 'HIGH'), ordered = TRUE)
		score <- round(100 * sum(as.integer(scores$rubricScore) - 1) / (nrow(scores) * 2))
	}
	gauge(value = score, min = 0, max = 100, symbol = '%', label = 'Writing',
		  sectors = gaugeSectors(success = c(85, 100), warning = c(65, 85), danger = c(0, 65)))
})

output$writingResult <- renderValueBox({
	results <- getResults()
	writing <- results[results$assessmentCategory == 'WRITING',]
	score <- NA
	if(nrow(writing) > 1) {
		score <- writing[1,]$overallScore
	}
	shinydashboard::valueBox(value = "Writing",
							 subtitle = scoreLabel(score),
							 icon = icon("compass"),
							 width = 3,
							 color = scoreColor(score))
})

output$challenges <- renderTable({
	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]
	srl <- srl[srl$status == 'GRADED',]
	srl.items <- getStudentResponses(srl, nrow(srl))

	srl.domains <- describeBy(srl.items$score, group = srl.items$domain, mat = TRUE, skew = FALSE)
	srl.domains <- srl.domains[,c('group1','mean')]
	srl.domains <- srl.domains[srl.domains$group1 %in% guide$Domain,]
	srl.domains <- srl.domains[order(srl.domains$mean),]

	guide[guide$Domain %in% srl.domains[1:2,]$group1, c('Challenge','Strategies','Resources')]
})

output$strengths <- renderTable({
	results <- getResults()
	srl <- results[results$assessmentCategory == 'COLLEGE_SKILLS',]
	srl <- srl[srl$status == 'GRADED',]
	srl.items <- getStudentResponses(srl, nrow(srl))

	srl.domains <- describeBy(srl.items$score, group = srl.items$domain, mat = TRUE, skew = FALSE)
	srl.domains <- srl.domains[,c('group1','mean')]
	srl.domains <- srl.domains[srl.domains$group1 %in% guide$Domain,]
	srl.domains <- srl.domains[order(srl.domains$mean),]

	guide[guide$Domain %in% srl.domains[nrow(srl.domains):(nrow(srl.domains)-1),]$group1,
		  c('Strength','Strategies','Resources')]
})

output$name <- renderText({
	results <- getResults()
	paste0('Student: ', results[nrow(results),]$firstName, ' ', results[nrow(results),]$lastName)
})

output$daacsLink <- renderText({
	userId <- getResults()[1,]$userId
	link <- paste0(daacs.base.url, '/dashboard?userId=', userId)
	return(paste0("<a href='", link, "' target='daacs'>Click here to view results in DAACS</a>"))
})
