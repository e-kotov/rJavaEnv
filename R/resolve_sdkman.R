#' Fetch SDKMAN candidate identifiers for a platform
#'
#' Queries /versions/all primary endpoint, falling back to /versions/list
#' table parsing if /versions/all returns an empty result.
#'
#' @param sdk_platform SDKMAN platform string (e.g., "linuxx64", "darwinarm64")
#' @return Character vector of identifiers
#' @keywords internal
sdkman_fetch_identifiers <- function(sdk_platform) {
  all_url <- sprintf(
    "https://api.sdkman.io/2/candidates/java/%s/versions/all",
    sdk_platform
  )
  list_url <- sprintf(
    "https://api.sdkman.io/2/candidates/java/%s/versions/list?installed=",
    sdk_platform
  )

  ids <- character(0)
  try(
    {
      lines <- rje_read_lines(all_url, warn = FALSE)
      raw_text <- trimws(paste(lines, collapse = ""))
      split_ids <- strsplit(raw_text, ",")[[1]]
      ids <- trimws(split_ids)
      ids <- ids[nzchar(ids)]
    },
    silent = TRUE
  )

  if (length(ids) == 0L) {
    # Fallback: extract last non-empty pipe field of each table row.
    # Immune to 6-col -> 4-col shift and leading-pipe presence/absence.
    try(
      {
        table_lines <- rje_read_lines(list_url, warn = FALSE)
        for (line in table_lines) {
          parts <- trimws(strsplit(line, "\\|")[[1]])
          parts <- parts[nzchar(parts)]
          if (length(parts) < 2L) next # separator rules, header dividers, banner lines
          candidate_id <- parts[length(parts)]
          if (candidate_id == "Identifier") next # table header
          if (grepl("^[0-9].*-[a-z]{2,}$", candidate_id)) {
            ids <- c(ids, candidate_id)
          }
        }
      },
      silent = TRUE
    )
  }

  unique(ids)
}

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
    vendor_code <- sdkman_distribution_to_vendor(distribution)
    if (is.null(vendor_code)) {
      cli::cli_abort("No SDKMAN mapping for distribution: {distribution}")
    }

    # Fetch candidate identifiers
    all_ids <- sdkman_fetch_identifiers(sdk_platform)
    df <- sdkman_parse_identifiers(all_ids, platform, arch)

    # Filter by vendor code
    if (nrow(df) > 0) {
      df <- df[
        tolower(sub(".*-", "", df$identifier)) == tolower(vendor_code),
        ,
        drop = FALSE
      ]
    }

    is_specific <- grepl("[^0-9]", version)

    if (nrow(df) > 0) {
      if (is_specific) {
        # Exact match or prefix match for specific version
        v_esc <- gsub("[.]", "[.]", version)
        matches <- df$version == version |
          grepl(paste0("^", v_esc, "([+]|-|[.]|$)"), df$version)
        df <- df[matches, , drop = FALSE]
      } else {
        # Match major version
        df <- df[
          !is.na(df$major) & df$major == as.integer(version),
          ,
          drop = FALSE
        ]

        # Exclude specialised builds unless explicitly requested
        specialised <- "(\\.fx|-fx|\\.crac|-crac|-ea$|\\+ea|-snapshot)"
        if (!grepl(specialised, version)) {
          standard_df <- df[!grepl(specialised, df$identifier), , drop = FALSE]
          if (nrow(standard_df) > 0) {
            df <- standard_df
          }
        }
      }
    }

    if (nrow(df) == 0) {
      cli::cli_abort(
        "No SDKMAN identifier for {distribution} {version}",
        class = "rJavaEnv_sdkman_unavailable"
      )
    }

    # Component-wise integer sorting (descending)
    ver_keys <- lapply(
      strsplit(gsub("[^0-9.]+", ".", df$version), "\\.+"),
      function(x) {
        nums <- as.integer(x[nzchar(x)])
        nums[!is.na(nums)]
      }
    )
    max_len <- max(vapply(ver_keys, length, integer(1)))
    padded_matrix <- do.call(rbind, lapply(ver_keys, function(k) {
      c(k, rep(0L, max_len - length(k)))
    }))
    ord <- do.call(
      order,
      c(as.data.frame(padded_matrix), list(decreasing = TRUE))
    )
    identifier <- df$identifier[ord[1]]
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
  resp <- rje_curl_fetch_memory(broker_url)

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
