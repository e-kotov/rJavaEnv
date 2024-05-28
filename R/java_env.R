# set java env ------------------------------------------------------------


#' Set the JAVA_HOME and PATH environment variables to a given path
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @param where Where to set the JAVA_HOME: "session", "project", or "both". Defaults to "both". When "both" or "project" is selected, the function updates the .Rprofile file in the project directory to set the JAVA_HOME and PATH environment variables at the start of the R session.
#' @export
#' @return Nothing. Sets the JAVA_HOME and PATH environment variables.
set_java_env <- function(java_home, where = c("both", "session", "project")) {
  where <- match.arg(where)

  if (where %in% c("session", "both")) {
    # Set environment variables for the current session
    .set_java_paths(java_home)
    message(sprintf("JAVA_HOME set to %s", java_home))
  }

  if (where %in% c("project", "both")) {
    # Update the .Rprofile in the project directory
    .set_java_home_in_rprofile(java_home)
  }

  invisible(NULL)
}

#' Set the JAVA_HOME and PATH environment variables
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @keywords internal
.set_java_paths <- function(java_home) {
  Sys.setenv(JAVA_HOME = java_home)
  old_path <- Sys.getenv("PATH")
  new_path <- file.path(java_home, "bin")
  Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep))
}

#' Update the .Rprofile file in the project directory
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @keywords internal
.set_java_home_in_rprofile <- function(java_home) {
  unset_java_env(quiet = TRUE)

  project <- getwd()
  rprofile_path <- file.path(project, ".Rprofile")
  lines_to_add <- c(
    "# rJavaEnv begin: Manage JAVA_HOME",
    sprintf("Sys.setenv(JAVA_HOME = '%s') # rJavaEnv", java_home),
    "old_path <- Sys.getenv('PATH') # rJavaEnv",
    "new_path <- file.path(Sys.getenv('JAVA_HOME'), 'bin') # rJavaEnv",
    "Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep)) # rJavaEnv",
    "# rJavaEnv end: Manage JAVA_HOME"
  )

  if (file.exists(rprofile_path)) {
    cat(lines_to_add, file = rprofile_path, append = TRUE, sep = "\n")
    message(sprintf("Set JAVA_HOME to '%s' in .Rprofile in '%s'", java_home, rprofile_path))
  } else {
    writeLines(lines_to_add, con = rprofile_path)
    message(sprintf(".Rprofile created with JAVA_HOME settings in '%s'", rprofile_path))
  }
}



# unset java env ----------------------------------------------------------

#' Unset the JAVA_HOME and PATH environment variables in the project .Rprofile
#'
#' @param quiet Whether to suppress messages. Defaults to FALSE.
#'
#' @export
#' @return Nothing. Removes the JAVA_HOME and PATH environment variables settings from the project .Rprofile.
unset_java_env <- function(quiet = FALSE) {
  project <- getwd()
  rprofile_path <- file.path(project, ".Rprofile")

  if (file.exists(rprofile_path)) {
    rprofile_content <- readLines(rprofile_path, warn = FALSE)
    rprofile_content <- rprofile_content[!grepl("# rJavaEnv", rprofile_content)]
    writeLines(rprofile_content, con = rprofile_path)
    if (!quiet) {
      message(sprintf("Removed JAVA_HOME settings from .Rprofile in '%s'", rprofile_path))
    }
  } else {
    if (!quiet) {
      message(sprintf("No .Rprofile found in '%s'", project))
    }
  }
}




# check java version ------------------------------------------------------


#' Check Java Version with a Specified JAVA_HOME Using a Separate R Session
#'
#' This function sets the JAVA_HOME environment variable, initializes the JVM using rJava,
#' and prints the Java version that would be used if the user sets the given JAVA_HOME
#' in the current R session. This check is performed in a separate R session to avoid
#' having to reload the current R session. The reason for this is that once Java is initialized in an R session, it
#' cannot be uninitialized unless the current R session is restarted.
#'
#' @param java_home The path to the desired JAVA_HOME. If NULL, uses the current JAVA_HOME environment variable.
#' @return A character string with the Java version.
#' @examples
#' \dontrun{
#' check_java_version_rjava("/new/path/to/java")
#' }
#' @export
check_java_version_rjava <- function(java_home = NULL) {
  # Use the helper function to set JAVA_HOME and check java executable
  .set_and_check_java_home(java_home)

  # Get the code of the unexported function to use a script
  internal_function <- getFromNamespace(".check_java_version_rscript", "rJavaEnv")
  script_content <- paste(deparse(body(internal_function)), collapse = "\n")

  # Create a wrapper script that includes the function definition and calls it
  wrapper_script <- sprintf(
    ".check_java_version_script <- function(java_home) {\n%s\n}\n\nargs <- commandArgs(trailingOnly = TRUE)\ncat(.check_java_version_script(args[1]))",
    script_content
  )

  script_file <- tempfile(fileext = ".R")
  writeLines(wrapper_script, script_file)

  output <- system2("Rscript",
    args = c(script_file, Sys.getenv("JAVA_HOME")),
    stdout = TRUE, stderr = TRUE
  )

  unlink(script_file)

  return(cat(output))
}


#' Check installed Java version using terminal commands
#'
#' @param java_home Path to Java home directory. If NULL, the function uses the JAVA_HOME environment variable.
#'
#' @return Java version, otherwise stops with an error.
#' @export
#'
#' @examples
#' \dontrun{
#' check_java_version_cmd()
#' }
check_java_version_cmd <- function(java_home = NULL) {
  # Use the helper function to set JAVA_HOME and check java executable
  .set_and_check_java_home(java_home)

  # Check Java path and version using system commands
  .check_java_system2()
}

#' Check and print Java path and version
#'
#' This function checks the Java executable path and retrieves the Java version,
#' then prints these details to the console.
#'
#' @return Nothing. Messages the Java path and version to the console.
.check_java_system2 <- function() {
  which_java <- system2("which", args = "java", stdout = TRUE, stderr = TRUE)
  java_ver <- system2("java", args = "-version", stdout = TRUE, stderr = TRUE)
  message(sprintf("Java path: %s", which_java))
  message(sprintf("Java version:\n%s", paste(java_ver, collapse = "\n")))
}


#' Helper function to set JAVA_HOME and check if java executable exists
#'
#' @param java_home The path to the desired JAVA_HOME. If NULL, uses the current JAVA_HOME environment variable.
#' @keywords internal
.set_and_check_java_home <- function(java_home = NULL) {
  # Set JAVA_HOME and PATH if java_home is provided
  if (!is.null(java_home)) {
    set_java_env(java_home)
  }

  # Get JAVA_HOME and check if it's set
  current_java_home <- Sys.getenv("JAVA_HOME")
  if (current_java_home == "") {
    warning("JAVA_HOME is not set.")
  } else {
    message(sprintf("JAVA_HOME: %s", current_java_home))
  }

  # Check if java executable exists in the PATH
  if (!nzchar(Sys.which("java"))) {
    stop("Java installation is not valid.")
  }

  return(TRUE)
}
