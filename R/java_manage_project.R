#' List the Java versions symlinked in the current project
#'
#' @param project_path The project directory to list. Defaults to the current working directory.
#' @param output The format of the output: "data.frame" or "vector". Defaults to "data.frame".
#' @inheritParams global_quiet_param
#' @return A data frame or character vector with the symlinked Java versions in the project directory.
#'
java_list_in_project <- function(
    project_path = NULL,
    output = c("data.frame", "vector"),
    quiet = TRUE
  ) {
  
  # Resolve the project path
  # consistent with renv behavior
  # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
  project_path <- ifelse(is.null(project_path), getwd(), project_path)
      
  output <- match.arg(output)
  java_symlink_dir <- file.path(project_path, "rjavaenv")

  if (!dir.exists(java_symlink_dir)) {
    cli::cli_alert_danger("No Java has been installed in the project.")
    return(invisible(NULL))
  }

  
  # List directories up to the specified depth
  java_paths <- list.dirs(java_symlink_dir, recursive = TRUE, full.names = TRUE)
  
  java_paths <- java_paths[vapply(java_paths, function(x) {
    length(strsplit(x, .Platform$file.sep)[[1]]) == length(strsplit(java_symlink_dir, .Platform$file.sep)[[1]]) + 3
  }, logical(1))]
  
  if (length(java_paths) == 0) {
    cli::cli_alert_danger("No Java has been installed in the project.")
    return(invisible(NULL))
  }
  
  if (!quiet) cli::cli_inform("Contents of the Java symlinks in the project folder:")
  
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

#' Clear the Java versions symlinked in the current project
#'
#' @param project_path The project directory to clear. Defaults to the current working directory.
#' @param check Whether to list the symlinked Java versions before clearing them. Defaults to TRUE.
#' @param delete_all Whether to delete all symlinks without prompting. Defaults to FALSE.
#' @return A message indicating whether the symlinks were cleared or not.
#'
#' @examples
#' \dontrun{
#' java_clear_in_project()
#' }
java_clear_in_project <- function(
    project_path = NULL,
    check = TRUE,
    delete_all = FALSE
) {
  rje_consent_check()
  
  # Resolve the project path
  # consistent with renv behavior
  # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
  project_path <- ifelse(is.null(project_path), getwd(), project_path)

  java_symlink_dir <- file.path(project_path, "rjavaenv")

  if (!dir.exists(java_symlink_dir)) {
    cli::cli_inform("Java symlink directory does not exist in the project.")
    return(invisible(NULL))
  }

  if (delete_all) {
    unlink(file.path(java_symlink_dir), recursive = TRUE)
    cli::cli_inform("All Java symlinks in the project have been cleared.")
    return(invisible(NULL))
  }

  if (check) {
    symlinks <- java_list_in_project(project_path = project_path, output = "vector")
    if (length(symlinks) == 0) {
      cli::cli_inform("No Java symlinks found to clear.")
      return(invisible(NULL))
    }

    cli::cli_alert_info("Existing Java symlinks:")
    for (i in seq_along(symlinks)) {
      cli::cli_inform("{i}: {symlinks[i]}")
    }

    cli::cli_alert_info("Enter the number of the symlink to delete, 'all' to delete all, or '0' or any other character to cancel:")
    response <- readline()

    if (tolower(response) == "all") {
      unlink(file.path(java_symlink_dir, "*"), recursive = TRUE)
      cli::cli_inform("All Java symlinks in the project have been cleared.")
    } else {
      choice <- suppressWarnings(as.integer(response))
      if (is.na(choice) || choice == 0 || choice > length(symlinks)) {
        cli::cli_inform("No symlinks were cleared.")
      } else {
        unlink(symlinks[choice], recursive = TRUE)
        cli::cli_inform("Java symlink {choice} has been cleared.")
      }
    }
  } else {
    cli::cli_alert_info("Are you sure you want to clear all Java symlinks in the project? (yes/no)")
    response <- readline()
    if (tolower(response) == "yes") {
      unlink(file.path(java_symlink_dir, "*"), recursive = TRUE)
      cli::cli_inform("All Java symlinks in the project have been cleared.")
    } else {
      cli::cli_inform("No Java symlinks were cleared.")
    }
  }

  return(invisible(NULL))
}
