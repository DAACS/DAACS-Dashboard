output$institutionTab <- renderUI({
	# results <- getResults()
	# if(nrow(results) == 0) {
	# 	return(mainPanel(p("No DAACS results found.")))
	# }
	#
	# fluidRow(column(width = 12,
	# 	fluidRow(
	# 	  column(gaugeOutput('srlResult.gauge', height = '150px'), width = 3),
	# 	  column(gaugeOutput('mathResult.gauge', height = '150px'), width = 3),
	# 	  column(gaugeOutput('readingResult.gauge', height = '150px'), width = 3),
	# 	  column(gaugeOutput('writingResult.gauge', height = '150px'), width = 3)
	# 	),
	# 	box(title = 'Challenges', width = 12, tableOutput('challenges')),
	# 	box(title = 'Strengths', width = 12, tableOutput('strengths')),
	# 	box(width = 12, plotOutput('userCalendar'))
	# )
	# )
})

