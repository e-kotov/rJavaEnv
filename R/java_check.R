#' Verify rJava Compatibility (Guard)
#'
#' Checks if the currently initialized `rJava` session matches the required Java version.
#' Intended for use in the `.onLoad` function of packages that depend on `rJava`.
#'
#' This function detects if `rJava` has already locked to a specific Java version
#' (which happens upon package loading) and warns the user if that version does not
#' match the requirement.
#'
#' @param version Integer. The required major Java version (e.g., 21).
#' @param type Character. "min" (default) checks for `>= version`. "exact" checks for `== version`.
#' @param action Character. What to do if incompatible:
#'   * "warn": Issue a warning but continue.
#'   * "stop": Throw an error (prevent package loading).
#'   * "message": Print a startup message.
#'   * "none": Return `FALSE` invisibly (useful for custom handling).
#' @return Logical `TRUE` if compatible, `FALSE` otherwise.
#' @export
#' @examples
#' \dontrun{
#' # In a package .onLoad:
#' .onLoad <- function(libname, pkgname) {
#'   rJavaEnv::java_check_compatibility(version = 21, action = "warn")
#' }
#' }
java_check_compatibility <- function(
  version,
  type = c("min", "exact"),
  action = c("warn", "stop", "message", "none")
) {
  type <- match.arg(type)
  action <- match.arg(action)
  req_ver <- as.integer(version)

  # 1. Get current rJava version (safely)
  curr_ver_str <- java_check_current_rjava_version()

  # If rJava isn't loaded or initialized yet, we can't check.
  # In an 'Imports: rJava' scenario, it IS loaded, but might not be .jinit()'d.
  # We try to initialize silently to check.
  if (is.null(curr_ver_str)) {
    if (requireNamespace("rJava", quietly = TRUE)) {
      tryCatch(rJava::.jinit(), error = function(e) NULL)
      curr_ver_str <- java_check_current_rjava_version()
    }
  }

  # If still null, rJava is broken, missing, or not initialized.
  if (is.null(curr_ver_str)) {
    # If rJava isn't present, we can't enforce check.
    # Return TRUE or FALSE depending on strictness?
    # Usually if Imports: rJava, this block is unreachable unless JVM failed.
    msg <- "rJava is loaded but the JVM could not be detected or initialized."
    if (action == "stop") {
      stop(msg, call. = FALSE)
    }
    if (action == "warn") {
      warning(msg, call. = FALSE)
    }
    if (action == "message") {
      packageStartupMessage(msg)
    }
    return(invisible(FALSE))
  }

  curr_ver <- as.integer(curr_ver_str)

  # 2. Compare
  is_compat <- FALSE
  if (type == "min") {
    is_compat <- curr_ver >= req_ver
  } else {
    is_compat <- curr_ver == req_ver
  }

  # 3. Handle Result
  if (is_compat) {
    return(invisible(TRUE))
  }

  # 4. Craft Helpful Message
  msg <- cli::format_message(c(
    "x" = "Java version mismatch.",
    "i" = "Current loaded Java: {curr_ver}",
    "i" = "Required Java: {if(type=='min') '>=' else '=='} {req_ver}",
    "!" = "Because {.pkg rJava} is already initialized, you must restart R to switch versions.",
    " " = "To fix this, restart R and run:",
    " " = "{.code rJavaEnv::use_java({req_ver})}",
    " " = "BEFORE loading this package."
  ))

  if (action == "stop") {
    stop(msg, call. = FALSE)
  }
  if (action == "warn") {
    warning(msg, call. = FALSE)
  }
  if (action == "message") {
    packageStartupMessage(msg)
  }

  return(invisible(FALSE))
}
