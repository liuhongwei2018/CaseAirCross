#' Load air pollution data from NetCDF file
#'
#' @param nc_path Path to the NetCDF file
#' @return A list containing lon, lat, time, and PM2.5 data
#' @export
#' @examples
#' pm_data <- load_pollution("data/CHAP_PM2.5_20200101.nc")
load_pollution <- function(nc_path) {
  nc <- ncdf4::nc_open(nc_path)
  list(
    lon = ncdf4::ncvar_get(nc, "lon"),
    lat = ncdf4::ncvar_get(nc, "lat"),
    time = ncdf4::ncvar_get(nc, "time"),
    data = ncdf4::ncvar_get(nc, "PM2.5") * 0.1  # 根据scaleFactor校正
  )
}
