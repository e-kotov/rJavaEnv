#' List the contents of the Java distributions cache folder
#'
#' @param output The format of the output: "data.frame" or "vector". Defaults to "data.frame".
#' @inheritParams java_list
#' @inheritParams java_download
#' @return A character vector with the contents of the cache directory.
#'
#' @examples
#' java_list_distrib_cache()
#'
java_list_distrib_cache <- function(
  cache_path = tools::R_user_dir("rJavaEnv", which = "cache"),
  output = c("data.frame", "vector"),
  verbose = FALSE
) {
  output <- match.arg(output)

  cache_path <- file.path(cache_path, "distrib")

  if (!dir.exists(cache_path)) {
    cli::cli_alert_danger("Path does not exist")
    return(character(0))
  }
  if (verbose) cli::cli_inform("Contents of the Java distributions cache folder:")

  java_distrs <- grep(
    "md5$",
    list.files(cache_path, full.names = TRUE),
    invert = TRUE,
    value = TRUE
  )

  if (output == "vector") {
    return(java_distrs)
  } else if (output == "data.frame") {
    java_distrs <- data.frame(java_distr_path = java_distrs)
    return(java_distrs)
  }
}

#' Clear the Java distributions cache folder
#'
#' @param cache_path The cache directory to clear. Defaults to the user-specific data directory.
#' @inheritParams java_clear
#' @inheritParams java_download
#' @return A message indicating whether the cache was cleared or not.
#'
#' @examples
#' \dontrun{
#' # delete all cached distributions, leave cache path empty to clear in the package cache in your default cache user space
#' java_clear_distrib_cache(
#'   cache_path = tempdir(),
#'   check = FALSE,
#'   delete_all = TRUE
#' )
#' }
java_clear_distrib_cache <- function(
  cache_path = tools::R_user_dir("rJavaEnv", which = "cache"),
  check = TRUE,
  delete_all = FALSE
) {
  rje_consent_check()
  
  distrib_cache_path <- file.path(cache_path, "distrib")

  if (!dir.exists(distrib_cache_path)) {
    if (length(list.files(distrib_cache_path)) == 0) {
      cli::cli_inform("Java distributions cache is already empty.")
      return(invisible(NULL))
    }
  }

  if (delete_all) {
    unlink(file.path(distrib_cache_path, "*"), recursive = TRUE)
    cli::cli_inform("Java distributions cache cleared.")
    return(invisible(NULL))
  }

  if (check) {
    distributions <- java_list_distrib_cache(output = "vector", cache_path = cache_path)
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
      unlink(file.path(distrib_cache_path, "*"), recursive = TRUE)
      cli::cli_inform("All Java distributions have been cleared.")
    } else {
      choice <- suppressWarnings(as.integer(response))
      if (is.na(choice) || choice == 0 || choice > length(distributions)) {
        cli::cli_inform("No distributions were cleared.")
      } else {
        unlink(distributions[choice], recursive = TRUE)
        md5_file <- paste0(distributions[choice], "md5")
        if(file.exists(md5_file)) unlink(md5_file)
        cli::cli_inform("Java distribution {choice} has been cleared.")
      }
    }
  } else {
    cli::cli_alert_info("Are you sure you want to clear the Java distributions cache? (yes/no)")
    response <- readline()
    if (tolower(response) == "yes") {
      unlink(file.path(distrib_cache_path, "*"), recursive = TRUE)
      cli::cli_inform("Java distributions cache cleared.")
    } else {
      cli::cli_inform("Java distributions cache was not cleared.")
    }
  }

  return(invisible(NULL))
}
