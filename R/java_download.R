#' Download a Java distribution
#'
#' @inheritParams global_version_param
#' @param distribution The Java distribution to download. One of "Corretto", "Temurin", or "Zulu". Defaults to "Corretto". Ignored if `version` is a SDKMAN identifier.
#' @inheritParams global_backend_param
#' @param cache_path The destination directory to download the Java distribution to. Defaults to a user-specific data directory.
#' @param platform The platform for which to download the Java distribution. Defaults to the current platform.
#' @param arch The architecture for which to download the Java distribution. Defaults to the current architecture.
#' @param force A logical. Whether the distribution file should be overwritten or not. Defaults to `FALSE`.
#' @param temp_dir A logical. Whether the file should be saved in a temporary directory. Defaults to `FALSE`.
#' @inheritParams global_quiet_param
#' @inheritParams global_sdkman_references
#'
#' @return The path to the downloaded Java distribution file.
#' @export
#'
#' @examples
#' \donttest{
#'
#' # download distribution of Java version 17
#' java_download(version = "17", temp_dir = TRUE)
#'
#' # download default Java distribution (version 21)
#' java_download(temp_dir = TRUE)
#'
#' # download using SDKMAN backend
#' java_download(version = "21", backend = "sdkman", temp_dir = TRUE)
#' }
java_download <- function(
  version = 21,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
  force = FALSE,
  temp_dir = FALSE
) {
  # Override cache_path if temp_dir is set to TRUE
  # Override cache_path if temp_dir is set to TRUE
  if (temp_dir) {
    cache_path <- file.path(tempdir(), "rJavaEnv_cache")
    if (!dir.exists(cache_path)) {
      dir.create(cache_path, recursive = TRUE)
    }
  }

  # Validate version
  version <- as.character(version)
  checkmate::check_vector(version, len = 1)

  # Auto-detect SDKMAN identifier
  if (is_sdkman_identifier(version)) {
    if (!quiet) {
      cli::cli_alert_info(
        "Detected SDKMAN identifier {.val {version}}. Using sdkman backend."
      )
    }
    backend <- "sdkman"
    distribution <- sdkman_vendor_to_distribution(sdkman_vendor_code(version))
    if (!quiet) {
      cli::cli_alert_info("Distribution: {.val {distribution}}")
    }
  }

  # Validate distribution (only for native backend)
  if (backend == "native") {
    valid_distributions <- c("Corretto", "Temurin", "Zulu")
    checkmate::assert_choice(distribution, valid_distributions)
  }

  # Validate backend
  valid_backends <- c("native", "sdkman")
  checkmate::assert_choice(backend, valid_backends)

  # Print detected platform and architecture
  if (!quiet) {
    cli::cli_inform(c(
      "Detected platform: {.strong {platform}}",
      "Detected architecture: {.strong {arch}}",
      "You can change the platform and architecture by specifying the {.arg platform} and {.arg arch} arguments."
    ))
  }

  # Resolve metadata
  build <- resolve_java_metadata(version, distribution, platform, arch, backend)

  # Prepare destination directory
  dest_dir <- file.path(cache_path, "distrib")
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }
  dest <- file.path(dest_dir, build$filename)

  # Download and verify
  result_path <- download_java_with_checksum(build, dest, quiet, force)

  # Attach metadata attributes for downstream functions
  attr(result_path, "distribution") <- distribution
  attr(result_path, "backend") <- backend
  attr(result_path, "version") <- version
  attr(result_path, "platform") <- platform
  attr(result_path, "arch") <- arch

  result_path
}

#' Download and verify checksum
#'
#' Internal function to download a Java distribution and verify its checksum
#'
#' @param build A java_build object containing download metadata
#' @param dest Destination file path
#' @param quiet Logical, suppress messages
#' @param force Logical, overwrite existing files
#'
#' @return Path to downloaded file
#' @keywords internal
download_java_with_checksum <- function(build, dest, quiet, force) {
  # Check if file already exists
  if (file.exists(dest) && !force) {
    if (!quiet) {
      cli::cli_inform("File already cached: {basename(dest)}")
    }
    return(dest)
  }

  # Remove existing file if force=TRUE
  if (file.exists(dest) && force) {
    if (!quiet) {
      cli::cli_inform("Removing existing file...")
    }
    unlink(dest)
  }

  # Download
  if (!quiet) {
    cli::cli_inform("Downloading {build$vendor} Java {build$major}...")
  }
  curl::curl_download(build$download_url, dest, quiet = quiet)

  # Verify checksum if available
  if (!is.null(build$checksum) && !is.null(build$checksum_type)) {
    if (!quiet) {
      cli::cli_inform("Verifying {build$checksum_type} checksum...")
    }

    actual <- switch(
      build$checksum_type,
      "md5" = tools::md5sum(dest),
      "sha256" = digest::digest(dest, algo = "sha256", file = TRUE),
      "sha512" = digest::digest(dest, algo = "sha512", file = TRUE),
      NULL
    )

    if (!is.null(actual) && actual != build$checksum) {
      unlink(dest)
      cli::cli_abort("{build$checksum_type} checksum mismatch! File deleted.")
    }

    if (!quiet) cli::cli_inform("Checksum verified.")
  } else if (build$backend == "sdkman") {
    if (!quiet) {
      cli::cli_alert_warning("Skipping checksum (unavailable for SDKMAN)")
    }
  }

  dest
}

#' Get extension for platform
#' @keywords internal
get_java_archive_extension <- function(platform) {
  if (platform == "windows") "zip" else "tar.gz"
}
