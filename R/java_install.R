#' Install Java from a distribution file
#'
#' @param java_path The path to the Java distribution file.
#' @param project_path The project directory where Java should be installed. Defaults to the current working directory.
#' @param autoset_java_env Whether to set the JAVA_HOME and PATH environment variables to the installed Java directory. Defaults to TRUE.
#' @param verbose Whether to print detailed messages. Defaults to TRUE.
#' @return The path to the installed Java directory.
#' @export
#'
#' @examples
#' \dontrun{
#' java_install("path/to/any-java-17-aarch64-macos-jdk.tar.gz")
#' }
java_install <- function(
  java_path,
  project_path = NULL,
  autoset_java_env = TRUE,
  verbose = TRUE) {
  platforms <- c("windows", "linux", "macos")
  architectures <- c("x64", "aarch64", "arm64")
  java_versions <- c("8", "11", "17", "21", "22")

  # Resolve the project path
  project_path <- ifelse(is.null(project_path), getwd(), project_path)

  # Extract information from the file name
  filename <- basename(java_path)
  parts <- strsplit(gsub("\\.tar\\.gz|\\.zip", "", filename), "-")[[1]]

  # Guess the version, architecture, and platform
  version <- parts[vapply(parts, function(x) x %in% java_versions, logical(1))][1]
  arch <- parts[vapply(parts, function(x) x %in% architectures, logical(1))][1]
  platform <- parts[vapply(parts, function(x) x %in% platforms, logical(1))][1]

  if (is.na(version)) stop(cli::cli_abort("Unable to detect Java version from filename.", .envir = environment()))
  if (is.na(arch)) stop(cli::cli_abort("Unable to detect architecture from filename.", .envir = environment()))
  if (is.na(platform)) stop(cli::cli_abort("Unable to detect platform from filename.", .envir = environment()))

  # Create the installation path in the package cache
  cache_dir <- tools::R_user_dir("rJavaEnv", which = "cache")
  installed_path <- file.path(cache_dir, "installed", platform, arch, version)

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
    file.copy(list.files(extracted_dir, full.names = TRUE), installed_path, recursive = TRUE)

    # Clean up temporary directory
    unlink(temp_dir, recursive = TRUE)
  } else {
    if (verbose) cli::cli_inform("Java distribution {filename} already unpacked at {.path {installed_path}}")
  }

  # Create a symlink in the project directory
  project_version_path <- file.path(project_path, "rjavaenv", platform, arch, version)
  if (!dir.exists(dirname(project_version_path))) {
    dir.create(dirname(project_version_path), recursive = TRUE)
  }

  link_success <- FALSE
  if (.Platform$OS.type == "windows") {
    try(
      {
        cmd <- sprintf("mklink /J \"%s\" \"%s\"", gsub("/", "\\\\", project_version_path), gsub("/", "\\\\", installed_path))
        result <- tryCatch(
          system2("cmd.exe", args = c("/c", cmd), stdout = TRUE, stderr = TRUE),
          warning = function(w) {
            # if (verbose) cli::cli_inform("Warning: {w}")
            NULL
          },
          error = function(e) {
            # if (verbose) cli::cli_inform("Error: {e}")
            NULL
          }
        )
        if (!is.null(result) && any(grepl("Junction created", result))) {
          link_success <- TRUE
        }
      },
      silent = TRUE
    )
    if (!link_success) {
      if (verbose) cli::cli_inform("Junction creation failed. This is likely because the project directory is not on the same disk as the R package cache directory. Java files will instead be copied to {.path {project_version_path}}")
      dir.create(project_version_path, recursive = TRUE)
      file.copy(installed_path, project_version_path, recursive = TRUE, overwrite = TRUE)
      if (verbose) cli::cli_inform("Java copied to project {.path {project_version_path}}")
    }
  } else {
    tryCatch(
      {
        file.symlink(installed_path, project_version_path)
      },
      warning = function(w) {
        if (verbose) cli::cli_inform("Warning: {w}")
      },
      error = function(e) {
        if (verbose) cli::cli_inform("Error: {e}")
        dir.create(project_version_path, recursive = TRUE)
        file.copy(installed_path, project_version_path, recursive = TRUE, overwrite = TRUE)
        if (verbose) cli::cli_inform("Symlink creation failed. Files copied to {.path {project_version_path}}")
      }
    )
  }



  # Write the JAVA_HOME to the .Rprofile and environment after installation
  if (autoset_java_env) {
    java_env_set(installed_path, verbose = verbose)
  }

  if (verbose) cli::cli_inform("Java {version} ({filename}) for {platform} {arch} installed at {.path {installed_path}} and symlinked to {.path {project_version_path}}", .envir = environment())
  return(installed_path)
}
