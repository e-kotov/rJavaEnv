#' Download a Java distribution
#'
#' @param version The Java version to download. If not specified, defaults to the latest LTS version.
#' @param distribution The Java distribution to download. If not specified, defaults to "Corretto".
#' @param dest_dir The destination directory to download the Java distribution to. Defaults to a user-specific data directory.
#' @param platform The platform for which to download the Java distribution. Defaults to the current platform.
#' @param arch The architecture for which to download the Java distribution. Defaults to the current architecture.
#' @param verbose Whether to print detailed messages. Defaults to TRUE.
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
                          platform = platform_detect()$os,
                          arch = platform_detect()$arch,
                          verbose = TRUE) {
  java_urls <- java_urls_load()

  valid_distributions <- names(java_urls)
  valid_platforms <- names(java_urls[[distribution]])
  valid_architectures <- names(java_urls[[distribution]][[platform]])

  # Checks for the parameters
  checkmate::assert(
    checkmate::check_integerish(version, lower = 1),
    checkmate::check_character(version, pattern = "^[0-9]+$")
  )
  checkmate::assert_choice(distribution, valid_distributions)

  # Create the distrib subfolder within the destination directory
  dest_dir <- file.path(dest_dir, "distrib")
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }
  checkmate::assert_directory_exists(dest_dir, access = "rw", add = TRUE)

  checkmate::assert_choice(platform, valid_platforms)
  checkmate::assert_choice(arch, valid_architectures)
  checkmate::assert_flag(verbose)

  # Print out the detected platform and architecture
  if (verbose) {
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

  dest_file <- file.path(dest_dir, basename(url))
  dest_file_md5 <- paste0(file.path(dest_dir, basename(url_md5)), ".md5")


  if (verbose) {
    cli::cli_inform("Downloading Java {version} ({distribution}) for {platform} {arch} to {dest_file}", .envir = environment())
  }

  if (file.exists(dest_file)) {
    if (verbose) {
      cli::cli_inform("File already exists. Skipping download.", .envir = environment())
    }
  } else {
    curl::curl_download(url, dest_file, quiet = FALSE)
    curl::curl_download(url_md5, dest_file_md5, quiet = TRUE)
    if (verbose) {
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
