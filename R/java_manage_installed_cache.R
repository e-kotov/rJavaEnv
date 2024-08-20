#' List the contents of the Java installations cache folder
#'
#' @param output The format of the output: "data.frame" or "vector". Defaults to "data.frame".
#' @param cache_path The cache directory to list. Defaults to the user-specific data directory. Not recommended to change.
#' @inheritParams global_quiet_param
#' @return A data frame or character vector with the contents of the cache directory.
#' @keywords internal
java_list_installed_cache <- function(
    output = c("data.frame", "vector"),
    quiet = TRUE,
    cache_path = getOption("rJavaEnv.cache_path")
) {
  output <- match.arg(output)
  installed_cache_path <- file.path(cache_path, "installed")

  if (!dir.exists(installed_cache_path)) {
    cli::cli_alert_danger("No Java distributions have been installed yet.")
    return(character(0))
  }

  if (!quiet) cli::cli_inform("Contents of the Java installations cache folder:")

  # List directories up to the specified depth
  java_paths <- list.dirs(installed_cache_path, recursive = TRUE, full.names = TRUE)

  java_paths <- java_paths[vapply(java_paths, function(x) {
    length(strsplit(x, .Platform$file.sep)[[1]]) == length(strsplit(installed_cache_path, .Platform$file.sep)[[1]]) + 3
  }, logical(1))]

  if (length(java_paths) == 0) {
    return(character(0))
  }

  if (output == "vector") {
    return(unname(java_paths))
  } else if (output == "data.frame") {
    java_info <- lapply(java_paths, function(path) {
      parts <- strsplit(path, .Platform$file.sep)[[1]]
      parts <- parts[(length(parts) - 2):length(parts)]
      names(parts) <- c("platform", "arch", "version")
      parts <- c(path = path, parts)
      return(parts)
    })
    java_info_df <- do.call(rbind, lapply(java_info, function(info) as.data.frame(t(info), stringsAsFactors = FALSE)))
    rownames(java_info_df) <- NULL
    return(java_info_df)
  }
}

#' Clear the Java installations cache folder
#'
#' @param cache_path The cache directory to clear. Defaults to the user-specific data directory.
#' @param check Whether to list the contents of the cache directory before clearing it. Defaults to TRUE.
#' @param delete_all Whether to delete all installations without prompting. Defaults to FALSE.
#' @return A message indicating whether the cache was cleared or not.
#'
#' @keywords internal
java_clear_installed_cache <- function(
    check = TRUE,
    delete_all = FALSE,
    cache_path = getOption("rJavaEnv.cache_path")
) {
  rje_consent_check()
  
  installed_cache_path <- file.path(cache_path, "installed")

  if (!dir.exists(installed_cache_path)) {
    cli::cli_inform("Java installations cache is already empty.")
    return(invisible(NULL))
  }

  if (delete_all) {
    unlink(file.path(installed_cache_path, "*"), recursive = TRUE)
    cli::cli_inform("Java installations cache cleared.")
    return(invisible(NULL))
  }

  if (check) {
    installations <- java_list_installed_cache(cache_path, quiet = FALSE, output = "vector")
    if (length(installations) == 0) {
      cli::cli_inform("No Java installations found to clear.")
      return(invisible(NULL))
    }

    cli::cli_alert_info("Existing Java installations:")
    for (i in seq_along(installations)) {
      cli::cli_inform("{i}: {installations[i]}")
    }

    cli::cli_alert_info("Enter the number of the installation to delete, 'all' to delete all, or '0' or any other character to cancel:")
    response <- readline()

    if (tolower(response) == "all") {
      unlink(file.path(installed_cache_path, "*"), recursive = TRUE)
      cli::cli_inform("All Java installations have been cleared.")
    } else {
      choice <- suppressWarnings(as.integer(response))
      if (is.na(choice) || choice == 0 || choice > length(installations)) {
        cli::cli_inform("No installations were cleared.")
      } else {
        unlink(installations[choice], recursive = TRUE)
        cli::cli_inform("Java installation {choice} has been cleared.")
      }
    }
  } else {
    cli::cli_alert_info("Are you sure you want to clear the Java installations cache? (yes/no)")
    response <- readline()
    if (tolower(response) == "yes") {
      unlink(file.path(installed_cache_path, "*"), recursive = TRUE)
      cli::cli_inform("Java installations cache cleared.")
    } else {
      cli::cli_inform("Java installations cache was not cleared.")
    }
  }

  return(invisible(NULL))
}
