#' Scan system for Java installations (cacheable part)
#'
#' @description
#' Internal function that scans the system for installed Java Development Kits (JDKs)
#' without calculating the `is_default` flag. This function is designed to be cached.
#'
#' Implementation based on CMake `FindJava.cmake` logic, rJava detection,
#' and standard OS checks.
#'
#' **Note**: This function only returns true system installations. Java installations
#' managed by rJavaEnv (stored in the package cache) are explicitly excluded, even if
#' `JAVA_HOME` or `PATH` currently point to them.
#'
#' @param quiet Logical. If `TRUE`, suppresses informational messages.
#' @return A data frame with columns:
#'   - `java_home`: Character. Path to the Java home directory.
#'   - `version`: Character. Major Java version (e.g., "17", "21").
#'   - `is_default`: Logical. Always `FALSE` in this function (set by caller).
#'   Returns an empty data frame if no Java installations are found.
#'
#' @keywords internal
._java_find_system_scan_impl <- function(quiet = TRUE) {
  candidates <- character()

  # 1. Environment Variable
  env_home <- Sys.getenv("JAVA_HOME")
  if (nzchar(env_home)) {
    candidates <- c(candidates, env_home)
  }

  # 2. PATH Lookup (Resolving Symlinks)
  java_bin <- Sys.which("java")
  if (nzchar(java_bin)) {
    real_path <- java_bin
    # Recursive symlink resolution for Linux (handles /etc/alternatives)
    if (.Platform$OS.type == "unix") {
      for (i in 1:10) {
        link <- Sys.readlink(real_path)
        if (!nzchar(link)) {
          break
        }
        if (!startsWith(link, "/")) {
          link <- file.path(dirname(real_path), link)
        }
        real_path <- link
      }
    }
    # If path ends in /bin/java, the grandparent dir is JAVA_HOME
    if (grepl("[/\\\\]bin[/\\\\]java(\\.exe)?$", real_path)) {
      candidates <- c(candidates, dirname(dirname(real_path)))
    }
  }

  # 3. OS-Specific Scans
  os <- platform_detect(quiet = quiet)$os

  if (os == "windows") {
    # --- CMake + rJava Logic: Windows Registry ---
    # Registry keys checked by rJava (see rJava/src/jvm-w32/findjava.c:12-46)
    # and CMake FindJava.cmake
    keys <- c(
      "SOFTWARE\\JavaSoft\\JDK", # rJava primary (line 44)
      "SOFTWARE\\JavaSoft\\Java Development Kit", # rJava fallback (line 41)
      "SOFTWARE\\JavaSoft\\JRE", # rJava JRE key (line 37)
      "SOFTWARE\\JavaSoft\\Java Runtime Environment" # rJava default (line 12)
    )

    for (key in keys) {
      try(
        {
          # readRegistry automatically uses the correct view (32 vs 64 bit) for the R session
          reg <- utils::readRegistry(key, hive = "HLM", maxdepth = 2)
          if (!is.null(reg)) {
            for (ver in names(reg)) {
              if ("JavaHome" %in% names(reg[[ver]])) {
                candidates <- c(candidates, reg[[ver]]$JavaHome)
              }
            }
          }
        },
        silent = TRUE
      )
    }

    # --- CMake Logic: Hardcoded Paths (Modernized) ---
    # These cover modern Java distributions not always in registry
    roots <- c(
      "C:/Program Files/Java",
      "C:/Program Files/Amazon Corretto",
      "C:/Program Files/Zulu",
      "C:/Program Files/Eclipse Adoptium",
      "C:/Program Files/Microsoft"
    )
    for (root in roots) {
      if (dir.exists(root)) {
        candidates <- c(candidates, list.dirs(root, recursive = FALSE))
      }
    }
  } else if (os == "macos") {
    # macOS Standard Tool
    try(
      {
        out <- suppressWarnings(system2(
          "/usr/libexec/java_home",
          args = "-V",
          stderr = TRUE,
          stdout = TRUE,
          timeout = 5
        ))
        # Extract absolute paths from output (e.g., "/Library/Java/JavaVirtualMachines/...")
        # The output format has paths as space/tab-separated fields, not at line start
        for (line in out) {
          # Extract all fields starting with / (absolute paths)
          path_matches <- gregexpr("(/[^ \t\n]+)", line)
          if (path_matches[[1]][1] > 0) {
            matched_paths <- regmatches(line, path_matches)[[1]]
            candidates <- c(candidates, matched_paths)
          }
        }
      },
      silent = TRUE
    )
  } else if (os == "linux") {
    # Standard Linux Paths (Debian/RHEL/Fedora standard locations)
    # Note: rJava relies on R CMD javareconf, but we do comprehensive scanning
    roots <- c("/usr/lib/jvm", "/usr/java", "/usr/local/java")
    for (root in roots) {
      if (dir.exists(root)) {
        candidates <- c(candidates, list.dirs(root, recursive = FALSE))
      }
    }
  }

  # 4. Validation & Cleaning
  # Normalize first to ensure unique() handles backslash/forward-slash duplicates
  candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
  candidates <- unique(candidates)

  # Filter out rJavaEnv cache paths - we only want true system installations
  candidates <- Filter(function(x) !is_rjavaenv_cache_path(x), candidates)

  # Must contain bin/java to be valid - this prevents returning corrupted/empty JDK folders
  valid_homes <- Filter(
    function(x) {
      bin_java <- file.path(
        x,
        "bin",
        if (os == "windows") "java.exe" else "java"
      )
      file.exists(bin_java)
    },
    candidates
  )

  # 5. Get Java versions for each home
  result_list <- list()

  for (home in valid_homes) {
    ver_str <- tryCatch(
      {
        java_check_version_cmd(java_home = home, quiet = TRUE)
      },
      error = function(e) FALSE
    )

    # Skip if version check failed
    if (isFALSE(ver_str)) {
      next
    }

    result_list[[length(result_list) + 1]] <- list(
      java_home = home,
      version = ver_str
    )
  }

  # 6. Build result data frame with is_default placeholder
  if (length(result_list) == 0) {
    # Return empty data frame with correct structure
    return(data.frame(
      java_home = character(),
      version = character(),
      is_default = logical()
    ))
  }

  # Build data frame properly to ensure columns are vectors, not lists
  result_df <- data.frame(
    java_home = sapply(result_list, `[[`, "java_home"),
    version = sapply(result_list, `[[`, "version"),
    stringsAsFactors = FALSE
  )
  # Set is_default to FALSE - it will be calculated by the caller
  result_df$is_default <- FALSE

  # 7. Sort by version (descending only, since is_default is all FALSE)
  sort_order <- order(
    -as.numeric(result_df$version),
    decreasing = TRUE
  )
  result_df <- result_df[sort_order, ]

  rownames(result_df) <- NULL
  return(result_df)
}

# Memoized version - cache indefinitely per session
# System Java installations don't change during an R session
._java_find_system_cached <- memoise::memoise(
  function(quiet = TRUE, .cache_session_id = NULL) {
    # Pass through to scan implementation function, ignoring .cache_session_id
    ._java_find_system_scan_impl(quiet)
  },
  cache = memoise::cache_memory()
)

#' Discover system-wide Java installations
#'
#' @description
#' Scans the system for installed Java Development Kits (JDKs).
#' Implementation based on CMake `FindJava.cmake` logic, rJava detection,
#' and standard OS checks.
#'
#' **Note**: This function only returns true system installations. Java installations
#' managed by rJavaEnv (stored in the package cache) are explicitly excluded, even if
#' `JAVA_HOME` or `PATH` currently point to them.
#'
#' @param quiet Logical. If `TRUE`, suppresses informational messages.
#' @param .use_cache Logical. If `TRUE`, uses memoisation cache for the expensive
#'   system scanning part. The `is_default` flag is always calculated dynamically
#'   based on the current `JAVA_HOME`. Default: `FALSE` (bypass cache for safety).
#'   Set to `TRUE` for performance in loops or repeated calls.
#' @return A data frame with columns:
#'   - `java_home`: Character. Path to the Java home directory.
#'   - `version`: Character. Major Java version (e.g., "17", "21").
#'   - `is_default`: Logical. `TRUE` if this matches the current system default Java
#'     (determined by `JAVA_HOME` or PATH).
#'   Rows are ordered with the default Java first (if detected), then by version descending.
#'   Returns an empty data frame if no Java installations are found.
#'
#' @section Performance:
#' The system scan is memoised (cached) for the session duration. First scan: ~209ms.
#' Subsequent scans with `.use_cache = TRUE`: <1ms. The `is_default` flag is always
#' calculated fresh to reflect current `JAVA_HOME`.
#'
#' @importFrom memoise memoise cache_memory
#' @export
java_find_system <- function(quiet = TRUE, .use_cache = FALSE) {
  # Get scan results (cached or fresh)
  if (.use_cache) {
    # Use a constant session ID since this should be cached for entire session
    scan_result <- ._java_find_system_cached(quiet, "session_scan")
  } else {
    # Bypass cache - call scan implementation directly (for testing with mocks)
    scan_result <- ._java_find_system_scan_impl(quiet)
  }

  # If no results, return empty frame with correct structure
  if (nrow(scan_result) == 0) {
    return(scan_result)
  }

  # Calculate is_default dynamically based on current JAVA_HOME
  # This part is never cached so it always reflects current state
  default_java <- NULL
  os <- platform_detect(quiet = quiet)$os

  if (os == "macos") {
    # On macOS, /usr/libexec/java_home (without -V) returns the default
    tryCatch(
      {
        default_path <- suppressWarnings(system2(
          "/usr/libexec/java_home",
          stdout = TRUE,
          stderr = TRUE,
          timeout = 5
        ))
        if (length(default_path) > 0 && nzchar(default_path[1])) {
          default_java <- trimws(default_path[1])
        }
      },
      silent = TRUE
    )
  } else {
    # On other platforms, check JAVA_HOME first, then PATH
    env_java <- Sys.getenv("JAVA_HOME")
    if (nzchar(env_java)) {
      default_java <- normalizePath(env_java, winslash = "/", mustWork = FALSE)
    }

    # If JAVA_HOME not set, try to resolve from PATH
    if (is.null(default_java)) {
      java_bin <- Sys.which("java")
      if (nzchar(java_bin)) {
        real_path <- java_bin
        # Recursive symlink resolution
        if (.Platform$OS.type == "unix") {
          for (i in 1:10) {
            link <- Sys.readlink(real_path)
            if (!nzchar(link)) {
              break
            }
            if (!startsWith(link, "/")) {
              link <- file.path(dirname(real_path), link)
            }
            real_path <- link
          }
        }
        # Extract JAVA_HOME from /bin/java path
        if (grepl("[/\\\\]bin[/\\\\]java(\\.exe)?$", real_path)) {
          default_java <- normalizePath(
            dirname(dirname(real_path)),
            winslash = "/",
            mustWork = FALSE
          )
        }
      }
    }
  }

  # Mark default Java and re-sort
  scan_result$is_default <- scan_result$java_home == default_java

  # Sort: default first (TRUE first), then by version (descending)
  sort_order <- order(
    scan_result$is_default,
    -as.numeric(scan_result$version),
    decreasing = TRUE
  )
  scan_result <- scan_result[sort_order, ]
  rownames(scan_result) <- NULL

  return(scan_result)
}
