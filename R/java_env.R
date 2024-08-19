# set Java environment ------------------------------------------------------------

#' Set the `JAVA_HOME` and `PATH` environment variables to a given path
#'
#' @param java_home The path to the desired `JAVA_HOME`.
#' @param where Where to set the `JAVA_HOME`: "session", "project", or "both". Defaults to "session" and only updates the paths in the current R session. When "both" or "project" is selected, the function updates the .Rprofile file in the project directory to set the JAVA_HOME and PATH environment variables at the start of the R session.
#' @param verbose Whether to print detailed messages. Defaults to TRUE.
#' @inheritParams java_install
#' @return Nothing. Sets the JAVA_HOME and PATH environment variables.
#' @export
#' @examples
#' \dontrun{
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
#'   where = "session",
#'   java_home = java_home,
#'   project_path = tempdir()
#' )
#' 
#' }
java_env_set <- function(
  where = c("session", "both", "project"),
  java_home,
  project_path,
  verbose = TRUE
) {
  rje_consent_check()

  where <- match.arg(where)
  checkmate::assertString(java_home)
  checkmate::assertFlag(verbose)



  if (where %in% c("session", "both")) {
    java_env_set_session(java_home)
    if (verbose) {
      cli::cli_alert_success(c(
        "Current R Session: ",
        "JAVA_HOME and PATH set to {.path {java_home}}"
      ))
    }
  }

  if (where %in% c("project", "both")) {
    java_env_set_rprofile(java_home, project_path = project_path)
    if (verbose) {
      cli::cli_alert_success(c(
        "Current R Project/Working Directory: ",
        "JAVA_HOME and PATH set to '{.path {java_home}}' in .Rprofile in '{.path {project_path, \".Rprofile\")}}'"
      ))
    }
  }

  invisible(NULL)
}

# Helper function for java_env_set_session
#' Set the JAVA_HOME and PATH environment variables for the current session
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @keywords internal
#'
java_env_set_session <- function(java_home) {
  Sys.setenv(JAVA_HOME = java_home)
  old_path <- Sys.getenv("PATH")
  new_path <- file.path(java_home, "bin")
  Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep))
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
  java_env_unset(verbose = FALSE)

  # Resolve the project path
  # consistent with renv behavior
  # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
  project_path <- ifelse(is.null(project_path), getwd(), project_path)
  rprofile_path <- file.path(project_path, ".Rprofile")

  # Normalize the path for Windows
  if (.Platform$OS.type == "windows") {
    java_home <- gsub("\\\\", "/", java_home)
  }

  lines_to_add <- c(
    "# rJavaEnv begin: Manage JAVA_HOME",
    sprintf("Sys.setenv(JAVA_HOME = '%s') # rJavaEnv", java_home),
    "old_path <- Sys.getenv('PATH') # rJavaEnv",
    "new_path <- file.path(Sys.getenv('JAVA_HOME'), 'bin') # rJavaEnv",
    "Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep)) # rJavaEnv",
    "rm(old_path, new_path) # rJavaEnv",
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
#' This function sets the JAVA_HOME environment variable, initializes the JVM using rJava,
#' and prints the Java version that would be used if the user sets the given JAVA_HOME
#' in the current R session. This check is performed in a separate R session to avoid
#' having to reload the current R session. The reason for this is that once Java is initialized in an R session,
#' it cannot be uninitialized unless the current R session is restarted.
#'
#' @param java_home The path to the desired JAVA_HOME. If NULL, uses the current JAVA_HOME environment variable.
#' @param verbose Whether to print detailed messages. Defaults to TRUE.
#' @return TRUE if successful, otherwise FALSE.
#' @examples
#' java_check_version_rjava()
#'
#' @export
java_check_version_rjava <- function(java_home = NULL, verbose = TRUE) {
  # Check if rJava is installed
  if (!requireNamespace("rJava", quietly = TRUE)) {
    cli::cli_alert_danger("rJava package is not installed. You need to install rJava to use this function to check if rJava-based packages will work with the specified Java version.")
    return(FALSE)
  }

  # Determine JAVA_HOME if not specified by the user
  if (is.null(java_home)) {
    current_java_home <- Sys.getenv("JAVA_HOME")
    if (verbose) {
      if (current_java_home == "") {
        if (verbose) cli::cli_inform("JAVA_HOME is not set.")
      } else {
        if (verbose) cli::cli_inform("Using current session's JAVA_HOME: {.path {current_java_home}}")
      }
    }
    java_home <- current_java_home
  } else {
    if (verbose) {
      if (verbose) cli::cli_inform("Using user-specified JAVA_HOME: {.path {java_home}}")
    }
  }

  # Get the code of the unexported function to use in a script
  internal_function <- getFromNamespace("java_version_check_rscript", "rJavaEnv")
  script_content <- paste(deparse(body(internal_function)), collapse = "\n")

  # Create a wrapper script that includes the function definition and calls it
  wrapper_script <- sprintf(
    "java_version_check <- function(java_home) {\n%s\n}\n\nargs <- commandArgs(trailingOnly = TRUE)\nresult <- java_version_check(args[1])\ncat(result, sep = '\n')",
    script_content
  )

  # Write the wrapper script to a temporary file
  script_file <- tempfile(fileext = ".R")
  writeLines(wrapper_script, script_file)

  # Run the script in a separate R session and capture the output
  output <- suppressWarnings(system2("Rscript",
    args = c(script_file, java_home),
    stdout = TRUE, stderr = TRUE
  ))

  # Delete the temporary script file
  unlink(script_file)

  # Process and print the output
  if (length(output) > 0) {
    if (any(grepl("error", tolower(output)))) {
      cli::cli_alert_danger("Failed to retrieve Java version.")
      return(FALSE)
    } else {
      output <- paste(output, collapse = "\n")
      java_version <- sub(".*Java version: \"([^\"]+)\".*", "\\1", output)
      if (verbose) {
        if (is.null(java_home)) {
          cli::cli_inform("With the current session's JAVA_HOME {output}")
        } else {
          cli::cli_inform("With the user-specified JAVA_HOME {output}")
        }
      } else {
        cli::cli_inform(c("OK", paste("Java version:", java_version)))
      }
      return(TRUE)
    }
  } else {
    if (verbose) cli::cli_alert_danger("Failed to retrieve Java version.")
  }
}

#' Check installed Java version using terminal commands
#'
#' @param java_home Path to Java home directory. If NULL, the function uses the JAVA_HOME environment variable.
#'
#' @return TRUE if successful, otherwise FALSE.
#' @export
#'
#' @examples
#' java_check_version_cmd()
#'
java_check_version_cmd <- function(java_home = NULL) {
  # Backup the current JAVA_HOME
  old_java_home <- Sys.getenv("JAVA_HOME")

  # Set JAVA_HOME in current session if specified
  if (!is.null(java_home)) {
    java_env_set_session(java_home)
  }

  # Get JAVA_HOME again and check if it's set
  current_java_home <- Sys.getenv("JAVA_HOME")
  if (current_java_home == "") {
    cli::cli_alert_warning("JAVA_HOME is not set.")
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
    }
    return(FALSE)
  } else {
    cli::cli_inform("JAVA_HOME: {.path {current_java_home}}")
  }

  # Check if java executable exists in the PATH
  if (!nzchar(Sys.which("java"))) {
    cli::cli_alert_danger("Java installation is not valid, Java executable not found.")
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
    }
    return(FALSE)
  }

  # Check Java path and version using system commands
  success <- java_check_version_system()

  # restore original JAVA_HOME that was in the environment before the function was called
  if (!is.null(java_home)) {
    Sys.setenv(JAVA_HOME = old_java_home)
  }

  return(success)
}

#' Check and print Java path and version
#'
#' This function checks the Java executable path and retrieves the Java version,
#' then prints these details to the console.
#'
#' @keywords internal
#'
#' @return TRUE if successful, otherwise FALSE.
java_check_version_system <- function() {
  which_java <- tryCatch(
    system2("which", args = "java", stdout = TRUE, stderr = TRUE),
    error = function(e) NULL
  )
  if (is.null(which_java)) {
    cli::cli_alert_danger("Java executable not found in PATH.")
    return(FALSE)
  }
  java_ver <- tryCatch(
    system2("java", args = "-version", stdout = TRUE, stderr = TRUE),
    error = function(e) NULL
  )
  if (is.null(java_ver)) {
    cli::cli_alert_danger("Failed to retrieve Java version.")
    return(FALSE)
  }

  cli::cli_inform(c(
    "Java path: {.path {which_java}}",
    "Java version:\n{.val {paste(java_ver, collapse = '\n')}}"
  ))

  invisible(TRUE)
}


# unset java env ----------------------------------------------------------

#' Unset the JAVA_HOME and PATH environment variables in the project .Rprofile
#'
#' @param verbose Whether to print detailed messages. Defaults to TRUE.
#' @inheritParams java_install
#' @export
#' @return Nothing. Removes the JAVA_HOME and PATH environment variables settings from the project .Rprofile.
#' @examples
#' \dontrun{
#' # clear the JAVA_HOME and PATH environment variables in the specified project .Rprofile
#' java_env_unset(project_path = tempdir())
#' }
java_env_unset <- function(
    project_path = NULL,
    verbose = TRUE
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
    if (verbose) {
      cli::cli_inform("Removed JAVA_HOME settings from .Rprofile in '{.path {rprofile_path}}'")
    }
  } else {
    if (verbose) {
      cli::cli_alert_warning("No .Rprofile found in the project directory: {.path project_path}")
    }
  }
}
