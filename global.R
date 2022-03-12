library(shiny)
library(shinyBS)
library(shinythemes) # layouts for shiny
library(dplyr) # data manipulation
library(ggplot2) #data visualization
library(DT) # for data tables
library(shinyWidgets) # for extra widgets
library(shinyjs)
library(shinydashboard) #for valuebox on techdoc tab
library(shinycssloaders) #for loading icons, see line below
# it uses github version devtools::install_github("andrewsali/shinycssloaders")
# This is to avoid issues with loading symbols behind charts and perhaps with bouncing of app
library(rmarkdown)
library(shinymanager)
library(digest)
# library(daacsR)

source('R/calendarHeat.R')
source('R/colortable.R')
source('R/db.R')
source('R/generateDAACSReport.R')

source('config/config.R')

source('R/local_users.R')

if(LOCAL_DB & file.exists(local.db)) {
	load(local.db)
} else {
	library(mongolite)
	URI <- paste0('mongodb://', mongo.user, ':', mongo.pass, '@',
				  mongo.host, ':', mongo.port, '/', mongo.db)
	m.users <- mongo(url = URI, collection = mongo.collection.users)
	m.user_assessments <- mongo(url = URI, collection = mongo.collection.assessments)
	m.events <- mongo(url = URI, collection = mongo.collection.events)
}

guide <- as.data.frame(readxl::read_excel('resources/guide.xlsx'))
writing.rubric <- as.data.frame(readxl::read_excel('resources/writing/rubric.xlsx'))


css <- c(
	"#bgred {background-color: #1f78b4;}",
	"#bgblue {background-color: #0000FF;}",
	"#bgyellow {background-color: #b2df8a;}",
	"#bggreen {background-color: #33a02c;}"
)

perc.rank <- function(x, score) {
	length(x[x <= score]) / length(x) * 100
}

# For Shiny manager
# Call get_labels() for a list of labels that can be changed
set_labels(
	language = "en",
	"Please authenticate" = "Please login",
	"Username:" = "Username:",
	"Password:" = "Password:",
	"You are not authorized for this application" = "Incorrect username or password!"
)
