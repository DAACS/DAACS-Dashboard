# DAACS Database Configuration

login.message <- "This is a prototype of the DAACS Advisor Dashboard."

LOCAL_DB <- FALSE
local.db <- ''

mongo.host <- ''
mongo.port <- 27017
mongo.db <- ''
mongo.collection.users <- 'users'
mongo.collection.assessments <- 'user_assessments'
mongo.collection.events <- 'event_containers'
mongo.user <- ''
mongo.pass <- ''

daacs.base.url <- paste0('https://', mongo.host)
