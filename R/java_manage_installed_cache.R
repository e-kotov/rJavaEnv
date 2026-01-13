#' List the contents of the Java installations cache folder
#'
#' @inheritParams java_list
#' @inheritParams java_download
#' @inheritParams global_quiet_param
#' @return A data frame or character vector with the contents of the cache directory.
#' @export
#'
#' @examples
#' # List the contents
#' java_list_installed()
#'
java_list_installed <- function(
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

  if (!quiet) {
    cli::cli_inform("Contents of the Java installations cache folder:")
  }

  # List all directories recursively
  all_dirs <- list.dirs(
    installed_cache_path,
    recursive = TRUE,
    full.names = TRUE
  )

  # Calculate depth relative to installed_cache_path
  base_depth <- length(strsplit(installed_cache_path, .Platform$file.sep)[[1]])

  # Find leaf directories (installations) - either depth 3 (legacy) or 5 (new)
  # Legacy: platform/arch/version (depth 3)

  # New: platform/arch/distribution/backend/version (depth 5)
  java_paths <- all_dirs[vapply(
    all_dirs,
    function(x) {
      depth <- length(strsplit(x, .Platform$file.sep)[[1]]) - base_depth
      # Check if this looks like a version directory (leaf node)
      # A version directory should contain bin/ or similar Java structure
      is_version_dir <- depth %in%
        c(3, 5) &&
        (dir.exists(file.path(x, "bin")) ||
          length(list.files(x, pattern = "^(bin|lib|conf|legal)$")) > 0)
      return(is_version_dir)
    },
    logical(1)
  )]

  if (length(java_paths) == 0) {
    return(character(0))
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

#' Clear the Java installations cache folder
#'
#' @inheritParams java_download
#' @inheritParams java_clear
#' @return A message indicating whether the cache was cleared or not.
#' @export
#'
#' @examples
#' if (interactive()) {
#'   java_clear_installed()
#' }
#'
java_clear_installed <- function(
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
    installations <- java_list_installed(
      output = "vector",
      quiet = FALSE,
      cache_path = cache_path
    )
    if (length(installations) == 0) {
      cli::cli_inform("No Java installations found to clear.")
      return(invisible(NULL))
    }

    cli::cli_alert_info("Existing Java installations:")
    for (i in seq_along(installations)) {
      cli::cli_inform("{i}: {installations[i]}")
    }

    cli::cli_alert_info(
      "Enter the number of the installation to delete, 'all' to delete all, or '0' or any other character to cancel:"
    )
    if (getOption("rJavaEnv.interactive", interactive())) {
      response <- rje_readline()
    } else {
      cli::cli_alert_danger(
        "Non-interactive session detected. Cannot request input. No action taken."
      )
      response <- "0"
    }

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
    cli::cli_alert_info(
      "Are you sure you want to clear the Java installations cache? (yes/no)"
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
      unlink(file.path(installed_cache_path, "*"), recursive = TRUE)
      cli::cli_inform("Java installations cache cleared.")
    } else {
      cli::cli_inform("Java installations cache was not cleared.")
    }
  }

  return(invisible(NULL))
}
