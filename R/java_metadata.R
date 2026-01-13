#' Java build metadata object
#'
#' Constructor for java_build objects that contain all metadata needed for download
#'
#' @param vendor Java vendor name (e.g., "Corretto", "Temurin", "Zulu")
#' @param major Major Java version number
#' @param semver Full semantic version string (optional)
#' @param platform Platform OS (e.g., "linux", "macos", "windows")
#' @param arch Architecture (e.g., "x64", "aarch64")
#' @param download_url URL to download the Java distribution
#' @param filename Filename for the downloaded archive
#' @param checksum Expected checksum value for verification
#' @param checksum_type Type of checksum (e.g., "md5", "sha256", "sha512")
#' @param backend Backend used for resolution ("native" or "sdkman")
#'
#' @return A java_build object (S3 list)
#' @keywords internal
java_build <- function(
  vendor,
  version,
  major = NULL,
  semver = NA_character_,
  platform,
  arch,
  download_url,
  filename,
  checksum = NULL,
  checksum_type = NULL,
  backend = "native"
) {
  # derive major if not provided
  if (is.null(major)) {
    # Try to parse major from version string (e.g. "11.0.2" -> 11)
    # Remove "jdk-" prefix if present
    v_clean <- sub("^jdk-?", "", version)
    major_candidate <- suppressWarnings(as.integer(sub(
      "^([0-9]+).*",
      "\\1",
      v_clean
    )))
    if (!is.na(major_candidate)) {
      major <- major_candidate
    } else {
      major <- NA_integer_
    }
  }

  structure(
    list(
      vendor = vendor,
      major = as.integer(major),
      version = version,
      semver = semver,
      platform = platform,
      arch = arch,
      download_url = download_url,
      filename = filename,
      checksum = checksum,
      checksum_type = checksum_type,
      backend = backend
    ),
    class = "java_build"
  )
}

#' Resolve Java download metadata
#'
#' Dispatches metadata resolution to the appropriate backend and distribution resolver
#'
#' @param version Major Java version (e.g., 21, 17, 11)
#' @param distribution Java distribution name ("Corretto", "Temurin", or "Zulu")
#' @param platform Platform OS (e.g., "linux", "macos", "windows")
#' @param arch Architecture (e.g., "x64", "aarch64")
#' @param backend Download backend to use: "native" (vendor APIs) or "sdkman"
#'
#' @return A java_build object containing all download metadata
#' @keywords internal
resolve_java_metadata <- function(
  version,
  distribution = "Corretto",
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  backend = getOption("rJavaEnv.backend", "native")
) {
  # SDKMAN backend
  if (backend == "sdkman") {
    return(resolve_sdkman_metadata(version, distribution, platform, arch))
  }

  # Native vendor APIs
  switch(
    distribution,
    "Corretto" = resolve_corretto_metadata(version, platform, arch),
    "Temurin" = resolve_temurin_metadata(version, platform, arch),
    "Zulu" = resolve_zulu_metadata(version, platform, arch),
    cli::cli_abort("Unknown distribution: {distribution}")
  )
}
