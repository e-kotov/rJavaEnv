#' Verify rJava Compatibility (Guard)
#'
#' Checks if the currently initialized `rJava` session matches the required Java version.
#' Use after your package has deliberately started rJava, for example at the
#' start of a Java-dependent operation. It is safe to call earlier, but then
#' returns `FALSE` because compatibility has not been verified.
#'
#' This function reads an already running JVM without loading rJava or calling
#' `.jinit()`. If no JVM is running, compatibility is unverified and the function
#' returns `FALSE`, using `action` to report the result. For a check in a fresh
#' subprocess, use `java_check_version_rjava()`. A loaded rJava namespace may
#' already have locked its library path even if its JVM is not running.
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
#' # After deliberately initializing rJava in a Java-dependent operation:
#' rJava::.jinit()
#' java_check_compatibility(version = 21, action = "stop")
#' }
java_check_compatibility <- function(
  version,
  type = c("min", "exact"),
  action = c("warn", "stop", "message", "none")
) {
  type <- match.arg(type)
  action <- match.arg(action)
  java_validate_requirement(version, "exact")
  if (!grepl("^[0-9]+$", as.character(version))) {
    cli::cli_abort("Compatibility checks require a major Java version.")
  }
  req_ver <- as.integer(version)

  # 1. Get current rJava version (safely)
  curr_ver_str <- java_check_current_rjava_version()

  if (is.null(curr_ver_str)) {
    msg <- "No running rJava JVM could be detected. This check does not load or initialize rJava."
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

  curr_ver <- as.integer(parse_java_major_version(curr_ver_str))

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
