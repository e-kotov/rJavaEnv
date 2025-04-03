.onLoad <- function(libname, pkgname) {
  # Detect the current platform (OS and architecture)
  platform <- platform_detect(quiet = TRUE)

  # Select the fallback valid Java versions based on the detected platform
  fallback_current <- switch(
    paste(platform$os, platform$arch, sep = "_"),
    "macos_aarch64" = c(
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
    "macos_x64" = c(
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
    "linux_aarch64" = c(
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
    "linux_x64" = c(
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
    stop("Unsupported platform/architecture combination")
  )

  # Get current options
  op <- options()

  # Create list of rJavaEnv options including the current platform valid versions
  op.rJavaEnv <- list(
    # Default folder choice (in line with renv package)
    rJavaEnv.cache_path = tools::R_user_dir("rJavaEnv", which = "cache"),
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.valid_versions_timestamp = NULL,
    # Fallback lists for various platforms
    rJavaEnv.fallback_valid_versions_current_platform_macos_aarch64 = c(
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
    rJavaEnv.fallback_valid_versions_current_platform_macos_x64 = c(
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
    rJavaEnv.fallback_valid_versions_current_platform_linux_aarch64 = c(
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
    rJavaEnv.fallback_valid_versions_current_platform_linux_x64 = c(
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
    # Current platform valid versions
    rJavaEnv.fallback_valid_versions_current_platform_current_platform = fallback_current
  )

  # Only set the options that haven't been set yet
  toset <- !(names(op.rJavaEnv) %in% names(op))
  if (any(toset)) options(op.rJavaEnv[toset])

  invisible()
}
