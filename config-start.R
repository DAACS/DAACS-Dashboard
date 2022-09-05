colors <- c('#1f78b4', '#b2df8a', '#33a02c')

mongo.host <- 'localhost'
mongo.port <- 27017
mongo.db <- 'daacsdb'
mongo.collection.users <- 'users'
mongo.collection.assessments <- 'user_assessments'
mongo.collection.events <- 'event_containers'
mongo.user <- 'admin'
mongo.pass <- 'MONGO_PASSWORD'

daacs.domain <- 'DAACS_DOMAIN'
daacs.base.url <- paste0('https://', daacs.domain)

summary_report_url <- '/summaryreport/?userid='

# user database for logins
user_base <- tibble::tibble(
	user = c("admin"),
	password = purrr::map_chr(c("changeme"), sodium::password_store),
	permissions = c("admin"), # admin or standard
	name = c("Administrator")
)

log_files <- c(
	'API' = '/usr/local/daacs/DAACS-API/nohup.out',
	'Web' = '/usr/local/daacs/DAACS-Web/nohup.out',
	'nginx Error' = '/var/log/nginx/error.log',
	'nginx Access' = '/var/log/nginx/access.log'
)
