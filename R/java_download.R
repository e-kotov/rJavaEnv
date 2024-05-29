#' Download a Java distribution
#'
#' @param version The Java version to download. If not specified, defaults to the latest LTS version.
#' @param distribution The Java distribution to download. If not specified, defaults to "Corretto".
#' @param dest_dir The destination directory to download the Java distribution to. Defaults to a user-specific data directory.
#' @param platform The platform for which to download the Java distribution. Defaults to the current platform.
#' @param arch The architecture for which to download the Java distribution. Defaults to the current architecture.
#' @param verbose Whether to print out information about the detected platform and architecture. Defaults to TRUE.
#'
#' @return The path to the downloaded Java distribution file.
#' @export
#'
#' @examples
#' \dontrun{
#' java_download(version = "17", distribution = "Corretto")
#' java_download(distribution = "Corretto")
#' java_download()
#' }
java_download <- function(version = 21,
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