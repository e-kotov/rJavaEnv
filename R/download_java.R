#' Download a Java distribution
#'
#' @param version The Java version to download. If not specified, defaults to the latest LTS version.
#' @param distribution The Java distribution to download. If not specified, defaults to "Corretto".
#' @param dest_dir The destination directory to download the Java distribution to. Defaults to a user-specific data directory.
#' @param platform The platform for which to download the Java distribution. Defaults to the current platform.
#' @param arch The architecture for which to download the Java distribution. Defaults to the current architecture.
#'
#' @return The path to the downloaded Java distribution file.
#' @export
#'
#' @examples
#' \dontrun{
#' download_java(version = "17", distribution = "Corretto")
#' download_java(distribution = "Corretto")
#' download_java()
#' }
download_java <- function(version = 21,
                          distribution = "Corretto",
                          dest_dir = tools::R_user_dir("rJavaEnv", which = "cache"),
                          platform = .detect_platform()$os,
                          arch = .detect_platform()$arch,
                          verbose = TRUE) {
  java_urls <- .load_java_urls()

  # print out the detected platform and architecture
  if (verbose) {
    message(sprintf("Detected platform: %s", platform))
    message(sprintf("Detected architecture: %s", arch))
    message("You can change the platform and architecture by specifying the 'platform' and 'arch' arguments.")
  }

  if (!distribution %in% names(java_urls)) {
    stop("Unsupported distribution")
  }

  if (!platform %in% names(java_urls[[distribution]])) {
    stop("Unsupported platform")
  }

  if (!arch %in% names(java_urls[[distribution]][[platform]])) {
    stop("Unsupported architecture")
  }

  url_template <- java_urls[[distribution]][[platform]][[arch]]
  url <- gsub("\\{version\\}", version, url_template)

  dest_file <- file.path(dest_dir, basename(url))

  message(sprintf("Downloading Java %s (%s) for %s %s to %s", version, distribution, platform, arch, dest_file))

  if (file.exists(dest_file)) {
    message("File already exists. Skipping download.")
  } else {
    if (!dir.exists(dest_dir)) {
      dir.create(dest_dir, recursive = TRUE)
    }
    curl::curl_download(url, dest_file, quiet = FALSE)
    message("Download completed.")
  }

  return(dest_file)
}

#' List the contents of the Java distributions cache folder
#'
#' @param cache_dir The cache directory to list. Defaults to the user-specific data directory.
#'
#' @return A character vector with the contents of the cache directory.
#' @export
#'
#' @examples list_java_distributions_cache()
list_java_distributions_cache <- function(
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache")) {
  if (!dir.exists(cache_dir)) {
    message("Path does not exist")
  }
  message("Contents of the Java distributions cache folder:")
  list.files(cache_dir) # todo: output as a nicely formatted table
}

#' Clear the Java distributions cache folder
#'
#' @param cache_dir The cache directory to clear. Defaults to the user-specific data directory.
#'
#' @return A message indicating whether the cache was cleared or not.
#' @export
#'
#' @examples clear_java_distributions_cache()
clear_java_distributions_cache <- function(
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache"),
    check = TRUE,
    confirm = TRUE) {
  if (dir.exists(cache_dir)) {
    if (confirm) {
      if (check) {
        print(list_java_distributions_cache(cache_dir))
      }
      message("Are you sure you want to clear the Java distributions cache? (yes/no)")
      response <- readline()
      if (tolower(response) != "yes") {
        # exit with message
        message("Java distributions cache was not cleared.")
        return(invisible(NULL))
      }
    }
    unlink(cache_dir, recursive = TRUE)
    message("Java distributions cache cleared.")
  } else {
    message("Java distributions cache is already empty.")
  }
}
