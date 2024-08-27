#' Install specified Java version and set the `JAVA_HOME` and `PATH` environment variables in current R session
#' 
#' @description
#' Using specified Java version, set the `JAVA_HOME` and `PATH` environment variables in the current R session. If Java distribtuion has not been downloaded yet, download it. If it was not installed into cache directory yet, install it there and then set the environment variables. This is intended as a quick and easy way to use different Java versions in R scripts that are in the same project, but require different Java versions. For example, one could use this in scripts that are called by `targets`` package or `callr` package.
#' @inheritParams java_download
#' @inheritParams java_install
#' @inheritParams global_quiet_param
#' @return `NULL`. Prints the message that Java was set in the current R session if `quiet` is set to `FALSE`.
#' 
#' @export
#' 
#' @examples
#' \dontrun{
#' 
#' # set cache directory for Java to be in temporary directory
#' options(rJavaEnv.cache_path = tempdir())
#' 
#' # install and set Java 8 in current R session
#' use_java(8)
#' 
#' # install and set Java 17 in current R session
#' use_java(17)
#' 
#' }
#' 
use_java <- function(
  version = NULL,
  distribution = "Corretto",
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = TRUE
){
  checkmate::check_vector(version, len = 1)
  version <- as.character(version)
  checkmate::assert_choice(version, getOption("rJavaEnv.valid_major_java_versions"))

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

  java_env_set(
    where = "session",
    java_home = java_cached_install_path,
    quiet = quiet
  )

  if (!quiet) {
    cli::cli_alert_success("Java version {version} was set in the current R session")
  }
}
