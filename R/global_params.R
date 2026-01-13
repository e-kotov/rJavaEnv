#' @title Global Quiet Parameter
#'
#' @description
#' Documentation for the `quiet` parameter, used globally.
#'
#' @param quiet A `logical` value indicating whether to suppress messages. Can be `TRUE` or `FALSE`.
#' @keywords internal
global_quiet_param <- function(quiet) {
  # this is just a placeholder for global quiet parameter
}

#' @title rJava Path-Locking Documentation
#'
#' @description
#' Documentation template for rJava path-locking behavior.
#'
#' @section rJava Path-Locking:
#' **Important for rJava Users**: This function sets environment variables
#' (JAVA_HOME, PATH) that affect both command-line Java tools and rJava initialization.
#' However, due to rJava's path-locking behavior when \code{\link[rJava]{.jinit}} is called
#' (see \url{https://github.com/s-u/rJava/issues/25}, \url{https://github.com/s-u/rJava/issues/249}, and \url{https://github.com/s-u/rJava/issues/334}),
#' this function must be called **BEFORE** \code{\link[rJava]{.jinit}} is invoked. Once \code{\link[rJava]{.jinit}}
#' initializes, the Java version is locked for that R session and cannot be changed without restarting R.
#'
#' \code{\link[rJava]{.jinit}} is invoked (and Java locked) when you:
#' \itemize{
#'   \item Explicitly call \code{library(rJava)}
#'   \item Load any package that imports rJava (which auto-loads it as a dependency)
#'   \item Even just use IDE autocomplete with \code{rJava::} (this triggers initialization!)
#'   \item Call any rJava-dependent function
#' }
#'
#' Once any of these happen, the Java version used by rJava for that session is locked in.
#' For command-line Java tools that don't use rJava, this function can be called at any
#' time to switch Java versions for subsequent system calls.
#'
#' @keywords internal
rjava_path_locking_note <- function() {
  # Placeholder for rJava path-locking documentation
}

#' @title Global Use Cache Parameter
#'
#' @description
#' Documentation for the `.use_cache` parameter, used for performance optimization.
#'
#' @param .use_cache A `logical` value controlling caching behavior. If `FALSE` (default),
#'   performs a fresh check each time (safe, reflects current state). If `TRUE`, uses
#'   session-scoped cached results for performance in loops or repeated calls.
#'
#'   **Caching Behavior:**
#'   - Session-scoped: Cache is cleared when R restarts
#'   - Key-based for version checks: Changes to JAVA_HOME create new cache entries
#'   - System-wide for scanning: Always recalculates current default Java
#'
#'   **Performance Benefits:**
#'   - First call: ~37-209ms (depending on operation)
#'   - Cached calls: <1ms
#'   - Prevents 30-100ms delays on every call in performance-critical code
#'
#'   **When to Enable:**
#'   - Package initialization code (`.onLoad` or similar)
#'   - Loops calling the same function multiple times
#'   - Performance-critical paths with frequent version checks
#'
#'   **When to Keep Default (FALSE):**
#'   - Interactive use (one-off checks)
#'   - When you need current data reflecting recent Java installations
#'   - General-purpose function calls that aren't time-critical
#'
#' @keywords internal
global_use_cache_param <- function(.use_cache) {
  # this is just a placeholder for global .use_cache parameter
}

#' @title Global Version Parameter
#'
#' @description
#' Documentation for the `version` parameter, used for specifying Java versions.
#'
#' @param version Java version specification. Accepts:
#'   \itemize{
#'     \item **Major version** (e.g., `21`, `17`): Downloads the latest release for that major version.
#'     \item **Specific version** (e.g., `"21.0.9"`, `"11.0.29"`): Downloads the exact version.
#'     \item **SDKMAN identifier** (e.g., `"25.0.1-amzn"`, `"24.0.2-open"`): Uses the SDKMAN
#'       backend automatically. When an identifier is detected, the `distribution` and `backend`
#'       arguments are **ignored** and derived from the identifier. Find available identifiers
#'       in the `identifier` column of \code{\link{java_list_available}(backend = "sdkman")}.
#'   }
#' @keywords internal
global_version_param <- function(version) {
  # this is just a placeholder for global version parameter
}

#' @title SDKMAN References
#'
#' @description
#' Standard references for SDKMAN attribution.
#'
#' @references
#' SDKMAN! - The Software Development Kit Manager: \url{https://github.com/sdkman}
#' @keywords internal
global_sdkman_references <- function() {
  # this is just a placeholder for SDKMAN references
}

#' @title Global Backend Parameter
#'
#' @description
#' Documentation for the `backend` parameter, used for specifying the download source.
#'
#' @param backend Download backend to use. One of "native" (vendor APIs) or "sdkman".
#'   Defaults to "native". Can also be set globally via `options(rJavaEnv.backend = "sdkman")`.
#' @keywords internal
global_backend_param <- function(backend) {
  # this is just a placeholder for global backend parameter
}
