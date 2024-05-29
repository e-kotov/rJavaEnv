#' Download and install and set Java in current working/project directory
#'
#' @inheritParams java_download
#' @param verbose Whether to print messages. Defaults to TRUE.
#' @return Message indicating that Java was installed and set in the current working/project directory.
#' @export
#'
#' @examples java_quick_install()
java_quick_install <- function(
    version = 21,
    distribution = "Corretto",
    platform = platform_detect()$os,
    arch = platform_detect()$arch,
    verbose = TRUE) {

  java_distr_path <- java_download(
    version = version,
    distribution = distribution,
    platform = platform,
    arch = arch,
    verbose = verbose
  )

  java_install(java_distr_path, autoset_java_path = TRUE)
  return(invisible(NULL))
}
