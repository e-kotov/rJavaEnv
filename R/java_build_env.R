#' Set up the environment for building R packages with Java dependencies from source
#'
#' This function configures the current R session or project's .Rprofile with
#' the necessary environment variables to compile Java-dependent packages like 'rJava' from source.
#'
#' @param java_home The path to the desired `JAVA_HOME`.
#' @param where Where to set the build environment: "session" for the current R session,
#'   or "project" to write to the `.Rprofile` file. Defaults to "session".
#' @inheritParams global_quiet_param
#' @inheritParams java_install
#' @return Invisibly returns `NULL` after setting the environment variables.
#' @export
#' @examples
#' \dontrun{
#' # Download and install Java 17
#' java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
#' java_home_path <- java_install(
#'   java_distrib_path = java_17_distrib,
#'   project_path = tempdir(),
#'   autoset_java_env = FALSE
#' )
#'
#' # Set up the build environment in the current session
#' java_set_build_env(java_home = java_home_path)
#' }
java_set_build_env <- function(
  java_home,
  where = c("session", "project"),
  project_path = NULL,
  quiet = FALSE
) {
  where <- match.arg(where)
  checkmate::assert_string(java_home)
  checkmate::assert_flag(quiet)

  if (where == "session") {
    set_java_build_env_vars(java_home, quiet = quiet)
    if (!quiet) {
      cli::cli_alert_success(
        "Build environment variables set for the current R session."
      )
    }
  } else {
    # "project"
    project_path <- ifelse(is.null(project_path), getwd(), project_path)
    # This part would need a corresponding function to write these settings to .Rprofile
    # For now, we focus on the session, as requested.
    cli::cli_abort(
      "Writing build environment to .Rprofile is not yet implemented."
    )
  }

  if (!quiet) {
    cli::cli_inform(c(
      "i" = "The environment is now set up to build Java-dependent packages from source.",
      " " = "You can now run: {.code install.packages(\"rJava\", type = \"source\")}",
      "!" = "Please ensure your repository points to a source package repository (e.g., https://cloud.r-project.org). Some repositories may serve pre-built binaries even when `type = \"source\"` is specified."
    ))
  }

  invisible(NULL)
}

#' Set Java build environment variables for the current session
#'
#' @param java_home The path to the desired JAVA_HOME.
#' @inheritParams global_quiet_param
#' @keywords internal
set_java_build_env_vars <- function(java_home, quiet = FALSE) {
  # Set core Java variables
  Sys.setenv(JAVA = file.path(java_home, "bin", "java"))
  Sys.setenv(JAVAC = file.path(java_home, "bin", "javac"))
  Sys.setenv(JAR = file.path(java_home, "bin", "jar"))

  # JAVAH is deprecated/removed in modern JDKs; set if it exists
  javah_path <- file.path(java_home, "bin", "javah")
  Sys.setenv(JAVAH = if (file.exists(javah_path)) javah_path else "")

  # Platform-specific setup
  sysname <- Sys.info()["sysname"]
  if (sysname == "Linux") {
    # Find libjvm.so
    libjvm_path <- list.files(
      path = java_home,
      pattern = "libjvm.so$",
      recursive = TRUE,
      full.names = TRUE
    )
    server_files <- libjvm_path[grepl("/server/libjvm.so$", libjvm_path)]
    libjvm_path <- if (length(server_files) > 0) {
      server_files[1]
    } else {
      libjvm_path[1]
    }

    if (!is.null(libjvm_path) && file.exists(libjvm_path)) {
      jvm_lib_dir <- dirname(libjvm_path)
      # Set runtime loader path and other necessary variables
      Sys.setenv(JAVA_LD_LIBRARY_PATH = jvm_lib_dir)
      Sys.setenv(
        LD_LIBRARY_PATH = paste(
          jvm_lib_dir,
          Sys.getenv("LD_LIBRARY_PATH"),
          sep = .Platform$path.sep
        )
      )
      Sys.setenv(JAVA_LIBS = paste0("-L", jvm_lib_dir, " -ljvm"))
      # Set C Pre-processor Flags for JNI headers
      cpp_flags <- paste0(
        "-I",
        file.path(java_home, "include"),
        " -I",
        file.path(java_home, "include", "linux")
      )
      Sys.setenv(JAVA_CPPFLAGS = cpp_flags)
      tryCatch(dyn.load(libjvm_path), error = function(e) {
        if (!quiet) {
          cli::cli_warn("Failed to dynamically load libjvm.so: {e$message}")
        }
      })
    } else {
      if (!quiet) {
        cli::cli_warn(
          "Could not find libjvm.so within JAVA_HOME: {.path {java_home}}"
        )
      }
    }
  } else if (sysname == "Darwin") {
    # Set JAVA_CPPFLAGS for JNI headers
    cpp_flags <- paste0(
      "-I",
      file.path(java_home, "include"),
      " -I",
      file.path(java_home, "include", "darwin")
    )
    Sys.setenv(JAVA_CPPFLAGS = cpp_flags)
    # Find libjvm.dylib
    libjvm_path <- file.path(java_home, "lib", "server", "libjvm.dylib")
    if (!file.exists(libjvm_path)) {
      libjvm_path <- file.path(java_home, "lib", "client", "libjvm.dylib")
    }

    if (file.exists(libjvm_path)) {
      jvm_lib_dir <- dirname(libjvm_path)
      # Set linker and loader variables
      Sys.setenv(JAVA_LIBS = paste0("-L", jvm_lib_dir, " -ljvm"))
      Sys.setenv(PKG_LIBS = paste0("-L", jvm_lib_dir, " -ljvm"))
      Sys.setenv(PKG_LDFLAGS = paste0("-Wl,-rpath,", jvm_lib_dir))
      Sys.setenv(
        DYLD_LIBRARY_PATH = paste(
          jvm_lib_dir,
          Sys.getenv("DYLD_LIBRARY_PATH"),
          sep = .Platform$path.sep
        )
      )
      tryCatch(dyn.load(libjvm_path), error = function(e) {
        if (!quiet) {
          cli::cli_warn("Failed to dynamically load libjvm.dylib: {e$message}")
        }
      })
    } else {
      if (!quiet) {
        cli::cli_warn(
          "Could not find libjvm.dylib within JAVA_HOME: {.path {java_home}}"
        )
      }
    }
  }
  # Note: Windows does not typically require these additional settings for building rJava,
  # as the installer handles the necessary configurations.
}
