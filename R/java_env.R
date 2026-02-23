# set Java environment ------------------------------------------------------------

#' Set the `JAVA_HOME` and `PATH` environment variables to a given path
#'
#' @description
#' Sets the JAVA_HOME and PATH environment variables for command-line Java tools and
#' rJava initialization. See details for important information about rJava timing.
#'
#' @inheritSection rjava_path_locking_note rJava Path-Locking
#'
#' @section Additional Details:
#' To use a different Java version with rJava-dependent packages, you must:
#' 1. Set JAVA_HOME using this function BEFORE loading rJava or any package that imports it
#' 2. Restart your R session if you already loaded rJava with the wrong Java version
#'
#' @param java_home The path to the desired `JAVA_HOME`.
#' @param where Where to set the `JAVA_HOME`: "session", "project", or "both". Defaults to "session" and only updates the paths in the current R session. When "both" or "project" is selected, the function updates the .Rprofile file in the project directory to set the JAVA_HOME and PATH environment variables at the start of the R session.
#' @inheritParams global_quiet_param
#' @inheritParams java_install
#' @return Nothing. Sets the JAVA_HOME and PATH environment variables.
#' @export
#' @examples
#' \donttest{
#' # download, install Java 17
#' java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
#' java_home <- java_install(
#'   java_distrib_path = java_17_distrib,
#'   project_path = tempdir(),
#'   autoset_java_env = FALSE
#' )
#'
#' # now manually set the JAVA_HOME and PATH environment variables in current session
#' java_env_set(
#'   where = "session",
#'   java_home = java_home
#' )
#'
#' # or set JAVA_HOME and PATH in the spefific projects' .Rprofile
#' java_env_set(
#'   where = "project",
#'   java_home = java_home,
#'   project_path = tempdir()
#' )
#'
#' }
java_env_set <- function(
  where = c("session", "both", "project"),
  java_home,
  project_path = NULL,
  quiet = FALSE
) {
  ._java_env_set_impl(
    where = where,
    java_home = java_home,
    project_path = project_path,
    quiet = quiet,
    ._skip_rjava_check = FALSE
  )
}

#' Internal implementation of java_env_set
#' @keywords internal
._java_env_set_impl <- function(
  where = c("session", "both", "project"),
  java_home,
  project_path = NULL,
  quiet = FALSE,
  ._skip_rjava_check = FALSE
) {
  where <- match.arg(where)
  checkmate::assertString(java_home)
  checkmate::assertFlag(quiet)

  if (where %in% c("session", "both")) {
    java_env_set_session(
      java_home,
      quiet = quiet,
      ._skip_rjava_check = ._skip_rjava_check
    )
    if (!quiet) {
      cli::cli_alert_success(c(
        "Current R Session: ",
        "JAVA_HOME and PATH set to {.path {java_home}}"
      ))
    }
  }

  if (where %in% c("project", "both")) {
    rje_consent_check()
    # consistent with renv behavior for using
    # the current working directory by default
    # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
    project_path <- ifelse(is.null(project_path), getwd(), project_path)

    java_env_set_rprofile(java_home, project_path = project_path)

    if (!quiet) {
      cli::cli_alert_success(c(
        "Current R Project/Working Directory: ",
        "JAVA_HOME and PATH set to '{.path {java_home}}' in .Rprofile at '{.path {project_path}}'"
      ))
    }
  }

  if (Sys.info()["sysname"] == "Linux" && !quiet) {
    cli::cli_inform(c(
      "i" = "On Linux, for rJava to work correctly, `libjvm.so` was dynamically loaded in the current session.",
      " " = "To make this change permanent for installing rJava-dependent packages from source, you may need to reconfigure Java.",
      " " = "See {.url https://solutions.posit.co/envs-pkgs/using-rjava/#reconfigure-r} for details.",
      " " = "If you have admin rights, run the following in your terminal:",
      " " = "{.code R CMD javareconf JAVA_HOME={java_home}}",
      " " = "If you do not have admin rights, run:",
      " " = "{.code R CMD javareconf JAVA_HOME={java_home} -e}"
    ))
  }

  invisible(NULL)
}

# Helper function for java_env_set_session
#' Set the JAVA_HOME and PATH environment variables for the current session
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @inheritParams global_quiet_param
#' @param ._skip_rjava_check Internal. If TRUE, skip the rJava initialization check.
#' @keywords internal
#' @importFrom utils installed.packages
#'
java_env_set_session <- function(
  java_home,
  quiet = FALSE,
  ._skip_rjava_check = FALSE
) {
  # Check if rJava is initialized and warn if so (unless caller already checked)
  if (!._skip_rjava_check) {
    check_rjava_initialized(quiet = quiet)
  }

  Sys.setenv(JAVA_HOME = java_home)

  old_path <- Sys.getenv("PATH")
  new_path <- file.path(java_home, "bin")
  Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep))

  # On Linux, find and dynamically load libjvm.so
  if (Sys.info()["sysname"] == "Linux") {
    libjvm_path <- get_libjvm_path(java_home)

    if (!is.null(libjvm_path) && file.exists(libjvm_path)) {
      tryCatch(
        dyn.load(libjvm_path),
        error = function(e) {
          if (!quiet) {
            cli::cli_warn(
              "Found libjvm.so at '{.path {libjvm_path}}' but failed to load it: {e$message}"
            )
          }
        }
      )
    } else {
      if (!quiet) {
        cli::cli_warn(
          "Could not find libjvm.so within the provided JAVA_HOME: {.path {java_home}}"
        )
      }
    }
  }
}


#' Update the .Rprofile file in the project directory
#'
#' @inheritParams java_install
#' @keywords internal
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @returns NULL
java_env_set_rprofile <- function(
  java_home,
  project_path = NULL
) {
  java_env_unset(quiet = TRUE, project_path = project_path)

  # Resolve the project path
  # consistent with renv behavior
  # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
  project_path <- ifelse(is.null(project_path), getwd(), project_path)
  rprofile_path <- file.path(project_path, ".Rprofile")

  # Normalize the path for consistency (especially on Windows)
  java_home <- normalizePath(java_home, winslash = "/", mustWork = FALSE)

  lines_to_add <- c(
    "# rJavaEnv begin: Manage JAVA_HOME",
    sprintf("Sys.setenv(JAVA_HOME = '%s') # rJavaEnv", java_home),
    "old_path <- Sys.getenv('PATH') # rJavaEnv",
    "new_path <- file.path(Sys.getenv('JAVA_HOME'), 'bin') # rJavaEnv",
    "Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep)) # rJavaEnv",
    "rm(old_path, new_path) # rJavaEnv"
  )

  # On Linux, find the path to libjvm.so once and hardcode it into .Rprofile
  if (Sys.info()["sysname"] == "Linux") {
    libjvm_path <- get_libjvm_path(java_home)

    if (!is.null(libjvm_path)) {
      # Normalize path for consistency in the file
      libjvm_path_normalized <- gsub("\\\\", "/", libjvm_path)
      dyn_load_line <- sprintf(
        "if (file.exists('%s')) { try(dyn.load('%s'), silent = TRUE) } # rJavaEnv",
        libjvm_path_normalized,
        libjvm_path_normalized
      )
      lines_to_add <- c(lines_to_add, dyn_load_line)
    }
  }

  lines_to_add <- c(
    lines_to_add,
    "# rJavaEnv end: Manage JAVA_HOME"
  )

  if (file.exists(rprofile_path)) {
    cat(lines_to_add, file = rprofile_path, append = TRUE, sep = "\n")
  } else {
    writeLines(lines_to_add, con = rprofile_path)
  }

  return(invisible(NULL))
}


#' Check Java Version with a Specified JAVA_HOME Using a Separate R Session
#'
#' This function sets the JAVA_HOME environment variable, initializes the JVM using rJava, and prints the Java version that would be used if the user sets the given JAVA_HOME in the current R session. This check is performed in a separate R session to avoid having to reload the current R session. The reason for this is that once Java is initialized in an R session, it cannot be uninitialized unless the current R session is restarted.
#'
#' @inheritParams global_quiet_param
#' @inheritParams java_check_version_cmd
#' @param .use_cache Logical. If `TRUE`, uses cached results for repeated calls with the same JAVA_HOME. If `FALSE` (default), forces a fresh check. Set to `TRUE` for performance in loops or repeated checks within the same session.
#' @return A `character` vector of length 1 containing the major Java version, or `FALSE` if rJava is not installed or the version check fails.
#' @examples
#' \donttest{
#' java_check_version_rjava()
#' }
#'
#' @export
java_check_version_rjava <- function(
  java_home = NULL,
  quiet = FALSE,
  .use_cache = FALSE
) {
  # Check if rJava is installed
  if (length(find.package("rJava", quiet = TRUE)) == 0) {
    cli::cli_alert_danger(
      "rJava package is not installed. You need to install rJava to use this function to check if rJava-based packages will work with the specified Java version."
    )
    return(FALSE)
  }

  # Determine JAVA_HOME if not specified by the user
  current_java_home <- Sys.getenv("JAVA_HOME")
  if (is.null(java_home)) {
    java_home <- current_java_home
    context_msg <- if (current_java_home == "") {
      NULL
    } else {
      "Using current session's JAVA_HOME"
    }
  } else {
    context_msg <- "Using user-specified JAVA_HOME"
  }

  # Get check result (either cached or fresh)
  # Use the effective java_home as cache key (what we're actually checking)
  effective_java_home <- java_home

  if (.use_cache) {
    data <- ._java_version_check_rjava_impl(java_home, effective_java_home)
  } else {
    # Bypass cache - call the implementation directly
    data <- ._java_version_check_rjava_impl_original(java_home)
  }

  if (isFALSE(data)) {
    if (!quiet) {
      cli::cli_alert_danger("Failed to retrieve Java version.")
    }
    return(FALSE)
  }

  # Print if not quiet (always, regardless of cache)
  if (!quiet) {
    if (!is.null(context_msg)) {
      cli::cli_inform(paste0(context_msg, ": {.path {java_home}}"))
    }
    if (current_java_home == "") {
      cli::cli_inform("JAVA_HOME is not set.")
    } else {
      cli::cli_inform("With the current session's JAVA_HOME {data$output}")
    }
  }

  return(data$major_version)
}

# Original implementation (not memoised) - used when .use_cache = FALSE
._java_version_check_rjava_impl_original <- function(java_home = NULL) {
  # Get the code of the unexported functions to use in a script
  # On Linux, the script depends on get_libjvm_path() to avoid crashes in .jinit()
  java_version_check_fn <- getFromNamespace(
    "java_version_check_rscript",
    "rJavaEnv"
  )
  get_libjvm_path_fn <- getFromNamespace("get_libjvm_path", "rJavaEnv")

  java_version_check_body <- paste(
    deparse(body(java_version_check_fn)),
    collapse = "\n"
  )
  get_libjvm_path_body <- paste(
    deparse(body(get_libjvm_path_fn)),
    collapse = "\n"
  )

  # Create a wrapper script that includes the function definitions and calls them
  # Capture current libPaths to ensure subprocess can find rJava in renv/packrat environments
  libs_code <- paste0(".libPaths(", deparse(as.character(.libPaths())), ")")

  wrapper_script <- paste0(
    libs_code,
    "\n\n",
    "get_libjvm_path <- function(java_home) {\n",
    get_libjvm_path_body,
    "\n}\n\n",
    "java_version_check <- function(java_home) {\n",
    java_version_check_body,
    "\n}\n\n",
    "args <- commandArgs(trailingOnly = TRUE)\n",
    "result <- java_version_check(args[1])\n",
    "cat(result, sep = '\n')"
  )

  # Write the wrapper script to a temporary file
  script_file <- tempfile(fileext = ".R")
  writeLines(wrapper_script, script_file)

  # Run the script in a separate R session and capture the output
  rscript_path <- file.path(R.home("bin"), "Rscript")
  output <- suppressWarnings(system2(
    rscript_path,
    args = c(script_file, java_home),
    stdout = TRUE,
    stderr = TRUE,
    timeout = 5
  ))

  # Delete the temporary script file
  unlink(script_file)

  # Process the output (no printing here)
  if (length(output) == 0 || any(grepl("error", tolower(output)))) {
    return(FALSE)
  }

  output <- paste(output, collapse = "\n")
  cleaned_output <- cli::ansi_strip(output)
  major_java_ver <- sub('.*version: \\"([0-9]+).*', '\\1', cleaned_output)

  if (!nzchar(major_java_ver) || !grepl("^[0-9]+$", major_java_ver)) {
    return(FALSE)
  }

  # Fix 1 to 8, as Java 8 prints "1.8"
  if (major_java_ver == "1") {
    major_java_ver <- "8"
  }

  # Return structured data for printing in wrapper
  return(list(
    major_version = major_java_ver,
    output = output
  ))
}

# Internal function: Spawn subprocess to check Java with rJava - this gets cached
._java_version_check_rjava_impl <- memoise::memoise(
  function(java_home = NULL, .cache_buster = NULL) {
    # Delegate to the original implementation
    ._java_version_check_rjava_impl_original(java_home)
  },
  cache = memoise::cache_memory()
)

#' Check installed Java version using terminal commands
#'
#' @param java_home Path to Java home directory. If NULL, the function uses the JAVA_HOME environment variable.
#' @inheritParams global_quiet_param
#' @param .use_cache Logical. If `TRUE`, uses cached results for repeated calls with the same JAVA_HOME. If `FALSE` (default), forces a fresh check. Set to `TRUE` for performance in loops or repeated checks within the same session.
#' @return A `character` vector of length 1 containing the major Java version, or `FALSE` if JAVA_HOME is not set or the Java executable cannot be found.
#'
#' @section Performance:
#' This function is memoised (cached) within the R session using the effective
#' JAVA_HOME as cache key. First call for a given JAVA_HOME: ~37ms. Subsequent
#' calls (with `.use_cache = TRUE`): <1ms. When you switch Java versions via `use_java()`, JAVA_HOME
#' changes, creating a new cache entry. Cache is session-scoped.
#'
#' @export
#'
#' @examples
#' \donttest{
#' java_check_version_cmd()
#' }
#'
java_check_version_cmd <- function(
  java_home = NULL,
  quiet = FALSE,
  .use_cache = FALSE
) {
  # Get data (either cached or fresh)
  # Use the effective java_home as cache key
  effective_java_home <- if (is.null(java_home)) {
    Sys.getenv("JAVA_HOME")
  } else {
    java_home
  }

  if (.use_cache) {
    data <- ._java_version_check_impl(java_home, effective_java_home)
  } else {
    # Bypass cache - call the implementation directly
    data <- ._java_version_check_impl_original(java_home)
  }

  # Handle error case
  if (isFALSE(data)) {
    if (!quiet) {
      cli::cli_inform(c("!" = "JAVA_HOME is not set."))
    }
    return(FALSE)
  }

  # Print if not quiet (always, regardless of cache)
  if (!quiet) {
    cli::cli_inform("JAVA_HOME: {.path {data$java_home}}")
    cli::cli_inform(c(
      "Java path: {.path {data$java_path}}",
      "Java version:\n{.val {paste(data$java_version_output, collapse = '\n')}}"
    ))
  }

  return(data$major_version)
}

# Original implementation (not memoised) - used when .use_cache = FALSE
._java_version_check_impl_original <- function(java_home = NULL) {
  # Backup the current JAVA_HOME and PATH
  old_java_home <- Sys.getenv("JAVA_HOME")
  old_path <- Sys.getenv("PATH")

  # Set JAVA_HOME in current session if specified
  # Skip rJava check since this is a temporary change just to check version
  if (!is.null(java_home)) {
    java_env_set_session(java_home, quiet = TRUE, ._skip_rjava_check = TRUE)
  }

  # Get JAVA_HOME again and check if it's set
  current_java_home <- Sys.getenv("JAVA_HOME")
  if (current_java_home == "") {
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
      Sys.setenv(PATH = old_path)
    }
    return(FALSE)
  }

  # Get Java path - use explicit path if java_home is specified
  if (!is.null(java_home)) {
    # Direct check of the executable within the provided java_home
    # This avoids Sys.which potentially picking up system shims (common on macOS)
    # or other executables in the PATH

    # Determine executable name based on OS
    exe_name <- if (.Platform$OS.type == "windows") "java.exe" else "java"
    java_bin_candidate <- file.path(java_home, "bin", exe_name)

    if (file.exists(java_bin_candidate)) {
      java_bin <- java_bin_candidate
    } else {
      # Fallback to failing if not found in the expected location
      return(FALSE)
    }
  } else {
    java_bin <- Sys.which("java")
    if (!nzchar(java_bin)) {
      return(FALSE)
    }
  }
  which_java <- java_bin

  # On macOS, the 'java' launcher stub dynamically loads libjvm.dylib.
  # If another JDK (e.g., system Temurin) is in the default library search path,
  # the launcher may load the wrong JVM library even if JAVA_HOME is set.
  # We fix this by targeting DYLD_LIBRARY_PATH specifically for this subprocess.
  # Note: We do NOT set DYLD_LIBRARY_PATH globally in java_env_set() because:
  # 1. rJava's .jinit() loads libjvm.dylib directly from path, bypassing the stub.
  # 2. Global DYLD_* vars are restricted by macOS SIP and can cause side effects.
  if (Sys.info()[["sysname"]] == "Darwin" && !is.null(java_home)) {
    libjvm_path <- get_libjvm_path(java_home)
    if (!is.null(libjvm_path)) {
      lib_server <- dirname(libjvm_path)
      old_dyld_path <- Sys.getenv("DYLD_LIBRARY_PATH", unset = NA)
      if (is.na(old_dyld_path)) {
        on.exit(Sys.unsetenv("DYLD_LIBRARY_PATH"), add = TRUE)
      } else {
        on.exit(Sys.setenv(DYLD_LIBRARY_PATH = old_dyld_path), add = TRUE)
      }
      Sys.setenv(DYLD_LIBRARY_PATH = lib_server)
    }

    # Also temporarily set JAVA_HOME for this check
    saved_java_home_for_darwin <- Sys.getenv("JAVA_HOME", unset = NA)
    if (is.na(saved_java_home_for_darwin)) {
      on.exit(Sys.unsetenv("JAVA_HOME"), add = TRUE)
    } else {
      on.exit(Sys.setenv(JAVA_HOME = saved_java_home_for_darwin), add = TRUE)
    }
    Sys.setenv(JAVA_HOME = java_home)
  }

  java_ver <- tryCatch(
    system2(
      java_bin,
      args = "-version",
      stdout = TRUE,
      stderr = TRUE,
      timeout = 30
    ),
    error = function(e) NULL
  )

  # Check for timeout or empty result
  # When system2 times out, it returns character(0) with status=124
  # When it fails in other ways, it may return NULL
  if (is.null(java_ver) || length(java_ver) == 0) {
    # Restore original environment
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
      Sys.setenv(PATH = old_path)
    }
    return(FALSE)
  }

  # Additional check for timeout status attribute
  status_attr <- attr(java_ver, "status")
  if (!is.null(status_attr) && status_attr == 124) {
    # Explicit timeout detected (status 124)
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
      Sys.setenv(PATH = old_path)
    }
    return(FALSE)
  }

  major_java_ver <- ._java_parse_version_output(java_ver)

  if (isFALSE(major_java_ver)) {
    # Restore original environment
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
      Sys.setenv(PATH = old_path)
    }
    return(FALSE)
  }

  # Restore original JAVA_HOME and PATH
  if (!is.null(java_home)) {
    Sys.setenv(JAVA_HOME = old_java_home)
    Sys.setenv(PATH = old_path)
  }

  # Return structured data for printing in wrapper
  return(list(
    major_version = major_java_ver,
    java_home = current_java_home,
    java_path = which_java,
    java_version_output = java_ver
  ))
}

# Internal function: Does the actual work (command execution) - this gets cached
._java_version_check_impl <- memoise::memoise(
  function(java_home = NULL, .cache_buster = NULL) {
    # Delegate to the original implementation
    ._java_version_check_impl_original(java_home)
  },
  cache = memoise::cache_memory()
)

# unset java env ----------------------------------------------------------

#' Unset the JAVA_HOME and PATH environment variables in the project .Rprofile
#'
#' @inheritParams java_install
#' @inheritParams global_quiet_param
#' @export
#' @return Nothing. Removes the JAVA_HOME and PATH environment variables settings from the project .Rprofile.
#' @examples
#' # clear the JAVA_HOME and PATH environment variables in the specified project .Rprofile
#' java_env_unset(project_path = tempdir())
java_env_unset <- function(
  project_path = NULL,
  quiet = FALSE
) {
  rje_consent_check()

  # Resolve the project path
  # consistent with renv behavior
  # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
  project_path <- ifelse(is.null(project_path), getwd(), project_path)
  rprofile_path <- file.path(project_path, ".Rprofile")

  if (file.exists(rprofile_path)) {
    rprofile_content <- readLines(rprofile_path, warn = FALSE)
    rprofile_content <- rprofile_content[!grepl("# rJavaEnv", rprofile_content)]
    writeLines(rprofile_content, con = rprofile_path)
    if (!quiet) {
      cli::cli_inform(
        "Removed JAVA_HOME settings from .Rprofile in '{.path {rprofile_path}}'"
      )
    }
  } else {
    if (!quiet) {
      cli::cli_inform(c(
        "!" = "No .Rprofile found in the project directory: {.path project_path}"
      ))
    }
  }
}

#' @title Get JAVA_HOME
#' @description Get the current JAVA_HOME environment variable.
#' @return The value of the JAVA_HOME environment variable.
#' @export
#' @examples
#' java_get_home()
java_get_home <- function() {
  java_home <- Sys.getenv("JAVA_HOME", unset = NA)
  if (is.na(java_home) || java_home == "") {
    return("")
  }
  java_home
}

#' Internal helper to parse java version output
#' @noRd
._java_parse_version_output <- function(java_ver) {
  # Handle null/empty input
  if (is.null(java_ver) || length(java_ver) == 0) {
    return(FALSE)
  }

  # Extract Java version
  # Iterate over all lines to find the version string
  # This is needed because sometimes there is noise (e.g. "Picked up ...")
  major_java_ver <- NULL
  for (line in java_ver) {
    matches <- regexec(
      '^[[:space:]]*(openjdk|java)[[:space:]]+(version[[:space:]]+)?(")?([0-9]+)',
      line
    )
    if (matches[[1]][1] != -1) {
      major_java_ver <- regmatches(line, matches)[[1]][5]
      break
    }
  }

  if (is.null(major_java_ver)) {
    return(FALSE)
  }

  # Fix 1 to 8, as Java 8 prints "1.8"
  if (major_java_ver == "1") {
    major_java_ver <- "8"
  }

  return(major_java_ver)
}
