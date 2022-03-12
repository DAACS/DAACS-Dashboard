colortable <- function(htmltab, css, style = "table-condensed table-bordered") {
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
	htmltab <- paste(tmp, collapse = "\n")
	Encoding(htmltab) <- "UTF-8"
	list(tags$style(type = "text/css", paste(css, collapse = "\n")),
		 tags$script(sprintf(
		 	'$( "table" ).addClass( "table %s" );', style
		 )),
		 HTML(htmltab))
}

