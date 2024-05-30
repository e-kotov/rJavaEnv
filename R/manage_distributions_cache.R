#' List the contents of the Java distributions cache folder
#'
#' @param cache_dir The cache directory to list. Defaults to the user-specific data directory.
#' @param verbose Whether to print detailed messages. Defaults to FALSE.
#' @return A character vector with the contents of the cache directory.
#' @export
#'
#' @examples
#' java_list_distrib_cache()
#'
java_list_distrib_cache <- function(
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache"),
    verbose = FALSE) {

  if (!dir.exists(cache_dir)) {
    cli::cli_alert_danger("Path does not exist")
    return(character(0))
  }
  if(verbose) cli::cli_inform("Contents of the Java distributions cache folder:")
  java_distrs <- data.frame(java_distr_path = list.files(cache_dir, full.names = T))
  return(java_distrs)
}

#' Clear the Java distributions cache folder
#'
#' @param cache_dir The cache directory to clear. Defaults to the user-specific data directory.
#' @param check Whether to list the contents of the cache directory before clearing it. Defaults to TRUE.
#' @param confirm Whether to ask for confirmation before clearing the cache. Defaults to TRUE.
#' @return A message indicating whether the cache was cleared or not.
#' @export
#'
#' @examples
#' \dontrun{
#' java_clear_distrib_cache()
#' }
java_clear_distrib_cache <- function(
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache"),
    check = TRUE,
    confirm = TRUE) {
  if (dir.exists(cache_dir)) {
    if (confirm) {
      if (check) {
        cli::cli_inform(java_list_distrib_cache(cache_dir))
      }
      cli::cli_alert_info("Are you sure you want to clear the Java distributions cache? (yes/no)")
      response <- readline()
      if (tolower(response) != "yes") {
        cli::cli_inform("Java distributions cache was not cleared.")
        return(invisible(NULL))
      }
    }
    unlink(file.path(cache_dir, "*"), recursive = TRUE)
    cli::cli_inform("Java distributions cache cleared.")
  } else {
    cli::cli_inform("Java distributions cache is already empty.")
  }
}
