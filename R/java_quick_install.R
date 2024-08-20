#' Download and install and set Java in current working/project directory
#'
#' @inheritParams java_download
#' @inheritParams java_install
#' @inheritParams global_quiet_param
#' @return Message indicating that Java was installed and set in the current working/project directory.
#' @export
#'
#' @examples
#' \dontrun{
#' 
#' # quick download, unpack, install and set in current working directory default Java version (21)
#' java_quick_install(temp_dir = TRUE)
#' }
java_quick_install <- function(
  version = 21,
  distribution = "Corretto",
  project_path = NULL,
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
  temp_dir = FALSE
) {
  rje_consent_check()

  if (temp_dir) {
    temp_dir <- tempdir()
    setwd(temp_dir)
    dir.create("rJavaEnv_cache", recursive = TRUE)
    cache_path <- file.path(temp_dir, "rJavaEnv_cache")
    dir.create("rJavaEnv_project", recursive = TRUE)
    project_path <- file.path(temp_dir, "rJavaEnv_project")
  } else {
    cache_path <- getOption("rJavaEnv.cache_path")
  }

  java_distrib_path <- java_download(
    version = version,
    distribution = distribution,
    cache_path = cache_path,
    platform = platform,
    arch = arch,
    quiet = quiet
  )

  java_install(
    java_distrib_path,
    project_path = project_path,
    autoset_java_env = TRUE,
    quiet = quiet
  )
  return(invisible(NULL))
}
