#' Set the JAVA_HOME and PATH environment variables to a given path
#'
#' @param java_dir
#'
#' @export
#' @return
set_java_env <- function(java_home) {
  Sys.setenv(JAVA_HOME = java_home)
  old_path <- Sys.getenv("PATH")
  new_path <- file.path(java_home, "bin")
  Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep))
}

#' Check Java Version with a Specified JAVA_HOME Using a Separate R Session
#'
#' This function sets the JAVA_HOME environment variable, initializes the JVM using rJava,
#' and prints the Java version that would be used if the user sets the given JAVA_HOME
#' in the current R session. This check is performed in a separate R session to avoid
#' having to reload the current R session. The reason for this is that once Java is initialized in an R session, it
#' cannot be uninitialized unless the current R session is restarted.
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @return A character string with the Java version.
#' @examples
#' \dontrun{
#' check_java_version_rjava("/new/path/to/java")
#' }
#' @export
check_java_version_rjava <- function(java_home) {
  if (!dir.exists(java_home)) {
    stop("Invalid JAVA_HOME path: Directory does not exist.")
  }

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
    args = c(script_file, java_home),
    stdout = TRUE, stderr = TRUE
  )

  unlink(script_file)

  return(cat(output))
}
