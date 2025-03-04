#' Download a Java distribution
#'
#' @param version `Integer` or `character` vector of length 1 for major version of Java to download or install. If not specified, defaults to the latest LTS version. Can be "8", "11", "17", "21", "22", or 8, 11, 17, 21, or 22.
#' @param distribution The Java distribution to download. If not specified, defaults to "Amazon Corretto". Currently only \href{https://aws.amazon.com/corretto/}{"Amazon Corretto"} is supported.
#' @param cache_path The destination directory to download the Java distribution to. Defaults to a user-specific data directory.
#' @param platform The platform for which to download the Java distribution. Defaults to the current platform.
#' @param arch The architecture for which to download the Java distribution. Defaults to the current architecture.
#' @param force A logical. Whether the distribution file should be overwritten or not. Defaults to `FALSE`.
#' @param temp_dir A logical. Whether the file should be saved in a temporary directory. Defaults to `FALSE`.
#' @inheritParams global_quiet_param
#'
#' @return The path to the downloaded Java distribution file.
#' @export
#'
#' @examples
#' \dontrun{
#'
#' # download distribution of Java version 17
#' java_download(version = "17", temp_dir = TRUE)
#'
#' # download default Java distribution (version 21)
#' java_download(temp_dir = TRUE)
#' }
java_download <- function(
  version = 21,
  distribution = "Corretto",
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
  force = FALSE,
  temp_dir = FALSE
) {

  # override cache_path if temp_dir is set to TRUE
  if (temp_dir) {
    temp_dir <- tempdir()
    setwd(temp_dir)
    if (!dir.exists("rJavaEnv_cache")) {
      dir.create("rJavaEnv_cache", recursive = TRUE)
    }
    cache_path <- file.path(temp_dir, "rJavaEnv_cache")
  }

  # rje_consent_check() # disabling consent check for now
  java_urls <- java_urls_load()

  valid_distributions <- names(java_urls)
  valid_platforms <- names(java_urls[[distribution]])
  valid_architectures <- names(java_urls[[distribution]][[platform]])

  # Checks for the parameters
  checkmate::check_vector(version, len = 1)
  version <- as.character(version)
  checkmate::assert_choice(version, getOption("rJavaEnv.valid_major_java_versions"))

  checkmate::assert_choice(distribution, valid_distributions)

  # Create the distrib subfolder within the destination directory
  cache_path <- file.path(cache_path, "distrib")
  if (!dir.exists(cache_path)) {
    dir.create(cache_path, recursive = TRUE)
  }
  checkmate::assert_directory_exists(cache_path, access = "rw", add = TRUE)

  checkmate::assert_choice(platform, valid_platforms)
  checkmate::assert_choice(arch, valid_architectures)
  checkmate::assert_flag(quiet)

  # Print out the detected platform and architecture
  if (!quiet) {
    cli::cli_inform(c(
      "Detected platform: {.strong {platform}}",
      "Detected architecture: {.strong {arch}}",
      "You can change the platform and architecture by specifying the {.arg platform} and {.arg arch} arguments."
    ))
  }

  if (!distribution %in% names(java_urls)) {
    cli::cli_abort("Unsupported distribution: {.val {distribution}}", .envir = environment())
  }

  if (!platform %in% names(java_urls[[distribution]])) {
    cli::cli_abort("Unsupported platform: {.val {platform}}", .envir = environment())
  }

  if (!arch %in% names(java_urls[[distribution]][[platform]])) {
    cli::cli_abort("Unsupported architecture: {.val {arch}}", .envir = environment())
  }

  url_template <- java_urls[[distribution]][[platform]][[arch]]
  url <- gsub("\\{version\\}", version, url_template)
  url_md5 <- gsub("latest/", "latest_checksum/", url)

  dest_file <- file.path(cache_path, basename(url))
  dest_file_md5 <- paste0(file.path(cache_path, basename(url_md5)), ".md5")


  if (!quiet) {
    cli::cli_inform("Downloading Java {version} ({distribution}) for {platform} {arch} to {dest_file}", .envir = environment())
  }

  if (file.exists(dest_file) & !force) {
    if (!quiet) {
      cli::cli_inform("File already exists. Skipping download.", .envir = environment())
    }
  } else if(file.exists(dest_file) & force){
    if (!quiet) {
      cli::cli_inform("Removing existing installation.", .envir = environment())
    }
    file.remove(dest_file)
    curl::curl_download(url, dest_file, quiet = FALSE)
    curl::curl_download(url_md5, dest_file_md5, quiet = TRUE)
    if (!quiet) {
      cli::cli_inform("Download completed.", .envir = environment())

      md5sum <- tools::md5sum(dest_file)
      md5sum_expected <- readLines(dest_file_md5, warn = FALSE)

      if (md5sum != md5sum_expected) {
        cli::cli_alert_danger("MD5 checksum mismatch. Please try downloading the file again.", .envir = environment())
        unlink(dest_file)
        return(NULL)
      } else {
        cli::cli_inform("MD5 checksum verified.", .envir = environment())
      }
    }
  } else if (!file.exists(dest_file)){
    curl::curl_download(url, dest_file, quiet = FALSE)
    curl::curl_download(url_md5, dest_file_md5, quiet = TRUE)
    if (!quiet) {
      cli::cli_inform("Download completed.", .envir = environment())

      md5sum <- tools::md5sum(dest_file)
      md5sum_expected <- readLines(dest_file_md5, warn = FALSE)

      if (md5sum != md5sum_expected) {
        cli::cli_alert_danger("MD5 checksum mismatch. Please try downloading the file again.", .envir = environment())
        unlink(dest_file)
        return(NULL)
      } else {
        cli::cli_inform("MD5 checksum verified.", .envir = environment())
      }
    }
  }

  return(dest_file)
}
