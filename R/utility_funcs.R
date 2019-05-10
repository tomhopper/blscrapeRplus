## Utility Functions ####
#' @title RIGHT
#' @description Extracts the right \code{n} characters from a character string
#' @param string A string to extract text from
#' @param n the number of characters to extract
.RIGHT <- function(string, n) {
  substr(string,
         nchar(string)-n+1,
         nchar(string))
}

