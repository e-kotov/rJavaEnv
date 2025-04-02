.onLoad <- function(libname, pkgname) {
  op <- options()
  op.rJavaEnv <- list(
    # this default folder choice is in-line with what renv package does
    # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/bootstrap.R#L940-L950
    rJavaEnv.cache_path = tools::R_user_dir("rJavaEnv", which = "cache"),
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.valid_versions_timestamp = NULL,
    # Fallback list of valid Java versions if the API call fails (e.g., no internet) as of 2025-04-02
    rJavaEnv.fallback_valid_versions = c(
      "8",
      "11",
      # "15", # not available from Amazon Corretto
      # "16", # not available from Amazon Corretto
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24"
    )
  )
  toset <- !(names(op.rJavaEnv) %in% names(op))
  if (any(toset)) options(op.rJavaEnv[toset])

  invisible()
}
