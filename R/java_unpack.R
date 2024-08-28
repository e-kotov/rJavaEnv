#' Unpack a Java distribution file into cache directory
#' 
#' @description
#' Unpack the Java distribution file into cache directory and return the path to the unpacked Java directory with Java binaries.
#' 
#' 
#' @inheritParams java_install
#' @inheritParams global_quiet_param
#' @return A `character` vector containing of length 1 containing the path to the unpacked Java directory.
#' @export
#' @examples
#' \dontrun{
#' 
#' # set cache dir to temporary directory
#' options(rJavaEnv.cache_path = tempdir())
#' 
#' # download Java 17 distrib and unpack it into cache dir
#' java_17_distrib <- java_download(version = "17")
#' java_home <- java_unpack(java_distrib_path = java_17_distrib)
#' 
#' # set the JAVA_HOME environment variable in the current session
#' # to the cache dir without touching any files in the current project directory
#' java_env_set(where = "session", java_home = java_home)
#' }
#' 
java_unpack <- function(
  java_distrib_path,
  quiet = FALSE
) {
  platforms <- c("windows", "linux", "macos")
  architectures <- c("x64", "aarch64", "arm64")
  java_versions <- getOption("rJavaEnv.valid_major_java_versions")

  # Extract information from the file name
  filename <- basename(java_distrib_path)
  parts <- strsplit(gsub("\\.tar\\.gz|\\.zip", "", filename), "-")[[1]]

  # Guess the version, architecture, and platform
    version <- parts[parts %in% java_versions][1]
    arch <- parts[parts %in% architectures][1]
    platform <- parts[parts %in% platforms][1]

  if (is.na(version)) cli::cli_abort("Unable to detect Java version from filename.")
  if (is.na(arch)) cli::cli_abort("Unable to detect architecture from filename.")
  if (is.na(platform)) cli::cli_abort("Unable to detect platform from filename.")

  # Create the installation path in the package cache
  cache_path <- getOption("rJavaEnv.cache_path")
  installed_path <- file.path(cache_path, "installed", platform, arch, version)

  # Check if the distribution has already been unpacked
  if (!dir.exists(installed_path) || length(list.files(installed_path)) == 0) {
    # Create the directories if they don't exist
    if (!dir.exists(installed_path)) {
      dir.create(installed_path, recursive = TRUE)
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

    dir.create(temp_dir, recursive = TRUE)

    if (grepl("\\.tar\\.gz$", java_distrib_path)) {
      utils::untar(java_distrib_path, exdir = temp_dir)
    } else if (grepl("\\.zip$", java_distrib_path)) {
      utils::unzip(java_distrib_path, exdir = temp_dir)
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
    file.copy(list.files(extracted_dir, full.names = TRUE), installed_path, recursive = TRUE)

    # Clean up temporary directory
    unlink(temp_dir, recursive = TRUE)
  } else {
    if (!quiet) cli::cli_inform("Java distribution {filename} already unpacked at {.path {installed_path}}")
  }
  return(installed_path)
}
