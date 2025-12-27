#' Ensure specific Java version is set
#'
#' @description
#' Checks for a specific Java version in the following order:
#' 1. Checks if the currently active session has the required version.
#' 2. (Optional) Scans system for installed Java (via `java_find_system`).
#' 3. Checks if the required version is already cached in `rJavaEnv`'s installed cache.
#' 4. If none found, downloads and installs the version (if `install = TRUE`).
#'
#' This function is designed to be "lazy": it will do nothing if a valid Java version
#' is already detected, making it safe to use in scripts or package startup code
#' (provided `install = FALSE`).
#'
#' @inheritSection rjava_path_locking_note rJava Path-Locking
#'
#' @section Additional Notes:
#' If rJava is already loaded, this function will warn you but will not prevent the
#' environment variable change (which won't help rJava at that point).
#'
#' @param version Integer or character. **Required.** The Java version you need (e.g., 17, 21). This parameter must be specified explicitly; there is no default.
#' @param type Character. `"exact"` (default) checks for exact version match. `"min"` checks for version >= `version`.
#' @param accept_system_java Logical. If `TRUE` (default), the function will scan the system for existing Java installations (using `JAVA_HOME`, `PATH`, and OS-specific locations). If a system Java matching the `version` and `type` requirements is found, it will be used. Set to `FALSE` to ignore system installations and strictly use an `rJavaEnv` managed version.
#' @param install Logical. If `TRUE` (default), attempts to download/install if missing.
#'   If `FALSE`, returns `FALSE` if the version is not found.
#' @param distribution Character. The Java distribution to download. Defaults to "Corretto".
#' @param check_against Character. Controls which context validity the function checks against.
#'   * `"rJava"` (default): Checks if the requested version can be enforced for `rJava`. If `rJava` is already initialized and locked to a different version, this will error, as the requested version cannot be enforced for the active `rJava` session.
#'   * `"cmd"`: Checks if the requested version can be enforced for command-line use. This ignores the state of `rJava` and allows setting the environment variables even if `rJava` is locked to a different version.
#' @inheritParams global_quiet_param
#' @inheritParams java_download
#' @param .check_rjava_fun Internal. Function to check if rJava is initialized.
#' @param .rjava_ver_fun Internal. Function to get the current rJava version.
#'
#' @return Logical. `TRUE` if the requirement is met (active or set successfully), `FALSE` otherwise.
#'
#' @seealso
#' `vignette("for-developers")` for comprehensive guidance on integrating `rJavaEnv` into your package,
#' including how to use `java_ensure()` in different scenarios and detailed use cases with `type` and
#' `accept_system_java` parameters.
#'
#' @export
#' @examples
#' \dontrun{
#' # For end users: Ensure Java 21 is ready BEFORE loading rJava packages
#' library(rJavaEnv)
#' java_ensure(version = 21, type = "min")
#' # Now safe to load packages that depend on rJava
#' library(myRJavaPackage)
#'
#' # For packages using command-line Java (not rJava):
#' # Can use java_ensure() within functions to set Java before calling system tools
#' my_java_tool <- function() {
#'   java_ensure(version = 17)
#'   system2("java", c("-jar", "tool.jar"))
#' }
#' }
java_ensure <- function(
  version = NULL,
  type = c("exact", "min"),
  accept_system_java = TRUE,
  install = TRUE,
  distribution = "Corretto",
  check_against = c("rJava", "cmd"),
  quiet = FALSE,
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  .check_rjava_fun = check_rjava_initialized,
  .rjava_ver_fun = java_check_current_rjava_version
) {
  # Validate that version is provided
  if (is.null(version)) {
    stop(
      "The 'version' parameter is required. ",
      "Specify the Java version you need, e.g., version = 21 or version = 17."
    )
  }

  type <- match.arg(type)
  check_against <- match.arg(check_against)
  req_ver_int <- as.integer(version)
  version <- as.character(version)

  # Handling rJava Path-Locking
  if (check_against == "rJava") {
    # Strict compliance: rJava MUST match if loaded
    # This will show the informative message if rJava is loaded and quiet = FALSE
    rjava_is_loaded <- .check_rjava_fun(quiet = quiet)

    if (rjava_is_loaded) {
      curr_rjava_ver <- .rjava_ver_fun()

      if (!is.null(curr_rjava_ver)) {
        curr_rjava_int <- as.integer(curr_rjava_ver)

        # Check if the LOCKED rJava version satisfies the requirement
        rjava_ok <- FALSE
        if (!is.na(curr_rjava_int)) {
          if (type == "exact" && curr_rjava_int == req_ver_int) {
            rjava_ok <- TRUE
          } else if (type == "min" && curr_rjava_int >= req_ver_int) {
            rjava_ok <- TRUE
          }
        }

        if (rjava_ok) {
          if (!quiet) {
            cli::cli_alert_success(
              "rJava is locked to version {curr_rjava_ver}, which satisfies the requirement."
            )
          }
          # If rJava is satisfied, we ideally also want JAVA_HOME to match,
          # but the critical part is rJava. We proceed to check other sources
          # (like system/cache) just to ensure environment variables are consistent
          # if possible, OR just return TRUE since rJava works.
          # Returning TRUE here is safest to avoid "setting" env vars that might confuse things.
          return(invisible(TRUE))
        } else {
          # Locked version FAILS requirement -> ERROR
          cli::cli_abort(c(
            "x" = "rJava is already loaded and locked to Java {curr_rjava_ver}.",
            "i" = "You requested Java {version} (type = '{type}').",
            "!" = "Cannot fulfill request because rJava path-locking prevents changing the JVM version in this session.",
            "i" = "Please restart your R session and run `java_ensure({version})` BEFORE loading rJava or packages that depend on it."
          ))
        }
      } else {
        # rJava loaded but version unknown.
        # In strict mode, we should warn even if quiet, because safety check failed.
        cli::cli_warn(
          "rJava is loaded but version could not be determined. Compatibility check skipped."
        )
      }
    }
  } else {
    # check_against == "cmd"
    # We essentially ignore rJava.
    # No warnings about rJava, just proceed to ensure JAVA_HOME is set for CLI usage.
  }

  # 1. Check Active Session (Fastest) for non-rJava (JAVA_HOME based) checks
  curr_ver_str <- java_check_version_cmd(quiet = TRUE)
  if (!isFALSE(curr_ver_str)) {
    curr_ver_int <- as.integer(curr_ver_str)
    if (!is.na(curr_ver_int)) {
      if (
        (type == "exact" && curr_ver_int == req_ver_int) ||
          (type == "min" && curr_ver_int >= req_ver_int)
      ) {
        if (!quiet) {
          cli::cli_alert_success(
            "Active Java version {curr_ver_str} satisfies requirement."
          )
        }
        return(invisible(TRUE))
      }
    }
  }

  # 2. Check System-wide Installations
  if (accept_system_java) {
    if (!quiet) {
      cli::cli_alert_info("Checking system for existing Java installations...")
    }

    # Scan for system Java with error handling
    system_javas <- tryCatch(
      {
        java_find_system(quiet = TRUE)
      },
      error = function(e) {
        if (!quiet) {
          cli::cli_warn("System Java scan failed: {e$message}")
        }
        data.frame(
          java_home = character(),
          version = character(),
          is_default = logical()
        )
      }
    )

    # Collect all valid matches
    valid_matches <- list()

    if (nrow(system_javas) > 0) {
      for (i in seq_len(nrow(system_javas))) {
        home <- system_javas$java_home[i]
        ver_str <- system_javas$version[i]

        # Parse version safely
        ver_int <- suppressWarnings(as.integer(ver_str))
        if (is.na(ver_int)) {
          next
        }

        # Check if this version meets requirements
        is_match <- if (type == "exact") {
          ver_int == req_ver_int
        } else {
          ver_int >= req_ver_int
        }

        if (is_match) {
          valid_matches[[length(valid_matches) + 1]] <- list(
            path = home,
            version = ver_int,
            is_default = system_javas$is_default[i]
          )
        }
      }
    }

    # Select best match if any found
    if (length(valid_matches) > 0) {
      selected <- NULL

      if (type == "exact") {
        # Any match in valid_matches is already exact due to the filter above.
        # Pick the first one (often default or first found).
        selected <- valid_matches[[1]]
      } else {
        # Sort descending by version
        sorted <- valid_matches[order(
          sapply(valid_matches, `[[`, "version"),
          decreasing = TRUE
        )]
        selected <- sorted[[1]]

        if (!quiet && selected$version != req_ver_int) {
          cli::cli_alert_info(
            "Exact match not found. Using system Java {selected$version} (>= {version})"
          )
        }
      }

      if (!quiet) {
        cli::cli_alert_success(
          "Found valid system Java {selected$version} at {.path {selected$path}}"
        )
      }

      ._java_env_set_impl(
        where = "session",
        java_home = selected$path,
        quiet = quiet,
        ._skip_rjava_check = TRUE
      )
      return(invisible(TRUE))
    }
  } else {
    if (!quiet) {
      cli::cli_alert_info(
        "Skipping system Java check (accept_system_java = FALSE)."
      )
    }
  }

  # 3. Check Local Cache (rJavaEnv managed)
  # Look for unpacked installations in the cache
  cache_list <- java_list_installed_cache(
    output = "data.frame",
    quiet = TRUE,
    cache_path = cache_path
  )
  found_path <- NULL

  if (length(cache_list) > 0 && nrow(cache_list) > 0) {
    # Ensure version column is integer for comparison
    cache_list$ver_int <- suppressWarnings(as.integer(cache_list$version))

    valid_candidates <- if (type == "exact") {
      cache_list[which(cache_list$ver_int == req_ver_int), ]
    } else {
      cache_list[which(cache_list$ver_int >= req_ver_int), ]
    }

    if (nrow(valid_candidates) > 0) {
      # Prefer exact match if available
      preferred <- valid_candidates[valid_candidates$ver_int == req_ver_int, ]

      if (nrow(preferred) > 0) {
        found_path <- preferred$path[1]
      } else {
        # If type="min" and no exact match, pick the highest available version
        valid_candidates <- valid_candidates[
          order(valid_candidates$ver_int, decreasing = TRUE),
        ]
        found_path <- valid_candidates$path[1]

        # Inform user that a newer version was selected
        if (!quiet) {
          cli::cli_alert_info(
            "Exact match for Java {version} not found in cache. Using available newer version {valid_candidates$version[1]}."
          )
        }
      }
    }
  }

  if (!is.null(found_path)) {
    if (!quiet) {
      cli::cli_alert_info(
        "Found cached Java at {.path {found_path}}. Setting environment..."
      )
    }
    ._java_env_set_impl(
      where = "session",
      java_home = found_path,
      quiet = quiet,
      ._skip_rjava_check = TRUE
    )
    return(invisible(TRUE))
  }

  # 4. Download/Install (Network required)
  if (!install) {
    if (!quiet) {
      cli::cli_alert_warning(
        "Required Java version not found and install = FALSE."
      )
    }
    return(invisible(FALSE))
  }

  if (!quiet) {
    cli::cli_alert_info(
      "Java {version} not found in session, system, or cache. Attempting download..."
    )
  }

  tryCatch(
    {
      # use_java handles the actual download/unpack/set logic
      use_java(
        version = version,
        distribution = distribution,
        cache_path = cache_path,
        platform = platform,
        arch = arch,
        quiet = quiet,
        ._skip_rjava_check = TRUE
      )
      return(invisible(TRUE))
    },
    error = function(e) {
      if (!quiet) {
        cli::cli_alert_danger("Failed to install/set Java: {e$message}")
      }
      return(invisible(FALSE))
    }
  )
}
