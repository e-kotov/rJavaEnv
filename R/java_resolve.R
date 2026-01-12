#' Resolve path to specific Java version
#'
#' Finds or installs Java and returns the path to JAVA_HOME.
#' This function does not modify any environment variables.
#'
#' @inheritParams java_ensure
#' @inheritParams global_backend_param
#' @inheritParams global_sdkman_references
#' @return Character string (Path to JAVA_HOME)
#' @export
#' @examples
#' \dontrun{
#' # Get path to Java 21 (installing if necessary)
#' path <- java_resolve(version = 21, install = TRUE)
#' }
java_resolve <- function(
  version = NULL,
  type = c("exact", "min"),
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  install = TRUE,
  accept_system_java = TRUE,
  quiet = FALSE,
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  .use_cache = FALSE
) {
  if (is.null(version)) {
    cli::cli_abort("The {.arg version} argument is required.")
  }

  type <- match.arg(type)
  version <- as.character(version)

  # Check if version is a specific version string (not just a major number)
  is_specific_version <- grepl("[^0-9]", version)
  req_ver_int <- suppressWarnings(as.integer(version))

  # 1. Check Active Session (JAVA_HOME)
  # If the current environment already satisfies the requirement, return it.
  curr_ver_str <- java_check_version_cmd(quiet = TRUE, .use_cache = .use_cache)
  if (!isFALSE(curr_ver_str)) {
    curr_ver_int <- suppressWarnings(as.integer(curr_ver_str))

    match_found <- FALSE

    if (is_specific_version) {
      if (type == "exact") {
        match_found <- curr_ver_str == version
      } else {
        # min version check for specific version
        match_found <- tryCatch(
          utils::compareVersion(curr_ver_str, version) >= 0,
          error = function(e) FALSE
        )
      }
    } else {
      # Major version check
      if (!is.na(curr_ver_int) && !is.na(req_ver_int)) {
        if (type == "exact") {
          match_found <- curr_ver_int == req_ver_int
        } else {
          match_found <- curr_ver_int >= req_ver_int
        }
      }
    }

    if (match_found) {
      if (!quiet) {
        cli::cli_alert_success(
          "Active Java version {curr_ver_str} satisfies requirement."
        )
      }
      return(Sys.getenv("JAVA_HOME"))
    }
  }

  # 2. Check System Installations
  if (accept_system_java) {
    if (!quiet) {
      cli::cli_alert_info("Checking system for existing Java installations...")
    }
    system_javas <- tryCatch(
      java_find_system(quiet = TRUE, .use_cache = .use_cache),
      error = function(e) {
        if (!quiet) {
          cli::cli_alert_warning("System Java search failed: {e$message}")
        }
        data.frame()
      }
    )

    valid_matches <- list()
    if (nrow(system_javas) > 0) {
      for (i in seq_len(nrow(system_javas))) {
        jv_ver <- system_javas$version[i]
        ver_int <- suppressWarnings(as.integer(jv_ver))

        is_match <- FALSE

        if (is_specific_version) {
          if (type == "exact") {
            is_match <- jv_ver == version
          } else {
            is_match <- tryCatch(
              utils::compareVersion(jv_ver, version) >= 0,
              error = function(e) FALSE
            )
          }
        } else {
          if (!is.na(ver_int) && !is.na(req_ver_int)) {
            if (type == "exact") {
              is_match <- ver_int == req_ver_int
            } else {
              is_match <- ver_int >= req_ver_int
            }
          }
        }

        if (is_match) {
          valid_matches[[length(valid_matches) + 1]] <- list(
            path = system_javas$java_home[i],
            version = jv_ver
          )
        }
      }
    }

    if (length(valid_matches) > 0) {
      # Sort descending by version (using version string comparison)
      # Extract versions as character vector first, then convert to numeric_version
      ver_strs <- vapply(valid_matches, function(x) x$version, character(1))
      sorted <- valid_matches[order(
        numeric_version(ver_strs),
        decreasing = TRUE
      )]
      selected <- sorted[[1]] # Pick best match
      if (!quiet) {
        cli::cli_alert_success(
          "Found valid system Java {selected$version} at {.path {selected$path}}"
        )
      }
      return(selected$path)
    }
  }

  # 3. Check Local Cache
  cache_list <- java_list_installed(
    output = "data.frame",
    quiet = TRUE,
    cache_path = cache_path
  )
  if (length(cache_list) > 0 && nrow(cache_list) > 0) {
    # Filter by distribution and backend
    dist_matches <- cache_list[
      cache_list$distribution == distribution &
        cache_list$backend == backend,
    ]

    valid_candidates <- data.frame()
    if (nrow(dist_matches) > 0) {
      if (is_specific_version) {
        # Specific string matching
        if (type == "exact") {
          valid_candidates <- dist_matches[dist_matches$version == version, ]
        } else {
          # Use logic to filter version >= req
          keep <- vapply(
            dist_matches$version,
            function(v) {
              utils::compareVersion(v, version) >= 0
            },
            logical(1)
          )
          valid_candidates <- dist_matches[keep, ]
        }
      } else {
        # Major version matching
        dist_matches$ver_int <- suppressWarnings(as.integer(
          dist_matches$version
        ))
        if (type == "exact") {
          valid_candidates <- dist_matches[
            which(dist_matches$ver_int == req_ver_int),
          ]
        } else {
          valid_candidates <- dist_matches[
            which(dist_matches$ver_int >= req_ver_int),
          ]
        }
      }
    }

    if (nrow(valid_candidates) > 0) {
      # Sort candidates by version descending
      # Helper to sort version strings safely
      v_order <- order(
        vapply(
          valid_candidates$version,
          function(v) {
            # Try to make it a numeric version, fallback to 0 if fails
            tryCatch(as.numeric(numeric_version(v))[1], error = function(e) 0)
          },
          numeric(1)
        ),
        decreasing = TRUE
      )
      valid_candidates <- valid_candidates[v_order, ]

      # Also prioritize exact match if any
      if (is_specific_version && type == "exact") {
        # Already filtered to exact match
      } else if (!is_specific_version && type == "exact") {
        # Prefer exact major version (already filtered)
      }

      found_path <- valid_candidates$path[1]
      if (!quiet) {
        cli::cli_alert_info("Found cached Java at {.path {found_path}}")
      }
      return(found_path)
    }
  }

  # 4. Download and Install
  if (!install) {
    cli::cli_abort(
      "Required Java version not found and {.arg install} is FALSE."
    )
  }

  # Check consent before downloading (rje_consent_check handles interactive prompts)
  rje_consent_check()

  if (!quiet) {
    cli::cli_alert_info("Attempting to download and install Java {version}...")
  }

  # Reuse java_download and java_unpack logic
  dist_path <- java_download(
    version = version,
    distribution = distribution,
    backend = backend,
    cache_path = cache_path,
    platform = platform,
    arch = arch,
    quiet = quiet
  )

  unpack_path <- java_unpack(
    java_distrib_path = dist_path,
    quiet = quiet
  )

  return(unpack_path)
}
