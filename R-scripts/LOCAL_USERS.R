# This script will supplement the DAACS user management with a local management.
# Useful for DAACS installations that use single sign-on meaning there is no
# password stored in the DAACS MongoDB.

library(digest)

LOCAL_USERS <- NULL
if(file.exists('LOCAL_USERS.rds')) {
	LOCAL_USERS <<- readRDS('LOCAL_USERS.rds')
} else {
	LOCAL_USERS <<- data.frame(username = character(),
							  roles = character(),
							  password = character(),
							  stringsAsFactors = FALSE)
}

addUser <- function(username, password, roles) {
	if(username %in% LOCAL_USERS$username) {
		LOCAL_USERS <<- LOCAL_USERS[LOCAL_USERS$username != username,]
		warning(paste0(username, ' already existed, replacing with new values'))
	}
	LOCAL_USERS <<- rbind(LOCAL_USERS,
						 data.frame(username = username,
						 		    roles = roles,
						 		    password = digest::digest(password, algo = 'sha1', serialize = FALSE),
						 		    stringsAsFactors = FALSE))
	saveRDS(LOCAL_USERS, file = 'LOCAL_USERS.rds')
}
