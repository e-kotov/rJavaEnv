#' Resolve metadata via SDKMAN broker (NO CHECKSUM)
#'
#' Resolves download metadata by querying the SDKMAN API. Note: SDKMAN does not
#' provide checksums, so verification will be skipped with a warning.
#'
#' @inheritParams global_version_param
#' @param distribution Java distribution name
#' @param platform Platform OS
#' @param arch Architecture
#'
#' @return A java_build object with checksum=NULL
#' @inheritParams global_sdkman_references
#' @keywords internal
resolve_sdkman_metadata <- function(version, distribution, platform, arch) {
  cfg <- java_config("sdkman")

  if (is.null(cfg)) {
    cli::cli_abort("SDKMAN configuration not found in java_config.yaml")
  }

  version <- as.character(version)

  # Fast-path: if version IS an identifier, use it directly
  if (is_sdkman_identifier(version)) {
    identifier <- version
    # Extract vendor code from identifier for metadata purposes
    vendor_code <- sdkman_vendor_code(identifier)
  } else {
    # Map to SDKMAN platform codes
    sdk_platform <- paste0(
      cfg$platform_map[[platform]] %||% platform,
      cfg$arch_map[[arch]] %||% arch
    )

    # Map distribution to SDKMAN vendor code
    vendor_code <- cfg$vendor_map[[distribution]]
    if (is.null(vendor_code)) {
      cli::cli_abort("No SDKMAN mapping for distribution: {distribution}")
    }

    # Get version list to find identifier
    versions_url <- sprintf(
      "https://api.sdkman.io/2/candidates/java/%s/versions/list?installed=",
      sdk_platform
    )

    versions_text <- tryCatch(
      rje_read_lines(versions_url, warn = FALSE),
      error = function(e) cli::cli_abort("SDKMAN API error: {e$message}")
    )

    # Parse pipe-delimited format: | | 21.0.9 | tem | | 21.0.9-tem |
    identifier <- NULL

    is_specific <- grepl("[^0-9]", version)
    v_esc <- gsub("\\.", "\\\\.", version)

    for (line in versions_text) {
      parts <- trimws(strsplit(line, "\\|")[[1]])
      if (length(parts) >= 5) {
        ver_str <- parts[3]
        line_vendor <- parts[4]
        line_id <- parts[6]

        if (!is.na(line_vendor) && line_vendor == vendor_code) {
          # Match version
          is_match <- FALSE
          if (is_specific) {
            # Exact match for specific version
            if (ver_str == version) {
              is_match <- TRUE
            }
          } else {
            # Prefix match for major version (e.g. "11" matches "11.0.2")
            if (grepl(paste0("^", v_esc, "\\."), ver_str)) {
              is_match <- TRUE
            }
          }

          if (is_match) {
            identifier <- line_id
            break
          }
        }
      }
    }

    if (is.null(identifier)) {
      cli::cli_abort("No SDKMAN identifier for {distribution} {version}")
    }
  }

  # Recalculate sdk_platform for broker URL (needed even in fast-path)
  sdk_platform <- paste0(
    cfg$platform_map[[platform]] %||% platform,
    cfg$arch_map[[arch]] %||% arch
  )

  # Get redirect URL from broker
  broker_url <- sprintf(
    "https://api.sdkman.io/2/broker/download/java/%s/%s",
    identifier,
    sdk_platform
  )

  # Follow redirect to get final URL
  resp <- curl::curl_fetch_memory(broker_url)

  # Extract final URL from response headers or body
  final_url <- if (!is.null(resp$url) && resp$url != broker_url) {
    resp$url
  } else {
    # Parse redirect from response
    rawToChar(resp$content)
  }

  ext <- if (platform == "windows") "zip" else "tar.gz"

  # Warn about missing checksum
  cli::cli_alert_warning("SDKMAN backend: checksum verification unavailable")

  java_build(
    vendor = distribution,
    version = version,
    major = NULL,
    semver = identifier,
    platform = platform,
    arch = arch,
    download_url = final_url,
    filename = sprintf(
      "%s-%s-%s-%s.%s",
      tolower(distribution),
      version,
      platform,
      arch,
      ext
    ),
    checksum = NULL, # NOT AVAILABLE
    checksum_type = NULL,
    backend = "sdkman"
  )
}
