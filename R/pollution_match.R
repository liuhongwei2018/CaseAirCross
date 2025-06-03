#' 从多维NetCDF文件提取时空匹配的污染数据
#' @param coords sf对象包含点位坐标
#' @param nc_files NetCDF文件路径列表
#' @param variables 提取变量（支持PM2.5/O3等）
#' @param method 空间插值方法（'idw'/'kriging'）
#' @param cache 启用HDF5缓存
#' @return 包含时空匹配数据的tibble
#' @import ncdf4
#' @import sf
#' @import gstat
#' @export
extract_pollution <- function(coords, nc_files, variables = "PM2.5",
                              method = "idw", cache = TRUE) {
  # 校验空间参考系
  if (sf::st_crs(coords)$epsg != 4326) {
    coords <- sf::st_transform(coords, 4326)
  }

  # 创建缓存池
  if (cache) {
    h5createFile("pollution_cache.h5")
  }

  # 主处理循环
  purrr::map_dfr(nc_files, function(file) {
    nc <- nc_open(file)
    on.exit(nc_close(nc))

    # 提取时空基准
    time_dim <- ncvar_get(nc, "time")
    base_time <- as.POSIXct(nc$dim$time$units %>%
                              gsub(".*since ", "", .), tz = "UTC")
    datetimes <- base_time + time_dim * 3600  # 假设时间单位为小时

    # 三维数据立方体（lon x lat x time）
    data_cube <- abind::abind(lapply(variables, function(var) {
      ncvar_get(nc, var)
    }), along = 3)

    # 空间插值
    if (method == "idw") {
      interpolated <- apply(data_cube, 3, function(layer) {
        gstat::idw(
          formula = value ~ 1,
          locations = as(sf::st_as_sf(
            expand.grid(lon = nc$dim$lon$vals,
                        lat = nc$dim$lat$vals),
            coords = c("lon", "lat"), crs = 4326),
            "sf"),
          newdata = coords,
          nmax = 5
        )$var1.pred
      })
    }

    # 构建输出
    tibble::tibble(
      datetime = rep(datetimes, each = nrow(coords)),
      site_id = rep(coords$site_id, times = length(datetimes)),
      variable = rep(variables, each = nrow(coords) * length(datetimes)),
      value = as.vector(interpolated)
    )
  })
}
