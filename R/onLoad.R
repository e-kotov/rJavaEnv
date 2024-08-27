.onLoad <- function(libname, pkgname) {
  op <- options()
  op.rJavaEnv <- list(
    # this default folder choice is in-line with what renv package does
    # https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/bootstrap.R#L940-L950
    rJavaEnv.cache_path = tools::R_user_dir("rJavaEnv", which = "cache"),
    rJavaEnv.valid_java_versions = c(8, 11, 17, 21, 22)
  )
  toset <- !(names(op.rJavaEnv) %in% names(op))
  if (any(toset)) options(op.rJavaEnv[toset])

  invisible()
}
