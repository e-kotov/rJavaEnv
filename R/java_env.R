# set Java environment ------------------------------------------------------------

#' Set the JAVA_HOME and PATH environment variables to a given path
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @param where Where to set the JAVA_HOME: "session", "project", or "both". Defaults to "both". When "both" or "project" is selected, the function updates the .Rprofile file in the project directory to set the JAVA_HOME and PATH environment variables at the start of the R session.
#' @return Nothing. Sets the JAVA_HOME and PATH environment variables.
#' @export
#' @examples
#' \dontrun{
#' java_env_set("/path/to/java", "both")
#' }
java_env_set <- function(java_home, where = c("both", "session", "project")) {
  where <- match.arg(where)

  old_java_home <- Sys.getenv("JAVA_HOME")
  old_path <- Sys.getenv("PATH")

  if (where %in% c("session", "both")) {
    java_env_set_session(java_home)
    pkg_message(c("Current R Session:",
                  "JAVA_HOME set to {.path {java_home}}"))
  }

  if (where %in% c("project", "both")) {
    java_env_set_rprofile(java_home)
    pkg_message(c("Current R Project/Working Directory:",
                  "Set JAVA_HOME to '{.path {java_home}}' in .Rprofile in '{.path {file.path(getwd(), \".Rprofile\")}}'"))
  }

  if (requireNamespace("rJava", quietly = TRUE)) {
    if (!java_check_version_rjava(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
      Sys.setenv(PATH = old_path)
      cli::cli_alert_danger("Failed to set JAVA_HOME. Reverted to previous settings.")
      return(invisible(NULL))
    }
  }

  cli::cli_alert_success("JAVA_HOME successfully set to {.path {java_home}}.")

  invisible(NULL)
}

# Helper function for java_env_set_session with Roxygen Documentation
#' Set the JAVA_HOME and PATH environment variables for the current session
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @keywords internal
java_env_set_session <- function(java_home) {
  Sys.setenv(JAVA_HOME = java_home)
  old_path <- Sys.getenv("PATH")
  new_path <- file.path(java_home, "bin")
  Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep))
}

# Helper function for java_env_set_rprofile with Roxygen Documentation
#' Update the .Rprofile file in the project directory
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @keywords internal
java_env_set_rprofile <- function(java_home) {
  java_unset_env(verbose = FALSE)

  project <- getwd()
  rprofile_path <- file.path(project, ".Rprofile")
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

  invisible(NULL)
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
#' @param verbose Logical indicating whether to print detailed messages. Defaults to TRUE.
#' @examples
#' \dontrun{
#' java_version_check_rjava("/new/path/to/java")
#' }
#' @export
java_version_check_rjava <- function(java_home = NULL, verbose = TRUE) {
  # Check if rJava is installed
  if (!requireNamespace("rJava", quietly = TRUE)) {
    stop("rJava package is not installed.")
  }

  # Determine JAVA_HOME
  if (is.null(java_home)) {
    current_java_home <- Sys.getenv("JAVA_HOME")
    if (verbose) {
      if (current_java_home == "") {
        pkg_message("JAVA_HOME is not set.")
      } else {
        pkg_message("Using current session's JAVA_HOME: {.path {current_java_home}}")
      }
    }
  } else {
    if (verbose) {
      pkg_message("Using user-specified JAVA_HOME: {.path {java_home}}")
    }
    current_java_home <- java_home
  }

  # Set JAVA_HOME and check if Java executable is available
  old_java_home <- Sys.getenv("JAVA_HOME")
  java_env_set_session(current_java_home)

  if (!nzchar(Sys.getenv("JAVA_HOME"))) {
    if (verbose) cli::cli_alert_warning("JAVA_HOME is not set correctly.")
    Sys.setenv(JAVA_HOME = old_java_home)
    return(invisible(NULL))
  }

  if (!nzchar(Sys.which("java"))) {
    if (verbose) cli::cli_alert_danger("Java installation is not valid.")
    Sys.setenv(JAVA_HOME = old_java_home)
    return(invisible(NULL))
  }

  # Get the code of the unexported function to use a script
  internal_function <- getFromNamespace("java_version_check_rscript", "rJavaEnv")
  script_content <- paste(deparse(body(internal_function)), collapse = "\n")

  # Create a wrapper script that includes the function definition and calls it
  wrapper_script <- sprintf(
    ".check_java_version_script <- function(java_home) {\n%s\n}\n\nargs <- commandArgs(trailingOnly = TRUE)\nresult <- .check_java_version_script(args[1])\ncat(result, sep = '\n')",
    script_content
  )

  script_file <- tempfile(fileext = ".R")
  writeLines(wrapper_script, script_file)

  output <- suppressWarnings(system2("Rscript",
                                     args = c(script_file, Sys.getenv("JAVA_HOME")),
                                     stdout = TRUE, stderr = TRUE))

  unlink(script_file)

  Sys.setenv(JAVA_HOME = old_java_home)

  # Process and print the output
  if (length(output) > 0) {
    output <- paste(output, collapse = "\n")
    java_version <- sub(".*Java version: \"([^\"]+)\".*", "\\1", output)
    if (verbose) {
      if (is.null(java_home)) {
        pkg_message("With the current session's JAVA_HOME {output}")
      } else {
        pkg_message("With the user-specified JAVA_HOME {output}")
      }
    } else {
      pkg_message(c("OK", paste("Java version:", java_version)))
    }
  } else {
    if (verbose) cli::cli_alert_danger("Failed to retrieve Java version.")
  }

  invisible(NULL)
}







#' Check installed Java version using terminal commands
#'
#' @param java_home Path to Java home directory. If NULL, the function uses the JAVA_HOME environment variable.
#'
#' @return TRUE if successful, otherwise FALSE.
#' @export
#'
#' @examples
#' \dontrun{
#' java_check_version_cmd()
#' }
java_check_version_cmd <- function(java_home = NULL) {
  # Set JAVA_HOME for this function's scope only
  old_java_home <- Sys.getenv("JAVA_HOME")
  if (!is.null(java_home)) {
    .java_set_env_session(java_home)
  }

  # Get JAVA_HOME and check if it's set
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
    cli::cli_alert_danger("Java installation is not valid.")
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
    }
    return(FALSE)
  }

  # Check Java path and version using system commands
  success <- .check_java_system2()

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
#' @return TRUE if successful, otherwise stops with an error.
.check_java_system2 <- function() {
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

  cli::cli_inform(c("Java path: {.path {which_java}}",
                    "Java version:\n{.val {paste(java_ver, collapse = '\n')}}"))

  return(TRUE)
}


# unset java env ----------------------------------------------------------

#' Unset the JAVA_HOME and PATH environment variables in the project .Rprofile
#'
#' @param quiet Whether to suppress messages. Defaults to FALSE.
#'
#' @export
#' @return Nothing. Removes the JAVA_HOME and PATH environment variables settings from the project .Rprofile.
java_unset_env <- function(verbose = TRUE) {
  project <- getwd()
  rprofile_path <- file.path(project, ".Rprofile")

  if (file.exists(rprofile_path)) {
    rprofile_content <- readLines(rprofile_path, warn = FALSE)
    rprofile_content <- rprofile_content[!grepl("# rJavaEnv", rprofile_content)]
    writeLines(rprofile_content, con = rprofile_path)
    if (!verbose) {
      message(sprintf("Removed JAVA_HOME settings from .Rprofile in '%s'", rprofile_path))
    }
  } else {
    if (!verbose) {
      message(sprintf("No .Rprofile found in '%s'", project))
    }
  }
}

