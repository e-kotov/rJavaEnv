#' Resolve Zulu metadata from Azul API
#'
#' Resolves download metadata for Azul Zulu from the Azul API
#'
#' @param version Major Java version
#' @param platform Platform OS
#' @param arch Architecture
#'
#' @return A java_build object
#' @keywords internal
resolve_zulu_metadata <- function(version, platform, arch) {
  # Map platform and architecture names for Azul API
  api_os <- switch(
    platform,
    "macos" = "macos",
    "alpine-linux" = "linux-musl",
    platform
  )

  api_arch <- switch(arch, "x64" = "x86", "aarch64" = "arm", arch)

  ext <- if (platform == "windows") "zip" else "tar.gz"
  lib_c <- if (platform == "alpine-linux") "musl" else "glibc"

  version <- as.character(version)
  is_specific <- grepl("[^0-9]", version)

  # Build API URL with required parameters
  # Zulu API supports "java_version=11" (major) or "java_version=11.0.2" (specific)
  url <- sprintf(
    "https://api.azul.com/metadata/v1/zulu/packages/?java_version=%s&os=%s&arch=%s&archive_type=%s&java_package_type=jdk&latest=true&include_fields=sha256_hash,download_url,name,java_version",
    utils::URLencode(version, reserved = TRUE),
    api_os,
    api_arch,
    ext
  )

  if (!is.null(lib_c) && platform == "alpine-linux") {
    url <- paste0(url, "&hw_bitness=", lib_c)
  }

  # Query API
  data <- tryCatch(
    read_json_url(url, max_simplify_lvl = "list"),
    error = function(e) cli::cli_abort("Azul API error: {e$message}")
  )

  if (length(data) == 0) {
    cli::cli_abort("No Zulu release for Java {version} on {platform}/{arch}")
  }

  # Extract package info
  pkg <- data[[1]]

  # Validate that the returned version actually matches the requested specific version
  # The API might ignore invalid version filters and return the latest available (Java 25 etc.), which is dangerous.
  pkg_ver_str <- paste(pkg$java_version, collapse = ".")
  # Also check if there is a more detailed version string?
  # pkg$name usually contains the full version e.g. "zulu11.56.19-ca-fx-jdk11.0.15-macosx_aarch64.tar.gz"
  # But `pkg$java_version` is reliable for the semver logic.

  if (is_specific) {
    # Helper to normalize versions for comparison (remove trailing zeros? or just strict?)
    # User input: "21.0.8+9.0.LT"
    # Returned: "25.0.1" (if fallback)

    # Use comparison:
    if (pkg_ver_str != version) {
      # Try looser matching if slightly different format (e.g. 11.0.2 vs 11.0.2+7)
      # But if they are completely different (21 vs 25), throw error.

      # Check if it starts with the version (prefix match)
      # e.g. request "11.0.2", got "11.0.2" (from [11,0,2]) -> Match
      # e.g. request "11.0.2+7", got "11.0.2" -> Mismatch?
      # The Azul API `java_version` field is just [major, minor, patch]. It drops build number.
      # So we might not be able to validate "21.0.8+9".

      # However, we CAN validate the Major version at least!
      # And certainly ensure it's not Java 25 when we asked for 21.

      req_major <- suppressWarnings(as.integer(sub(
        "^([0-9]+).*",
        "\\1",
        version
      )))
      got_major <- pkg$java_version[[1]]

      if (!is.na(req_major) && got_major != req_major) {
        cli::cli_abort(
          "Zulu API returned Java {got_major} when {req_major} ({version}) was requested. The specific version likely does not exist."
        )
      }

      # If majors match, but full strings differ?
      # e.g. 21.0.8+9 vs 21.0.8?
      # This is acceptable if Azul doesn't return build info in `java_version`.
      # But for "21.0.8+9.0.LT", the major is 21.
      # If API returned 25, the major check catches it.
    }
  }

  java_build(
    vendor = "Zulu",
    version = version,
    major = NULL,
    semver = pkg_ver_str,
    platform = platform,
    arch = arch,
    download_url = pkg$download_url,
    filename = sprintf("zulu-%s-%s-%s.%s", version, platform, arch, ext),
    checksum = pkg$sha256_hash,
    checksum_type = "sha256",
    backend = "native"
  )
}
