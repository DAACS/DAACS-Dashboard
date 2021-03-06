library(shiny)
library(shinydashboard)
library(flexdashboard)
library(psych)
library(digest)
library(ggplot2)
library(markdown)
library(readxl)
library(pander)
library(stringr)
library(DT)
library(dashboardthemes) # devtools::install_github("nik01010/dashboardthemes")
# library(shinyTypeahead)  # devtools::install_github("ThomasSiegmund/shinyTypeahead")
library(dqshiny)
library(tidyverse)
library(tools)
source('R/calendarHeat.R')

# source('config-ec.R')     # Excelsior College
source('config.R')          # Demo Site
# source('config-albany.R') # UAlbany

source('R/LOCAL_USERS.R')

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


##### Utility Functions ########################################################

perc.rank <- function(x, score) {
	length(x[x <= score]) / length(x)*100
}

getUser <- function(username) {
	if(!is.null(LOCAL_USERS)) {
		results <- LOCAL_USERS[LOCAL_USERS$username == username,]
		if(nrow(results) == 1) {
			return(results)
		}
	}
	if(LOCAL_DB) {
		results <- users[users$username == username,]
	} else {
		fields <- c('_id', 'username', 'roles', 'createdDate', 'version',
				    'reportedCompletionToCanvas', 'canvasSisId','secondaryId', 'password')
		f <- paste0("{", paste0('"', fields, '":',
								1:length(fields), collapse = ', '), "}")
		results <- m.users$find(paste0('{"username": "', username, '"}'),
								field = f)
	}
	return(results)
}

getUserResults <- function(username) {
	if(LOCAL_DB) {
		results <- user_assessments[user_assessments$username == username, ]
	} else {
		# fields <- c('_id', 'username', 'userId', 'assessmentId',
		# 			'assessmentType', 'assessmentCategory', 'assessmentLabel',
		# 			'takenDate', 'status', 'progressPercentage', 'completionDate',
		# 			'domainScores', 'overallScore', 'scoringType', 'writingPrompt')
		# f <- paste0("{", paste0('"', fields, '":', 1:length(fields), collapse = ', '), "}")
		# results <- m.user_assessments$find(paste0('{"username":"', username, '"}'),
		# 								   field = f)
		#
		results <- m.user_assessments$find(paste0('{"username":"', username, '"}'))
	}
	return(results)
}

#' Return all users
getUsers <- function() {
	results <- NULL
	if(LOCAL_DB) {
		results <- users
	} else {
		results <- m.users$find()
	}
	results$role <- sapply(results$roles, FUN = function(x) { paste0(x, collapse = ', ')} )
	results$createdDate <- as.POSIXct(results$createdDate, origin = '1970-01-01')
	return(results)
}

scoreLabel <- function(score) {
	if(is.na(score)) {
		return('Not completed')
	} else if(score == 'LOW') {
		return('Developing')
	} else if(score == 'MEDIUM') {
		return('Emerging')
	} else if(score == 'HIGH') {
		return('Mastering')
	} else {
		return('N/A')
	}
}

#' Color returned for valueBox.
scoreColor <- function(score) {
	if(is.na(score)) {
		return('maroon')
	} else if(score == 'LOW') {
		return('light-blue')
	} else if(score == 'MEDIUM') {
		return('blue')
	} else if(score == 'HIGH') {
		return('purple')
	} else {
		return('maroon')
	}
}

#' Returns the students responses to questions as a data.frame.
getStudentResponses <- function(srl, studentRow) {
	studentdf <- data.frame(question = character(),
							domain = character(),
							answer = character(),
							score = integer(),
							stringsAsFactors = FALSE)
	tmp <- srl[studentRow,]$itemGroups[[1]]
	for(itemGroup in seq_len(nrow(tmp))) { # Loop through item groups
		tmp2 <- tmp[itemGroup,]$items[[1]]
		for(item in seq_len(nrow(tmp2))) {
			ans <- tmp2[item,]$possibleItemAnswers[[1]][tmp2[item,]$possibleItemAnswers[[1]]$`_id` == tmp2[item,]$chosenItemAnswerId, ]
			studentdf <- rbind(studentdf, data.frame(
				question = tmp2[item,]$question,
				domain = tmp2[item,]$domainId,
				answer = ans$content,
				score = ans$score,
				stringsAsFactors = FALSE) )
		}
	}
	return(studentdf)
}

# css <- c("#bgred {background-color: #E6B0AA;}",
# 		 "#bgblue {background-color: #0000FF;}",
# 		 "#bgyellow {background-color: #ffff99;}",
# 		 "#bggreen {background-color: #82E0AA;}")

css <- c("#bgred {background-color: #1f78b4;}",
		 "#bgblue {background-color: #0000FF;}",
		 "#bgyellow {background-color: #b2df8a;}",
		 "#bggreen {background-color: #33a02c;}")

colortable <- function(htmltab, css, style="table-condensed table-bordered"){
	tmp <- str_split(htmltab, "\n")[[1]]
	CSSid <- gsub("\\{.+", "", css)
	CSSid <- gsub("^[\\s+]|\\s+$", "", CSSid)
	CSSidPaste <- gsub("#", "", CSSid)
	CSSid2 <- paste(" ", CSSid, sep = "")
	ids <- paste0("<td id='", CSSidPaste, "'")
	for (i in 1:length(CSSid)) {
		locations <- grep(CSSid[i], tmp)
		tmp[locations] <- gsub("<td", ids[i], tmp[locations])
		tmp[locations] <- gsub(CSSid2[i], "", tmp[locations],
							   fixed = TRUE)
	}
	htmltab <- paste(tmp, collapse="\n")
	Encoding(htmltab) <- "UTF-8"
	list(
		tags$style(type="text/css", paste(css, collapse="\n")),
		tags$script(sprintf(
			'$( "table" ).addClass( "table %s" );', style
		)),
		HTML(htmltab)
	)
}

generateDAACSReport <- function(username,
								report_dir = 'student_report',
								out_dir = paste0(report_dir, '/generated')) {
	start.globalevn.vars <- ls(envir = globalenv())

	results <- getUserResults(username)

	if(nrow(results) == 0) {
		warning(paste0('No results found for ', username))
		return(NA)
	}

	results$completionDate <- as.Date(results$completionDate, origin = '1970-01-01')
	results <- results %>%
		filter(status == 'GRADED') %>%
		select(username, firstName, lastName, completionDate,
			   assessmentCategory, assessmentType, overallScore, domainScores) %>%
		arrange(desc(completionDate)) %>%
		filter(!duplicated(.[["assessmentCategory"]]))

	if(nrow(results) == 0) {
		warning(paste0('No results found for ', username))
		return(NA)
	}

	wd <- setwd(report_dir)
	tryCatch({
		assign('results', results, envir = globalenv())
		# sink("DAACS_report_log.txt", append = TRUE)
		cat(paste0('Generating report for ', username))
		utils::Sweave('sample.Rnw')
		utils::Sweave('sidebar.Rnw')
		tools::texi2pdf('sample.tex', quiet=TRUE, clean=TRUE)
		# tinytex::pdflatex('sample.tex') # possible alternative
		# sink()
	}, finally = {
		setwd(wd)
		end.globalevn.vars <- ls(envir = globalenv())
		rm(list = end.globalevn.vars[!end.globalevn.vars %in% start.globalevn.vars],
		   envir = globalenv())
	})

	report_file <- paste0(out_dir, '/', strsplit(username, '@')[[1]][1],
						  '-', Sys.Date(), '.pdf')
	file.copy(from = paste0(report_dir, '/sample.pdf'),
			  to = report_file, overwrite = TRUE)

	tryCatch({ # Cleanup
		files <- c('sample.tex', 'sidebar.tex', 'sample.pdf',
				   'sample-concordance.tex')
		for(i in files) {
			file.remove(paste0(report_dir, '/', i))
		}
	})

	return(report_file)
}
