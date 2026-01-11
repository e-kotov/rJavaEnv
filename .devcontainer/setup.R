#!/usr/bin/env Rscript

# Ensure remotes is installed
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Get dependencies from DESCRIPTION in the current directory
deps <- remotes::dev_package_deps(dependencies = TRUE)

# Filter out rJava to ensure no Java is installed
packages_to_install <- deps$package[deps$package != "rJava"]

# Install/Update the selected packages
if (length(packages_to_install) > 0) {
  # We use install_cran to handle versions if specified in DESCRIPTION (though usually remotes::install_deps does this better)
  # But since we need to exclude one, we pass the vector.
  # remotes::install_cran will install the latest CRAN version.
  # To respect version requirements in DESCRIPTION, strictly speaking we should use something more sophisticated,
  # but for a dev container, latest versions of dependencies are usually desired.
  remotes::install_cran(packages_to_install)
}
