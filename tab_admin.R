output$adminTab <- renderUI({
	if(USER$Role %in% c('ROLE_ADMIN', 'ROLE_ADVISOR')) {
		fluidRow(column(12,
						DT::dataTableOutput('userDT')))
	}
})

output$userDT <- DT::renderDataTable({
	users <- getUsers()
	return(users[,c('username', 'firstName', 'lastName', 'createdDate', 'hasDataUsageConsent')])
}, server = TRUE, selection='single', rownames=FALSE)

