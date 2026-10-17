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
    candidates <- version
    # Extract vendor code from identifier for metadata purposes
    vendor_code <- sdkman_vendor_code(version)
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

    candidates <- character(0)
    if (nrow(df) > 0) {
      # Component-wise integer sorting (descending)
      ver_keys <- lapply(
        strsplit(gsub("[^0-9.]+", ".", df$version), "\\.+"),
        function(x) {
          nums <- as.integer(x[nzchar(x)])
          nums[!is.na(nums)]
        }
      )
      max_len <- max(vapply(ver_keys, length, integer(1)))
      padded_matrix <- do.call(
        rbind,
        lapply(ver_keys, function(k) {
          c(k, rep(0L, max_len - length(k)))
        })
      )
      ord <- do.call(
        order,
        c(as.data.frame(padded_matrix), list(decreasing = TRUE))
      )
      candidates <- df$identifier[ord]
    }

    # The broker often serves exact versions the listing omits
    # (e.g. 21.0.9-amzn), so also try the requested version directly.
    if (is_specific) {
      candidates <- unique(c(candidates, paste0(version, "-", vendor_code)))
    }

    if (length(candidates) == 0) {
      cli::cli_abort(
        "No SDKMAN identifier for {distribution} {version}",
        class = "rJavaEnv_sdkman_unavailable"
      )
    }
  }

  # Recalculate sdk_platform for broker URL (needed even in fast-path)
  sdk_platform <- paste0(
    cfg$platform_map[[platform]] %||% platform,
    cfg$arch_map[[arch]] %||% arch
  )

  # SDKMAN lists some identifiers the broker cannot serve (e.g. the
  # "+build" style ids such as 21.0.4.0+7-amzn). Try each candidate, and its
  # legacy alias, newest first, until the broker returns a download URL.
  max_candidates <- 5L
  try_ids <- unique(unlist(lapply(
    utils::head(candidates, max_candidates),
    function(x) c(x, sdkman_legacy_identifier(x))
  )))
  final_url <- NULL
  identifier <- NULL
  for (try_id in try_ids) {
    final_url <- sdkman_broker_resolve(try_id, sdk_platform)
    if (!is.null(final_url)) {
      identifier <- try_id
      break
    }
  }

  if (is.null(final_url)) {
    cli::cli_abort(
      c(
        "SDKMAN broker has no download for {distribution} {version} on {sdk_platform}.",
        "i" = "Tried identifier{?s}: {.val {try_ids}}",
        "i" = "Use {.code backend = \"native\"} to download from the vendor's API instead."
      ),
      class = "rJavaEnv_sdkman_unavailable"
    )
  }

  # Only warn when falling back to a different version, not to a legacy alias
  if (
    !identifier %in% c(candidates[1], sdkman_legacy_identifier(candidates[1]))
  ) {
    cli::cli_alert_warning(
      "SDKMAN broker cannot serve {.val {candidates[1]}}; using {.val {identifier}} instead."
    )
  }

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
    filename = sdkman_filename(version, distribution, platform, arch),
    checksum = NULL, # NOT AVAILABLE
    checksum_type = NULL,
    backend = "sdkman"
  )
}

#' Resolve a download URL from the SDKMAN broker
#'
#' Does not follow the redirect, so the JDK archive itself is not fetched.
#'
#' @param identifier SDKMAN identifier (e.g., "21.0.4-amzn")
#' @param sdk_platform SDKMAN platform string (e.g., "linuxx64")
#' @return The download URL, or NULL if the broker cannot serve the identifier
#' @keywords internal
sdkman_broker_resolve <- function(identifier, sdk_platform) {
  broker_url <- sprintf(
    "https://api.sdkman.io/2/broker/download/java/%s/%s",
    utils::URLencode(identifier, reserved = TRUE),
    sdk_platform
  )

  # The SDKMAN API rate-limits bursts of requests with 503 (or 429), so back
  # off and retry. Only a 4xx answer means the broker cannot serve the
  # identifier; persistent server or network errors abort rather than let the
  # caller fall back to an older build.
  max_attempts <- 4L
  for (attempt in seq_len(max_attempts)) {
    resp <- tryCatch(
      rje_curl_fetch_memory(
        broker_url,
        handle = curl::new_handle(
          followlocation = FALSE,
          connecttimeout = 15,
          timeout = 60
        )
      ),
      error = function(e) e
    )
    failed <- inherits(resp, "error") ||
      resp$status_code == 429L ||
      resp$status_code >= 500L
    if (!failed) {
      break
    }
    if (attempt == max_attempts) {
      cli::cli_abort(
        c(
          "SDKMAN API request for {.val {identifier}} failed.",
          "x" = if (inherits(resp, "error")) {
            conditionMessage(resp)
          } else {
            "HTTP status {resp$status_code}."
          },
          "i" = "Try again later, or use {.code backend = \"native\"}."
        ),
        class = "rJavaEnv_sdkman_api_error"
      )
    }
    rje_sleep(attempt)
  }

  status <- resp$status_code
  if (status >= 400L) {
    return(NULL)
  }

  final_url <- NULL
  if (status >= 300L && length(resp$headers) > 0) {
    final_url <- curl::parse_headers_list(resp$headers)[["location"]]
  }
  if (is.null(final_url) && !is.null(resp$url) && resp$url != broker_url) {
    final_url <- resp$url
  }
  if (is.null(final_url) && length(resp$content) > 0) {
    final_url <- trimws(rawToChar(resp$content))
  }

  if (is.null(final_url) || !grepl("^https?://", final_url)) {
    return(NULL)
  }
  final_url
}

#' Map a "+build" SDKMAN identifier to its legacy broker form
#'
#' SDKMAN's listing uses identifiers like "21.0.4.0+7-amzn",
#' "21.0.12+1.1-tem" or "21.0.12-fx+1.1-librca", while its broker still serves
#' the legacy forms "21.0.4-amzn", "21.0.12-tem" and "21.0.12.fx-librca".
#'
#' @param identifier SDKMAN identifier
#' @return The legacy identifier, or NULL if `identifier` has no "+build" part
#'   or is an early-access build
#' @keywords internal
sdkman_legacy_identifier <- function(identifier) {
  # Early-access ids ("28.0.0.0+ea.18-open") have no known legacy mapping
  if (
    !grepl("+", identifier, fixed = TRUE) ||
      grepl("+ea", identifier, fixed = TRUE)
  ) {
    return(NULL)
  }
  vendor <- sub(".*-", "", identifier)
  base <- sub("[+].*$", "", sub("-[^-]*$", "", identifier))
  # "21.0.12-fx" -> "21.0.12.fx"
  base <- sub("-([a-z]+)$", ".\\1", base)
  # "21.0.4.0" -> "21.0.4" (also before a ".fx"/".crac" suffix)
  base <- sub(
    "^([0-9]+[.][0-9]+[.][0-9]+)[.]0(?=$|[.][a-z])",
    "\\1",
    base,
    perl = TRUE
  )
  paste0(base, "-", vendor)
}

#' Sleep wrapper (mockable in tests)
#'
#' @param seconds Number of seconds to sleep
#' @keywords internal
rje_sleep <- function(seconds) {
  Sys.sleep(seconds)
}

#' File name of a cached SDKMAN archive
#'
#' Depends only on the request, not on the resolved build, so a cached archive
#' can be found without querying the SDKMAN API.
#'
#' @inheritParams global_version_param
#' @param distribution Java distribution name
#' @param platform Platform OS
#' @param arch Architecture
#' @return File name
#' @keywords internal
sdkman_filename <- function(version, distribution, platform, arch) {
  ext <- if (platform == "windows") "zip" else "tar.gz"
  sprintf(
    "%s-%s-%s-%s.%s",
    tolower(distribution),
    version,
    platform,
    arch,
    ext
  )
}
