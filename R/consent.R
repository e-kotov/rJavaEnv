#' Obtain User Consent for rJavaEnv
#'
#' Get user consent for rJavaEnv to write and update files on the file system.
#' rJavaEnv needs permission to manage files in your project and cache directories
#' to function correctly.
#'
#' In line with [CRAN policies](https://cran.r-project.org/web/packages/policies.html), explicit user consent is required before making these changes.
#' Please call `rJavaEnv::consent()` to provide consent.
#'
#' Alternatively, you can set the following \R option
#' (especially useful for non-interactive R sessions):
#'
#' ```
#' options(rJavaEnv.consent = TRUE)
#' ```
#' The function is based on the code of the `renv` package.
#' Copyright 2023 Posit Software, PBC
#' License: https://github.com/rstudio/renv/blob/main/LICENSE
#'
#' @param provided Logical indicating if consent is already provided.
#'  To provide consent in non-interactive \R sessions
#'  use `rJavaEnv::rje_consent(provided = TRUE)`. Default is `FALSE`.
#'
#' @return `TRUE` if consent is given, otherwise an error is raised.
#'
#' @export
#' @examples
#' \donttest{
#'
#' # to provide consent and prevent other functions from interrupting to get the consent
#' rje_consent(provided = TRUE)
#' }
#'
rje_consent <- function(provided = FALSE) {
  # Check if consent is already given via environment variable
  if (getOption("rJavaEnv.consent", default = FALSE)) {
    cli::cli_inform("Consent for using rJavaEnv has already been provided.")
    return(invisible(TRUE))
  }

  # Check if consent is already given via cache directory
  user_package_cache_path <- getOption("rJavaEnv.cache_path")
  user_package_cache_path <- normalizePath(
    user_package_cache_path,
    winslash = "/",
    mustWork = FALSE
  )
  if (dir.exists(user_package_cache_path)) {
    cli::cli_inform("Consent for using rJavaEnv has already been provided.")
    return(invisible(TRUE))
  }

  # write welcome message
  template <- system.file("resources/consent-info", package = "rJavaEnv")
  contents <- readLines(template)
  contents <- gsub("\\$\\{rJavaEnv_CACHE\\}", user_package_cache_path, contents)
  cli::cli_inform(contents)

  # Request user consent if not already provided
  if (!provided) {
    response <- rje_readline(prompt = "Your response: (yes/no) ")
    provided <- tolower(response) %in% c("y", "yes", "yes.")
  }

  if (!provided) {
    cli::cli_abort("Consent was not provided; operation aborted.")
  }

  # Save user consent
  options(rJavaEnv.consent = TRUE)
  dir.create(user_package_cache_path, recursive = TRUE, showWarnings = FALSE)
  cli::cli_inform("Consent has been granted and recorded.")

  invisible(TRUE)
}

#' Verify User Consent for rJavaEnv
#'
#' Ensure that the user has granted permission for rJavaEnv to manage files on their file system.
#'
#' The function is based on the code of the `renv` package.
#' Copyright 2023 Posit Software, PBC
#' License: https://github.com/rstudio/renv/blob/main/LICENSE
#'
#' @return `TRUE` if consent is verified, otherwise an error is raised.
#' @keywords internal
rje_consent_check <- function() {
  # Check if explicit consent is given
  if (getOption("rJavaEnv.consent", FALSE)) {
    return(TRUE)
  }
  if (dir.exists(getOption("rJavaEnv.cache_path"))) {
    return(TRUE)
  }

  # Check for implicit consent
  consented <-
    !interactive() ||
    rje_envvar_exists("CI") ||
    rje_envvar_exists("GITHUB_ACTION") ||
    rje_envvar_exists("RENV_PATHS_ROOT") ||
    file.exists("/.singularity.d")

  if (consented) {
    options(rJavaEnv.consent = TRUE)
    return(TRUE)
  }

  # Prompt for explicit consent
  rje_consent()
}


#' Helper for clean env var check
#'
#' #' The function is based on the code of the `renv` package.
#' Copyright 2023 Posit Software, PBC
#' License: https://github.com/rstudio/renv/blob/main/LICENSE
#' @param key The environment variable key to check.
#' @keywords internal
rje_envvar_exists <- function(key) {
  !is.na(Sys.getenv(key, unset = NA))
}
