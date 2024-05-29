#' List the contents of the Java distributions cache folder
#'
#' @param cache_dir The cache directory to list. Defaults to the user-specific data directory.
#'
#' @return A character vector with the contents of the cache directory.
#' @export
#'
#' @examples list_java_distributions_cache()
list_java_distributions_cache <- function(
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache")) {
  if (!dir.exists(cache_dir)) {
    message("Path does not exist")
  }
  message("Contents of the Java distributions cache folder:")
  list.files(cache_dir) # todo: output as a nicely formatted table
}

#' Clear the Java distributions cache folder
#'
#' @param cache_dir The cache directory to clear. Defaults to the user-specific data directory.
#' @param check Whether to list the contents of the cache directory before clearing it. Defaults to TRUE.
#' @param confirm Whether to ask for confirmation before clearing the cache. Defaults to TRUE.
#' @return A message indicating whether the cache was cleared or not.
#' @export
#'
#' @examples clear_java_distributions_cache()
clear_java_distributions_cache <- function(
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache"),
    check = TRUE,
    confirm = TRUE) {
  if (dir.exists(cache_dir)) {
    if (confirm) {
      if (check) {
        message(list_java_distributions_cache(cache_dir))
      }
      message("Are you sure you want to clear the Java distributions cache? (yes/no)")
      response <- readline()
      if (tolower(response) != "yes") {
        # exit with message
        message("Java distributions cache was not cleared.")
        return(invisible(NULL))
      }
    }
    unlink(cache_dir, recursive = TRUE)
    message("Java distributions cache cleared.")
  } else {
    message("Java distributions cache is already empty.")
  }
}
