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
# devtools::install_github("nik01010/dashboardthemes")
library(dashboardthemes)
# devtools::install_github("ThomasSiegmund/shinyTypeahead")
library(shinyTypeahead)

source('config.R')

if(LOCAL_DB & file.exists(local.db)) {
	load(local.db)
} else {
	library(mongolite)
	URI <- paste0('mongodb://', mongo.user, ':', mongo.pass, '@',
				  mongo.host, ':', mongo.port, '/', mongo.db)
	m.users <- mongo(url = URI, collection = 'users')
	m.user_assessments <- mongo(url = URI, collection = 'user_assessments')
}

guide <- as.data.frame(readxl::read_excel('guide.xlsx'))
writing.rubric <- as.data.frame(readxl::read_excel('resources/writing/rubric.xlsx'))


##### Utility Functions ########################################################

perc.rank <- function(x, score) {
	length(x[x <= score]) / length(x)*100
}

getUser <- function(username) {
	if(LOCAL_DB) {
		results <- users[users$username == username,]
	} else {
		results <- m.users$find(paste0('{"username": "', username, '"}'))
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

scoreColor <- function(score) {
	if(is.na(score)) {
		return('maroon')
	} else if(score == 'LOW') {
		return('yellow')
	} else if(score == 'MEDIUM') {
		return('blue')
	} else if(score == 'HIGH') {
		return('green')
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

# srl[1,]$itemGroups[[1]]
#
# anw <- srl[1,]$itemGroups[[1]][1,]$items[[1]]$chosenItemAnswerId
# srl[1,]$itemGroups[[1]][1,]$items[[1]]$possibleItemAnswers
#
# apply(srl[1,]$itemGroups[[1]][1,]$items[[1]], 1, FUN = function(x1) {
# 	x1$possibleItemAnswers[[1]][x1$chosenItemAnswerId == x1$possibleItemAnswers[[1]]$`_id`,]$score
# })
#
# mapply(function(chosenAnswer, possibleAnswers) {
# 	print(possibleAnswers)
# 	# possibleAnswers[possibleAnswers$`_id` == chosenAnswer,]$score
# }, srl[1,]$itemGroups[[1]]$items[[1]]$chosenItemAnswerId, srl[1,]$itemGroups[[1]]$items[[1]]$possibleItemAnswers[[1]])

css <- c("#bgred {background-color: #E6B0AA;}",
		 "#bgblue {background-color: #0000FF;}",
		 "#bgyellow {background-color: #ffff99;}",
		 "#bggreen {background-color: #82E0AA;}")

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

