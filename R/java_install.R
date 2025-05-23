#' Install Java from a distribution file
#'
#' @description
#' Unpack Java distribution file into cache directory and link the installation into a project directory, optionally setting the `JAVA_HOME` and `PATH` environment variables to the Java version that was just installed.
#'
#' @param java_distrib_path A `character` vector of length 1 containing the path to the Java distribution file.
#' @param project_path A `character` vector of length 1 containing the project directory where Java should be installed. If not specified or `NULL`, defaults to the current working directory.
#' @param autoset_java_env A `logical` indicating whether to set the `JAVA_HOME` and `PATH` environment variables to the installed Java directory. Defaults to `TRUE`.
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
  autoset_java_env = TRUE,
  quiet = FALSE
) {
  rje_consent_check()

  # Resolve the project path
  # consistent with renv behavior
  # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86
  project_path <- ifelse(is.null(project_path), getwd(), project_path)

  installed_path <- java_unpack(
    java_distrib_path = java_distrib_path,
    quiet = quiet
  )

  platforms <- c("windows", "linux", "macos")
  architectures <- c("x64", "aarch64", "arm64")
  java_versions <- java_valid_versions()

  # Extract information from the file name
  filename <- basename(java_distrib_path)
  parts <- strsplit(gsub("\\.tar\\.gz|\\.zip", "", filename), "-")[[1]]

  # Guess the version, architecture, and platform
  version <- parts[vapply(parts, function(x) x %in% java_versions, logical(1))][
    1
  ]
  arch <- parts[vapply(parts, function(x) x %in% architectures, logical(1))][1]
  platform <- parts[vapply(parts, function(x) x %in% platforms, logical(1))][1]

  # Create a symlink in the project directory
  project_version_path <- file.path(
    project_path,
    "rjavaenv",
    platform,
    arch,
    version
  )
  if (!dir.exists(dirname(project_version_path))) {
    dir.create(dirname(project_version_path), recursive = TRUE)
  }

  link_success <- FALSE
  if (.Platform$OS.type == "windows") {
    try(
      {
        if (file.exists(project_version_path)) {
          unlink(project_version_path, recursive = TRUE)
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
      if (!quiet)
        cli::cli_inform(
          "Junction creation failed. This is likely because the project directory is not on the same disk as the R package cache directory. Java files will instead be copied to {.path {project_version_path}}"
        )
      dir.create(project_version_path, recursive = TRUE)
      file.copy(
        installed_path,
        project_version_path,
        recursive = TRUE,
        overwrite = TRUE
      )
      if (!quiet)
        cli::cli_inform("Java copied to project {.path {project_version_path}}")
    }
  } else {
    tryCatch(
      {
        if (file.exists(project_version_path)) {
          unlink(project_version_path, recursive = TRUE)
        }
        file.symlink(installed_path, project_version_path)
      },
      warning = function(w) {
        if (!quiet) cli::cli_inform("Warning: {w}")
      },
      error = function(e) {
        if (!quiet) cli::cli_inform("Error: {e}")
        dir.create(project_version_path, recursive = TRUE)
        file.copy(
          installed_path,
          project_version_path,
          recursive = TRUE,
          overwrite = TRUE
        )
        if (!quiet)
          cli::cli_inform(
            "Symlink creation failed. Files copied to {.path {project_version_path}}"
          )
      }
    )
  }

  # Write the JAVA_HOME to the .Rprofile and environment after installation
  if (autoset_java_env) {
    java_env_set(
      installed_path,
      where = "both",
      quiet = quiet,
      project_path = project_path
    )
  }

  if (!quiet)
    cli::cli_inform(
      "Java {version} ({filename}) for {platform} {arch} installed at {.path {installed_path}} and symlinked to {.path {project_version_path}}",
      .envir = environment()
    )
  return(installed_path)
}
