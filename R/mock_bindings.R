# NULL bindings to allow mocking base functions in tests.
# This file is only used to create entries in the package namespace
# so that testthat::local_mocked_bindings can replace them.
# See: https://testthat.r-lib.org/reference/local_mocked_bindings.html

Sys.info <- NULL
file.exists <- NULL
system2 <- NULL
dyn.load <- NULL
dirname <- NULL
