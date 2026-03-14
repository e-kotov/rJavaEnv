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
  RcppSimdJson::fload(json_file, max_simplify_lvl = "list")
}

#' Read JSON from a URL
#'
#' Helper function to read JSON from a URL using RcppSimdJson for fast parsing
#'
#' @param url URL to read JSON from
#' @param max_simplify_lvl Simplification level (default: "data_frame")
#' @return Parsed JSON object
#' @keywords internal
read_json_url <- function(url, max_simplify_lvl = "data_frame") {
  content <- rawToChar(rje_curl_fetch_memory(url)$content)
  RcppSimdJson::fparse(content, max_simplify_lvl = max_simplify_lvl)
}

#' Build environment variables for a Java subprocess
#'
#' @param java_home Path to Java home directory.
#' @param rjava Logical. Whether the subprocess will initialize rJava.
#'
#' @return Named character vector of environment variables.
#' @keywords internal
#' @noRd
java_subprocess_env <- function(java_home, rjava = FALSE) {
  checkmate::assert_string(java_home)
  checkmate::assert_logical(rjava, len = 1)

  env_vars <- Sys.getenv()
  env_get <- function(name) {
    if (name %in% names(env_vars)) {
      env_vars[[name]]
    } else {
      NA_character_
    }
  }
  java_bin <- file.path(java_home, "bin")
  old_path <- env_get("PATH")

  env_vars["JAVA_HOME"] <- java_home
  env_vars["PATH"] <- paste(java_bin, old_path, sep = .Platform$path.sep)

  if (!isTRUE(rjava)) {
    return(env_vars)
  }

  sysname <- Sys.info()[["sysname"]]
  libjvm_path <- get_libjvm_path(java_home)
  if (is.null(libjvm_path)) {
    return(env_vars)
  }

  jvm_lib_dir <- dirname(libjvm_path)

  if (identical(sysname, "Linux")) {
    old_ld <- env_get("LD_LIBRARY_PATH")
    if (is.na(old_ld)) {
      old_ld <- ""
    }
    env_vars["JAVA_LD_LIBRARY_PATH"] <- jvm_lib_dir
    env_vars["LD_LIBRARY_PATH"] <- if (nzchar(old_ld)) {
      paste(jvm_lib_dir, old_ld, sep = .Platform$path.sep)
    } else {
      jvm_lib_dir
    }
  } else if (identical(sysname, "Darwin")) {
    old_dyld <- env_get("DYLD_LIBRARY_PATH")
    if (is.na(old_dyld)) {
      old_dyld <- ""
    }
    env_vars["DYLD_LIBRARY_PATH"] <- if (nzchar(old_dyld)) {
      paste(jvm_lib_dir, old_dyld, sep = .Platform$path.sep)
    } else {
      jvm_lib_dir
    }
  }

  env_vars
}

#' Read lines from a URL or file
#'
#' Helper function to read lines, mainly for testability.
#'
#' @param path Path or URL
#' @param warn Logical. Whether to warn.
#' @return Character vector of lines
#' @keywords internal
#' @noRd
rje_read_lines <- function(path, warn = FALSE) {
  readLines(path, warn = warn)
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
            response <- rje_curl_fetch_memory(
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
      suppressWarnings(rJava::.jinit())
      java_version <- suppressWarnings(
        rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
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

#' Parse major Java version from a java.version string
#'
#' @param java_ver_str Character string containing Java version.
#'
#' @return Character scalar major version or NULL.
#' @keywords internal
#' @noRd
parse_java_major_version <- function(java_ver_str) {
  if (is.null(java_ver_str) || !nzchar(java_ver_str)) {
    return(NULL)
  }

  matches <- regexec("^(1\\.)?([0-9]+)", java_ver_str)
  parts <- regmatches(java_ver_str, matches)[[1]]

  if (length(parts) < 3) {
    return(NULL)
  }

  parts[3]
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

  parse_java_major_version(java_ver_str)
}

#' Find the actual extracted directory, ignoring hidden/metadata files
#'
#' @param temp_dir The directory where files were extracted.
#' @return The path to the first non-hidden directory found.
#' @keywords internal
#' @noRd
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

#' Wrapper for curl::curl_fetch_memory for testability
#'
#' @param url URL to fetch
#' @param handle curl handle
#' @return Response object
#' @keywords internal
#' @noRd
rje_curl_fetch_memory <- function(url, handle = curl::new_handle()) {
  curl::curl_fetch_memory(url, handle = handle)
}
