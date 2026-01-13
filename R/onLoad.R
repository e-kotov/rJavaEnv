.onLoad <- function(libname, pkgname) {
  # Load YAML config
  config_path <- system.file(
    "extdata",
    "java_config.yaml",
    package = "rJavaEnv"
  )
  if (file.exists(config_path)) {
    config <- yaml::read_yaml(config_path)
    options(rJavaEnv.config = config)
  }

  op <- options()
  op.rJavaEnv <- list(
    # Default folder choice (in line with renv package)
    rJavaEnv.cache_path = tools::R_user_dir("rJavaEnv", which = "cache"),
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.valid_versions_timestamp = NULL,
    # Fallback lists for various platforms
    rJavaEnv.fallback_valid_versions_macos_aarch64 = c(
      "8",
      "11",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24",
      "25"
    ),
    rJavaEnv.fallback_valid_versions_macos_x64 = c(
      "8",
      "11",
      "15",
      "16",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24",
      "25"
    ),
    rJavaEnv.fallback_valid_versions_linux_aarch64 = c(
      "8",
      "11",
      "15",
      "16",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24",
      "25"
    ),
    rJavaEnv.fallback_valid_versions_linux_x64 = c(
      "8",
      "11",
      "15",
      "16",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24",
      "25"
    ),
    rJavaEnv.fallback_valid_versions_windows_x64 = c(
      "8",
      "11",
      "15",
      "16",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24",
      "25"
    ),
    rJavaEnv.fallback_valid_versions_windows_x86 = c(
      "8",
      "11"
    ),
    rJavaEnv.fallback_valid_versions_temurin = c(
      "8",
      "11",
      "17",
      "21",
      "22",
      "23",
      "24",
      "25"
    ),
    rJavaEnv.fallback_valid_versions_zulu = c(
      "8",
      "11",
      "13",
      "15",
      "17",
      "19",
      "21",
      "22",
      "23",
      "24",
      "25"
    )
  )

  # Only set the options that haven't been defined yet
  toset <- !(names(op.rJavaEnv) %in% names(op))
  if (any(toset)) {
    options(op.rJavaEnv[toset])
  }

  # Now, detect the current platform (OS and architecture)
  platform <- platform_detect(quiet = TRUE)

  # Build the option name dynamically based on platform$os and platform$arch.
  # For example, for macOS on x64, this results in "rJavaEnv.fallback_valid_versions_macos_x64"
  fallback_option_name <- paste0(
    "rJavaEnv.fallback_valid_versions_",
    platform$os,
    "_",
    platform$arch
  )

  # Retrieve the corresponding fallback list using getOption()
  fallback_current <- getOption(fallback_option_name)

  # Set the current platform valid versions option
  options(rJavaEnv.fallback_valid_versions_current_platform = fallback_current)

  invisible()
}

#' Access Java configuration from YAML
#'
#' Helper function to access configuration loaded from java_config.yaml
#'
#' @param key Optional key to retrieve specific config section. If NULL, returns entire config.
#' @return Configuration value or NULL if not found
#' @keywords internal
java_config <- function(key = NULL) {
  cfg <- getOption("rJavaEnv.config")
  if (is.null(key)) cfg else cfg[[key]]
}
