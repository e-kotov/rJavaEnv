#' Set up the environment for building R packages with Java dependencies from source
#'
#' This function configures the current R session with the necessary environment
#' variables to compile Java-dependent packages like 'rJava' from source. **Note: this function is still experimental.**
#'
#' @param java_home The path to the desired `JAVA_HOME`. Defaults to the value of the `JAVA_HOME` environment variable.
#' @param where Where to set the build environment: "session", "project", or "both". Defaults to "session". When "both" or "project" is selected, the function updates the .Rprofile file in the project directory.
#' @param project_path The path to the project directory, required when `where` is "project" or "both". Defaults to the current working directory.
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
#' java_build_env_set(java_home = java_home_path)
#'
#' # Now, install rJava from source
#' install.packages("rJava", type = "source", repos = "https://cloud.r-project.org")
#' }
java_build_env_set <- function(
  java_home = Sys.getenv("JAVA_HOME"),
  where = c("session", "project", "both"),
  project_path = NULL,
  quiet = FALSE
) {
  where <- match.arg(where)

  if (!nzchar(java_home)) {
    cli::cli_abort(c(
      "The {.arg java_home} argument is not provided and the JAVA_HOME environment variable is not set.",
      "i" = "Please provide a path to a Java installation."
    ))
  }
  checkmate::assert_string(java_home)
  checkmate::assert_flag(quiet)

  if (where %in% c("session", "both")) {
    set_java_build_env_vars(java_home, quiet)
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
  }

  if (where %in% c("project", "both")) {
    rje_consent_check()
    project_path <- ifelse(is.null(project_path), getwd(), project_path)
    java_build_env_set_rprofile(java_home, project_path)
    if (!quiet) {
      cli::cli_alert_success(c(
        "Current R Project/Working Directory: ",
        "Build environment set in .Rprofile at '{.path {project_path}}"
      ))
    }
  }

  if (!quiet) {
    os <- Sys.info()["sysname"]
    if (os == "Linux") {
      cli::cli_warn(c(
        "System dependencies required for building rJava from source on Linux.",
        "i" = "On Debian/Ubuntu, you may need to install: {.pkg libpcre2-dev}, {.pkg libdeflate-dev}, {.pkg libzstd-dev}, {.pkg liblzma-dev}, {.pkg libbz2-dev}, {.pkg zlib1g-dev}, and {.pkg libicu-dev}.",
        "i" = "Example installation command for Debian/Ubuntu:",
        " " = "{.code sudo apt-get update && sudo apt-get install -y --no-install-recommends libpcre2-dev libdeflate-dev libzstd-dev liblzma-dev libbz2-dev zlib1g-dev libicu-dev && sudo rm -rf /var/lib/apt/lists/*}"
      ))
    } else if (os == "Windows") {
      cli::cli_warn(c(
        "Rtools is required for building rJava from source on Windows.",
        "i" = "Please ensure it is installed and its path is correctly configured.",
        "i" = "For more information, visit: {.url https://cran.r-project.org/bin/windows/Rtools/}"
      ))
    } else if (os == "Darwin") {
      cli::cli_warn(c(
        "Xcode Command Line Tools are required for building rJava from source on macOS.",
        "i" = "If not already installed, run the following command in your terminal:",
        " " = "{.code xcode-select --install}"
      ))
    }
  }

  invisible(NULL)
}

#' Unset the Java build environment variables in the project .Rprofile
#'
#' @inheritParams java_env_unset
#' @export
java_build_env_unset <- function(project_path = NULL, quiet = FALSE) {
  rje_consent_check()

  project_path <- ifelse(is.null(project_path), getwd(), project_path)
  rprofile_path <- file.path(project_path, ".Rprofile")

  if (file.exists(rprofile_path)) {
    rprofile_content <- readLines(rprofile_path, warn = FALSE)
    rprofile_content <- rprofile_content[
      !grepl("# rJavaEnvBuild", rprofile_content)
    ]
    writeLines(rprofile_content, con = rprofile_path)
    if (!quiet) {
      cli::cli_inform(
        "Removed Java build environment settings from .Rprofile in '{.path {rprofile_path}}'"
      )
    }
  } else {
    if (!quiet) {
      cli::cli_inform(c(
        "!" = "No .Rprofile found in the project directory: {.path {project_path}}"
      ))
    }
  }
}

#' Helper function to set Java build environment variables
#' @param java_home The path to the desired `JAVA_HOME`.
#' @inheritParams global_quiet_param
#' @keywords internal
set_java_build_env_vars <- function(java_home, quiet = FALSE) {
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
}

#' Helper function to write build environment settings to .Rprofile
#' @param java_home The path to the desired `JAVA_HOME`.
#' @param project_path The path to the project directory.
#' @keywords internal
java_build_env_set_rprofile <- function(java_home, project_path) {
  java_build_env_unset(quiet = TRUE, project_path = project_path)

  rprofile_path <- file.path(project_path, ".Rprofile")

  if (.Platform$OS.type == "windows") {
    java_home <- gsub("\\", "/", java_home)
  }

  lines_to_add <- c(
    "# rJavaEnvBuild begin: Manage Java Build Environment",
    sprintf(
      "if (requireNamespace(\"rJavaEnv\", quietly = TRUE)) { rJavaEnv:::set_java_build_env_vars(java_home = '%s', quiet = TRUE) } # rJavaEnvBuild",
      java_home
    ),
    "# rJavaEnvBuild end: Manage Java Build Environment"
  )

  if (file.exists(rprofile_path)) {
    cat(lines_to_add, file = rprofile_path, append = TRUE, sep = "\n")
  } else {
    writeLines(lines_to_add, con = rprofile_path)
  }
}
