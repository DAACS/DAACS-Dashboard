# This R script will extract the data from DAACS used by the dachboard.

# source('config.R')

URI <- paste0('mongodb://', mongo.user, ':', mongo.pass, '@',
			  mongo.host, ':', mongo.port, '/', mongo.db)

collections <- c('user_assessments', 'users')

fields <- list(
	users = c('_id', 'username', 'roles', 'createdDate', 'version',
			  'reportedCompletionToCanvas', 'canvasSisId','secondaryId'),#, 'password'),
	user_assessments <- c('_id', 'username', 'userId', 'assessmentId',
						  'assessmentType', 'assessmentCategory', 'assessmentLabel',
						  'takenDate', 'status', 'progressPercentage', 'completionDate',
						  'domainScores', 'overallScore', 'scoringType', 'writingPrompt')

)

for(i in collections) {
	message(paste0('Loading ', i, ' collection...'))
	m <- mongo(url = URI, collection = i)
	if(i %in% names(fields)) {
		f <- paste0("{", paste0('"', fields[[i]], '":',
								1:length(fields[[i]]), collapse = ', '), "}")
		thedata <- m$find(field = f)
	} else {
		thedata <- m$find()
	}
	assign(i, thedata)
}

save(list = collections, file = local.db)
