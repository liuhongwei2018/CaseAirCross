#' Convert Geographic Coordinate Systems (GCJ02/BD09/WGS84)
#'
#' High-precision coordinate conversion between China's GCJ02, BD09 and global WGS84 systems
#' @param lons Numeric vector of longitudes
#' @param lats Numeric vector of latitudes
#' @param from Original coordinate system ("GCJ02", "BD09", or "WGS84")
#' @param to Target coordinate system ("GCJ02", "BD09", or "WGS84")
#' @param retry Number of retry attempts for failed conversions
#' @param progress Show progress bar for batch processing
#' @return sf object containing transformed coordinates
#' @importFrom V8 v8
#' @importFrom progress progress_bar
#' @importFrom sf st_as_sf st_crs st_transform
#' @export
geo_transform <- function(lons, lats, from = "GCJ02", to = "WGS84",
                          retry = 3, progress = TRUE) {

  # Validate coordinate systems
  valid_systems <- c("GCJ02", "BD09", "WGS84")
  if (!from %in% valid_systems || !to %in% valid_systems) {
    stop("Invalid coordinate system. Supported: ", paste(valid_systems, collapse = ", "))
  }

  # Initialize JavaScript environment
  ctx <- V8::v8()
  ctx$source("https://cdn.jsdelivr.net/npm/gcoord@2.0.3/dist/gcoord.min.js")

  # Create progress bar
  pb <- if (progress) progress_bar$new(total = length(lons)) else NULL

  # Batch conversion with error handling
  transformed <- lapply(seq_along(lons), function(i) {
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
        if (attempt == retry) stop(sprintf("Conversion failed: %s", e$message))
        Sys.sleep(1)
      })
    }
  })

  # Create spatial object
  sf_result <- st_as_sf(
    data.frame(
      orig_lon = lons,
      orig_lat = lats,
      trans_lon = sapply(transformed, `[[`, 1),
      trans_lat = sapply(transformed, `[[`, 2)
    ),
    coords = c("trans_lon", "trans_lat"),
    crs = 4326
  )

  return(sf_result)
}
