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
