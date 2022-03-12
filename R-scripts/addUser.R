args <- commandArgs(trailingOnly=TRUE)
if(length(args) == 2) {
	# print(paste0('Args: ', args))
	source('R/LOCAL_USERS.R')
	addUser(username = args[1],
			password = args[2],
			roles = "ROLE_ADVISOR")
} else {
	cat("Must have two arguments: username and password. Usage:\n")
	cat("   ./adduser.sh USERNAME PASSWORD\n")
}
