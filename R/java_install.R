#' Install Java from a distribution file
#'
#' @description
#' Unpack Java distribution file into cache directory and link the installation into a project directory, optionally setting the `JAVA_HOME` and `PATH` environment variables to the Java version that was just installed.
#'
#' @param java_distrib_path A `character` vector of length 1 containing the path to the Java distribution file.
#' @param project_path A `character` vector of length 1 containing the project directory where Java should be installed. If not specified or `NULL`, defaults to the current working directory.
#' @param distribution The Java distribution name (e.g., "Corretto", "Temurin"). If NULL, uses attributes from java_distrib_path or defaults to "unknown".
#' @param backend The download backend used (e.g., "native", "sdkman"). If NULL, uses attributes from java_distrib_path or defaults to "unknown".
#' @param autoset_java_env A `logical` indicating whether to set the `JAVA_HOME` and `PATH` environment variables to the installed Java directory. Defaults to `TRUE`.
#' @param force A logical. Whether to overwrite an existing installation. Defaults to `FALSE`.
#' @inheritParams java_download
#' @inheritParams global_quiet_param
#' @return The path to the installed Java directory.
#' @export
#'
#' @examples
#' \dontrun{
#'
#' # set cache dir to temporary directory
#' options(rJavaEnv.cache_path = tempdir())
#' # download, install and autoset environmnet variables for Java 17
#' java_17_distrib <- java_download(version = "17")
#' java_install(java_distrib_path = java_17_distrib, project_path = tempdir())
#' }
java_install <- function(
  java_distrib_path,
  project_path = NULL,
  distribution = NULL,
  backend = NULL,
  autoset_java_env = TRUE,
  quiet = FALSE,
  force = FALSE
) {
  rje_consent_check()

  # Resolve the project path
  # consistent with renv behavior
  # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
  project_path <- ifelse(is.null(project_path), getwd(), project_path)

  # Resolve distribution and backend from arguments or attributes
  if (is.null(distribution)) {
    distribution <- attr(java_distrib_path, "distribution")
    if (is.null(distribution)) distribution <- "unknown"
  }
  if (is.null(backend)) {
    backend <- attr(java_distrib_path, "backend")
    if (is.null(backend)) backend <- "unknown"
  }

  installed_path <- java_unpack(
    java_distrib_path = java_distrib_path,
    distribution = distribution,
    backend = backend,
    quiet = quiet,
    force = force
  )

  java_link_project(
    installed_path = installed_path,
    layout = utils::tail(strsplit(installed_path, "[/\\\\]")[[1]], 5),
    project_path = project_path,
    autoset_java_env = autoset_java_env,
    quiet = quiet,
    force = force,
    source = basename(java_distrib_path)
  )
}

#' Link a cached Java installation into a project
#'
#' Creates `<project>/rjavaenv/<layout>` as a symlink (junction on Windows, or a
#' copy if linking fails) to `installed_path`, and optionally writes `JAVA_HOME`
#' to the project's `.Rprofile`.
#'
#' @param installed_path Path to the installed Java home in the cache.
#' @param layout The cache path components below `installed/`:
#'   `platform/arch/distribution/backend/version`, or `platform/arch/version`
#'   for installs made before rJavaEnv 0.4.0.
#' @param source Label for the final message (archive name or cache path).
#' @inheritParams java_install
#' @return `installed_path`.
#' @keywords internal
#' @noRd
java_link_project <- function(
  installed_path,
  layout,
  project_path,
  autoset_java_env = TRUE,
  quiet = FALSE,
  force = FALSE,
  source = basename(installed_path)
) {
  platform <- layout[1]
  arch <- layout[2]
  version <- layout[length(layout)]

  # Create a symlink in the project directory, mirroring the cache layout
  project_version_path <- do.call(
    file.path,
    as.list(c(project_path, "rjavaenv", layout))
  )
  if (!dir.exists(dirname(project_version_path))) {
    dir.create(dirname(project_version_path), recursive = TRUE)
  }

  link_success <- FALSE
  if (.Platform$OS.type == "windows") {
    try(
      {
        if (nzchar(Sys.readlink(project_version_path)) || isTRUE(force)) {
          unlink(project_version_path, recursive = TRUE, force = TRUE)
        }
        cmd <- sprintf(
          "mklink /J \"%s\" \"%s\"",
          gsub("/", "\\\\", project_version_path),
          gsub("/", "\\\\", installed_path)
        )
        result <- tryCatch(
          system2("cmd.exe", args = c("/c", cmd), stdout = TRUE, stderr = TRUE),
          warning = function(w) {
            # if (!quiet) cli::cli_inform("Warning: {w}")
            NULL
          },
          error = function(e) {
            # if (!quiet) cli::cli_inform("Error: {e}")
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
      if (!quiet) {
        cli::cli_inform(
          "Junction creation failed. This is likely because the project directory is not on the same disk as the R package cache directory. Java files will instead be copied to {.path {project_version_path}}"
        )
      }
      dir.create(project_version_path, recursive = TRUE)
      file.copy(
        installed_path,
        project_version_path,
        recursive = TRUE,
        overwrite = TRUE
      )
      if (!quiet) {
        cli::cli_inform("Java copied to project {.path {project_version_path}}")
      }
    }
  } else {
    tryCatch(
      {
        if (nzchar(Sys.readlink(project_version_path)) || isTRUE(force)) {
          unlink(project_version_path, recursive = TRUE, force = TRUE)
        }
        file.symlink(installed_path, project_version_path)
        link_success <- TRUE
      },
      warning = function(w) {
        if (!quiet) cli::cli_inform("Warning: {w}")
      },
      error = function(e) {
        if (!quiet) {
          cli::cli_inform("Error: {e}")
        }
        dir.create(project_version_path, recursive = TRUE)
        file.copy(
          installed_path,
          project_version_path,
          recursive = TRUE,
          overwrite = TRUE
        )
        if (!quiet) {
          cli::cli_inform(
            "Symlink creation failed. Files copied to {.path {project_version_path}}"
          )
        }
      }
    )
  }

  # Write the JAVA_HOME to the .Rprofile and environment after installation
  if (autoset_java_env) {
    java_env_set(
      where = "both",
      java_home = installed_path,
      quiet = quiet,
      project_path = project_path
    )
  }

  if (!quiet) {
    cli::cli_inform(
      "Java {version} ({source}) for {platform} {arch} installed at {.path {installed_path}} and symlinked to {.path {project_version_path}}",
      .envir = environment()
    )
  }
  return(installed_path)
}
