#' Set up the environment for building R packages with Java dependencies from source
#'
#' This function configures the current R session with the necessary environment
#' variables to compile Java-dependent packages like 'rJava' from source.
#'
#' @param java_home The path to the desired `JAVA_HOME`.
#' @param where Where to set the build environment. Currently only "session" is supported.
#' @inheritParams global_quiet_param
#'
#' @return Invisibly returns `NULL` after setting the environment variables.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download and install Java 17
#' java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
#' java_home_path <- java_install(
#'   java_distrib_path = java_17_distrib,
#'   project_path = tempdir(),
#'   autoset_java_env = FALSE # Manually set env
#' )
#'
#' # Set up the build environment in the current session
#' java_set_build_env(java_home = java_home_path)
#'
#' # Now, install rJava from source
#' install.packages("rJava", type = "source", repos = "https://cloud.r-project.org")
#' }
java_set_build_env <- function(
  java_home,
  where = "session",
  quiet = FALSE
) {
  where <- match.arg(where)
  if (where != "session") {
    cli::cli_abort(
      "Currently, only setting the build environment for the current 'session' is supported."
    )
  }

  checkmate::assert_string(java_home)
  checkmate::assert_flag(quiet)

  # First, set the basic JAVA_HOME and PATH
  java_env_set_session(java_home)

  # Set core Java variables for build process
  Sys.setenv(JAVA = file.path(java_home, "bin", "java"))
  Sys.setenv(JAVAC = file.path(java_home, "bin", "javac"))
  Sys.setenv(JAR = file.path(java_home, "bin", "jar"))
  javah_path <- file.path(java_home, "bin", "javah")
  Sys.setenv(JAVAH = if (file.exists(javah_path)) javah_path else "")

  # Platform-specific build flags
  if (Sys.info()["sysname"] == "Linux") {
    # Find libjvm.so
    all_files <- list.files(
      path = java_home,
      pattern = "libjvm.so$",
      recursive = TRUE,
      full.names = TRUE
    )
    libjvm_path <- NULL
    if (length(all_files) > 0) {
      server_files <- all_files[grepl("/server/libjvm.so$", all_files)]
      libjvm_path <- if (length(server_files) > 0) {
        server_files[1]
      } else {
        all_files[1]
      }
    }

    if (!is.null(libjvm_path) && file.exists(libjvm_path)) {
      jvm_lib_dir <- dirname(libjvm_path)
      r_lib_dir <- R.home("lib")

      # Set runtime loader path (LD_LIBRARY_PATH)
      Sys.setenv(JAVA_LD_LIBRARY_PATH = jvm_lib_dir)
      old_ld_path <- Sys.getenv("LD_LIBRARY_PATH", unset = "")
      paths_to_prepend <- unique(c(jvm_lib_dir, r_lib_dir))
      new_ld_path <- if (nzchar(old_ld_path)) {
        paste(c(paths_to_prepend, old_ld_path), collapse = .Platform$path.sep)
      } else {
        paste(paths_to_prepend, collapse = .Platform$path.sep)
      }
      Sys.setenv(LD_LIBRARY_PATH = new_ld_path)

      # Construct and set LIBS for the linker
      r_cmd_path <- file.path(R.home("bin"), "R")
      r_libs <- tryCatch(
        system2(r_cmd_path, "CMD config LIBS", stdout = TRUE, stderr = TRUE),
        warning = function(w) "",
        error = function(e) ""
      )
      r_ldflags <- tryCatch(
        system2(r_cmd_path, "CMD config LDFLAGS", stdout = TRUE, stderr = TRUE),
        warning = function(w) "",
        error = function(e) ""
      )
      full_libs <- paste(
        c(paste0("-L", jvm_lib_dir), "-ljvm", r_ldflags, r_libs),
        collapse = " "
      )
      Sys.setenv(LIBS = full_libs)

      # Set Java libs for rJava's main configure script
      Sys.setenv(JAVA_LIBS = paste0("-L", jvm_lib_dir, " -ljvm"))

      # Set C Pre-processor Flags for JNI headers
      cpp_flags <- paste0(
        "-I",
        file.path(java_home, "include"),
        " -I",
        file.path(java_home, "include", "linux")
      )
      if (nzchar(cpp_flags)) {
        Sys.setenv(JAVA_CPPFLAGS = cpp_flags)
      }

      # Dynamically load the library
      tryCatch(dyn.load(libjvm_path), error = function(e) {
        if (!quiet) {
          cli::cli_warn(
            "Found libjvm.so at '{.path {libjvm_path}}' but failed to load it: {e$message}"
          )
        }
      })
    } else {
      if (!quiet) {
        cli::cli_warn(
          "Could not find libjvm.so within JAVA_HOME: {.path {java_home}}"
        )
      }
    }
  } else if (Sys.info()["sysname"] == "Darwin") {
    # Set JAVA_CPPFLAGS for JNI headers
    Sys.setenv(
      JAVA_CPPFLAGS = paste0(
        "-I",
        file.path(java_home, "include"),
        " -I",
        file.path(java_home, "include", "darwin")
      )
    )

    # Find libjvm.dylib
    server_path <- file.path(java_home, "lib", "server", "libjvm.dylib")
    client_path <- file.path(java_home, "lib", "client", "libjvm.dylib")
    libjvm_path <- if (file.exists(server_path)) {
      server_path
    } else if (file.exists(client_path)) {
      client_path
    } else {
      NULL
    }

    if (!is.null(libjvm_path)) {
      jvm_lib_dir <- dirname(libjvm_path)
      r_lib_dir <- R.home("lib")

      # Set JAVA_LIBS for rJava's main configure script
      Sys.setenv(JAVA_LIBS = paste0("-L", jvm_lib_dir, " -ljvm"))

      # Set PKG_LIBS and PKG_LDFLAGS for the final link step of rJava.so
      Sys.setenv(PKG_LIBS = paste0("-L", jvm_lib_dir, " -ljvm"))
      Sys.setenv(PKG_LDFLAGS = paste0("-Wl,-rpath,", jvm_lib_dir))

      # Set runtime loader path (DYLD_LIBRARY_PATH)
      old_dyld_path <- Sys.getenv("DYLD_LIBRARY_PATH", unset = "")
      paths_to_prepend <- unique(c(jvm_lib_dir, r_lib_dir))
      new_dyld_path <- if (nzchar(old_dyld_path)) {
        paste(c(paths_to_prepend, old_dyld_path), collapse = .Platform$path.sep)
      } else {
        paste(paths_to_prepend, collapse = .Platform$path.sep)
      }
      Sys.setenv(DYLD_LIBRARY_PATH = new_dyld_path)

      # Set LDFLAGS for the JRI compilation step's configure script
      r_cmd_path <- file.path(R.home("bin"), "R")
      r_ldflags <- tryCatch(
        system2(r_cmd_path, "CMD config LDFLAGS", stdout = TRUE, stderr = TRUE),
        warning = function(w) "",
        error = function(e) ""
      )
      new_ldflags <- paste(
        c(
          paste0("-L", jvm_lib_dir),
          paste0("-Wl,-rpath,", jvm_lib_dir),
          r_ldflags
        ),
        collapse = " "
      )
      Sys.setenv(LDFLAGS = new_ldflags)

      # Dynamically load the library
      tryCatch(dyn.load(libjvm_path), error = function(e) {
        if (!quiet) {
          cli::cli_warn(
            "Found libjvm.dylib at '{.path {libjvm_path}}' but failed to load it: {e$message}"
          )
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

  if (!quiet) {
    cli::cli_alert_success(
      "Build environment variables set for the current R session."
    )
    cli::cli_inform(c(
      "i" = "The environment is now set up to build Java-dependent packages from source.",
      " " = "You can now run: {.code install.packages(\"rJava\", type = \"source\")}",
      "!" = "Please ensure your repository points to a source package repository (e.g., https://cloud.r-project.org). Some repositories may serve pre-built binaries even when `type = \"source\"` is specified."
    ))
  }

  invisible(NULL)
}
