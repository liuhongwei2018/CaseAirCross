#' Match case locations to pollution grid
#'
#' @param cases Dataframe with columns: id, date, lon, lat
#' @param pollution Pollution data from load_pollution()
#' @return Dataframe with added exposure column
#' @export
#' @examples
#' matched_data <- geo_match(sample_cases, pm_data)
geo_match <- function(cases, pollution) {
  cases$exposure <- sapply(1:nrow(cases), function(i) {
    lon_idx <- which.min(abs(pollution$lon - cases$lon[i]))
    lat_idx <- which.min(abs(pollution$lat - cases$lat[i]))
    pollution$data[lon_idx, lat_idx, which(pollution$time == cases$date[i])]
  })
  cases
}
