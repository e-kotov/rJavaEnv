#' Download and install and set Java in current working/project directory
#'
#' @inheritParams java_download
#' @inheritParams java_install
#' @inheritParams global_backend_param
#' @inheritParams global_quiet_param
#' @return Invisibly returns the path to the Java home directory. If quiet is set to `FALSE`, also prints a message indicating that Java was installed and set in the current working/project directory.
#' @export
#'
#' @examples
#' \donttest{
#'
#' # quick download, unpack, install and set in current working directory default Java version (21)
#' java_quick_install(17, temp_dir = TRUE)
#' }
java_quick_install <- function(
  version = 21,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  project_path = NULL,
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
  temp_dir = FALSE
) {
  rje_consent_check()

  if (temp_dir) {
    # Use session temp directory
    temp_path <- tempdir()

    cache_path <- file.path(temp_path, "rJavaEnv_cache")
    if (!dir.exists(cache_path)) {
      dir.create(cache_path, recursive = TRUE)
    }

    project_path <- file.path(temp_path, "rJavaEnv_project")
    if (!dir.exists(project_path)) {
      dir.create(project_path, recursive = TRUE)
    }
  } else {
    cache_path <- getOption("rJavaEnv.cache_path")
  }

  java_distrib_path <- java_download(
    version = version,
    distribution = distribution,
    backend = backend,
    cache_path = cache_path,
    platform = platform,
    arch = arch,
    quiet = quiet
  )

  java_home <- java_install(
    java_distrib_path,
    project_path = project_path,
    autoset_java_env = TRUE,
    quiet = quiet
  )
  return(invisible(java_home))
}
