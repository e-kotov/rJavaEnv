#' Install specified Java version and set the `JAVA_HOME` and `PATH` environment variables in current R session
#'
#' @description
#' Using specified Java version, set the `JAVA_HOME` and `PATH` environment variables in the current R session. If Java distribtuion has not been downloaded yet, download it. If it was not installed into cache directory yet, install it there and then set the environment variables. This function first checks if the requested version is already present in the `rJavaEnv` cache. If found, it sets the environment immediately without downloading. If not found, it downloads and unpacks the distribution.
#'
#' This is intended as a quick and easy way to use different Java versions in R scripts that are in the same project, but require different Java versions. For example, one could use this in scripts that are called by `targets` package or `callr` package.
#'
#' @inheritSection rjava_path_locking_note rJava Path-Locking
#' @inheritParams java_download
#' @inheritParams java_install
#' @inheritParams global_quiet_param
#' @param ._skip_rjava_check Internal. If TRUE, skip the rJava initialization check.
#' @return Logical. Returns `TRUE` invisibly on success. Prints status messages if `quiet` is set to `FALSE`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#'
#' # set cache directory for Java to be in temporary directory
#' options(rJavaEnv.cache_path = tempdir())
#'
#' # For end users: Install and set Java BEFORE loading rJava packages
#' use_java(21)
#' library(myRJavaPackage)  # Now uses Java 21
#'
#' # For command-line Java tools (no rJava involved):
#' # Can switch versions between system calls
#' use_java(8)
#' system2("java", "-version")  # Shows Java 8
#' use_java(17)
#' system2("java", "-version")  # Shows Java 17
#'
#' # WARNING: Do NOT do this with rJava packages:
#' # library(rJava)          # Initializes with system Java
#' # use_java(21)            # Too late! rJava is already locked
#' # rJava still uses the Java version from before use_java() call
#'
#' }
#'
use_java <- function(
  version = NULL,
  distribution = "Corretto",
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = TRUE,
  ._skip_rjava_check = FALSE
) {
  checkmate::check_vector(version, len = 1)
  version <- as.character(version)

  # 1. Check if specific version is already in installed cache
  # This prevents java_download (and its network checks) from running if we have it.
  cache_list <- java_list_installed_cache(
    output = "data.frame",
    quiet = TRUE,
    cache_path = cache_path
  )
  found_path <- NULL

  if (length(cache_list) > 0 && nrow(cache_list) > 0) {
    # Look for exact string match on version in the specific platform/arch
    match <- cache_list[
      cache_list$version == version &
        cache_list$platform == platform &
        cache_list$arch == arch,
    ]
    if (nrow(match) > 0) {
      found_path <- match$path[1]
    }
  }

  if (!is.null(found_path)) {
    if (!quiet) {
      cli::cli_alert_info(
        "Version {version} found in cache. Setting environment..."
      )
    }
    ._java_env_set_impl(
      where = "session",
      java_home = found_path,
      quiet = quiet,
      ._skip_rjava_check = ._skip_rjava_check
    )
    if (!quiet) {
      cli::cli_alert_success(
        "Java version {version} was set in the current R session"
      )
    }
    return(invisible(TRUE))
  }

  # 2. Validate version (Network call if valid_versions cache expired)
  checkmate::assert_choice(version, java_valid_versions())

  # 3. Proceed with Download and Install
  java_distrib_path <- java_download(
    version = version,
    distribution = distribution,
    cache_path = cache_path,
    platform = platform,
    arch = arch,
    quiet = quiet
  )

  java_cached_install_path <- java_unpack(
    java_distrib_path = java_distrib_path,
    quiet = quiet
  )

  ._java_env_set_impl(
    where = "session",
    java_home = java_cached_install_path,
    quiet = quiet,
    ._skip_rjava_check = ._skip_rjava_check
  )

  if (!quiet) {
    cli::cli_alert_success(
      "Java version {version} was set in the current R session"
    )
  }
  invisible(TRUE)
}
