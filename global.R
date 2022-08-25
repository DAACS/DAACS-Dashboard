library(shiny)
library(shinyauthr)
library(mongolite)
library(tidyverse)
library(shinydashboard)
library(shinyWidgets)

source('config.R')

assessment_labels <- c(COLLEGE_SKILLS = 'SRL',
					   WRITING = 'Writing',
					   MATHEMATICS = 'Mathematics',
					   READING = 'Reading')


user_fields <- c('_id', 'username', #'password',
				 'firstName', 'lastName', 'roles',
				 'assessmentType', 'assessmentCategory', 'assessmentLabel',
				 'createdDate')
user_fields <- paste0("{", paste0('"', user_fields, '":', 1:length(user_fields), collapse = ', '), "}")

assessment_fields <- c('_id', 'username',
					   'firstName', 'lastName',
					   'assessmentCategory', 'assessmentLabel',
					   'takenDate', 'completionDate', 'status', 'progressPercent',
					   'overallScore')
assessment_fields <- paste0("{", paste0('"', assessment_fields, '":', 1:length(assessment_fields), collapse = ', '), "}")

event_fields = c('_id', 'userEvents', 'version')
event_fields <- paste0("{", paste0('"', event_fields, '":', 1:length(event_fields), collapse = ', '), "}")


##### Additional tabs to be added after login ##################################
home_tab <- tabPanel(
	title = icon("user"),
	value = "home",
	column(
		width = 12,
		tags$h2("User Information"),
		verbatimTextOutput("user_data")
	)
)

data_tab <- tabPanel(
	title = 'Students',
	icon = icon("table"),
	value = "data",
	column(
		width = 12,
		# uiOutput("data_title"),
		DT::DTOutput("table")
	)
)

log_file_tab <- tabPanel(
	'Log Files',
	icon = icon('file-lines'),
	value = 'log_files',
	uiOutput('log_file'),
	verbatimTextOutput('log_file_contents')
)

# login tab ui to be rendered on launch
login_tab <- tabPanel(
	title = 'Login',
	icon = icon("unlock"),
	value = "login",
	shinyauthr::loginUI("login")
)
