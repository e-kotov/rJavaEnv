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
#' \donttest{
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
  type <- match.arg(type)
  java_validate_requirement(version, type)
  version <- as.character(version)
  identifier <- is_sdkman_identifier(version)
  specific <- !grepl("^[0-9]+$", version)
  if (identifier) {
    backend <- "sdkman"
    distribution <- sdkman_vendor_to_distribution(sdkman_vendor_code(version))
  }

  # Check this JAVA_HOME, not an unrelated executable earlier on PATH.
  # An SDKMAN identity cannot be established from a system JVM's version alone.
  active_home <- Sys.getenv("JAVA_HOME")
  if (accept_system_java && !identifier && nzchar(active_home)) {
    active_version <- if (specific) {
      java_version_at_home(active_home)
    } else {
      java_check_version_cmd(java_home = active_home, quiet = TRUE, .use_cache = .use_cache)
    }
    if (java_version_satisfies(active_version, version, type)) {
      if (!quiet) cli::cli_alert_success("Active Java version {active_version} satisfies requirement.")
      return(active_home)
    }
  }

  if (accept_system_java && !identifier) {
    if (!quiet) cli::cli_alert_info("Checking system for existing Java installations...")
    system_javas <- tryCatch(
      java_find_system(quiet = TRUE, .use_cache = .use_cache),
      error = function(e) {
        if (!quiet) cli::cli_alert_warning("System Java search failed: {e$message}")
        data.frame()
      }
    )
    if (nrow(system_javas) > 0) {
      versions <- system_javas$version
      if (specific) {
        versions <- vapply(system_javas$java_home, java_version_at_home, character(1))
      }
      matches <- vapply(versions, java_version_satisfies, logical(1),
        requested = version, type = type)
      if (any(matches)) {
        candidates <- which(matches)
        selected <- candidates[order(java_numeric_version(versions[candidates]), decreasing = TRUE)[1]]
        if (!quiet) cli::cli_alert_success("Found valid system Java at {.path {system_javas$java_home[selected]}}")
        return(system_javas$java_home[selected])
      }
    }
  }

  # Managed installations must match the requested backend and distribution.
  cache <- java_list_installed(output = "data.frame", quiet = TRUE, cache_path = cache_path)
  if (is.data.frame(cache) && nrow(cache) > 0) {
    cache <- java_installed_matching(cache, distribution, backend, platform, arch)
    if (nrow(cache) > 0) {
      versions <- cache$version
      if (specific && !identifier) {
        versions <- vapply(cache$path, java_version_at_home, character(1))
      }
      matches <- if (identifier) versions == version else {
        vapply(versions, java_version_satisfies, logical(1), requested = version, type = type)
      }
      if (any(matches)) {
        candidates <- which(matches)
        selected <- if (identifier) candidates[1] else {
          candidates[order(java_numeric_version(versions[candidates]), decreasing = TRUE)[1]]
        }
        if (!quiet) cli::cli_alert_info("Found cached Java at {.path {cache$path[selected]}}")
        return(cache$path[selected])
      }
    }
  }

  if (!install) {
    cli::cli_abort("Required Java version not found and {.arg install} is FALSE.")
  }
  rje_consent_check()
  if (!quiet) cli::cli_alert_info("Attempting to download and install Java {version}...")
  dist_path <- java_download(
    version = version, distribution = distribution, backend = backend,
    cache_path = cache_path, platform = platform, arch = arch, quiet = quiet
  )
  home <- java_unpack(java_distrib_path = dist_path, quiet = quiet)
  # Vendor download APIs can return a nearby release for a patch request.
  # Verify the installed runtime before claiming that exact/minimum setup worked.
  if (specific && !identifier &&
      !java_version_satisfies(java_version_at_home(home), version, type)) {
    cli::cli_abort("The installed Java runtime does not satisfy version {version} (type = '{type}').")
  }
  home
}

# Normalize Java's legacy 1.8.0_452 spelling for numeric comparisons.
java_numeric_version <- function(version) {
  version <- sub("^1\\.", "", as.character(version))
  version <- sub("[+-].*$", "", version)
  numeric_version(gsub("_", ".", version, fixed = TRUE))
}

java_validate_requirement <- function(version, type) {
  checkmate::assert_scalar(version)
  version <- as.character(version)
  if (is_sdkman_identifier(version)) {
    if (type != "exact") cli::cli_abort("SDKMAN identifiers require type = 'exact'.")
  } else if (!grepl("^[0-9]+([._][0-9]+)*$", version)) {
    cli::cli_abort("The {.arg version} argument must be a major version, a numeric Java version, or a SDKMAN identifier.")
  }
  invisible(TRUE)
}

java_version_satisfies <- function(actual, requested, type) {
  if (is.null(actual) || isFALSE(actual) || !length(actual) ||
      is.na(actual) || !nzchar(actual) || is_sdkman_identifier(as.character(requested))) {
    return(FALSE)
  }
  if (grepl("^[0-9]+$", as.character(requested))) {
    major <- parse_java_major_version(as.character(actual))
    if (is.null(major)) return(FALSE)
    if (type == "exact") return(as.integer(major) == as.integer(requested))
    return(as.integer(major) >= as.integer(requested))
  }
  tryCatch({
    if (type == "exact") java_numeric_version(actual) == java_numeric_version(requested)
    else java_numeric_version(actual) >= java_numeric_version(requested)
  }, error = function(e) FALSE)
}

# Full version detection stays internal; java_check_version_cmd() continues to
# return the major version for backwards compatibility.
java_version_at_home <- function(java_home) {
  data <- ._java_version_check_impl_original(java_home)
  if (isFALSE(data)) return("")
  for (line in data$java_version_output) {
    parts <- regmatches(line, regexec(
      '^[[:space:]]*(openjdk|java)[[:space:]]+(version[[:space:]]+)?"?([0-9][^"[:space:]]*)', line
    ))[[1]]
    if (length(parts) >= 4) return(parts[4])
  }
  ""
}
