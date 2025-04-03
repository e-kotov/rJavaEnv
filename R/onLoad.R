.onLoad <- function(libname, pkgname) {
  # First, set all the base rJavaEnv options
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
      "24"
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
      "24"
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
      "24"
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
      "24"
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
      "24"
    ),
    rJavaEnv.fallback_valid_versions_windows_x86 = c(
      "8",
      "11"
    )
  )

  # Only set the options that haven't been defined yet
  toset <- !(names(op.rJavaEnv) %in% names(op))
  if (any(toset)) options(op.rJavaEnv[toset])

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
