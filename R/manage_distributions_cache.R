#' List the contents of the Java distributions cache folder
#'
#' @param cache_dir The cache directory to list. Defaults to the user-specific data directory.
#'
#' @return A character vector with the contents of the cache directory.
#' @export
#'
#' @examples java_cache_list()
java_cache_list <- function(
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache")) {
  if (!dir.exists(cache_dir)) {
    pkg_message("Path does not exist")
    return(character(0))
  }
  pkg_message("Contents of the Java distributions cache folder:")
  list.files(cache_dir) # TODO: output as a nicely formatted table
}

#' Clear the Java distributions cache folder
#'
#' @param cache_dir The cache directory to clear. Defaults to the user-specific data directory.
#' @param check Whether to list the contents of the cache directory before clearing it. Defaults to TRUE.
#' @param confirm Whether to ask for confirmation before clearing the cache. Defaults to TRUE.
#' @return A message indicating whether the cache was cleared or not.
#' @export
#'
#' @examples java_cache_clear()
java_cache_clear <- function(
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache"),
    check = TRUE,
    confirm = TRUE) {
  if (dir.exists(cache_dir)) {
    if (confirm) {
      if (check) {
        pkg_message(java_cache_list(cache_dir))
      }
      pkg_message("Are you sure you want to clear the Java distributions cache? (yes/no)")
      response <- readline()
      if (tolower(response) != "yes") {
        # exit with message
        pkg_message("Java distributions cache was not cleared.")
        return(invisible(NULL))
      }
    }
    unlink(cache_dir, recursive = TRUE)
    pkg_message("Java distributions cache cleared.")
  } else {
    pkg_message("Java distributions cache is already empty.")
  }
}
