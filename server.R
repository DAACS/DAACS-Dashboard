function(input, output, session) {
	# hack to add the logout button to the navbar on app launch
	insertUI(
		selector = ".navbar .container-fluid .navbar-collapse",
		ui = tags$ul(
			class="nav navbar-nav navbar-right",
			tags$li(
				div(
					style = "padding: 10px; padding-top: 8px; padding-bottom: 0;",
					shinyauthr::logoutUI("logout", class = 'btn-info')
				)
			)
		)
	)

	##### Database functions ###################################################
	get_db_connection <- reactive({
		URI <- paste0('mongodb://', mongo.user, ':', mongo.pass, '@',
					  mongo.host, ':', mongo.port, '/', mongo.db)
		return(URI)
	})

	get_users <- reactive({
		URI <- get_db_connection()
		m.users <- mongo(url = URI, collection = mongo.collection.users)
		users <- m.users$find(fields = user_fields)
		users$roles <- sapply(users$roles, FUN = function(x) { x[[1]] })
		return(users)
	})

	get_admins <- reactive({
		users <- get_users()
		admins <- users |> filter(roles %in% c('ROLE_ADMIN'))
		return(admins)
	})

	get_assessments <- reactive({
		URI <- get_db_connection()
		m.assmts <- mongo(url = URI, collection = mongo.collection.assessments)
		assmts <- m.assmts$find(fields = assessment_fields)
		return(assmts)
	})

	get_events <- reactive({
		URI <- get_db_connection()
		m.events <- mongo(url = URI, collection = mongo.collection.events)
		events <- m.events$find()
		tmp <- (lapply(events$userEvents, FUN = function(x) {
			x2 <- x[,c('eventType','timestamp')]
			# x2x2$url <- sapply(x$eventData, FUN = function(x) { x['url']})
			x2
		}))
		tmp <- do.call('rbind', tmp)
		return(tmp)
	})

	##### Info Boxes ###########################################################
	output$unscored_assessments <- renderInfoBox({
		assmts <- get_assessments() |>
			filter(status == 'GRADING_FAILURE')
		color <- 'green'
		if(nrow(assmts) > 10) {
			color = 'red'
		} else if(nrow(assmts) > 0) {
			color = 'yellow'
		}
		infoBox(title = 'Ungraded Assessments',
				value = nrow(assmts),
				color = color,
				fill = TRUE,
				icon = icon('circle-exclamation'))
	})

	output$info_users <- renderInfoBox({
		students <- get_users() |> filter(roles == 'ROLE_STUDENT')
		infoBox(title = "Registered Students",
				value = nrow(students),
				color = 'purple',
				fill = TRUE,
				icon = icon('graduation-cap'))
	})

	output$completed_assessments <- renderInfoBox({
		assmts <- get_assessments() |>
			filter(status %in% c('GRADED', 'COMPLETED'))
		infoBox(title = 'Completed Assessments',
				value = nrow(assmts),
				color = 'purple',
				fill = TRUE,
				icon = icon('check'))
	})

	output$inprogress_assessments <- renderInfoBox({
		assmts <- get_assessments() |>
			filter(status %in% c('IN_PROGRESS'))
		infoBox(title = 'In Progress',
				value = nrow(assmts),
				color = 'yellow',
				fill = TRUE,
				icon = icon('question'))
	})

	##### Log files viewer #####################################################
	output$log_file <- renderUI({
		selectInput(inputId = 'log_file',
					label = 'Log file:',
					choices = log_files)
	})

	output$log_file_contents <- renderText({
		req(input$log_file)
		txt <- ''
		if(file.exists(input$log_file)) {
			file <- readLines(input$log_file)
			txt <- paste0(
				file[seq(max(0, length(file) - 500), length(file))],
				collapse = '\n'
			)
		} else {
			txt <- paste0('Could not find ', input$log_file)
		}
		return(txt)
	})

	##### Results plots ########################################################
	assessment_plot <- function(assmts, category) {
		subject <- assmts |>
			filter(status %in% c('GRADED'),
				   assessmentCategory == category) |>
			mutate(overallScore = factor(overallScore,
										 levels = c('LOW','MEDIUM','HIGH'),
										 ordered = TRUE)) |>
			count(overallScore = overallScore) |>
			mutate(pct = prop.table(n) * 100)
		ggplot(subject, aes(x = overallScore, y = n)) +
			geom_bar(stat = 'identity', fill = colors[1]) +
			geom_text(aes(label = paste0('n = ', n, '\n', round(pct), '%')),
					  hjust = -0.1) +
			coord_flip() +
			ylim(c(0, max(subject$n) * 1.1)) +
			xlab('') + ylab('Count') +
			ggtitle(paste0('Distribution of results for ', assessment_labels[category]))
	}

	output$srl_plot <- renderPlot({
		assessment_plot(get_assessments(), 'COLLEGE_SKILLS')
	})

	output$writing_plot <- renderPlot({
		assessment_plot(get_assessments(), 'WRITING')
	})

	output$reading_plot <- renderPlot({
		assessment_plot(get_assessments(), 'READING')
	})

	output$mathematics_plot <- renderPlot({
		assessment_plot(get_assessments(), 'MATHEMATICS')
	})

	##### Page views plot ######################################################
	output$page_view_plot <- renderPlot({
		tmp <- get_events()
		tmp <- tmp |> filter(eventType == 'PAGE_VIEW')
		tab <- as.data.frame(table(as.Date(tmp$timestamp)))
		tab$Var1 <- as.Date(tab$Var1)
		ggplot(tab, aes(x = Var1, y = Freq)) +
			geom_path() +
			xlab('Date') + ylab('Page Views') +
			ggtitle('Page Views per Day')
	})

	##### Completion plot ######################################################
	output$assessments_by_date_plot <- renderPlot({
		assmts <- get_assessments()
		tmp <- assmts |>
			filter(status == 'GRADED') |>
			mutate(completionDate = as.Date(completionDate)) |>
			group_by(completionDate) |>
			summarize(n = n())
		ggplot(tmp, aes(x = completionDate, y = n)) +
			geom_path() +
			xlab('Date') + ylab('Assessment Completions') +
			ggtitle('Assessment Completions per Day')
	})

	##### User authentication ##################################################
	# call the shinyauthr login and logout server modules
	credentials <- shinyauthr::loginServer(
		id = "login",
		data = user_base,
		user_col = "user",
		pwd_col = "password",
		sodium_hashed = TRUE,
		reload_on_logout = TRUE,
		cookie_logins = FALSE,
		log_out = reactive(logout_init())
	)

	logout_init <- shinyauthr::logoutServer(
		id = "logout",
		active = reactive(credentials()$user_auth)
	)

	observeEvent(credentials()$user_auth, {
		# if user logs in successfully
		if (credentials()$user_auth) {
			# remove the login tab
			removeTab("tabs", "login")
			# add home tab
			appendTab("tabs", home_tab, select = TRUE)
			# render user data output
			output$user_data <- renderPrint({ dplyr::glimpse(credentials()$info) })
			# add data tab
			appendTab("tabs", data_tab)
			# add log files tab
			appendTab("tabs", log_file_tab)
			# render data tab title and table depending on permissions
			user_permission <- credentials()$info$permissions
			if (user_permission == "admin") {
				# output$data_title <- renderUI(tags$h2("Storms data. Permissions: admin"))
				output$table <- DT::renderDataTable(DT::datatable({
						users <- get_users()
						users$Summary_Report <- paste0(
							"<a href='", summary_report_url, users[,'_id'], "' target='_new'>",
							summary_report_url, users[,'_id'], "</a>")
						users
					}, escape = FALSE),
					options = list(pageLength = 50, autoWidth = TRUE, escape = FALSE),
					filter = list(position = 'top', clear = FALSE)
				)
			} else if (user_permission == "standard") {
				# output$data_title <- renderUI(tags$h2("Starwars data. Permissions: standard"))
				# output$table <- DT::renderDT({ dplyr::starwars[, 1:10] })
			}
		}
	})
}
