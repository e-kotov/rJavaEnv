#' List the Java versions symlinked in the current project
#'
#' @param project_path The project directory to list. Defaults to the current working directory.
#' @inheritParams java_list
#' @inheritParams global_quiet_param
#' @return A data frame or character vector with the symlinked Java versions in the project directory.
#' @export
#'
#' @examples
#' \donttest{
#' java_list_project()
#' }
java_list_project <- function(
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

  # List all directories recursively
  all_dirs <- list.dirs(java_symlink_dir, recursive = TRUE, full.names = TRUE)

  # Calculate depth relative to java_symlink_dir
  base_depth <- length(strsplit(java_symlink_dir, .Platform$file.sep)[[1]])

  # Find leaf directories (installations) - either depth 3 (legacy) or 5 (new)
  # Legacy: platform/arch/version (depth 3)
  # New: platform/arch/distribution/backend/version (depth 5)
  java_paths <- all_dirs[vapply(
    all_dirs,
    function(x) {
      depth <- length(strsplit(x, .Platform$file.sep)[[1]]) - base_depth
      # Check if this looks like a version directory (leaf node)
      # A version directory should contain bin/ or be a symlink to one
      is_version_dir <- depth %in%
        c(3, 5) &&
        (dir.exists(file.path(x, "bin")) ||
          Sys.readlink(x) != "" ||
          length(list.files(x, pattern = "^(bin|lib|conf|legal)$")) > 0)
      return(is_version_dir)
    },
    logical(1)
  )]

  if (length(java_paths) == 0) {
    cli::cli_alert_danger("No Java has been installed in the project.")
    return(invisible(NULL))
  }

  if (!quiet) {
    cli::cli_inform("Contents of the Java symlinks in the project folder:")
  }

  if (output == "vector") {
    return(unname(java_paths))
  } else if (output == "data.frame") {
    java_info <- lapply(java_paths, function(path) {
      parts <- strsplit(path, .Platform$file.sep)[[1]]
      rel_parts <- parts[(base_depth + 1):length(parts)]
      depth <- length(rel_parts)

      if (depth == 3) {
        # Legacy structure: platform/arch/version
        info <- c(
          path = path,
          platform = rel_parts[1],
          arch = rel_parts[2],
          distribution = "unknown",
          backend = "unknown",
          version = rel_parts[3]
        )
      } else if (depth == 5) {
        # New structure: platform/arch/distribution/backend/version
        info <- c(
          path = path,
          platform = rel_parts[1],
          arch = rel_parts[2],
          distribution = rel_parts[3],
          backend = rel_parts[4],
          version = rel_parts[5]
        )
      } else {
        # Unknown structure, treat as legacy with unknown fields
        info <- c(
          path = path,
          platform = if (length(rel_parts) >= 1) rel_parts[1] else "unknown",
          arch = if (length(rel_parts) >= 2) rel_parts[2] else "unknown",
          distribution = "unknown",
          backend = "unknown",
          version = if (length(rel_parts) >= 3) {
            rel_parts[length(rel_parts)]
          } else {
            "unknown"
          }
        )
      }
      return(info)
    })
    java_info_df <- do.call(
      rbind,
      lapply(java_info, function(info) {
        as.data.frame(t(info), stringsAsFactors = FALSE)
      })
    )
    rownames(java_info_df) <- NULL
    return(java_info_df)
  }
}

#' Clear the Java versions symlinked in the current project
#'
#' @param project_path The project directory to clear. Defaults to the current working directory.
#' @inheritParams java_clear
#' @return A message indicating whether the symlinks were cleared or not.
#' @export
#'
#' @examples
#' if (interactive()) {
#'   java_clear_project()
#' }
#'
java_clear_project <- function(
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
    symlinks <- java_list_project(
      project_path = project_path,
      output = "vector"
    )
    if (length(symlinks) == 0) {
      cli::cli_inform("No Java symlinks found to clear.")
      return(invisible(NULL))
    }

    cli::cli_alert_info("Existing Java symlinks:")
    for (i in seq_along(symlinks)) {
      cli::cli_inform("{i}: {symlinks[i]}")
    }

    cli::cli_alert_info(
      "Enter the number of the symlink to delete, 'all' to delete all, or '0' or any other character to cancel:"
    )
    if (getOption("rJavaEnv.interactive", interactive())) {
      response <- rje_readline()
    } else {
      # If not interactive, we can't ask for input, so we effectively cancel (or error?)
      # For safety in CI/check, we should probably output a message and do nothing unless forced.
      cli::cli_alert_danger(
        "Non-interactive session detected. Cannot request input. No action taken."
      )
      response <- "0"
    }

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
    cli::cli_alert_info(
      "Are you sure you want to clear all Java symlinks in the project? (yes/no)"
    )
    if (getOption("rJavaEnv.interactive", interactive())) {
      response <- rje_readline()
    } else {
      cli::cli_alert_danger(
        "Non-interactive session detected. Cannot request input. No action taken."
      )
      response <- "no"
    }
    if (tolower(response) == "yes") {
      unlink(file.path(java_symlink_dir, "*"), recursive = TRUE)
      cli::cli_inform("All Java symlinks in the project have been cleared.")
    } else {
      cli::cli_inform("No Java symlinks were cleared.")
    }
  }

  return(invisible(NULL))
}
