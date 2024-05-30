#' List the contents of the Java cache
#'
#' @param type The type of cache to list: "distrib", "installed", or "project".
#' @param output The format of the output: "data.frame" or "vector". Defaults to "data.frame".
#' @param verbose Whether to print detailed messages. Defaults to FALSE.
#' @param target_dir The cache directory to list. Defaults to the user-specific data directory for "distrib" and "installed", and the current working directory for "project".
#' @return A data frame or character vector with the contents of the specified cache directory.
#' @export
#'
#' @examples
#' java_list("project")
#' java_list("installed")
#' java_list("distrib")
#'
java_list <- function(
    type = c("project", "installed", "distrib"),
    output = c("data.frame", "vector"),
    verbose = FALSE,
    target_dir = NULL) {

  type <- match.arg(type)
  output <- match.arg(output)

  if (is.null(target_dir)) {
    if (type == "project") {
      target_dir <- getwd()
    } else {
      target_dir <- tools::R_user_dir("rJavaEnv", which = "cache")
    }
  }

  if (type == "distrib") {
    return(java_list_distrib_cache(output = output, verbose = verbose, cache_dir = target_dir))
  } else if (type == "installed") {
    return(java_list_installed_cache(output = output, verbose = verbose, cache_dir = target_dir))
  } else if (type == "project") {
    return(java_list_in_project(output = output, verbose = verbose, project_dir = target_dir))
  }
}

#' Manage Java installations and distributions caches
#'
#' Wrapper function to clear the Java symlinked in the current project, installed, or distributions caches.
#'
#' @param type What to clear: "project" - remove symlinks to install cache in the current project, "installed" - remove installed Java versions, "distrib" - remove downloaded Java distributions.
#' @param check Whether to list the contents of the cache directory before clearing it. Defaults to TRUE.
#' @param delete_all Whether to delete all items without prompting. Defaults to FALSE.
#' @param target_dir The directory to clear. Defaults to current working directory for "project" and user-specific data directory for "installed" and "distrib". Not recommended to change.
#' @return A message indicating whether the cache was cleared or not.
#' @export
#'
#' @examples
#' java_clear("project")
#' java_clear("installed")
#' java_clear("distrib")
#'
java_clear <- function(
    type = c("project", "installed", "distrib"),
    target_dir = NULL,
    check = TRUE,
    delete_all = FALSE) {

  type <- match.arg(type)

  if (is.null(target_dir)) {
    if (type == "project") {
      target_dir <- getwd()
    } else {
      target_dir <- tools::R_user_dir("rJavaEnv", which = "cache")
    }
  }

  if (type == "distrib") {
    java_clear_distrib_cache(cache_dir = target_dir, check = check, delete_all = delete_all)
  } else if (type == "installed") {
    java_clear_installed_cache(cache_dir = target_dir, check = check, delete_all = delete_all)
  } else if (type == "project") {
    java_clear_in_project(project_dir = target_dir, check = check, delete_all = delete_all)
  }
}

