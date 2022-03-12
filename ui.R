secure_app(tagList(
	useShinyjs(),
	navbarPage(
		id = "tabs", # needed for landing page
		title = div(tags$a(img(src="DAACS_logo.png", height=35), href= "https://daacs.net"),
								style = "position: relative; top: -5px;"), # Navigation bar
		windowTitle = "DAACS", # title for browser tab
		theme = shinytheme("lumen"),
		collapsible = TRUE, #tab panels collapse into menu in small screens
		header = tags$head(
			includeCSS("www/styles.css"), # CSS styles
			tags$link(rel="stylesheet", type="text/css", href="style.css"),
			# tags$script(type="text/javascript", src = "md5.js"),
			# tags$script(type="text/javascript", src = "sha1.js"),
			# tags$script(type="text/javascript", src = "passwdInputBinding.js"),
			# tags$style(type='text/css', "body { padding-top: 0px; padding-bottom: 170px} "),
			HTML("<html lang='en'>"),
			tags$link(rel="shortcut icon", href="favicon.ico"), #Icon for browser tab
			HTML("<base target='_blank'>")
		),

		tabPanel(
			title = "Home",
			icon = icon("home"),
			mainPanel(
				width = 11, style="margin-left:4%; margin-right:4%",

				verbatimTextOutput("auth_output")
			)
		), # Home tabPanel

		tabPanel(
			title = "Summary",
			icon = icon("list-ul"),
			value = "summary"
		), #Summary tabPanel

		tabPanel(
			title = "Student",
			icon = icon("table"),
			value = "table",
		), # Data tabPanel

		tabPanel(
			title = "Admin",
			icon = icon("toolbox"),
			value = "adminTab",
			uiOutput('admin_tab')
		),

		navbarMenu(
			"Info",
			icon = icon("info-circle"),
			tabPanel(
				"About",
				value = "about",
				sidebarPanel(width=1),
				mainPanel(
					width=8,
					h4("About", style = "color:black;"),
					p("Diagnostic Assessment and Achievement of College Skills")),
				br()
			), # about tabPanel
		), # navbarMenu

		div(style = "margin-bottom: 30px;"), # this adds breathing space between content and footer

		tags$footer(
			column(6, "© DAACS"),
			column(2, tags$a(href="mailto:admin@daacs.net", tags$b("Contact us!"),
											 class="externallink", style = "color: white; text-decoration: none")),
			# column(1, actionLink("twitter_share", label = "Share", icon = icon("twitter"),
			#									 style= "color:white;", onclick = sprintf("window.open('%s')",
			#									 "https://twitter.com/jbryer"))),
			style = "position:fixed;
							 text-align:center;
							 left: 0;
							 bottom:0;
							 width:100%;
							 z-index:1000;
							 height:30px; /* Height of the footer */
							 color: white;
							 padding: 10px;
							 font-weight: bold;
							 background-color: #54075B"
			)
		) # navbarPage
	),
	tags_top =
		tags$div(
			# tags$h4("DAACS Dashboard", style = "align:center"),
			tags$img(src = "DAACS_logo.png", width = 150)
	),
	tags_bottom = tags$div(
		tags$p(
			"For any question, please contact ",
			tags$a(
				href = "mailto:admin@daacs.net?Subject=DAACS%20aDashboard",
				target="_top", "admin@daacs.net"
			)
		)
	)
)
