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
download_java <- function(version = "17", distribution = "Corretto", dest_dir = rappdirs::user_data_dir("R/java"), platform = .detect_platform()$os, arch = .detect_platform()$arch) {
  java_urls <- .load_java_urls()

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
