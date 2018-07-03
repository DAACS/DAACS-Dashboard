dashboardPage(#skin = 'purple',
	dashboardHeader(title = paste0('DAACS Dashboard')#, titleWidth = '200px'
	),
	dashboardSidebar(
		tagList(
			tags$head(
				tags$link(rel="stylesheet", type="text/css", href="style.css"),
				# tags$script(type="text/javascript", src = "md5.js"),
				tags$script(type="text/javascript", src = "sha1.js"),
				tags$script(type="text/javascript", src = "passwdInputBinding.js"),
				tags$style(type='text/css', "body { padding-top: 0px; padding-bottom: 170px} ")
			)
		),
		uiOutput('dashboard.user'),
		uiOutput('dashboard.search'),
		sidebarMenuOutput('dashboard.sidebar')
	),
	dashboardBody(
		shinyDashboardThemes(theme = "onenote"),
		uiOutput('dashboard.body')
	)
)
