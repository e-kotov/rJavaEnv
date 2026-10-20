#' Ensure specific Java version is set
#'
#' @description
#' Checks for a specific Java version in the following order:
#' 1. Checks if the currently active session has the required version.
#' 2. (Optional) Scans system for installed Java (via `java_find_system`).
#' 3. Checks if the required version is already cached in `rJavaEnv`'s installed cache.
#' 4. If none found, downloads and installs the version (if `install = TRUE`).
#'
#' This function is designed to be "lazy": it will do nothing if a valid Java version
#' is already detected. It changes session environment variables when selecting
#' Java; call it explicitly before loading rJava, rather than in `.onLoad`.
#' `install = FALSE` prevents downloads but does not make setup read-only.
#'
#' @inheritSection rjava_path_locking_note rJava Path-Locking
#'
#' @section Additional Notes:
#' With `check_against = "rJava"`, an already running compatible JVM is accepted.
#' A loaded but uninitialized rJava namespace causes an error without starting its
#' JVM or changing environment variables. Restart R before setup in that case.
#' Experimental rJava builds with deferred loading permit selection while their
#' state API confirms that no JVM library has been loaded.
#' `check_against = "cmd"` configures command-line use only.
#'
#' @inheritParams global_version_param
#' @param type Character. `"exact"` (default) checks for exact version match. `"min"` checks for version >= `version`.
#' @param accept_system_java Logical. If `TRUE` (default), the function will scan the system for existing Java installations (using `JAVA_HOME`, `PATH`, and OS-specific locations). If a system Java matching the `version` and `type` requirements is found, it will be used. Set to `FALSE` to ignore system installations and strictly use an `rJavaEnv` managed version.
#' @param install Logical. If `TRUE` (default), attempts to download/install if missing.
#'   If `FALSE`, returns `FALSE` if the version is not found.
#' @param distribution Character. The Java distribution to download. Defaults to "Corretto". Ignored if `version` is a SDKMAN identifier.
#' @param check_against Character. Controls which context validity the function checks against.
#'   * `"rJava"` (default): Checks if the requested version can be enforced for `rJava`. If `rJava` is already initialized and locked to a different version, this will error, as the requested version cannot be enforced for the active `rJava` session.
#'   * `"cmd"`: Checks if the requested version can be enforced for command-line use. This ignores the state of `rJava` and allows setting the environment variables even if `rJava` is locked to a different version.
#' @inheritParams global_quiet_param
#' @inheritParams java_download
#' @inheritParams global_backend_param
#' @inheritParams global_use_cache_param
#' @inheritParams global_sdkman_references
#' @param .check_rjava_fun Internal. Function to check if rJava is initialized.
#' @param .rjava_ver_fun Internal. Function to get the current rJava version.
#'
#' @return Logical. `TRUE` if the requirement is met (active or set successfully), `FALSE` otherwise.
#'
#' @seealso
#' `vignette("for-developers")` for comprehensive guidance on integrating `rJavaEnv` into your package,
#' including how to use `java_ensure()` in different scenarios and detailed use cases with `type` and
#' `accept_system_java` parameters.
#'
#' @export
#' @examples
#' \donttest{
#' # For end users: Ensure Java 21 is ready BEFORE loading rJava packages
#' library(rJavaEnv)
#' java_ensure(version = 21, type = "min")
#' # Now safe to load packages that depend on rJava
#' # library(myRJavaPackage)
#'
#' # For packages using command-line Java (not rJava):
#' # Can use java_ensure() within functions to set Java before calling system tools
#' my_java_tool <- function() {
#'   java_ensure(version = 17)
#'   system2("java", c("-jar", "tool.jar"))
#' }
#' }
java_ensure <- function(
  version = NULL,
  type = c("exact", "min"),
  accept_system_java = TRUE,
  install = TRUE,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  check_against = c("rJava", "cmd"),
  quiet = FALSE,
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  .use_cache = FALSE,
  .check_rjava_fun = check_rjava_initialized,
  .rjava_ver_fun = java_check_current_rjava_version
) {
  # Validate that version is provided
  if (is.null(version)) {
    stop(
      "The 'version' parameter is required. ",
      "Specify the Java version you need, e.g., version = 21 or version = 17."
    )
  }

  type <- match.arg(type)
  check_against <- match.arg(check_against)
  java_validate_requirement(version, type)

  # Handling rJava Path-Locking
  if (check_against == "rJava") {
    # Strict compliance: rJava MUST match if loaded
    # This will show the informative message if rJava is loaded and quiet = FALSE
    rjava_is_loaded <- .check_rjava_fun(quiet = quiet)

    if (rjava_is_loaded && !java_rjava_can_select()) {
      curr_rjava_ver <- .rjava_ver_fun()

      if (!is.null(curr_rjava_ver)) {
        rjava_ok <- java_version_satisfies(curr_rjava_ver, version, type)

        if (rjava_ok) {
          if (!quiet) {
            cli::cli_alert_success(
              "rJava is locked to version {curr_rjava_ver}, which satisfies the requirement."
            )
          }
          return(invisible(TRUE))
        } else {
          # Locked version FAILS requirement -> ERROR
          cli::cli_abort(c(
            "x" = "rJava is already loaded and locked to Java {curr_rjava_ver}.",
            "i" = "You requested Java {version} (type = '{type}').",
            "!" = "Cannot fulfill request because rJava path-locking prevents changing the JVM version in this session.",
            "i" = "Please restart your R session and run `java_ensure({version})` BEFORE loading rJava or packages that depend on it."
          ))
        }
      } else {
        cli::cli_abort(c(
          "rJava is loaded but its JVM version cannot be verified without initialization.",
          "i" = "Loading rJava can already lock the JVM library path, before .jinit().",
          "i" = "Restart R, then run java_ensure() BEFORE loading rJava, or use with_rjava_env()."
        ))
      }
    }
  }
  # check_against == "cmd": We essentially ignore rJava.

  # Resolve path using the pure function
  found_path <- tryCatch(
    java_resolve(
      version = version,
      type = type,
      distribution = distribution,
      backend = backend,
      install = install,
      accept_system_java = accept_system_java,
      quiet = quiet,
      cache_path = cache_path,
      platform = platform,
      arch = arch,
      .use_cache = .use_cache
    ),
    error = function(e) {
      # If java_resolve fails (e.g. not found and install=FALSE), return NULL
      if (!quiet) {
        cli::cli_alert_warning("Java resolution failed: {e$message}")
      }
      NULL
    }
  )

  if (is.null(found_path)) {
    if (!quiet) {
      cli::cli_alert_warning("Required Java version not found.")
    }
    return(invisible(FALSE))
  }

  # Set the environment
  ._java_env_set_impl(
    where = "session",
    java_home = found_path,
    quiet = quiet,
    ._skip_rjava_check = TRUE,
    ._load_jvm = check_against == "rJava"
  )

  return(invisible(TRUE))
}
