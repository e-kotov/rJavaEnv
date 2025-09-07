# set Java environment ------------------------------------------------------------

#' Set the Java runtime or build environment
#'
#' @description
#' Sets the essential `JAVA_HOME`, `PATH`, and system-specific library path for running Java-based packages.
#'
#' By default, it sets a minimal, safe runtime environment suitable for project `.Rprofile` files. For compiling `rJava` from source, set `setup_build_env = TRUE` to configure the necessary build tools in the **current R session only**.
#'
#' @param java_home The path to the desired `JAVA_HOME`.
#' @param where Where to set the `JAVA_HOME`: "session", "project", or "both". Defaults to "session" and only updates the paths in the current R session. When "both" or "project" is selected, the function updates the .Rprofile file in the project directory to set the JAVA_HOME and PATH environment variables at the start of the R session.
#' @inheritParams global_quiet_param
#' @inheritParams java_install
#' @return Nothing. Sets environment variables.
#' @export
#' @examples
#' \dontrun{
#' # Download and install Java 17
#' java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
#' java_home <- java_install(
#'   java_distrib_path = java_17_distrib,
#'   project_path = tempdir(),
#'   autoset_java_env = FALSE
#' )
#'
#' # Set the minimal runtime environment in the current session
#' java_env_set(where = "session", java_home = java_home)
#'
#' # Prepare the current session for building rJava from source
#' java_env_set(where = "session", java_home = java_home, setup_build_env = TRUE)
#' # Now you can run: install.packages("rJava", type = "source")
#' }
java_env_set <- function(
  where = c("session", "both", "project"),
  java_home,
  project_path = NULL,
  setup_build_env = FALSE,
  quiet = FALSE
) {
  where <- match.arg(where)
  checkmate::assertString(java_home)
  checkmate::assertFlag(setup_build_env)
  checkmate::assertFlag(quiet)

  if (where %in% c("session", "both")) {
    java_env_set_session(java_home, setup_build_env = setup_build_env)
    if (!quiet) {
      cli::cli_alert_success(c(
        "Current R Session: ",
        "Java environment set to {.path {java_home}}.",
        if (setup_build_env) {
          " Session is now configured for building `rJava` from source."
        }
      ))
    }
  }

  rje_consent_check()
  if (where %in% c("project", "both")) {
    # consistent with renv behavior for using
    # the current working directory by default
    # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
    project_path <- ifelse(is.null(project_path), getwd(), project_path)
    # Always use a minimal setup for .Rprofile to avoid conflicts
    java_env_set_rprofile(
      java_home,
      project_path = project_path,
      setup_build_env = FALSE
    )
    if (!quiet) {
      cli::cli_alert_success(c(
        "Current R Project/Working Directory: ",
        "Minimal Java runtime environment written to .Rprofile at '{.path {project_path}}'"
      ))
    }
  }

  if (setup_build_env && !quiet) {
    cli::cli_div(theme = list(rule = list(color = "blue")))
    cli::cli_rule(left = "Build Environment Ready")
    cli::cli_alert_info("You can now install `rJava` from source by running:")
    cli::cli_code(
      'install.packages("rJava", type = "source", repos = "https://cloud.r-project.org")'
    )
    cli::cli_rule()
  }

  invisible(NULL)
}


# --- Internal Helper Functions ---

#' Set environment variables for the current session
#' @param java_home The path to the desired JAVA_HOME.
#' @param setup_build_env Logical. If TRUE, also sets build-specific variables.
#' @keywords internal
java_env_set_session <- function(java_home, setup_build_env = FALSE) {
  # Set minimal runtime environment first
  set_java_runtime_env_vars_session(java_home)

  # Set comprehensive build environment if requested
  if (setup_build_env) {
    set_java_build_env_vars_session(java_home)
  }
}

#' Set minimal Java runtime environment variables for the current session
#' @param java_home The path to the desired JAVA_HOME.
#' @keywords internal
set_java_runtime_env_vars_session <- function(java_home) {
  if (
    any(utils::installed.packages()[, 1] == "rJava") &&
      "rJava" %in% loadedNamespaces()
  ) {
    cli::cli_inform(c(
      "!" = "The `rJava` package is already loaded. You may need to restart the R session for environment changes to take full effect for `rJava`."
    ))
  }

  Sys.setenv(JAVA_HOME = java_home)
  old_path <- Sys.getenv("PATH")
  new_path <- file.path(java_home, "bin")
  if (!grepl(new_path, old_path, fixed = TRUE)) {
    Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep))
  }

  if (.Platform$OS.type == "unix") {
    lib_name_ext <- .Platform$dynlib.ext
    lib_pattern <- paste0("libjvm", lib_name_ext)
    all_files <- list.files(
      path = java_home,
      pattern = lib_pattern,
      recursive = TRUE,
      full.names = TRUE
    )
    libjvm_path <- if (length(all_files) > 0) {
      all_files[grepl(
        paste0("/server/", lib_pattern),
        all_files,
        fixed = TRUE
      )][1]
    } else if (length(all_files) > 0) {
      all_files[1]
    } else {
      NA
    }

    if (!is.na(libjvm_path)) {
      jvm_lib_dir <- dirname(libjvm_path)
      loader_var <- if (Sys.info()["sysname"] == "Darwin") {
        "DYLD_LIBRARY_PATH"
      } else {
        "LD_LIBRARY_PATH"
      }
      old_ld_path <- Sys.getenv(loader_var, unset = "")
      new_ld_path <- if (nzchar(old_ld_path)) {
        paste(jvm_lib_dir, old_ld_path, sep = .Platform$path.sep)
      } else {
        jvm_lib_dir
      }
      Sys.setenv(loader_var = new_ld_path)
      tryCatch(dyn.load(libjvm_path), error = function(e) {
        cli::cli_warn(
          "Found {basename(libjvm_path)} at '{.path {libjvm_path}}' but failed to load it: {e$message}"
        )
      })
    } else {
      cli::cli_warn(
        "Could not find the Java Virtual Machine library (libjvm) within {.path {java_home}}"
      )
    }
  }
}

#' Set Java build environment variables for the current session
#' @param java_home The path to the desired JAVA_HOME.
#' @keywords internal
set_java_build_env_vars_session <- function(java_home) {
  if (.Platform$OS.type != "unix") {
    cli::cli_alert_info(
      "Source build environment setup is currently only implemented for macOS and Linux."
    )
    return()
  }

  os_specific_include <- if (Sys.info()["sysname"] == "Darwin") {
    "darwin"
  } else {
    "linux"
  }
  cpp_flags <- paste0(
    "-I",
    file.path(java_home, "include"),
    " -I",
    file.path(java_home, "include", os_specific_include)
  )
  Sys.setenv(JAVA_CPPFLAGS = cpp_flags)

  lib_name_ext <- .Platform$dynlib.ext
  lib_pattern <- paste0("libjvm", lib_name_ext)
  all_files <- list.files(
    path = java_home,
    pattern = lib_pattern,
    recursive = TRUE,
    full.names = TRUE
  )
  libjvm_path <- if (length(all_files) > 0) {
    all_files[grepl(paste0("/server/", lib_pattern), all_files, fixed = TRUE)][
      1
    ]
  } else if (length(all_files) > 0) {
    all_files[1]
  } else {
    NA
  }

  if (is.na(libjvm_path)) {
    cli::cli_warn(
      "Could not find libjvm to set build environment; source installation may fail."
    )
    return()
  }

  jvm_lib_dir <- dirname(libjvm_path)
  java_libs_str <- paste0("-L", jvm_lib_dir, " -ljvm")
  Sys.setenv(JAVA_LIBS = java_libs_str)

  if (Sys.info()["sysname"] == "Darwin") {
    Sys.setenv(PKG_LIBS = java_libs_str)
    pkg_ldflags_str <- paste0("-Wl,-rpath,", jvm_lib_dir)
    Sys.setenv(PKG_LDFLAGS = pkg_ldflags_str)
    existing_ldflags <- Sys.getenv("LDFLAGS", unset = "")
    Sys.setenv(
      LDFLAGS = paste(c(existing_ldflags, pkg_ldflags_str), collapse = " ")
    )
  } else {
    # Linux
    existing_libs <- Sys.getenv("LIBS", unset = "")
    Sys.setenv(LIBS = paste(c(java_libs_str, existing_libs), collapse = " "))
  }
}

#' Update the .Rprofile file with a minimal runtime environment
#' @param java_home The path to the desired JAVA_HOME.
#' @param project_path Path to the project directory.
#' @param setup_build_env Logical. If TRUE, writes a comprehensive build environment.
#' @keywords internal
java_env_set_rprofile <- function(
  java_home,
  project_path = NULL,
  setup_build_env = FALSE
) {
  java_env_unset(quiet = TRUE, project_path = project_path)
  rprofile_path <- file.path(project_path, ".Rprofile")
  java_home <- gsub("\\\\", "/", java_home)

  lines_to_add <- c(
    "# rJavaEnv begin: Manage JAVA_HOME",
    sprintf("Sys.setenv(JAVA_HOME = '%s') # rJavaEnv", java_home)
  )

  # --- Runtime Block (always added) ---
  lines_to_add <- c(
    lines_to_add,
    "local({ # rJavaEnv",
    "  old_path <- Sys.getenv('PATH') # rJavaEnv",
    "  new_path <- file.path(Sys.getenv('JAVA_HOME'), 'bin') # rJavaEnv",
    "  if (!grepl(new_path, old_path, fixed = TRUE)) { # rJavaEnv",
    "    Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep)) # rJavaEnv",
    "  } # rJavaEnv",
    "}) # rJavaEnv"
  )

  if (.Platform$OS.type == "unix") {
    lib_name_ext <- .Platform$dynlib.ext
    lib_pattern <- paste0("libjvm", lib_name_ext)
    all_files <- list.files(
      path = java_home,
      pattern = lib_pattern,
      recursive = TRUE,
      full.names = TRUE
    )
    libjvm_path <- if (length(all_files) > 0) {
      all_files[grepl(
        paste0("/server/", lib_pattern),
        all_files,
        fixed = TRUE
      )][1]
    } else if (length(all_files) > 0) {
      all_files[1]
    } else {
      NA
    }

    if (!is.na(libjvm_path)) {
      jvm_lib_dir <- dirname(libjvm_path)
      loader_var <- if (Sys.info()["sysname"] == "Darwin") {
        "DYLD_LIBRARY_PATH"
      } else {
        "LD_LIBRARY_PATH"
      }
      lines_to_add <- c(
        lines_to_add,
        "local({ # rJavaEnv",
        sprintf("  loader_var <- '%s' # rJavaEnv", loader_var),
        "  old_ld_path <- Sys.getenv(loader_var, unset = '') # rJavaEnv",
        sprintf("  jvm_lib_dir <- '%s' # rJavaEnv", jvm_lib_dir),
        "  new_ld_path <- if (nzchar(old_ld_path)) paste(jvm_lib_dir, old_ld_path, sep = .Platform$path.sep) else jvm_lib_dir # rJavaEnv",
        "  Sys.setenv(loader_var = new_ld_path) # rJavaEnv",
        sprintf("  libjvm_path <- '%s' # rJavaEnv", libjvm_path),
        "  if (file.exists(libjvm_path)) { try(dyn.load(libjvm_path), silent = TRUE) } # rJavaEnv",
        "}) # rJavaEnv"
      )
    }
  }

  lines_to_add <- c(lines_to_add, "# rJavaEnv end: Manage JAVA_HOME")
  if (file.exists(rprofile_path)) {
    cat(lines_to_add, file = rprofile_path, append = TRUE, sep = "\n")
  } else {
    writeLines(lines_to_add, con = rprofile_path)
  }
  invisible(NULL)
}

#' Check Java Version with a Specified JAVA_HOME Using a Separate R Session
#'
#' This function sets the JAVA_HOME environment variable, initializes the JVM using rJava, and prints the Java version that would be used if the user sets the given JAVA_HOME in the current R session. This check is performed in a separate R session to avoid having to reload the current R session. The reason for this is that once Java is initialized in an R session, it cannot be uninitialized unless the current R session is restarted.
#'
#' @inheritParams global_quiet_param
#' @inheritParams java_check_version_cmd
#' @return A `character` vector of length 1 containing the major Java version.
#' @examples
#' \dontrun{
#' java_check_version_rjava()
#' }
#'
#' @export
java_check_version_rjava <- function(
  java_home = NULL,
  quiet = FALSE
) {
  # Check if rJava is installed
  if (!requireNamespace("rJava", quietly = TRUE)) {
    cli::cli_alert_danger(
      "rJava package is not installed. You need to install rJava to use this function to check if rJava-based packages will work with the specified Java version."
    )
    return(FALSE)
  }

  # Determine JAVA_HOME if not specified by the user
  if (is.null(java_home)) {
    current_java_home <- Sys.getenv("JAVA_HOME")
    if (!quiet) {
      if (current_java_home == "") {
        cli::cli_inform("JAVA_HOME is not set.")
      } else {
        cli::cli_inform(
          "Using current session's JAVA_HOME: {.path {current_java_home}}"
        )
      }
    }
    java_home <- current_java_home
  } else {
    if (!quiet) {
      cli::cli_inform("Using user-specified JAVA_HOME: {.path {java_home}}")
    }
  }

  # Get the code of the unexported function to use in a script
  internal_function <- getFromNamespace(
    "java_version_check_rscript",
    "rJavaEnv"
  )
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
  rscript_path <- file.path(R.home("bin"), "Rscript")
  output <- suppressWarnings(system2(
    rscript_path,
    args = c(script_file, java_home),
    stdout = TRUE,
    stderr = TRUE
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
      if (!quiet) {
        if (is.null(java_home)) {
          cli::cli_inform("With the current session's JAVA_HOME {output}")
        } else {
          cli::cli_inform("With the user-specified JAVA_HOME {output}")
        }
      }
    }
  } else {
    if (!quiet) cli::cli_alert_danger("Failed to retrieve Java version.")
  }

  major_java_ver <- sub('.*version: \\"([0-9]+).*', '\\1', output[1])
  if (!nzchar(major_java_ver) || !grepl("^[0-9]+$", major_java_ver)) {
    if (!quiet) {
      cli::cli_alert_danger("Could not parse Java major version.")
    }
    return(FALSE)
  }

  # fix 1 to 8, as Java 8 prints "1.8"
  if (major_java_ver == "1") {
    major_java_ver <- "8"
  }

  return(major_java_ver)
}

#' Check installed Java version using terminal commands
#'
#' @param java_home Path to Java home directory. If NULL, the function uses the JAVA_HOME environment variable.
#' @inheritParams global_quiet_param
#' @return A `character` vector of length 1 containing the major Java version.
#' @export
#'
#' @examples
#' java_check_version_cmd()
#'
java_check_version_cmd <- function(
  java_home = NULL,
  quiet = FALSE
) {
  # Backup the current JAVA_HOME
  old_java_home <- Sys.getenv("JAVA_HOME")

  # Set JAVA_HOME in current session if specified
  if (!is.null(java_home)) {
    java_env_set_session(java_home)
  }

  # Get JAVA_HOME again and check if it's set
  current_java_home <- Sys.getenv("JAVA_HOME")
  if (current_java_home == "") {
    if (!quiet) {
      cli::cli_inform(c("!" = "JAVA_HOME is not set."))
    }
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
    }
    return(FALSE)
  } else {
    if (!quiet) cli::cli_inform("JAVA_HOME: {.path {current_java_home}}")
  }

  # Check if java executable exists in the PATH
  if (!nzchar(Sys.which("java"))) {
    cli::cli_alert_danger(
      "Java installation is not valid, Java executable not found."
    )
    if (!is.null(java_home)) {
      Sys.setenv(JAVA_HOME = old_java_home)
    }
    return(FALSE)
  }

  # Check Java path and version using system commands
  major_java_version <- java_check_version_system(quiet = quiet)

  # restore original JAVA_HOME that was in the environment before the function was called
  if (!is.null(java_home)) {
    Sys.setenv(JAVA_HOME = old_java_home)
  }

  return(major_java_version)
}

#' Check and print Java path and version using system commands
#'
#' This function checks the Java executable path and retrieves the Java version,
#' then prints these details to the console.
#' @inheritParams java_check_version_cmd
#' @return A `character` vector of length 1 containing the major Java version.
#' @keywords internal
#'
java_check_version_system <- function(
  quiet
) {
  which_java <- tryCatch(
    Sys.which("java"),
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

  if (!quiet) {
    cli::cli_inform(c(
      "Java path: {.path {which_java}}",
      "Java version:\n{.val {paste(java_ver, collapse = '\n')}}"
    ))
  }

  # extract Java version
  java_ver_string <- java_ver[[1]]
  matches <- regexec(
    '(openjdk|java) (version )?(\\\")?([0-9]{1,2})',
    java_ver_string
  )
  major_java_ver <- regmatches(java_ver_string, matches)[[1]][5]

  # fix 1 to 8, as Java 8 prints "1.8"
  if (major_java_ver == "1") {
    major_java_ver <- "8"
  }

  return(major_java_ver)
}


# unset java env ----------------------------------------------------------

#' Unset the JAVA_HOME and PATH environment variables in the project .Rprofile
#'
#' @inheritParams java_install
#' @inheritParams global_quiet_param
#' @export
#' @return Nothing. Removes the JAVA_HOME and PATH environment variables settings from the project .Rprofile.
#' @examples
#' \dontrun{
#' # clear the JAVA_HOME and PATH environment variables in the specified project .Rprofile
#' java_env_unset(project_path = tempdir())
#' }
java_env_unset <- function(
  project_path = NULL,
  quiet = FALSE
) {
  rje_consent_check()

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
