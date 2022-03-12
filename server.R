function(input, output, session) {

	##### Overall Results ######################################################

	##### Student Results ######################################################

	##### Admin Tab ############################################################
	output$admin_tab <- renderUI({
		auth <- reactiveValuesToList(res_auth)
		if(is.null(auth$admin) | !auth$admin) {
			return()
		}
		print('Creating some admin stuff...')
	})

	##### Authentication #######################################################
	daacs_check_credentials <- function(user, password) {
		password <- digest::digest(password, algo = 'sha1', serialize = FALSE)
		daacs_user <- getUser(user)
		authorized <- FALSE
		user_info <- data.frame(
			user = user,
			password = password,
			is_hashed_password = FALSE,
			admin = FALSE,
			start = Sys.Date() - 1,
			expire = Sys.Date() + 1,
			role = NA,
			stringsAsFactors = FALSE
		)
		if(nrow(daacs_user) == 1) {
			if(password == daacs_user[1,]$password) {
				authorized <- TRUE
				user_info$role <- daacs_user[1,]$roles[[1]]
				user_info$admin <- daacs_user[1,]$roles[[1]] == 'ROLE_ADMIN'
			}
		}
		auth <- auth <- list(result = authorized,
							 expired = FALSE,
							 authorized = authorized,
							 user_info = user_info)
		return(auth)
	}

	res_auth <- secure_server(
		check_credentials = daacs_check_credentials # Using custom authenticator
		# check_credentials = check_credentials(credentials)
	)

	output$auth_output <- renderPrint({
		reactiveValuesToList(res_auth)
	})

	observe({ # Toggle the admin tab
		showTab <- FALSE
		auth <- reactiveValuesToList(res_auth)
		if(!is.null(auth$admin)) {
			showTab <- auth$admin
		}
		if(showTab) {
			showTab('tabs', 'adminTab', session = getDefaultReactiveDomain())
		} else {
			hideTab('tabs', 'adminTab', session = getDefaultReactiveDomain())
		}
	})
}
