# See https://gist.github.com/withr/9001831 for more information

USER <- reactiveValues(Logged = FALSE,
					   Unique = format(Sys.time(), '%Y%m%d%H%M%S'),
					   Username = NA,
					   Role = '')

# For testing
# USER <- list(Username = 'jbryer@excelsior.edu',
# 					   Logged = TRUE,
# 					   # Role = 'ROLE_ADMIN',
# 					   Role = '',
# 					   Unique = format(Sys.time(), '%Y%m%d%H%M%S'))

passwdInput <- function(inputId, label, value) {
	tagList(
		tags$label(label),
		tags$input(id=inputId, type="password", value=value, class='form-control')
	)
}

output$uiLogin <- renderUI({
	if(USER$Logged == FALSE) {
		div(
			# h5("This is a prototype of the DAACS Advisor Dashboard. Please login using your
			#    username and password from demo.daacs.net."),
			br(),
		wellPanel(
			div(textInput(paste0("username", USER$Unique), "Username: ", value='')),
			div(passwdInput(paste0("password", USER$Unique), "Password: ", value='')),
			br(),
			actionButton("Login", "Login")
		)
		)
	}
})

output$uiLogout <- renderUI({
	actionButton('logoutButton', 'Logout')
})

observeEvent(input$logoutButton, {
	if(!is.null(input$logoutButton) & input$logoutButton == 1) {
		USER$Logged <- FALSE
		USER$Username <- USER$Role <- NA
		USER$Unique <- format(Sys.time(), '%Y%m%d%H%M%S')
	}
})

output$pass <- renderText({
	if(USER$Logged == FALSE) {
		if(!is.null(input$Login)) {
			if(input$Login > 0) {
				Username <- isolate(input[[paste0('username', USER$Unique)]])
				Password <- isolate(input[[paste0('password', USER$Unique)]])
				test.user <- getUser(username = Username)
				try({
					if(nrow(test.user) == 0) {
						return(paste0(Username, ' not found.'))
					} else if(Password == test.user[1,]$password)
					{
						USER$Logged <- TRUE
						USER$Username <- Username
						USER$Role <- as.character(test.user[1,]$roles)
						return('Login successful.')
					}
				})
				return("Username or password failed!")
			}
		}
	}
})
