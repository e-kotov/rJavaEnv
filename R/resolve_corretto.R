#' Resolve Corretto metadata from AWS JSON
#'
#' Resolves download metadata for Amazon Corretto from the official JSON index
#'
#' @param version Major Java version
#' @param platform Platform OS
#' @param arch Architecture
#'
#' @return A java_build object
#' @keywords internal
resolve_corretto_metadata <- function(version, platform, arch) {
  cfg <- java_config("endpoints")$Corretto
  index_url <- cfg$index_url

  version <- as.character(version)

  # Download and parse the JSON index for checksums
  index <- tryCatch(
    read_json_url(index_url, max_simplify_lvl = "list"),
    error = function(e) {
      cli::cli_abort("Corretto index download error: {e$message}")
    }
  )

  # Map platform names to Corretto keys
  platform_key <- switch(
    platform,
    "linux" = "linux",
    "macos" = "macos",
    "windows" = "windows",
    "alpine-linux" = "alpine-linux",
    cli::cli_abort("Unsupported platform for Corretto: {platform}")
  )

  # Corretto uses the same arch names as us
  arch_key <- arch

  # Determine Major Version lookup key
  # If version is specific (e.g. 11.0.2), we need to extract "11"
  v_clean <- sub("^jdk-?", "", version)
  major_str <- sub("^([0-9]+).*", "\\1", v_clean)

  # Navigate to the specific entry (using major version)
  entry <- index[[platform_key]][[arch_key]][["jdk"]][[major_str]]
  if (is.null(entry)) {
    cli::cli_abort("Corretto {version} not found for {platform}/{arch}")
  }

  # Prefer tar.gz for Linux/macOS, zip for Windows
  pkg <- entry[["tar.gz"]] %||% entry[["zip"]]
  if (is.null(pkg)) {
    cli::cli_abort("No downloadable package found for Corretto {version}")
  }

  # Map platform to Corretto URL format
  url_platform <- switch(
    platform,
    "macos" = "macos",
    "linux" = "linux",
    "windows" = "windows",
    "alpine-linux" = "alpine",
    platform
  )

  # Determine file extension
  ext <- if (platform == "windows") "zip" else "tar.gz"

  # Extract detailed version from resource path to verify
  # Resource format: /downloads/resources/11.0.29.7.1/amazon-corretto-11.0.29.7.1-macosx-aarch64.tar.gz
  # or sometimes just the folder version
  # Let's try to extract the version part from the folder version in the path

  # Usually /downloads/resources/{VERSION}/...
  res_parts <- strsplit(pkg$resource, "/")[[1]]
  # It usually starts with empty string if leading /, so index 4 is likely version?
  # /downloads/resources/11.0.29.7.1/...
  # 1: "", 2: "downloads", 3: "resources", 4: "11.0.29.7.1"
  found_version <- if (length(res_parts) >= 4) res_parts[4] else major_str

  # Check if specific version requested matches found version
  is_specific <- grepl("[^0-9]", version)
  if (is_specific) {
    # Compare found_version with requested version
    # Corretto versions often have extra build info like .7.1
    # If user requested "11.0.2", and we found "11.0.29...", that's a mismatch.
    # But if user requested "11.0.29" and we found "11.0.29.7.1", is that a match?
    # Usually yes.
    # Let's check for prefix match or exact match.

    if (!startsWith(found_version, version)) {
      cli::cli_abort(
        "Specific version {version} not available via Corretto native backend. Found latest: {found_version}. Please use 'sdkman' backend or specify major version only."
      )
    }
  }

  # Use corretto.aws which handles redirects properly (not corretto.github.io which is broken)
  # But if we want specific version we might need to construct URL differently?
  # The existing code uses /latest/... which implies we always fetch latest.
  # If we verified that found_version == requested version, then /latest IS the requested version.

  download_url <- sprintf(
    "https://corretto.aws/downloads/latest/amazon-corretto-%s-%s-%s-jdk.%s",
    major_str,
    arch,
    url_platform,
    ext
  )

  java_build(
    vendor = "Corretto",
    version = version,
    major = NULL,
    semver = found_version,
    platform = platform,
    arch = arch,
    download_url = download_url,
    filename = basename(pkg$resource),
    checksum = pkg$checksum_sha256,
    checksum_type = "sha256",
    backend = "native"
  )
}
