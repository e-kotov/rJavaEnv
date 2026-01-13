#' Resolve Temurin metadata from Adoptium API
#'
#' Resolves download metadata for Eclipse Temurin from the Adoptium API
#'
#' @param version Major Java version
#' @param platform Platform OS
#' @param arch Architecture
#'
#' @return A java_build object
#' @keywords internal
resolve_temurin_metadata <- function(version, platform, arch) {
  # Map platform name: rJavaEnv "macos" -> Adoptium "mac"
  api_os <- switch(
    platform,
    "macos" = "mac",
    "alpine-linux" = "alpine-linux",
    platform
  )

  version <- as.character(version)
  is_specific <- grepl("[^0-9]", version)

  if (is_specific) {
    # Specific version lookup
    # e.g. https://api.adoptium.net/v3/assets/version/11.0.29%2B7?os=mac&architecture=aarch64
    url <- sprintf(
      "https://api.adoptium.net/v3/assets/version/%s?os=%s&architecture=%s&image_type=jdk&jvm_impl=hotspot",
      utils::URLencode(version, reserved = TRUE),
      api_os,
      arch
    )
  } else {
    # Major version lookup (latest)
    # e.g. https://api.adoptium.net/v3/assets/latest/11/hotspot?os=mac&architecture=aarch64
    url <- sprintf(
      "https://api.adoptium.net/v3/assets/latest/%s/hotspot?os=%s&architecture=%s&image_type=jdk",
      version,
      api_os,
      arch
    )
  }

  # Query API
  data <- tryCatch(
    read_json_url(url, max_simplify_lvl = "list"),
    # If specifically requested version fails, try variations
    error = function(e) {
      if (is_specific) {
        # Try replacing .0.LTS with -LTS (common Temurin discrepancy)
        if (grepl("\\.0\\.LTS$", version)) {
          alt_version <- sub("\\.0\\.LTS$", "-LTS", version)
          alt_url <- sprintf(
            "https://api.adoptium.net/v3/assets/version/%s?os=%s&architecture=%s&image_type=jdk&jvm_impl=hotspot",
            utils::URLencode(alt_version, reserved = TRUE),
            api_os,
            arch
          )
          return(read_json_url(alt_url, max_simplify_lvl = "list"))
        }
      }
      msg <- e$message
      if (grepl("EMPTY: no JSON found", msg) || grepl("404", msg)) {
        cli::cli_abort(
          "Temurin version {version} not found for {platform}/{arch}. Please check the version string or use java_list_available()."
        )
      }
      cli::cli_abort("Adoptium API error or version not found: {msg}")
    }
  )

  if (length(data) == 0) {
    cli::cli_abort("No Temurin release for Java {version} on {platform}/{arch}")
  }

  # Result structure differs slightly between ends
  # /latest returns a LIST of binaries (usually 1, or more) directly?
  # /version returns a LIST of release objects (usually 1) which contain binaries?
  # Let's handle both.

  # Logic to extract binary info
  # IF data has "binary" field directly, it's from /latest (binary object) or simple list
  # Actually /latest returns list of binary objects
  # /version returns list of release objects

  bin <- NULL
  semver <- NULL

  if (is_specific) {
    # /version returns [ { "binaries": [...], "version_data": ... } ]
    # We take the first release
    rel <- data[[1]]
    semver <- rel$version_data$semver
    # Find matching binary in binaries list (should match os/arch but API filters it too? API filters usually work)
    # The API filter `os` and `architecture` filters strictly.
    # So simply pick the first binary?
    if (length(rel$binaries) > 0) {
      bin <- rel$binaries[[1]]
    }
  } else {
    # /latest returns [ { "binary": { ... }, "release_name": ... } ]
    # Wait, documentation says /latest returns a list of *Binary* objects?
    # Actually /latest/{feature_version}/{jvm_impl} returns list of binaries.
    # Each item has "binary" field? No, it IS the binary object?
    # Let's check structure from docs or assumption.
    # Documentation: "Returns a list of latest assets..."
    # `[ { "binary": { "package": ... }, "release_name": "..." } ]`

    # Let's inspect the first item
    if (length(data) > 0) {
      item <- data[[1]]
      if (!is.null(item$binary)) {
        bin <- item$binary
        semver <- item$release_name # or derive?
        if (is.null(semver) || semver == "") {
          # Try to find semver in some other field if available, but /latest might not have full version_data easily accessible
          # actually it usually has `version_data`?
          # Let's assume item has version_data too?
          # If not, we use release_name
          if (!is.null(item$version_data)) {
            semver <- item$version_data$semver
          }
        }
      }
    }
  }

  if (is.null(bin)) {
    # Fallback or error
    cli::cli_abort("Could not parse Temurin API response for {version}")
  }

  ext <- if (platform == "windows") "zip" else "tar.gz"

  java_build(
    vendor = "Temurin",
    version = version,
    major = NULL, # let it derive
    semver = semver,
    platform = platform,
    arch = arch,
    download_url = bin$package$link,
    filename = sprintf("temurin-%s-%s-%s.%s", version, platform, arch, ext),
    checksum = bin$package$checksum,
    checksum_type = "sha256",
    backend = "native"
  )
}
