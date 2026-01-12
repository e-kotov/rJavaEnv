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
#'
#' @examples
#' \dontrun{
#' is_sdkman_identifier("25.0.1-amzn")    # TRUE
#' is_sdkman_identifier("26.ea.13-graal") # TRUE
#' is_sdkman_identifier("21")             # FALSE
#' is_sdkman_identifier("21.0.9")         # FALSE
#' is_sdkman_identifier("21.0.9+10-LTS") # FALSE (uppercase suffix)
#' }
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
  # Pattern: starts with digit, then digits/dots/lowercase, hyphen, then lowercase letters
  grepl("^[0-9]+[0-9.a-z]*-[a-z]+$", version)
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
