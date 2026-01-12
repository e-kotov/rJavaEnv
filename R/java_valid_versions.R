#' Get valid Java versions without network overhead
#'
#' @description
#' Returns a list of valid Java versions from the fastest available source.
#' This function never triggers a network call. It checks:
#' 1. Session cache (current options)
#' 2. Persistent file cache (24 hours)
#' 3. Shipped fallback list for the current platform
#'
#' This is useful for offline workflows or when parsing filenames.
#'
#' @return A character vector of valid Java versions.
#'
#' @keywords internal
java_valid_versions_fast <- function() {
  # 1. Try session cache (current options)
  opt_cache <- getOption("rJavaEnv.valid_versions_cache")
  if (!is.null(opt_cache)) {
    return(opt_cache)
  }

  # 2. Try persistent file cache
  cache_path <- getOption("rJavaEnv.cache_path")
  cache_file <- file.path(cache_path, "valid_versions.json")

  if (file.exists(cache_file)) {
    # Check if file is less than 24 hours old
    info <- file.info(cache_file)
    age_hours <- as.numeric(difftime(Sys.time(), info$mtime, units = "hours"))
    if (age_hours < 24) {
      tryCatch(
        {
          cached_vers <- RcppSimdJson::fload(cache_file)
          return(as.character(unlist(cached_vers)))
        },
        error = function(e) {
          # If file is corrupt, continue to fallback
          NULL
        }
      )
    }
  }

  # 3. Return Fallback (Shipped with package)
  plat <- platform_detect(quiet = TRUE)
  platform_arch <- paste(plat$os, plat$arch, sep = "_")
  fallback <- getOption(paste0(
    "rJavaEnv.fallback_valid_versions_",
    platform_arch
  ))
  if (is.null(fallback)) {
    # Fallback to a basic list if option not set
    fallback <- c("8", "11", "17", "21")
  }
  return(fallback)
}

#' Retrieve Valid Java Versions
#'
#' This function retrieves a list of valid Java versions by querying an appropriate API endpoint based on the chosen distribution.
#' The result is cached across sessions via file cache (24 hours) and within a session in memory (8 hours) to avoid repeated API calls.
#' If the API call fails (for example, due to a lack of internet connectivity),
#' the function falls back to a pre-defined list of Java versions.
#'
#' @inheritParams java_download
#'
#' @param force Logical. If TRUE, forces a fresh API call even if a cached value exists. Defaults to FALSE.
#'
#' @return A character vector of valid Java versions.
#'
#' @examples
#' \dontrun{
#'   # Retrieve valid Java versions (cached if available) using Amazon Corretto endpoint
#'   versions <- java_valid_versions()
#'
#'   # Force refresh the list of Java versions using the Oracle endpoint
#'   versions <- java_valid_versions(distribution = "Corretto", force = TRUE)
#' }
#'
#' @export
#'
java_valid_versions <- function(
  distribution = "Corretto",
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  force = FALSE
) {
  # Define cache expiry times
  session_expiry_hours <- 8
  file_expiry_hours <- 24

  # 1. Check session cache (fastest)
  cache_key <- sprintf("%s_%s_%s", distribution, platform, arch)

  valid_versions_cache <- getOption(
    "rJavaEnv.valid_versions_cache_list",
    list()
  )
  valid_versions_timestamp <- getOption(
    "rJavaEnv.valid_versions_timestamp_list",
    list()
  )

  if (
    !force &&
      !is.null(valid_versions_cache[[cache_key]]) &&
      !is.null(valid_versions_timestamp[[cache_key]]) &&
      as.numeric(difftime(
        Sys.time(),
        valid_versions_timestamp[[cache_key]],
        units = "hours"
      )) <
        session_expiry_hours
  ) {
    return(valid_versions_cache[[cache_key]])
  }

  # 2. Check Persistent File Cache (Cross-session)
  # Only use if force=FALSE. If force=TRUE, we want fresh network data.
  cache_path <- getOption("rJavaEnv.cache_path")
  cache_file <- file.path(
    cache_path,
    sprintf("valid_versions_%s.json", cache_key)
  )

  if (!force && file.exists(cache_file)) {
    info <- file.info(cache_file)
    age_hours <- as.numeric(difftime(Sys.time(), info$mtime, units = "hours"))
    if (age_hours < file_expiry_hours) {
      tryCatch(
        {
          cached_vers <- RcppSimdJson::fload(cache_file)
          # Ensure consistent character vector output
          cached_vers <- as.character(unlist(cached_vers))

          # Update session options so we don't read file every time
          valid_versions_cache[[cache_key]] <- cached_vers
          valid_versions_timestamp[[cache_key]] <- Sys.time()

          options(
            rJavaEnv.valid_versions_cache_list = valid_versions_cache,
            rJavaEnv.valid_versions_timestamp_list = valid_versions_timestamp
          )
          return(cached_vers)
        },
        error = function(e) {
          # If file is corrupt, continue to network fetch
          NULL
        }
      )
    }
  }

  # 3. Fetch from Network
  new_versions <- tryCatch(
    {
      switch(
        distribution,
        "Corretto" = java_valid_major_versions_corretto(
          platform = platform,
          arch = arch
        ),
        "Temurin" = java_valid_major_versions_temurin(
          platform = platform,
          arch = arch
        ),
        "Zulu" = java_valid_major_versions_zulu(
          platform = platform,
          arch = arch
        ),
        stop("Unsupported distribution")
      )
    },
    error = function(e) {
      # Fallback to shipped list on network error
      platform_arch <- paste(platform, arch, sep = "_")
      getOption(paste0("rJavaEnv.fallback_valid_versions_", platform_arch))
    }
  )

  # 4. Save to caches
  # Update session cache
  valid_versions_cache[[cache_key]] <- new_versions
  valid_versions_timestamp[[cache_key]] <- Sys.time()

  options(
    rJavaEnv.valid_versions_cache_list = valid_versions_cache,
    rJavaEnv.valid_versions_timestamp_list = valid_versions_timestamp
  )

  # Save to persistent disk cache if directory exists
  if (dir.exists(cache_path)) {
    try(
      writeLines(
        sprintf('[%s]', paste0('"', new_versions, '"', collapse = ", ")),
        cache_file
      ),
      silent = TRUE
    )
  }

  return(new_versions)
}

#' Get Available Online Versions of Amazon Corretto
#'
#' This function downloads the latest Amazon Corretto version information from the
#' Corretto GitHub endpoint and returns a data frame with details for all eligible releases.
#'
#' It leverages the existing \code{platform_detect()} function to infer the current operating
#' system and architecture if these are not provided.
#'
#' @param arch Optional character string for the target architecture (e.g., "x64").
#'   If \code{NULL}, it is inferred using \code{platform_detect()}.
#' @param platform Optional character string for the operating system (e.g., "windows", "macos", "linux").
#'   If \code{NULL}, it is inferred using \code{platform_detect()}.
#' @param imageType Optional character string to filter on; defaults to \code{"jdk"}. Can be set to \code{"jre"} for Windows Java Runtime Environment.
#'
#' @return A `character` vector of available major Corretto versions.
#'
#' @keywords internal
#'
java_valid_major_versions_corretto <- function(
  arch = NULL,
  platform = NULL,
  imageType = "jdk"
) {
  # If platform or arch are not provided, detect them using the existing function.
  if (is.null(platform) || is.null(arch)) {
    plat <- platform_detect(quiet = TRUE)
    if (is.null(platform)) {
      platform <- plat$os
    }
    if (is.null(arch)) arch <- plat$arch
  }

  # URL for the Corretto version information.
  availableVersionsUrl <- "https://corretto.github.io/corretto-downloads/latest_links/indexmap_with_checksum.json"

  # Fetch and parse the JSON.
  corretto_versions <- tryCatch(
    {
      json_data <- read_json_url(
        availableVersionsUrl,
        max_simplify_lvl = "list"
      )
      eligible <- json_data[[platform]][[arch]][[imageType]]
      if (is.null(eligible)) {
        stop(
          "No eligible versions found for the specified platform, architecture, and image type."
        )
      }
      names(eligible)
    },
    error = function(e) {
      platform_arch <- paste(platform, arch, sep = "_")
      getOption(paste0("rJavaEnv.fallback_valid_versions_", platform_arch))
    }
  )

  corretto_versions <- as.character(sort(as.numeric(corretto_versions)))
  return(corretto_versions)
}

#' Get Available Online Versions of Adoptium Temurin
#'
#' @keywords internal
java_valid_major_versions_temurin <- function(arch = NULL, platform = NULL) {
  # Note: The 'available_releases' endpoint lists *all* versions, regardless of platform/arch.
  # This serves as a quick check for valid version numbers.
  url <- "https://api.adoptium.net/v3/info/available_releases"
  response <- read_json_url(url)
  as.character(response$available_releases)
}

#' Get Available Online Versions of Azul Zulu
#'
#' @keywords internal
java_valid_major_versions_zulu <- function(
  arch = NULL,
  platform = NULL,
  imageType = "jdk"
) {
  if (is.null(platform) || is.null(arch)) {
    plat <- platform_detect(quiet = TRUE)
    if (is.null(platform)) {
      platform <- plat$os
    }
    if (is.null(arch)) arch <- plat$arch
  }

  # Map to Azul naming conventions
  os_map <- c("macos" = "macos", "linux" = "linux", "windows" = "windows")
  arch_map <- c("x64" = "x86", "aarch64" = "arm")

  zul_os <- os_map[platform]
  zul_arch <- arch_map[arch]

  if (is.na(zul_os) || is.na(zul_arch)) {
    return(character(0))
  }

  params <- list(
    os = zul_os,
    arch = zul_arch,
    java_package_type = imageType,
    release_status = "ga",
    availability_types = "CA",
    page_size = 100
  )

  # Construct query string manually
  query_params <- vapply(
    names(params),
    function(key) {
      val <- params[[key]]
      paste0(key, "=", utils::URLencode(as.character(val), reserved = TRUE))
    },
    character(1)
  )

  query_string <- paste(query_params, collapse = "&")
  url <- paste0(
    "https://api.azul.com/metadata/v1/zulu/packages/?",
    query_string
  )

  data <- read_json_url(url, max_simplify_lvl = "list")

  # Extract java_version fields (which are lists like [21, 0, 4])
  versions <- unique(sapply(data, function(x) x$java_version[[1]]))
  as.character(sort(versions))
}

# Helper function for Oracle distribution
# java_valid_versions_oracle <- function() {
#   oracle_api_url <- "https://java.oraclecloud.com/javaVersions"
#   tryCatch(
#     {
#       oracle_java_versions <- jsonlite::fromJSON(
#         oracle_api_url,
#         simplifyDataFrame = TRUE
#       )
#       # Combine "8" and "11" with the sorted versions from the API
#       c("8", "11", sort(as.character(oracle_java_versions$items$jdkVersion)))
#     },
#     error = function(e) {
#       # If the API call fails, use the fallback list stored in options.
#       getOption("rJavaEnv.fallback_valid_versions_current_platform")
#     }
#   )
# }
