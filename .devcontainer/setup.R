#!/usr/bin/env Rscript

# Ensure remotes is installed
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Get dependencies from DESCRIPTION in the current directory
deps <- remotes::dev_package_deps(dependencies = TRUE)

# Filter out rJava to ensure no Java is installed
# deps is a data.frame with class "package_deps"
deps <- deps[deps$package != "rJava", ]

# Install/Update the selected packages
# The update() method for package_deps respects version requirements
remotes::update(deps, upgrade = "always")
