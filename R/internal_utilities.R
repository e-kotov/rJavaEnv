#' Detect platform and architecture
#'
#' @inheritParams global_quiet_param
#' @keywords internal
#' @return A list of length 2 with the detected platform and architecture.
#'
platform_detect <- function(quiet = TRUE) {
  sys_info <- tolower(Sys.info())

  os <- switch(
    sys_info["sysname"],
    "windows" = "windows",
    "linux" = "linux",
    "darwin" = "macos",
    stop(cli::cli_abort("Unsupported platform"))
  )

  # NEW: Check R_ARCH first, then fall back to Sys.info()
  r_arch_env <- Sys.getenv("R_ARCH")

  if (r_arch_env == "/i386") {
    arch <- "x86"
  } else if (r_arch_env == "/x64") {
    arch <- "x64"
  } else {
    # Fallback for non-Windows or when not in a build context
    arch <- switch(
      sys_info["machine"],
      "x86-64" = "x64",
      "x86_64" = "x64",
      "i386" = "x86",
      "i486" = "x86",
      "i586" = "x86",
      "i686" = "x86",
      "aarch64" = "aarch64",
      "arm64" = "aarch64",
      stop(cli::cli_abort("Unsupported architecture"))
    )
  }

  if (isFALSE(quiet)) {
    cli::cli_inform("Detected platform: {os}")
    cli::cli_inform("Detected architecture: {arch}")
  }

  return(list(os = os, arch = arch))
}

#' Load Java URLs from JSON file
#'
#' @keywords internal
#'
#' @return A list with the Java URLs structured as in the JSON file by distribution, platform, and architecture.
#'
java_urls_load <- function() {
  json_file <- system.file("extdata", "java_urls.json", package = "rJavaEnv")
  if (json_file == "") {
    cli::cli_abort("Configuration file not found")
  }
  jsonlite::fromJSON(json_file, simplifyVector = FALSE)
}

#' Test all Java URLs
#'
#' @keywords internal
#'
#' @return A list with the results of testing all Java URLs.
#'
urls_test_all <- function() {
  java_urls <- java_urls_load()
  results <- list()

  for (distribution in names(java_urls)) {
    for (platform in names(java_urls[[distribution]])) {
      for (arch in names(java_urls[[distribution]][[platform]])) {
        url_template <- java_urls[[distribution]][[platform]][[arch]]

        # Replace {version} with a placeholder version to test URL
        url <- gsub("\\{version\\}", "11", url_template)

        try(
          {
            response <- curl::curl_fetch_memory(
              url,
              handle = curl::new_handle(nobody = TRUE)
            )
            status <- response$status_code
          },
          silent = TRUE
        )

        if (!exists("status")) {
          status <- NA
        }

        results[[paste(distribution, platform, arch, sep = "-")]] <- list(
          url = url,
          status = status
        )

        # Clear status variable for next iteration
        rm(status)
      }
    }
  }

  return(results)
}


# Unexported function to initialize Java using rJava and check Java version
# This is intended to be called from the exported function java_check_version_rjava
# Updated java_version_check_rscript function with verbosity control
#' Check Java version using rJava
#'
#' @keywords internal
#'
#' @param java_home
#'
#' @return A message with the Java version or an error message.
#'
java_version_check_rscript <- function(java_home) {
  result <- tryCatch(
    {
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
              # Use base message to avoid dependency issues in the isolated script
              message(sprintf(
                "Found libjvm.so at '%s' but failed to load it: %s",
                libjvm_path,
                e$message
              ))
            }
          )
        } else {
          message(sprintf(
            "Could not find libjvm.so within the provided JAVA_HOME: %s",
            java_home
          ))
        }
      }

      suppressWarnings(rJava::.jinit())
      suppressWarnings(
        java_version <- rJava::.jcall(
          "java.lang.System",
          "S",
          "getProperty",
          "java.version"
        )
      )

      message <- cli::format_message(
        "rJava and other rJava/Java-based packages will use Java version: {.val {java_version}}"
      )

      message
    },
    error = function(e) {
      cli::format_message("Error checking Java version: {e$message}")
    }
  )

  return(result)
}

#' Find path to libjvm dynamic library
#'
#' @description
#' Locates the Java Virtual Machine (JVM) dynamic library within a given JAVA_HOME.
#' Searches for `libjvm.so` on Linux and `libjvm.dylib` on macOS.
#' Prefers the server JVM over the client JVM when multiple versions are found.
#'
#' @param java_home Character. Path to Java Home directory.
#' @return Character path to libjvm library, or NULL if not found.
#' @keywords internal
get_libjvm_path <- function(java_home) {
  checkmate::assert_string(java_home)

  sysname <- Sys.info()["sysname"]
  lib_path <- NULL

  if (sysname == "Linux") {
    # Search for libjvm.so recursively
    all_files <- list.files(
      path = java_home,
      pattern = "libjvm.so$",
      recursive = TRUE,
      full.names = TRUE
    )

    if (length(all_files) > 0) {
      # Prefer server/ directory over client/
      server_files <- all_files[grepl("/server/libjvm.so$", all_files)]
      lib_path <- if (length(server_files) > 0) {
        server_files[1]
      } else {
        all_files[1]
      }
    }
  } else if (sysname == "Darwin") {
    # macOS: Check standard paths first
    server_path <- file.path(java_home, "lib", "server", "libjvm.dylib")
    client_path <- file.path(java_home, "lib", "client", "libjvm.dylib")

    if (file.exists(server_path)) {
      lib_path <- server_path
    } else if (file.exists(client_path)) {
      lib_path <- client_path
    } else {
      # Fallback: recursive search
      all_files <- list.files(
        path = java_home,
        pattern = "libjvm.dylib$",
        recursive = TRUE,
        full.names = TRUE
      )
      # Ignore AppleDouble files (._)
      all_files <- all_files[!grepl("/\\._", all_files)]
      if (length(all_files) > 0) lib_path <- all_files[1]
    }
  }

  return(lib_path)
}

#' Check if a path is within the rJavaEnv cache directory
#'
#' @param path Character. Path to check.
#' @return Logical. TRUE if path is within rJavaEnv cache, FALSE otherwise.
#' @keywords internal
#' @noRd
is_rjavaenv_cache_path <- function(path) {
  checkmate::assert_string(path)

  # Get the cache directory from options
  cache_root <- getOption("rJavaEnv.cache_path")

  # If cache_root is not set, nothing can be in cache
  if (is.null(cache_root) || !nzchar(cache_root)) {
    return(FALSE)
  }

  # Normalize both paths for comparison
  # mustWork = FALSE because path might be a symlink or non-existent
  path_norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  cache_norm <- normalizePath(cache_root, winslash = "/", mustWork = FALSE)

  # Check if path is under cache directory
  # Use startsWith for prefix matching
  # On Windows, use case-insensitive comparison
  if (.Platform$OS.type == "windows") {
    path_norm <- tolower(path_norm)
    cache_norm <- tolower(cache_norm)
  }

  return(startsWith(path_norm, cache_norm))
}

#' Resolve symlinks recursively on Unix systems
#'
#' @param path Character. Path to resolve.
#' @param max_depth Integer. Maximum symlink depth to follow (default 10).
#' @return Character. Resolved path (or original if not a symlink or on Windows).
#' @keywords internal
#' @noRd
resolve_symlinks <- function(path, max_depth = 10L) {
  if (.Platform$OS.type != "unix" || !nzchar(path)) {
    return(path)
  }

  real_path <- path
  for (i in seq_len(max_depth)) {
    link <- Sys.readlink(real_path)
    if (is.na(link) || !nzchar(link)) {
      break
    }
    # Handle relative symlinks
    if (!startsWith(link, "/")) {
      link <- file.path(dirname(real_path), link)
    }
    real_path <- link
  }

  return(real_path)
}

#' Internal readline wrapper for testability
#'
#' Wraps base::readline() to enable mocking in tests without polluting public API.
#'
#' @param prompt Character string to display as prompt
#' @return Character string from user input or mocked response
#' @keywords internal
#' @noRd
rje_readline <- function(prompt = "") {
  readline(prompt = prompt)
}

#' Check if rJava is initialized and warn if so
#'
#' @description
#' Checks if the rJava package is currently loaded in the session.
#' If it is, issues an informative alert explaining that rJava path-locking
#' prevents new JAVA_HOME settings from taking effect for rJava itself.
#'
#' @param quiet Logical. If TRUE, suppresses the alert.
#' @return Logical. TRUE if rJava is loaded, FALSE otherwise.
#' @keywords internal
check_rjava_initialized <- function(quiet = FALSE) {
  if (any(utils::installed.packages()[, 1] == "rJava")) {
    if ("rJava" %in% loadedNamespaces()) {
      if (!quiet) {
        cli::cli_alert_info(c(
          "!" = "You have {.pkg rJava} loaded in the current session. {.pkg rJava} gets locked to the Java version that was active when it was first initialized.",
          "i" = "{.pkg rJava} is initialized when you: (1) call {.code library(rJava)}, (2) load a package that imports {.pkg rJava}, (3) use IDE autocomplete with {.code rJava::}, or (4) call any {.pkg rJava} function.",
          "i" = "This path-locking is a limitation of {.pkg rJava} itself. See: https://github.com/s-u/rJava/issues/25, https://github.com/s-u/rJava/issues/249, and https://github.com/s-u/rJava/issues/334",
          " " = "Unless you restart the R session or run your code in a new R subprocess (using {.pkg targets} or {.pkg callr}), the new {.var JAVA_HOME} and {.var PATH} will not take effect."
        ))
      }
      return(TRUE)
    }
  }
  return(FALSE)
}

#' Check the Java version currently used by the loaded rJava package
#'
#' @description
#' Safely queries the `rJava` package (if loaded) to determine which Java version
#' it is actually using.
#'
#' @return A character string representing the major Java version (e.g., "17", "21", "8"),
#'   or `NULL` if `rJava` is not loaded or the version/property could not be retrieved.
#' @keywords internal
java_check_current_rjava_version <- function() {
  if (!"rJava" %in% loadedNamespaces()) {
    return(NULL)
  }

  # Safely call rJava to get the java.version property
  # We use tryCatch to avoid crashing if rJava is in a weird state
  java_ver_str <- tryCatch(
    {
      # Ensure JVM is initialized before calling .jcall
      # .jinit returns 0 if already initialized, or initializes if not
      rJava::.jinit(silent = TRUE)
      rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
    },
    error = function(e) {
      NULL
    }
  )

  if (is.null(java_ver_str) || !nzchar(java_ver_str)) {
    return(NULL)
  }

  # Parse version: "1.8.0_..." -> "8", "17.0.1" -> "17"
  matches <- regexec(
    "^(1\\.)?([0-9]+)",
    java_ver_str
  )
  parts <- regmatches(java_ver_str, matches)[[1]]

  if (length(parts) < 3) {
    return(NULL)
  }

  major <- parts[3]
  # Handle 1.8 -> 8 case (parts[2] is "1." and parts[3] is "8")
  # Handle 17 -> 17 case (parts[2] is "" and parts[3] is "17")

  return(major)
}

#' Find the actual extracted directory, ignoring hidden/metadata files
#'
#' @param temp_dir The directory where files were extracted.
#' @return The path to the first non-hidden directory found.
#' @keywords internal
._find_extracted_dir <- function(temp_dir) {
  # Ignore hidden files like .DS_Store or AppleDouble files (._)
  all_files <- list.files(temp_dir, full.names = TRUE)
  extracted_dirs <- all_files[
    dir.exists(all_files) & !grepl("^\\._", basename(all_files))
  ]

  if (length(extracted_dirs) == 0) {
    cli::cli_abort(
      "No directory found after unpacking the Java distribution at {.path {temp_dir}}"
    )
  }
  return(extracted_dirs[1])
}
