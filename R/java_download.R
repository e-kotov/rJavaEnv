#' Download a Java distribution
#'
#' @inheritParams global_version_param
#' @param distribution The Java distribution to download. One of "Corretto", "Temurin", or "Zulu". Defaults to "Corretto". Ignored if `version` is a SDKMAN identifier.
#' @inheritParams global_backend_param
#' @param cache_path The destination directory to download the Java distribution to. Defaults to a user-specific data directory.
#' @param platform The platform for which to download the Java distribution. Defaults to the current platform.
#' @param arch The architecture for which to download the Java distribution. Defaults to the current architecture.
#' @param force A logical. Whether the distribution file should be overwritten or not. Defaults to `FALSE`.
#' @param temp_dir A logical. Whether the file should be saved in a temporary directory. Defaults to `FALSE`.
#' @inheritParams global_quiet_param
#' @inheritParams global_sdkman_references
#'
#' @return The path to the downloaded Java distribution file.
#' @details SDKMAN catalogues can contain older releases or identifiers that its
#'   download broker cannot serve. When resolving a new SDKMAN download, the
#'   selected identifier is printed unless `quiet = TRUE`. Cached SDKMAN archives
#'   are reused without querying the catalogue or broker; their resolved
#'   identifier is not stored or reported. Use `backend = "native"` for the
#'   current release from a supported vendor, or request a specific version or
#'   SDKMAN identifier.
#'
#'   Cached archive names include the backend to prevent native and SDKMAN
#'   downloads from sharing an archive. Archives cached by earlier versions are
#'   left in place; while the vendor API can be reached, a fresh archive is
#'   downloaded under the new name. Existing installed Java environments are
#'   unchanged.
#'
#'   If the vendor API cannot be reached (offline, DNS or proxy failure, or a
#'   server error), a matching archive already in the cache is used instead,
#'   including archives saved by rJavaEnv 0.3.0. For Corretto, the newest cached
#'   build of the requested version is used. Other errors, such as an
#'   unavailable version, are reported as before.
#' @export
#'
#' @examples
#' \donttest{
#'
#' # download distribution of Java version 17
#' java_download(version = "17", temp_dir = TRUE)
#'
#' # download default Java distribution (version 21)
#' java_download(temp_dir = TRUE)
#'
#' # download using SDKMAN backend
#' try(java_download(version = "21", backend = "sdkman", temp_dir = TRUE))
#' }
java_download <- function(
  version = 21,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
  force = FALSE,
  temp_dir = FALSE
) {
  # Override cache_path if temp_dir is set to TRUE
  # Override cache_path if temp_dir is set to TRUE
  if (temp_dir) {
    cache_path <- file.path(tempdir(), "rJavaEnv_cache")
    if (!dir.exists(cache_path)) {
      dir.create(cache_path, recursive = TRUE)
    }
  }

  # Validate version
  version <- as.character(version)
  checkmate::check_vector(version, len = 1)

  # Auto-detect SDKMAN identifier
  if (is_sdkman_identifier(version)) {
    if (!quiet) {
      cli::cli_alert_info(
        "Detected SDKMAN identifier {.val {version}}. Using sdkman backend."
      )
    }
    backend <- "sdkman"
    distribution <- sdkman_vendor_to_distribution(sdkman_vendor_code(version))
    if (!quiet) {
      cli::cli_alert_info("Distribution: {.val {distribution}}")
    }
  }

  # Validate distribution (only for native backend)
  if (backend == "native") {
    valid_distributions <- c("Corretto", "Temurin", "Zulu")
    checkmate::assert_choice(distribution, valid_distributions)
  }

  # Validate backend
  valid_backends <- c("native", "sdkman")
  checkmate::assert_choice(backend, valid_backends)

  # Print detected platform and architecture
  if (!quiet) {
    cli::cli_inform(c(
      "Detected platform: {.strong {platform}}",
      "Detected architecture: {.strong {arch}}",
      "You can change the platform and architecture by specifying the {.arg platform} and {.arg arch} arguments."
    ))
  }

  # Prepare destination directory
  dest_dir <- file.path(cache_path, "distrib")
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # SDKMAN archive names do not depend on the resolved build, so reuse a
  # cached archive without querying the SDKMAN API
  sdkman_cached <- if (backend == "sdkman") {
    file.path(
      dest_dir,
      sdkman_filename(version, distribution, platform, arch)
    )
  }
  if (!is.null(sdkman_cached) && file.exists(sdkman_cached) && !force) {
    if (!quiet) {
      cli::cli_inform("File already cached: {basename(sdkman_cached)}")
    }
    result_path <- sdkman_cached
  } else {
    # Resolve metadata
    build <- tryCatch(
      resolve_java_metadata(
        version,
        distribution,
        platform,
        arch,
        backend,
        quiet = quiet
      ),
      # Only when the vendor API cannot be reached, never for answers like
      # "version not found"
      rJavaEnv_network_error = function(e) e
    )

    if (inherits(build, "error")) {
      # Offline (or vendor API down): fall back to a matching archive that was
      # downloaded earlier, otherwise report the original error
      cached <- if (backend == "native" && !force) {
        find_cached_native_distrib(dest_dir, version, distribution, platform, arch)
      }
      if (is.null(cached)) {
        stop(build)
      }
      if (!quiet) {
        cli::cli_alert_warning(
          "Could not reach the {distribution} download service ({conditionMessage(build)}). Using cached archive {.file {basename(cached)}}."
        )
      }
      result_path <- cached
    } else {
      filename <- if (backend == "native") {
        paste0("native-", build$filename)
      } else {
        build$filename
      }
      dest <- file.path(dest_dir, filename)

      # Download and verify
      result_path <- download_java_with_checksum(build, dest, quiet, force)
    }
  }

  # Attach metadata attributes for downstream functions
  attr(result_path, "distribution") <- distribution
  attr(result_path, "backend") <- backend
  attr(result_path, "version") <- version
  attr(result_path, "platform") <- platform
  attr(result_path, "arch") <- arch

  result_path
}

#' Download and verify checksum
#'
#' Internal function to download a Java distribution and verify its checksum
#'
#' @param build A java_build object containing download metadata
#' @param dest Destination file path
#' @param quiet Logical, suppress messages
#' @param force Logical, overwrite existing files
#'
#' @return Path to downloaded file
#' @keywords internal
download_java_with_checksum <- function(build, dest, quiet, force) {
  # Check if file already exists
  if (file.exists(dest) && !force) {
    if (!quiet) {
      cli::cli_inform("File already cached: {basename(dest)}")
    }
    return(dest)
  }

  # Remove existing file if force=TRUE
  if (file.exists(dest) && force) {
    if (!quiet) {
      cli::cli_inform("Removing existing file...")
    }
    unlink(dest)
  }

  # Download
  if (!quiet) {
    cli::cli_inform("Downloading {build$vendor} Java {build$major}...")
  }
  curl::curl_download(build$download_url, dest, quiet = quiet)

  # Verify checksum if available
  if (!is.null(build$checksum) && !is.null(build$checksum_type)) {
    if (!quiet) {
      cli::cli_inform("Verifying {build$checksum_type} checksum...")
    }

    actual <- switch(
      build$checksum_type,
      "md5" = tools::md5sum(dest),
      "sha256" = digest::digest(dest, algo = "sha256", file = TRUE),
      "sha512" = digest::digest(dest, algo = "sha512", file = TRUE),
      NULL
    )

    if (!is.null(actual) && actual != build$checksum) {
      unlink(dest)
      cli::cli_abort("{build$checksum_type} checksum mismatch! File deleted.")
    }

    if (!quiet) cli::cli_inform("Checksum verified.")
  } else if (build$backend == "sdkman") {
    if (!quiet) {
      cli::cli_alert_warning("Skipping checksum (unavailable for SDKMAN)")
    }
  }

  dest
}

#' Find a previously downloaded native archive without network access
#'
#' Temurin and Zulu archive names depend only on the request. Corretto archive
#' names carry the full build (e.g. `amazon-corretto-21.0.9.10.1-linux-x64`),
#' so the newest cached build of the requested version is used. Archives saved
#' by rJavaEnv < 0.4.0 (`amazon-corretto-21-x64-linux-jdk.tar.gz`) are also
#' recognised for major-version requests.
#'
#' @param dest_dir The `distrib` folder of the cache.
#' @inheritParams java_download
#' @return Path to the cached archive, or `NULL` if none matches.
#' @keywords internal
#' @noRd
find_cached_native_distrib <- function(dest_dir, version, distribution, platform, arch) {
  files <- list.files(dest_dir)
  if (length(files) == 0) {
    return(NULL)
  }
  version <- as.character(version)
  ext <- get_java_archive_extension(platform)

  if (distribution %in% c("Temurin", "Zulu")) {
    filename <- sprintf(
      "native-%s-%s-%s-%s.%s",
      tolower(distribution), version, platform, arch, ext
    )
    return(if (filename %in% files) file.path(dest_dir, filename))
  }
  if (distribution != "Corretto") {
    return(NULL)
  }

  escape <- function(x) gsub("([.+])", "\\\\\\1", x)
  corretto_platform <- if (platform == "macos") "macosx" else platform
  pattern <- sprintf(
    "^native-amazon-corretto-([0-9][0-9.]*[0-9])-%s-%s(-jdk)?\\.%s$",
    escape(corretto_platform), escape(arch), escape(ext)
  )
  hits <- grep(pattern, files, value = TRUE)
  builds <- sub(pattern, "\\1", hits)
  keep <- builds == version | startsWith(builds, paste0(version, "."))
  hits <- hits[keep]
  builds <- builds[keep]
  if (length(hits) > 0) {
    newest <- order(numeric_version(builds), decreasing = TRUE)[1]
    return(file.path(dest_dir, hits[newest]))
  }

  legacy <- sprintf("amazon-corretto-%s-%s-%s-jdk.%s", version, arch, platform, ext)
  if (grepl("^[0-9]+$", version) && legacy %in% files) {
    return(file.path(dest_dir, legacy))
  }
  NULL
}

#' Get extension for platform
#' @keywords internal
get_java_archive_extension <- function(platform) {
  if (platform == "windows") "zip" else "tar.gz"
}
