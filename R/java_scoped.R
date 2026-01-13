#' Set Java environment for the current scope
#'
#' Sets `JAVA_HOME` and `PATH` to the specified Java version for the remainder
#' of the current function or scope. The environment is automatically restored
#' when the scope exits.
#'
#' This is the recommended way for package developers to use Java executables
#' (via `system2` or `processx`) without permanently altering the user's global environment.
#'
#' @section Warning - Not for rJava:
#' **Do not use this function if your package depends on rJava.**
#' rJava locks the JVM at initialization and cannot switch versions within a session.
#' If you load an rJava-dependent package inside a `local_java_env()` scope,
#' rJava will lock to the scoped version, but after the scope exits, `JAVA_HOME`
#' will revert while rJava remains locked to the old version.
#' For rJava packages, use `java_ensure()` at the start of the R session instead.
#'
#' @inheritParams java_resolve
#' @param .local_envir The environment to apply the scope to. Defaults to the calling frame.
#' @param .use_cache Logical. If `TRUE`, uses cached results for Java version checks,
#'   improving performance in repeated calls (e.g., inside loops).
#' @return Invisibly returns the path to the selected JAVA_HOME.
#' @export
#' @examples
#' \donttest{
#' # Using system2
#' my_tool_wrapper <- function() {
#'   rJavaEnv::local_java_env(version = 21)
#'   system2("java", "-version")
#' } # Environment restored automatically here
#'
#' # Using processx
#' run_java_jar <- function(jar_path, args) {
#'   rJavaEnv::local_java_env(version = 21)
#'   processx::run("java", c("-jar", jar_path, args))
#' }
#'
#' # With caching for repeated calls
#' process_files <- function(files) {
#'   for (f in files) {
#'     rJavaEnv::local_java_env(version = 21, .use_cache = TRUE)
#'     processx::run("java", c("-jar", "processor.jar", f))
#'   }
#' }
#' }
local_java_env <- function(
  version,
  type = c("exact", "min"),
  distribution = "Corretto",
  install = TRUE,
  accept_system_java = TRUE,
  quiet = TRUE,
  .local_envir = parent.frame(),
  .use_cache = FALSE
) {
  # Resolve the path (find or install)
  java_home <- java_resolve(
    version = version,
    type = match.arg(type),
    distribution = distribution,
    install = install,
    accept_system_java = accept_system_java,
    quiet = quiet,
    .use_cache = .use_cache
  )

  # Capture current state
  old_java_home <- Sys.getenv("JAVA_HOME")
  old_path <- Sys.getenv("PATH")

  # Set new state
  Sys.setenv(JAVA_HOME = java_home)

  # Prepend bin to PATH so 'java' command refers to this version
  # Handle Windows .exe extension implicitly by path location
  java_bin <- file.path(java_home, "bin")
  Sys.setenv(PATH = paste(java_bin, old_path, sep = .Platform$path.sep))

  # Schedule restoration
  withr::defer(
    {
      if (old_java_home == "") {
        Sys.unsetenv("JAVA_HOME")
      } else {
        Sys.setenv(JAVA_HOME = old_java_home)
      }
      Sys.setenv(PATH = old_path)
    },
    envir = .local_envir
  )

  invisible(java_home)
}

#' Execute code with a specific Java environment
#'
#' Temporarily sets `JAVA_HOME` and `PATH` for the duration of the provided
#' code block, then restores the previous environment.
#'
#' @section Warning - Not for rJava:
#' **Do not use this function if your package depends on rJava.**
#' See `local_java_env()` for details on why rJava is incompatible with scoped Java switching.
#'
#' @inheritParams local_java_env
#' @param code The code to execute with the temporary Java environment.
#' @param ... Additional arguments passed to `local_java_env()`.
#' @return The result of executing `code`.
#' @export
#' @examples
#' \donttest{
#' # Using system2
#' rJavaEnv::with_java_env(version = 21, {
#'   system2("java", "-version")
#' })
#'
#' # Using processx
#' rJavaEnv::with_java_env(version = 21, {
#'   processx::run("java", c("-jar", "tool.jar", "--help"))
#' })
#' }
with_java_env <- function(version, code, ...) {
  local_java_env(version = version, ...)
  force(code)
}

#' Execute rJava code in a separate process with specific Java version
#'
#' Runs the provided function in a fresh R subprocess where `rJava` has not yet
#' been loaded. This allows you to enforce a specific Java version for `rJava`
#' operations without affecting the main R session or requiring a restart.
#'
#' This function requires the \pkg{callr} package.
#'
#' @inheritParams java_resolve
#' @param func The function to execute in the subprocess.
#' @param args A list of arguments to pass to `func`.
#' @param libpath Optional character vector of library paths to use in the subprocess.
#'   Defaults to `.libPaths()`.
#'
#' @return The result of `func`.
#' @export
#' @examples
#' \donttest{
#' # Run a function using Java 21 in a subprocess
#' result <- with_rjava_env(
#'   version = 21,
#'   func = function(x) {
#'     library(rJava)
#'     .jinit()
#'     .jcall("java.lang.System", "S", "getProperty", "java.version")
#'   },
#'   args = list(x = 1)
#' )
#' print(result)
#' }
with_rjava_env <- function(
  version,
  func,
  args = list(),
  distribution = "Corretto",
  install = TRUE,
  accept_system_java = TRUE,
  quiet = TRUE,
  libpath = .libPaths()
) {
  if (!requireNamespace("callr", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg callr} is required for {.fn with_rjava_env}.")
  }

  # 1. Resolve Java path (Install/Find)
  java_home <- java_resolve(
    version = version,
    distribution = distribution,
    install = install,
    accept_system_java = accept_system_java,
    quiet = quiet
  )

  # 2. Define the environment variables for the subprocess
  env_vars <- Sys.getenv() # Copy current env

  # Update JAVA variables
  env_vars["JAVA_HOME"] = java_home

  # Prepend to PATH
  java_bin <- file.path(java_home, "bin")
  old_path <- env_vars["PATH"]
  env_vars["PATH"] = paste(java_bin, old_path, sep = .Platform$path.sep)

  # Linux specific: LD_LIBRARY_PATH for rJava
  if (Sys.info()["sysname"] == "Linux") {
    libjvm_path <- get_libjvm_path(java_home)
    if (!is.null(libjvm_path)) {
      jvm_lib_dir <- dirname(libjvm_path)
      old_ld <- env_vars["LD_LIBRARY_PATH"]
      if (is.na(old_ld)) {
        old_ld <- ""
      }
      env_vars["LD_LIBRARY_PATH"] = paste(
        jvm_lib_dir,
        old_ld,
        sep = .Platform$path.sep
      )
    }
  }

  # 3. Run in subprocess
  callr::r(
    func = func,
    args = args,
    libpath = libpath,
    env = env_vars,
    show = !quiet # Show output if not quiet
  )
}
