#' List the contents of the Java distributions cache folder
#'
#' @param output The format of the output: "data.frame" or "vector". Defaults to "data.frame".
#' @param verbose Whether to print detailed messages. Defaults to FALSE.
#' @param cache_dir The cache directory to list. Defaults to the user-specific data directory.
#' @return A character vector with the contents of the cache directory.
#' @export
#'
#' @examples
#' java_list_distrib_cache()
#'
java_list_distrib_cache <- function(
    output = c("data.frame", "vector"),
    verbose = FALSE,
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache")) {
  output <- match.arg(output)

  cache_dir <- file.path(cache_dir, "distrib")

  if (!dir.exists(cache_dir)) {
    cli::cli_alert_danger("Path does not exist")
    return(character(0))
  }
  if (verbose) cli::cli_inform("Contents of the Java distributions cache folder:")

  if (output == "vector") {
    java_distrs <- list.files(cache_dir, full.names = TRUE)
    return(java_distrs)
  } else if (output == "data.frame") {
    java_distrs <- data.frame(java_distr_path = list.files(cache_dir, full.names = TRUE))
    return(java_distrs)
  }
}

#' Clear the Java distributions cache folder
#'
#' @param cache_dir The cache directory to clear. Defaults to the user-specific data directory.
#' @param check Whether to list the contents of the cache directory before clearing it. Defaults to TRUE.
#' @param delete_all Whether to delete all distributions without prompting. Defaults to FALSE.
#' @return A message indicating whether the cache was cleared or not.
#' @export
#'
#' @examples
#' \dontrun{
#' java_clear_distrib_cache()
#' }
java_clear_distrib_cache <- function(
    check = TRUE,
    delete_all = FALSE,
    cache_dir = tools::R_user_dir("rJavaEnv", which = "cache")) {
  rje_consent_check()
  
  distrib_cache_dir <- file.path(cache_dir, "distrib")

  if (!dir.exists(distrib_cache_dir)) {
    cli::cli_inform("Java distributions cache is already empty.")
    return(invisible(NULL))
  }

  if (delete_all) {
    unlink(file.path(distrib_cache_dir, "*"), recursive = TRUE)
    cli::cli_inform("Java distributions cache cleared.")
    return(invisible(NULL))
  }

  if (check) {
    distributions <- java_list_distrib_cache(output = "vector", cache_dir = cache_dir)
    if (length(distributions) == 0) {
      cli::cli_inform("No Java distributions found to clear.")
      return(invisible(NULL))
    }

    cli::cli_alert_info("Existing Java distributions:")
    for (i in seq_along(distributions)) {
      cli::cli_inform("{i}: {distributions[i]}")
    }

    cli::cli_alert_info("Enter the number of the distribution to delete, 'all' to delete all, or '0' or any other character to cancel:")
    response <- readline()

    if (tolower(response) == "all") {
      unlink(file.path(distrib_cache_dir, "*"), recursive = TRUE)
      cli::cli_inform("All Java distributions have been cleared.")
    } else {
      choice <- suppressWarnings(as.integer(response))
      if (is.na(choice) || choice == 0 || choice > length(distributions)) {
        cli::cli_inform("No distributions were cleared.")
      } else {
        unlink(distributions[choice], recursive = TRUE)
        cli::cli_inform("Java distribution {choice} has been cleared.")
      }
    }
  } else {
    cli::cli_alert_info("Are you sure you want to clear the Java distributions cache? (yes/no)")
    response <- readline()
    if (tolower(response) == "yes") {
      unlink(file.path(distrib_cache_dir, "*"), recursive = TRUE)
      cli::cli_inform("Java distributions cache cleared.")
    } else {
      cli::cli_inform("Java distributions cache was not cleared.")
    }
  }

  return(invisible(NULL))
}
