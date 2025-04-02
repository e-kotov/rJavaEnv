#' Retrieve Valid Java Versions
#'
#' This function retrieves a list of valid Java versions by querying an appropriate API endpoint based on the chosen distribution.
#' The result is cached for 8 hours to avoid repeated API calls. If the API call fails (for example, due to a lack of internet connectivity),
#' the function falls back to a pre-defined list of Java versions.
#'
#' @param distribution Character. The Java distribution to use. If set to `"Oracle"`, the Oracle API is used.
#'   If set to `"Corretto"` (the default), an Amazon Corretto endpoint is used.
#' @param force Logical. If TRUE, forces a fresh API call even if a cached value exists. Defaults to FALSE.
#'
#' @return A character vector of valid Java versions.
#'
#' @examples
#' \dontrun{
#'   # Retrieve valid Java versions (cached if available) using Amazon Corretto endpoint
#'   versions <- java_valid_versions()
#'
#'   # Force refresh the list of Java versions using the Oracle endpoint
#'   versions <- java_valid_versions(distribution = "Corretto", force = TRUE)
#' }
#'
#' @export
#'
java_valid_versions <- function(
  distribution = "Corretto",
  force = FALSE
) {
  # Define cache expiry time (in hours)
  expiry_hours <- 8

  # Retrieve cached values from options
  valid_versions_cache <- getOption("rJavaEnv.valid_versions_cache")
  valid_versions_timestamp <- getOption("rJavaEnv.valid_versions_timestamp")

  # Return cached value if available and not expired, unless force is TRUE.
  if (
    !force &&
      !is.null(valid_versions_cache) &&
      !is.null(valid_versions_timestamp) &&
      as.numeric(difftime(
        Sys.time(),
        valid_versions_timestamp,
        units = "hours"
      )) <
        expiry_hours
  ) {
    return(valid_versions_cache)
  }

  # Select helper based on distribution value.
  new_versions <- switch(
    distribution,
    # "Oracle" = java_valid_versions_oracle(),
    "Corretto" = java_valid_major_versions_corretto(),
    stop("Unsupported distribution")
  )

  # Update the cache options with the new values and current timestamp.
  options(
    rJavaEnv.valid_versions_cache = new_versions,
    rJavaEnv.valid_versions_timestamp = Sys.time()
  )

  return(new_versions)
}

#' Get Available Online Versions of Amazon Corretto
#'
#' This function downloads the latest Amazon Corretto version information from the
#' Corretto GitHub endpoint and returns a data frame with details for all eligible releases.
#'
#' It leverages the existing \code{platform_detect()} function to infer the current operating
#' system and architecture if these are not provided.
#'
#' @param arch Optional character string for the target architecture (e.g., "x64").
#'   If \code{NULL}, it is inferred using \code{platform_detect()}.
#' @param platform Optional character string for the operating system (e.g., "windows", "macos", "linux").
#'   If \code{NULL}, it is inferred using \code{platform_detect()}.
#' @param imageType Optional character string to filter on; defaults to \code{"jdk"}.
#' @param extension Optional character string specifying the desired file extension; defaults to \code{"tar.gz"}.
#'
#' @return A `character` vector of available major Corretto versions.
#'
#' @keywords internal
#'
java_valid_major_versions_corretto <- function(
  arch = NULL,
  platform = NULL,
  imageType = "jdk",
  extension = "tar.gz"
) {
  # If platform or arch are not provided, detect them using the existing function.
  if (is.null(platform) || is.null(arch)) {
    plat <- platform_detect(quiet = TRUE)
    if (is.null(platform)) platform <- plat$os
    if (is.null(arch)) arch <- plat$arch
  }

  # URL for the Corretto version information.
  availableVersionsUrl <- "https://corretto.github.io/corretto-downloads/latest_links/indexmap_with_checksum.json"

  # Fetch and parse the JSON using httr.
  corretto_versions <- tryCatch(
    {
      json_data <- jsonlite::read_json(availableVersionsUrl)
      eligible <- json_data[[platform]][[arch]][[imageType]]
      if (is.null(eligible)) {
        stop(
          "No eligible versions found for the specified platform, architecture, and image type."
        )
      }
      names(eligible)
    },
    error = function(e) {
      getOption("rJavaEnv.fallback_valid_versions")
    }
  )

  corretto_versions <- as.character(sort(as.numeric(corretto_versions)))
  return(corretto_versions)
}

# Helper function for Oracle distribution
# java_valid_versions_oracle <- function() {
#   oracle_api_url <- "https://java.oraclecloud.com/javaVersions"
#   tryCatch(
#     {
#       oracle_java_versions <- jsonlite::fromJSON(
#         oracle_api_url,
#         simplifyDataFrame = TRUE
#       )
#       # Combine "8" and "11" with the sorted versions from the API
#       c("8", "11", sort(as.character(oracle_java_versions$items$jdkVersion)))
#     },
#     error = function(e) {
#       # If the API call fails, use the fallback list stored in options.
#       getOption("rJavaEnv.fallback_valid_versions")
#     }
#   )
# }
