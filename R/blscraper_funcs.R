#' @title get_bls_data
#' @description Recursively get jobs data from the Bureau of Labor Statistics.
#' @param series_id The ID of the series you want to download
#' @param start_year The first (earliest) year for which you want data for the \code{series_id}.
#'   If \code{NULL}, will attempt to pull the earliest available data.
#' @param end_year The last (most recent) year for which you want data for the \code{series_id}.
#'   If \code{NULL}, will pull the most recent data.
#' @param api_key Your registred BLS API key, or \code{NULL} if you do not have a key.
#' @return A data frame containing the requested data.
#'
#' @details Recursively requests data for the given series. Starts by downloading an \code{increment}
#'   number of years ending with the user-supplied \code{end_year}, and recursively works backward
#'   to either the user-supplied \code{start_year} or the first available year, whichever is greater.
#'
#'   If \code{api_key} is \code{NULL}, \code{get_bls_data()} will set \code{increment = 10},
#'   working within the 10-year limitation of the BLS API for unregistered users.
#'
#' @importFrom blscrapeR bls_api dateCast
#' @importFrom magrittr %>%
#' @importFrom dplyr bind_rows distinct arrange
#' @importFrom lubridate now year
#'
#' @seealso \code{\link{bls_api}}
#'
#' @export
get_bls_data <- function(series_id, start_year = NULL, end_year = NULL, api_key = NULL) {
  if(!missing(series_id)) {
    if((isTRUE(all.equal(length(api_key), 1L)) & is.character(api_key) | is.null(api_key))) {
      if(isTRUE(all.equal(length(series_id), 1L))) {
        if(is.null(end_year)) {
          end_year <- now() %>% year()
        }
        increment <- 10 #ifelse(is.null(api_key), 10, 20)
        series_range <- c(ifelse(is.null(start_year),
                                 end_year - 2 * increment,
                                 start_year),
                          end_year)
        if(series_range[1] < (series_range[2] - increment))
          series_range[1] <- series_range[2] - increment
        # Iteratively call get_bls_data with values of start - 20 and end - 20 until either
        # start == start_year or the bls_api() call returns an empty data frame (nrow(df) == 0)
        # 1) call bls_api()
        # 2) if nrow() == 0 or range[2] < start_year then return data frame
        # 3) else call get_bls_data() with parameters series_id, start_year = start_year_i-1 - increment
        temp_df <- bls_api(seriesid = series_id,
                           startyear = series_range[1], endyear = series_range[2],
                           registrationKey = api_key) %>%
          dateCast()
        # If bls_api() returned an empty data frame, we're done collecting data so
        # return the (empty) data frame, ending recursion.
        # Otherwise, recursively call this function with end_year decremented to get the next
        # batch of data.
        if(isTRUE(all.equal(nrow(temp_df), 0L))) {
          ### EXIT Function #
          return(temp_df)
        } else {
          end_year <- series_range[1]
          # end_year <- series_range[1]
          # TODO: fix this if() so that it doesn't just automatically download the entire series
          if(isTRUE(all.equal(target = start_year, current = end_year))) {
            ### EXIT Function #
            return(temp_df)
          }
          ### EXIT Recursive function call #
          return(temp_df %>% bind_rows(get_bls_data(series_id = series_id, start_year = start_year, end_year = end_year, api_key = api_key)) %>%
                   distinct() %>%
                   arrange(year, period))}
      } else { # series_id is not length 1
        stop("series_id can only contain a single series.")
      }
    } else {
      stop("api_key must be a character string (your BLS API key) or NULL.")
    }
  } else {
    stop("series_id is required.")
  }
}

#' @title load_bls_data
#' @description Returns a data frame containing the specified Bureau of Labor Statistics data.
#' @param file_name character. The path and filename of an R serial data (.RDS) file to use for loading
#'   or saving data on disk.
#' @param series_id character. The BLS series ID used to download data.
#' @param start_year numeric. The first (earliest) year for which you want data for the \code{series_id}.
#'   If \code{NULL}, will attempt to pull the earliest available data.
#' @param end_year numeric. The last (most recent) year for which you want data for the \code{series_id}.
#'   If \code{NULL}, will pull the most recent data.
#' @param fresh_start boolean. If true, will delete any existing data file specified by \code{file_name}
#'   before proceeding to download new data from the specified series.
#' @param api_key Your registred BLS API key, or \code{NULL} if you do not have a key.
#' @return A data frame
#'
#' @details If the file specified by \code{file_name} already exists, the data is loaded
#'   from disk and returned. If the file does not exist, the series ID is used to download the
#'   data from the BLS. The data is then saved to the file \code{file_name}, and returned as
#'   a data frame.
#'   In addition to the data returned from the BLS's API, a new column \code{date} is added,
#'   with data class Date, and the data is sorted by date.
#'   Both \code{file_name} and \code{series_id} should be passed as character strings, e.g.
#'   \code{file_name = "data/jobs_u.rds", series_id = "CEU0000000001"}.
#'
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate distinct arrange
#' @importFrom lubridate ymd days
#'
#' @export
#'
#' @examples
#'   \dontrun{
#'   # Get all years of seasonally adjusted position reported by employers ("jobs report")
#'   # and save to data/employer_jobs_s.rds
#'   employer_jobs_s_df <- load_bls_data(file_name = "data/employer_jobs_s.rds",
#'                                       series_id = "CES0000000001")
#'
#'   # Get the last decade of unadjusted employer-reported position
#'   library(magrittr); library(lubridate)
#'   my_start_date <- today() %>% year()
#'   employer_decade_df <- load_bls_data(file_name = "data/last_decade_u.rds",
#'                                       series_id = "CEU0000000001",
#'                                       start_date = my_start_date)
#'   }
#  TODO: Add flag to delete old file and load new data
load_bls_data <- function(file_name, series_id, start_year = NULL, end_year = NULL, api_key = NULL, fresh_start = FALSE) {
  if(missing(file_name) | missing(series_id)) stop("file_name and series_id are both required.")
  if(is.character(file_name)) {
    if(file.exists(file_name)) {
      if(fresh_start) {
        file.remove(file_name)
      } else {
        message("Loading data from existing data file.")
        data_df <- readRDS(file_name)
      }
    }
    if(!file.exists(file_name)) {
      message("Downloading data from BLS.")
      data_df <- get_bls_data(series_id = series_id,
                              start_year = start_year,
                              end_year = end_year,
                              api_key = api_key) %>%
        distinct() %>%
        arrange(date)

      saveRDS(data_df, file = file_name)
    }
    return(data_df)
  } else {
    stop("file_name must be a character string containing the file name. See ?files for details on valid file names.")
  }
}
