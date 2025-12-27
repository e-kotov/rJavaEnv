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
#' **Important for \strong{rJava} Users**: This function sets environment variables
#' (JAVA_HOME, PATH) that affect both command-line Java tools and \strong{rJava} initialization.
#' However, due to \strong{rJava}'s path-locking behavior when \code{\link[rJava]{.jinit}} is called
#' (see \url{https://github.com/s-u/rJava/issues/25}, \url{https://github.com/s-u/rJava/issues/249}, and \url{https://github.com/s-u/rJava/issues/334}),
#' this function must be called **BEFORE** \code{\link[rJava]{.jinit}} is invoked. Once \code{\link[rJava]{.jinit}}
#' initializes, the Java version is locked for that R session and cannot be changed without restarting R.
#'
#' \code{\link[rJava]{.jinit}} is invoked (and Java locked) when you:
#' \itemize{
#'   \item Explicitly call \code{library(rJava)}
#'   \item Load any package that imports \strong{rJava} (which auto-loads it as a dependency)
#'   \item Even just use IDE autocomplete with \code{rJava::} (this triggers initialization!)
#'   \item Call any \strong{rJava}-dependent function
#' }
#'
#' Once any of these happen, the Java version used by \strong{rJava} for that session is locked in.
#' For command-line Java tools that don't use \strong{rJava}, this function can be called at any
#' time to switch Java versions for subsequent system calls.
#'
#' @keywords internal
rjava_path_locking_note <- function() {
  # Placeholder for rJava path-locking documentation
}
