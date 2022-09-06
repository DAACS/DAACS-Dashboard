getUserResults <- function(username) {
	# fields <- c('_id', 'username', 'userId', 'assessmentId',
	# 			'assessmentType', 'assessmentCategory', 'assessmentLabel',
	# 			'takenDate', 'status', 'progressPercentage', 'completionDate',
	# 			'domainScores', 'overallScore', 'scoringType', 'writingPrompt')
	# f <- paste0("{", paste0('"', fields, '":', 1:length(fields), collapse = ', '), "}")
	# results <- m.user_assessments$find(paste0('{"username":"', username, '"}'),
	# 								   field = f)
	#
	results <- m.user_assessments$find(paste0('{"username":"', username, '"}'))
	return(results)
}

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

new_page <- function() {
	if(knitr::is_latex_output()) {
		return('\\clearpage\n')
	} else if(knitr::is_html_output()) {
		return('--------------------------------------------------------------------------------')
	}
}

make_link <- function(text, url) {
	# return(paste0('[', text, '](', url, ')'))
	if(knitr::is_latex_output()) {
		sprintf("\\href{%s}{%s}", url, text)
	} else if(knitr::is_html_output()) {
		sprintf("<a href='%s'>%s</a>", url, text)
	} else {
		text
	}
}

daacs_link <- function(assessment, domain, subdomain, takenDate, userId) {
	takenDate <- takenDate + 0.0005 # See https://stackoverflow.com/questions/10931972/r-issue-with-rounding-milliseconds
	takenDate <- gsub(':', '%3A', format(takenDate,'%Y-%m-%dT%H:%M:%OS3Z', tz = 'GMT'))
	return(paste0(daacs.base.url, '/assessments/', assessment,
				  ifelse(!missing(domain), paste0('/domain/', domain), ''),
				  ifelse(!missing(subdomain), paste0('/subdomain/', subdomain), ''),
				  ifelse(!missing(userId), paste0('?userId=', userId, '')),
				  ifelse(!missing(domain), paste0('&takenDate=', takenDate), '') ) )
}

colorize <- function(x, color) {
	if(knitr::is_latex_output()) {
		sprintf("\\textcolor[HTML]{%s}{%s}", color, x)
	} else if(knitr::is_html_output()) {
		sprintf("<span style='color: #%s;'>%s</span>", color, x)
	} else {
		x
	}
}


capitalize <- function(str) {
	str <- strsplit(str, " ")[[1]]
	str <- strsplit(str, "_")[[1]]
	paste(toupper(substring(str, 1,1)), substring(str, 2), sep="", collapse=" ")
}

getDots <- function(str) {
	if(is.null(str) | is.na(str)) {
		return(0)
	} else if(str == 'LOW') {
		return(1)
	} else if(str == 'MEDIUM') {
		return(2)
	} else if(str == 'HIGH') {
		return(3)
	} else {
		return(0)
	}
}

getDotsImage <- function(str) {
	dot <- getDots(str)
	txt <- ''
	if(dot == 0) {
		txt <- ''
	} else if(knitr::is_latex_output() | TRUE) {
		txt <- paste0("\\includegraphics[height=10px]{dots", dot, ".png}")
	} else if(knitr::is_html_output()) {
		txt <- paste0("<img src='dots", dot, ".png' height='20px' />")
	}
	return(txt)
}
