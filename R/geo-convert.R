#' 高精度地理坐标系转换（支持GCJ02/BD09/WGS84互转）
#' @param lons 经度向量
#' @param lats 纬度向量
#' @param from 原坐标系类型（'GCJ02'/'BD09'/'WGS84'）
#' @param to 目标坐标系类型
#' @param retry 网络请求重试次数
#' @param progress 显示进度条
#' @return 包含转换后坐标的sf对象
#' @importFrom V8 v8
#' @importFrom future.apply future_lapply
#' @importFrom progress progress_bar
#' @export
geo_convert <- function(lons, lats, from = "GCJ02", to = "WGS84",
                        retry = 3, progress = TRUE) {
  # 坐标系校验
  coord_systems <- c("GCJ02", "BD09", "WGS84")
  if (!from %in% coord_systems || !to %in% coord_systems) {
    stop("无效坐标系，支持：", paste(coord_systems, collapse = "/"))
  }

  # 创建V8环境（带缓存）
  ctx <- V8::v8()
  ctx$source("https://cdn.jsdelivr.net/npm/gcoord@2.0.3/dist/gcoord.min.js")

  # 进度条设置
  pb <- if (progress) progress_bar$new(total = length(lons)) else NULL

  # 并行转换
  result <- future_lapply(seq_along(lons), function(i) {
    for (attempt in 1:retry) {
      tryCatch({
        ctx$assign("input", list(lons[i], lats[i]))
        ctx$eval(sprintf(
          "output = gcoord.transform(input, gcoord.%s, gcoord.%s)",
          from, to))
        res <- ctx$get("output")
        if (!is.null(pb)) pb$tick()
        return(res)
      }, error = function(e) {
        if (attempt == retry) stop("转换失败: ", e$message)
        Sys.sleep(1)
      })
    }
  }, future.seed = TRUE)

  # 转换为sf对象
  sf_result <- sf::st_as_sf(
    data.frame(
      lon_orig = lons,
      lat_orig = lats,
      lon_dest = sapply(result, `[[`, 1),
      lat_dest = sapply(result, `[[`, 2)
    ),
    coords = c("lon_dest", "lat_dest"),
    crs = 4326
  )

  return(sf_result)
}
