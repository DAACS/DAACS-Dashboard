#' Creates a PDF DAACS report for the given student,
generateDAACSReport <- function(username,
								report_dir = 'student_report',
								out_dir = paste0(report_dir, '/generated')) {
	start.globalevn.vars <- ls(envir = globalenv())

	results <- getUserResults(username)

	if (nrow(results) == 0) {
		warning(paste0('No results found for ', username))
		return(NA)
	}

	results$completionDate <-
		as.Date(results$completionDate, origin = '1970-01-01')
	results <- results %>%
		filter(status == 'GRADED') %>%
		select(
			username,
			firstName,
			lastName,
			completionDate,
			assessmentCategory,
			assessmentType,
			overallScore,
			domainScores
		) %>%
		arrange(desc(completionDate)) %>%
		filter(!duplicated(.[["assessmentCategory"]]))

	if (nrow(results) == 0) {
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
		tools::texi2pdf('sample.tex', quiet = TRUE, clean = TRUE)
		# tinytex::pdflatex('sample.tex') # possible alternative
		# sink()
	}, finally = {
		setwd(wd)
		end.globalevn.vars <- ls(envir = globalenv())
		rm(list = end.globalevn.vars[!end.globalevn.vars %in% start.globalevn.vars],
		   envir = globalenv())
	})

	report_file <-
		paste0(out_dir,
			   '/',
			   strsplit(username, '@')[[1]][1],
			   '-',
			   Sys.Date(),
			   '.pdf')
	file.copy(
		from = paste0(report_dir, '/sample.pdf'),
		to = report_file,
		overwrite = TRUE
	)

	tryCatch({
		# Cleanup
		files <- c('sample.tex',
				   'sidebar.tex',
				   'sample.pdf',
				   'sample-concordance.tex')
		for (i in files) {
			file.remove(paste0(report_dir, '/', i))
		}
	})

	return(report_file)
}
