shinyServer(function(input, output, session) {
	source("Login.R",  local = TRUE)

	getResults <- reactive({
		results <- data.frame()
		if(USER$Role %in% c('ROLE_ADMIN', 'ROLE_ADVISOR')) {
			results <- getUserResults(input$userSearch)
		} else {
			results <- getUserResults(USER$Username) # TODO: use search box if admin
		}
		if(nrow(results) > 0) {
			results$takenDate <- as.POSIXct(results$takenDate, origin = '1970-01-01')
			results$completionDate <- as.POSIXct(results$completionDate, origin = '1970-01-01')
			results <- results[order(results$takenDate, decreasing = TRUE),]
		}
		return(results)
	})

	getUserEvents <- reactive({
		userid <- ''
		if(USER$Role %in% c('ROLE_ADMIN', 'ROLE_ADVISOR')) {
			user <- getUser(input$userSearch)
		} else {
			user <- getUser(USER$Username)
		}
		userid <- user[1,]$`_id`
		event_containers.fields = c('_id', 'userEvents', 'version')
		f <- paste0("{", paste0('"', event_containers.fields, '":',
								1:length(event_containers.fields), collapse = ', '), "}")
		user.events <- m.events$find(paste0('{"_id":{"$oid":"', userid, '"}}'), field = f)
		return(user.events)
	})

	output$dashboard.user <- renderUI({
		if(USER$Logged) {
			results <- getResults()
			name <- paste0('Student: ', results[nrow(results),]$firstName, ' ',
						   results[nrow(results),]$lastName)
			userId <- results[1,]$userId
			link <- paste0(daacs.base.url, '/dashboard?userId=', userId)
			link <- paste0("<a href='", link, "' target='daacs' style='color:black'>View results in DAACS</a>")
			sidebarUserPanel(strong(h5(name)), subtitle = HTML(link))
		} else {
			return()
		}
	})

	output$dashboard.search <- renderUI({
		if(USER$Role %in% c('ROLE_ADMIN', 'ROLE_ADVISOR')) {
			# sidebarSearchForm(textId = "searchText", buttonId = "searchButton",
			#  				  label = "Search...")
			users <- getUsers()
			# selectizeInput('searchText', label = 'Search',
			# 			   choices = users$username,
			# 			   multiple = FALSE)
			value <- ''
			selectedRow <- input$userDT_rows_selected
			if(!is.null(selectedRow)) {
				users <- getUsers()
				value <- users[selectedRow,]$username
			}
			typeaheadInput('userSearch', 'Student search...', value = value,
						   choices = users$username)
		}
	})

	output$dashboard.sidebar <- renderMenu({
		if(USER$Logged) {
			results <- getResults()

			panels <- list()

			panels[['id']] <- 'tabs'

			panels[[length(panels) + 1]] <- menuItem("Overview", tabName = 'overview', selected = TRUE)

			if(sum(results$assessmentCategory == 'COLLEGE_SKILLS') > 0) {
				panels[[length(panels) + 1]] <- menuItem("SRL", tabName = "srl")
			}
			if(sum(results$assessmentCategory == 'MATHEMATICS') > 0) {
				panels[[length(panels) + 1]] <- menuItem("Mathematics", tabName = "mathematics")
			}
			if(sum(results$assessmentCategory == 'READING') > 0) {
				panels[[length(panels) + 1]] <- menuItem("Reading", tabName = "reading")
			}
			if(sum(results$assessmentCategory == 'WRITING') > 0) {
				panels[[length(panels) + 1]] <- menuItem("Writing", tabName = "writing")
			}
			if(USER$Role %in% c('ROLE_ADMIN')) {
				panels[[length(panels) + 1]] <- menuItem("Admin", tabName = 'admin')
			}

			panel <- do.call(sidebarMenu, args = panels)
		} else {
			panel <- sidebarMenu(id = 'tabs',
				 menuItem('Login', tabName = 'login', selected = TRUE)
			)
		}
		return(panel)
	})

	output$dashboard.body <- renderUI({
		if(USER$Logged) {
			panel <- tabItems(
				tabItem("overview", uiOutput('overviewTab')),
				tabItem('srl', uiOutput('srlTab')),
				tabItem('mathematics', uiOutput('mathTab')),
				tabItem('reading', uiOutput('readTab')),
				tabItem('writing', uiOutput('writingTab')),
				tabItem('admin', uiOutput('adminTab'))
			)
		} else {
			panel <- tabItem("login",
							 fluidRow(
							 	column(width=3),
							 	column(width=6,
							 		   div(id = format(Sys.time(), '%Y%m%d%H%M%S'),
							 		   	class = "login",
							 		   	uiOutput("uiLogin"),
							 		   	textOutput("pass")) ),
							 	column(width=3) ) )
		}
		return(panel)
	})

	##### Overview Tab #########################################################
	source('tab_overview.R', local = TRUE)

	##### SRL ##################################################################
	source('tab_srl.R', local = TRUE)

	##### Writing ##############################################################
	source('tab_writing.R', local = TRUE)

	##### Mathematics ##########################################################
	source('tab_mathematics.R', local = TRUE)

	##### Reading ##############################################################
	source('tab_reading.R', local = TRUE)

	##### Administration #######################################################
	source('tab_admin.R', local = TRUE)

})
