#' Known SDKMAN vendor codes
#'
#' Returns vector of known SDKMAN vendor suffixes extracted from java_list_available().
#' Used for robust SDKMAN identifier detection.
#'
#' @return Character vector of vendor codes
#' @keywords internal
known_sdkman_vendors <- function() {
  c(
    "albba",
    "amzn",
    "bisheng",
    "gln",
    "graal",
    "graalce",
    "jbr",
    "kona",
    "librca",
    "mandrel",
    "ms",
    "nik",
    "open",
    "oracle",
    "sapmchn",
    "sem",
    "tem",
    "trava",
    "zulu"
  )
}

#' Check if version string is a SDKMAN identifier
#'
#' Uses two-step detection:
#' 1. Primary: Check if ends with known vendor suffix
#' 2. Fallback: Regex pattern for unknown future vendors
#'
#' @param version Version string to check
#' @return Logical
#' @keywords internal
is_sdkman_identifier <- function(version) {
  if (!grepl("-", version)) {
    return(FALSE)
  }

  suffix <- sub(".*-", "", version)

  # Primary: known vendor
  if (suffix %in% known_sdkman_vendors()) {
    return(TRUE)
  }

  # Fallback: regex pattern for unknown future vendors
  # Pattern: starts with digit, allows digits/dots/letters/plus/hyphen, ends with hyphen + at least 2 letters
  grepl("^[0-9][0-9a-zA-Z.+_-]*-[a-z]{2,}$", version)
}

#' Extract vendor code from SDKMAN identifier
#'
#' @param identifier SDKMAN identifier (e.g., "25.0.1-amzn")
#' @return Vendor code (e.g., "amzn")
#' @keywords internal
sdkman_vendor_code <- function(identifier) {
  sub(".*-", "", identifier)
}

#' Map SDKMAN vendor code to distribution name
#'
#' Uses reverse mapping from java_config.yaml. Issues warning for unknown vendors.
#'
#' @param vendor_code SDKMAN vendor code (e.g., "amzn", "tem")
#' @return Distribution name (e.g., "Corretto", "Temurin")
#' @keywords internal
sdkman_vendor_to_distribution <- function(vendor_code) {
  cfg <- java_config("sdkman")

  if (is.null(cfg) || is.null(cfg$vendor_reverse_map)) {
    cli::cli_abort("SDKMAN configuration not found in java_config.yaml")
  }

  dist <- cfg$vendor_reverse_map[[vendor_code]]

  if (is.null(dist)) {
    cli::cli_warn(
      "Unknown SDKMAN vendor: {.val {vendor_code}}. Using as distribution name."
    )
    return(vendor_code)
  }

  dist
}

#' Map distribution name to SDKMAN vendor code
#'
#' Uses reverse lookup on vendor_reverse_map with fallback to vendor_map.
#' Case-insensitive matching.
#'
#' @param distribution Distribution name (e.g., "Corretto", "Temurin", "microsoft")
#' @return Vendor code (e.g., "amzn", "tem", "ms") or NULL if not found
#' @keywords internal
sdkman_distribution_to_vendor <- function(distribution) {
  cfg <- java_config("sdkman")
  if (is.null(cfg)) {
    return(NULL)
  }

  # Try explicit vendor_map first
  if (!is.null(cfg$vendor_map[[distribution]])) {
    return(cfg$vendor_map[[distribution]])
  }

  # Case-insensitive match against vendor_map
  vmap_names <- names(cfg$vendor_map)
  match_idx <- which(tolower(vmap_names) == tolower(distribution))
  if (length(match_idx) > 0) {
    return(cfg$vendor_map[[match_idx[1]]])
  }

  # Case-insensitive match on distribution names in vendor_reverse_map
  rev_map <- cfg$vendor_reverse_map
  if (!is.null(rev_map)) {
    rev_values <- unlist(rev_map)
    match_idx <- which(tolower(rev_values) == tolower(distribution))
    if (length(match_idx) > 0) {
      return(names(rev_values)[match_idx[1]])
    }
    # Also match if distribution is already the short vendor code
    if (tolower(distribution) %in% tolower(names(rev_map))) {
      return(tolower(distribution))
    }
  }

  NULL
}

#' Parse SDKMAN identifiers into structured data frame
#'
#' @param identifiers Character vector of SDKMAN identifiers (e.g., "21.0.12-amzn")
#' @param platform Platform OS
#' @param arch Architecture
#' @return data.frame with standard columns
#' @keywords internal
sdkman_parse_identifiers <- function(identifiers, platform, arch) {
  empty_df <- data.frame(
    backend = character(0),
    vendor = character(0),
    major = integer(0),
    version = character(0),
    platform = character(0),
    arch = character(0),
    identifier = character(0),
    checksum_available = logical(0),
    stringsAsFactors = FALSE
  )

  if (length(identifiers) == 0) {
    return(empty_df)
  }

  identifiers <- trimws(identifiers)
  identifiers <- identifiers[nzchar(identifiers)]
  if (length(identifiers) == 0) {
    return(empty_df)
  }

  cfg <- java_config("sdkman")
  rev_map <- if (!is.null(cfg)) cfg$vendor_reverse_map else list()

  res <- lapply(identifiers, function(id) {
    v_code <- sub(".*-", "", id)
    v_name <- if (!is.null(rev_map[[v_code]])) rev_map[[v_code]] else v_code
    ver_str <- sub("-[^-]+$", "", id)
    major_num <- as.integer(sub("^([0-9]+).*", "\\1", ver_str))

    data.frame(
      backend = "sdkman",
      vendor = v_name,
      major = major_num,
      version = ver_str,
      platform = platform,
      arch = arch,
      identifier = id,
      checksum_available = FALSE,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, res)
}
