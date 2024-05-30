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

  # Check if the directory exists, if not, create it
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

  dest_file <- file.path(dest_dir, basename(url))

  if (verbose) {
    cli::cli_inform("Downloading Java {version} ({distribution}) for {platform} {arch} to {dest_file}", .envir = environment())
  }

  if (file.exists(dest_file)) {
    if (verbose) {
      cli::cli_inform("File already exists. Skipping download.", .envir = environment())
    }
  } else {
    curl::curl_download(url, dest_file, quiet = FALSE)
    if (verbose) {
      cli::cli_inform("Download completed.", .envir = environment())
    }
  }

  return(dest_file)
}
