#' Install Java from a distribution file
#'
#' @param java_path The path to the Java distribution file.
#' @param project The project directory where Java should be installed. Defaults to the current working directory.
#' @param autoset_java_path Whether to set the JAVA_HOME and PATH environment variables to the installed Java directory. Defaults to TRUE.
#' @return The path to the installed Java directory.
#' @export
#'
#' @examples
#' \dontrun{
#' java_install("path/to/any-java-17-aarch64-macos-jdk.tar.gz")
#' }
java_install <- function(java_path, project = NULL, autoset_java_path = TRUE) {

  platforms <- c("windows", "linux", "macos")
  architectures <- c("x64", "aarch64", "arm64")
  java_versions <- c("8", "11", "17", "21", "22")

  # Resolve the project path
  project <- ifelse(is.null(project), getwd(), project)

  # Extract information from the file name
  filename <- basename(java_path)
  parts <- strsplit(gsub("\\.tar\\.gz|\\.zip", "", filename), "-")[[1]]

  # Guess the version, architecture, and platform
  version <- parts[sapply(parts, function(x) x %in% java_versions)][1]
  arch <- parts[sapply(parts, function(x) x %in% architectures)][1]
  platform <- parts[sapply(parts, function(x) x %in% platforms)][1]

  if (is.na(version)) stop(cli::cli_abort("Unable to detect Java version from filename.", .envir = environment()))
  if (is.na(arch)) stop(cli::cli_abort("Unable to detect architecture from filename.", .envir = environment()))
  if (is.na(platform)) stop(cli::cli_abort("Unable to detect platform from filename.", .envir = environment()))

  # Create the installation path
  java_install_path <- file.path(project, "rjavaenv", platform, arch, version)

  # Create the directories if they don't exist
  if (!dir.exists(java_install_path)) {
    dir.create(java_install_path, recursive = TRUE)
  }

  # Determine extraction path based on platform
  if (platform == "macos") {
    extract_subdir <- "Contents/Home"
  } else {
    extract_subdir <- "."
  }

  # Extract the files
  temp_dir <- file.path(tempdir(), "java_temp")
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }

  dir.create(temp_dir)

  if (grepl("\\.tar\\.gz$", java_path)) {
    utils::untar(java_path, exdir = temp_dir)
  } else if (grepl("\\.zip$", java_path)) {
    utils::unzip(java_path, exdir = temp_dir)
  } else {
    stop(cli::cli_abort("Unsupported file format", .envir = environment()))
  }

  # Safely find the extracted directory
  extracted_root_dir <- list.files(temp_dir, full.names = TRUE)[1]
  if (platform == "macos") {
    extracted_dir <- file.path(extracted_root_dir, "Contents", "Home")
  } else {
    extracted_dir <- extracted_root_dir
  }

  # Move the extracted files to the installation path
  file.copy(list.files(extracted_dir, full.names = TRUE), java_install_path, recursive = TRUE)

  # Clean up temporary directory
  unlink(temp_dir, recursive = TRUE)

  # Write the JAVA_HOME to the .Rprofile and environment after installation
  if (autoset_java_path) {
    java_env_set(java_install_path)
  }

  cli::cli_inform("Java {version} ({filename}) for {platform} installed at {java_install_path}", .envir = environment())
  return(java_install_path)
}
