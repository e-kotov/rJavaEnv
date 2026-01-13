#' List Available Java Versions
#'
#' @description
#' This function retrieves a list of all available installable Java versions
#' from the specified backend(s). It returns a unified data frame with
#' version details, vendors, and checksum availability.
#'
#' @param backend Character vector. Backends to query: "native", "sdkman", or "both" (default).
#' @param platform Platform OS. Defaults to current platform. Use "all" to list for all supported platforms.
#' @param arch Architecture. Defaults to current architecture. Use "all" to list for all supported architectures.
#' @param force Logical. If TRUE, bypasses and refreshes the internal cache.
#' @param quiet Logical. If TRUE, suppresses progress messages.
#'
#' @return A data.frame with columns:
#' \itemize{
#'   \item \code{backend}: "native" or "sdkman"
#'   \item \code{vendor}: Java distribution name
#'   \item \code{major}: Major version number
#'   \item \code{version}: Full version string
#'   \item \code{platform}: Platform OS
#'   \item \code{arch}: Architecture
#'   \item \code{identifier}: Internal identifier (mainly for SDKMAN)
#'   \item \code{checksum_available}: Whether checksum verification is available
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' # List all available versions for current platform
#' java_list_available()
#'
#' # List all versions for all platforms (Pro users)
#' java_list_available(platform = "all", arch = "all")
#' }
java_list_available <- function(
  backend = c("both", "native", "sdkman"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  force = FALSE,
  quiet = FALSE
) {
  backend <- match.arg(backend)

  if (isTRUE(force)) {
    memoise::forget(memoised_list_temurin)
    memoise::forget(memoised_list_corretto)
    memoise::forget(memoised_list_zulu)
    memoise::forget(memoised_list_sdkman)
  }

  cfg <- java_config()

  platforms <- if (platform == "all") cfg$platforms$supported else platform
  arches <- if (arch == "all") c("x64", "aarch64") else arch

  if (platform == "all" || arch == "all") {
    rlang::warn(
      "Listing all versions for all platforms/architectures. This is for advanced users; many versions may not be compatible with your current system."
    )
  }

  results <- list()

  # Iterate over all requested platforms and arches
  for (p in platforms) {
    for (a in arches) {
      if (backend %in% c("both", "native")) {
        if (!quiet) {
          cli::cli_progress_step("Querying native vendor APIs for {p}/{a}...")
        }
        results[[paste0("temurin_", p, "_", a)]] <- memoised_list_temurin(p, a)
        results[[paste0("corretto_", p, "_", a)]] <- memoised_list_corretto(
          p,
          a
        )
        results[[paste0("zulu_", p, "_", a)]] <- memoised_list_zulu(p, a)
      }

      if (backend %in% c("both", "sdkman")) {
        if (!quiet) {
          cli::cli_progress_step("Querying SDKMAN API for {p}/{a}...")
        }
        results[[paste0("sdkman_", p, "_", a)]] <- memoised_list_sdkman(p, a)
      }
    }
  }

  # Combine results
  df <- do.call(rbind, results)
  rownames(df) <- NULL

  if (!is.null(df) && nrow(df) > 0) {
    # Sort by major version (descending) and version string
    df <- df[order(df$major, df$version, decreasing = TRUE), ]
  }

  if (!quiet) {
    cli::cli_progress_done()
  }

  df
}

#' @keywords internal
list_temurin_versions_impl <- function(platform, arch) {
  # Adoptium API mapping
  api_os <- switch(
    platform,
    "macos" = "mac",
    "alpine-linux" = "alpine-linux",
    platform
  )

  # We first get available major releases
  major_vers <- tryCatch(
    java_valid_major_versions_temurin(),
    error = function(e) return(NULL)
  )

  if (is.null(major_vers)) {
    return(data.frame())
  }

  all_releases <- list()

  for (v in major_vers) {
    url <- sprintf(
      "https://api.adoptium.net/v3/assets/feature_releases/%s/ga?os=%s&architecture=%s&image_type=jdk&jvm_impl=hotspot",
      v,
      api_os,
      arch
    )

    data <- tryCatch(
      read_json_url(url, max_simplify_lvl = "list"),
      error = function(e) NULL
    )

    if (is.null(data) || length(data) == 0) {
      next
    }

    for (rel in data) {
      all_releases[[length(all_releases) + 1]] <- data.frame(
        backend = "native",
        vendor = "Temurin",
        major = as.integer(v),
        version = rel$version_data$semver,
        platform = platform,
        arch = arch,
        identifier = rel$version_data$openjdk_version,
        checksum_available = TRUE,
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(all_releases) == 0) {
    return(data.frame())
  }
  do.call(rbind, all_releases)
}

#' @keywords internal
list_corretto_versions_impl <- function(platform, arch) {
  cfg <- java_config("endpoints")$Corretto
  index <- tryCatch(
    read_json_url(cfg$index_url, max_simplify_lvl = "list"),
    error = function(e) return(data.frame())
  )

  platform_key <- switch(
    platform,
    "linux" = "linux",
    "macos" = "macos",
    "windows" = "windows",
    "alpine-linux" = "alpine-linux",
    NULL
  )
  if (is.null(platform_key)) {
    return(data.frame())
  }

  entries <- index[[platform_key]][[arch]][["jdk"]]
  if (is.null(entries)) {
    return(data.frame())
  }

  res <- list()
  for (major in names(entries)) {
    pkg <- entries[[major]][["tar.gz"]] %||% entries[[major]][["zip"]]
    if (is.null(pkg)) {
      next
    }

    ver_match <- regmatches(
      pkg$resource,
      regexec("/([0-9.]+[^/]*)/", pkg$resource)
    )[[1]]
    full_ver <- if (length(ver_match) > 1) ver_match[2] else major

    res[[length(res) + 1]] <- data.frame(
      backend = "native",
      vendor = "Corretto",
      major = as.integer(major),
      version = full_ver,
      platform = platform,
      arch = arch,
      identifier = pkg$resource,
      checksum_available = TRUE,
      stringsAsFactors = FALSE
    )
  }

  if (length(res) == 0) {
    return(data.frame())
  }
  do.call(rbind, res)
}

#' @keywords internal
list_zulu_versions_impl <- function(platform, arch) {
  # Map to Azul naming
  zulu_os <- switch(
    platform,
    "linux" = "linux",
    "macos" = "macos",
    "windows" = "windows",
    "alpine-linux" = "linux",
    platform
  )
  zulu_arch <- arch
  zulu_ext <- if (platform == "windows") "zip" else "tar.gz"
  zulu_hw <- if (platform == "alpine_linux") "musl" else NULL

  url <- sprintf(
    "https://api.azul.com/metadata/v1/zulu/packages/?os=%s&arch=%s&archive_type=%s&java_package_type=jdk&release_status=ga&page_size=100",
    zulu_os,
    zulu_arch,
    zulu_ext
  )
  if (!is.null(zulu_hw)) {
    url <- paste0(url, "&hw_bitness=", zulu_hw)
  }

  data <- tryCatch(
    read_json_url(url, max_simplify_lvl = "list"),
    error = function(e) return(data.frame())
  )

  if (length(data) == 0) {
    return(data.frame())
  }

  res <- lapply(data, function(x) {
    data.frame(
      backend = "native",
      vendor = "Zulu",
      major = as.integer(x$java_version[[1]]),
      version = paste(x$java_version, collapse = "."),
      platform = platform,
      arch = arch,
      identifier = x$package_uuid,
      checksum_available = TRUE,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, res)
}

#' @keywords internal
list_sdkman_versions_impl <- function(platform, arch) {
  cfg <- java_config("sdkman")
  if (is.null(cfg)) {
    return(data.frame())
  }

  sdk_platform <- paste0(
    cfg$platform_map[[platform]] %||% platform,
    cfg$arch_map[[arch]] %||% arch
  )

  versions_url <- sprintf(
    "https://api.sdkman.io/2/candidates/java/%s/versions/list?installed=",
    sdk_platform
  )

  versions_text <- tryCatch(
    rje_read_lines(versions_url, warn = FALSE),
    error = function(e) return(data.frame())
  )

  res <- list()
  for (line in versions_text) {
    parts <- trimws(strsplit(line, "\\|")[[1]])
    if (length(parts) >= 6) {
      ver_str <- parts[3]
      vendor_code <- parts[4]
      id <- parts[6]

      if (ver_str == "Version" || vendor_code == "Dist" || id == "Identifier") {
        next
      }

      vendor_name <- names(cfg$vendor_map)[which(cfg$vendor_map == vendor_code)]
      if (length(vendor_name) == 0) {
        vendor_name <- vendor_code
      }

      major <- as.integer(gsub("^([0-9]+).*", "\\1", ver_str))

      res[[length(res) + 1]] <- data.frame(
        backend = "sdkman",
        vendor = vendor_name,
        major = major,
        version = ver_str,
        platform = platform,
        arch = arch,
        identifier = id,
        checksum_available = FALSE,
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(res) == 0) {
    return(data.frame())
  }
  do.call(rbind, res)
}

# Memoised versions of the helper functions
# These must remain at the bottom so the _impl functions are defined
memoised_list_temurin <- memoise::memoise(list_temurin_versions_impl)
memoised_list_corretto <- memoise::memoise(list_corretto_versions_impl)
memoised_list_zulu <- memoise::memoise(list_zulu_versions_impl)
memoised_list_sdkman <- memoise::memoise(list_sdkman_versions_impl)
