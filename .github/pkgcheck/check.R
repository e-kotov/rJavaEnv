# Entrypoint for the ropensci-review-tools/pkgcheck-action container.
#
# This follows the action's R/check.R and runs the same checks with the same
# failure rule. Differences:
# - The report is coerced to a character vector before writing. Upstream
#   checks_to_markdown() returns a list when CI checks pass, which makes
#   writeLines() fail (ropensci-review-tools/pkgcheck#444).
# - Outputs use GITHUB_OUTPUT and the summary goes to GITHUB_STEP_SUMMARY
#   instead of the deprecated set-output command.
# - The exit status is the result; no issue is created or updated.

library(pkgcheck)
library(magrittr)
library(octolog)
enable_github_colors()

set_output <- function(name, value) {
  out <- Sys.getenv("GITHUB_OUTPUT")
  if (nzchar(out)) {
    cat(sprintf("%s=%s\n", name, value), file = out, append = TRUE)
  }
  invisible(value)
}

octo_start_group("Install dependencies")

file_dir <- fs::dir_create(".pkgcheck")
Sys.setenv("PKGCACHE_HTTP_VERSION" = "2")
pak::lockfile_create(
  "local::.",
  lockfile = ".pkgcheck/pkg.lock",
  dependencies = "all"
)
pak::lockfile_install(".pkgcheck/pkg.lock")
if (packageVersion("sessioninfo") >= "1.2.1") {
  sessioninfo::session_info(pkgs = "installed", include_base = TRUE)
} else {
  options(width = 200)
  sessioninfo::session_info(rownames(installed.packages()), include_base = TRUE)
}

# prevent rcmdcheck NOTE
usethis::use_build_ignore(".pkgcheck")

octo_end_group()

octo_start_group("Running Pkgcheck...")
pkgstats::ctags_install(sudo = TRUE)

check <- pkgcheck()

if (fs::file_exists(check$info$network_file)) {
  fs::file_copy(check$info$network_file, file_dir) %>%
    set_output("visnet_path", .)
}

md <- checks_to_markdown(check, render = FALSE)
md <- as.character(unlist(md, use.names = FALSE))
s_break <- grep("---", md)[[1]]

writeLines(md[1:(s_break - 1)], "summary.md")
fs::file_copy("summary.md", file_dir, overwrite = TRUE) %>%
  set_output("summary_md", .)

writeLines(md, "full.md")
fs::file_copy("full.md", file_dir, overwrite = TRUE) %>%
  set_output("full_md", .)

step_summary <- Sys.getenv("GITHUB_STEP_SUMMARY")
if (nzchar(step_summary)) {
  cat(md[1:(s_break - 1)], file = step_summary, sep = "\n", append = TRUE)
}

octo_end_group()

errors <- md[1:s_break] %>%
  grep("^- :heavy_multiplication_x:", .) %>%
  `[`(md, .) %>%
  gsub("^- :heavy_multiplication_x: ", "", .)

for (error in errors) {
  octo_abort(error, .fail_fast = FALSE)
}

octo_start_group("Check Results")
print(check)
octo_end_group()

status <- as.integer(length(errors) > 0)
set_output("status", status)
quit(save = "no", status = status)
