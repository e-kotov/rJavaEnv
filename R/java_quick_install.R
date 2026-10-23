#' Download and install and set Java in current working/project directory
#'
#' @description
#' Downloads, unpacks and links Java into the project, then sets `JAVA_HOME` and `PATH`. If the requested Java is already installed in the cache (including installs made by rJavaEnv 0.3.0), it is linked into the project without downloading it again.
#'
#' @inheritParams java_download
#' @inheritParams java_install
#' @inheritParams global_backend_param
#' @inheritParams global_quiet_param
#' @return Invisibly returns the path to the Java home directory. If quiet is set to `FALSE`, also prints a message indicating that Java was installed and set in the current working/project directory.
#' @export
#'
#' @examples
#' \donttest{
#'
#' # quick download, unpack, install and set in current working directory default Java version (21)
#' java_quick_install(17, temp_dir = TRUE)
#' }
java_quick_install <- function(
  version = 21,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  project_path = NULL,
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
  temp_dir = FALSE
) {
  rje_consent_check()

  if (temp_dir) {
    # Use session temp directory
    temp_path <- tempdir()

    cache_path <- file.path(temp_path, "rJavaEnv_cache")
    if (!dir.exists(cache_path)) {
      dir.create(cache_path, recursive = TRUE)
    }

    project_path <- file.path(temp_path, "rJavaEnv_project")
    if (!dir.exists(project_path)) {
      dir.create(project_path, recursive = TRUE)
    }
  } else {
    cache_path <- getOption("rJavaEnv.cache_path")
  }

  # Reuse an installed Java (including legacy pre-0.4.0 Corretto installs)
  # instead of downloading and unpacking it again
  version <- as.character(version)
  if (is_sdkman_identifier(version)) {
    backend <- "sdkman"
    distribution <- sdkman_vendor_to_distribution(sdkman_vendor_code(version))
  }
  found <- java_find_installed(version, distribution, backend, platform, arch, cache_path)
  if (!is.null(found)) {
    # Link layout mirrors the install's folders below installed/ (3 or 5 levels)
    installed_root <- file.path(cache_path, "installed")
    layout <- strsplit(
      substring(found$path, nchar(installed_root) + 2L),
      "[/\\\\]"
    )[[1]]
    if (!quiet) {
      cli::cli_inform("Java {version} found in cache, skipping download.")
    }
    return(invisible(java_link_project(
      installed_path = found$path,
      layout = layout,
      project_path = project_path %||% getwd(),
      autoset_java_env = TRUE,
      quiet = quiet,
      source = "cached"
    )))
  }

  java_distrib_path <- java_download(
    version = version,
    distribution = distribution,
    backend = backend,
    cache_path = cache_path,
    platform = platform,
    arch = arch,
    quiet = quiet
  )

  java_home <- java_install(
    java_distrib_path,
    project_path = project_path,
    autoset_java_env = TRUE,
    quiet = quiet
  )
  return(invisible(java_home))
}
