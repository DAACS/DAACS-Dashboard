navbarPage(
	title = paste0("", daacs.domain),
	id = "tabs", # must give id here to add/remove tabs in server
	collapsible = TRUE,
	# This tab is visible for non-authenticated users
	tabPanel(
		title = icon('house'),
		value = 'home',
		useShinydashboard(),
		fluidRow(
			infoBoxOutput('info_users', width = 3),
			infoBoxOutput('unscored_assessments', width = 3),
			infoBoxOutput('completed_assessments', width = 3),
			infoBoxOutput('inprogress_assessments', width = 3)
		),
		fluidRow(
			tabBox(
				# title = 'Assessments',
				id = 'assessment_plots',
				tabPanel('SRL', plotOutput('srl_plot')),
				tabPanel('Writing', plotOutput('writing_plot')),
				tabPanel('Reading', plotOutput('reading_plot')),
				tabPanel('Mathematics', plotOutput('mathematics_plot'))
			),
			tabBox(
				id = 'access_plots',
				tabPanel('Assessments', plotOutput('assessments_by_date_plot')),
				tabPanel('Page Views', plotOutput('page_view_plot'))
			)
		)
	),
	login_tab
)
