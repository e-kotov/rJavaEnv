#' Resolve path to specific Java version
#'
#' Finds or installs Java and returns the path to JAVA_HOME.
#' This function does not modify any environment variables.
#'
#' @inheritParams java_ensure
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
  req_ver_int <- as.integer(version)
  version <- as.character(version)

  # 1. Check Active Session (JAVA_HOME)
  # If the current environment already satisfies the requirement, return it.
  curr_ver_str <- java_check_version_cmd(quiet = TRUE, .use_cache = .use_cache)
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
        return(Sys.getenv("JAVA_HOME"))
      }
    }
  }

  # 2. Check System Installations
  if (accept_system_java) {
    if (!quiet) {
      cli::cli_alert_info("Checking system for existing Java installations...")
    }
    system_javas <- tryCatch(
      java_find_system(quiet = TRUE, .use_cache = .use_cache),
      error = function(e) data.frame()
    )

    valid_matches <- list()
    if (nrow(system_javas) > 0) {
      for (i in seq_len(nrow(system_javas))) {
        ver_int <- suppressWarnings(as.integer(system_javas$version[i]))
        if (is.na(ver_int)) {
          next
        }

        is_match <- if (type == "exact") {
          ver_int == req_ver_int
        } else {
          ver_int >= req_ver_int
        }
        if (is_match) {
          valid_matches[[length(valid_matches) + 1]] <- list(
            path = system_javas$java_home[i],
            version = ver_int
          )
        }
      }
    }

    if (length(valid_matches) > 0) {
      # Sort descending by version
      sorted <- valid_matches[order(
        sapply(valid_matches, `[[`, "version"),
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
  cache_list <- java_list_installed_cache(
    output = "data.frame",
    quiet = TRUE,
    cache_path = cache_path
  )
  if (length(cache_list) > 0 && nrow(cache_list) > 0) {
    cache_list$ver_int <- suppressWarnings(as.integer(cache_list$version))
    valid_candidates <- if (type == "exact") {
      cache_list[which(cache_list$ver_int == req_ver_int), ]
    } else {
      cache_list[which(cache_list$ver_int >= req_ver_int), ]
    }

    if (nrow(valid_candidates) > 0) {
      # Prefer exact match, then newest
      valid_candidates <- valid_candidates[
        order(
          valid_candidates$ver_int == req_ver_int,
          valid_candidates$ver_int,
          decreasing = TRUE
        ),
      ]
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
