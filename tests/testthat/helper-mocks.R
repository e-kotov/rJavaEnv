# Helper function to mock global dependencies for java_install tests
mock_java_globals <- function(env = parent.frame()) {
  # We use assignInNamespace because local_mocked_bindings was failing to mock
  # the functions in the package namespace reliably in this context.

  # Mock java_valid_versions
  # It is internal, but assignInNamespace handles it.
  if (exists("java_valid_versions", envir = asNamespace("rJavaEnv"))) {
    original_java_valid_versions <- get(
      "java_valid_versions",
      envir = asNamespace("rJavaEnv")
    )
    assignInNamespace(
      "java_valid_versions",
      function(...) c("8", "11", "17", "21"),
      ns = "rJavaEnv"
    )
    withr::defer(
      assignInNamespace(
        "java_valid_versions",
        original_java_valid_versions,
        ns = "rJavaEnv"
      ),
      envir = env
    )
  }

  # Mock rje_consent_check
  if (exists("rje_consent_check", envir = asNamespace("rJavaEnv"))) {
    original_rje_consent_check <- get(
      "rje_consent_check",
      envir = asNamespace("rJavaEnv")
    )
    assignInNamespace("rje_consent_check", function() TRUE, ns = "rJavaEnv")
    withr::defer(
      assignInNamespace(
        "rje_consent_check",
        original_rje_consent_check,
        ns = "rJavaEnv"
      ),
      envir = env
    )
  }

  # Mock java_unpack
  if (exists("java_unpack", envir = asNamespace("rJavaEnv"))) {
    original_java_unpack <- get("java_unpack", envir = asNamespace("rJavaEnv"))

    mock_unpack <- function(
      java_distrib_path,
      distribution = NULL,
      backend = NULL,
      ...
    ) {
      filename <- basename(java_distrib_path)
      parts <- strsplit(gsub("\\.tar\\.gz|\\.zip", "", filename), "-")[[1]]
      version <- parts[parts %in% c("8", "11", "17", "21")][1]
      arch <- parts[parts %in% c("x64", "aarch64")][1]
      platform <- parts[parts %in% c("linux", "windows", "macos")][1]

      # Resolve distribution and backend (match real function behavior)
      if (is.null(distribution)) {
        distribution <- attr(java_distrib_path, "distribution")
        if (is.null(distribution)) distribution <- "unknown"
      }
      if (is.null(backend)) {
        backend <- attr(java_distrib_path, "backend")
        if (is.null(backend)) backend <- "unknown"
      }

      # Use a generic, hardcoded root path instead of calling getOption().
      # This makes the mock independent of the state being tested.
      # New structure: platform/arch/distribution/backend/version
      file.path(
        "/mock/cache/path",
        "installed",
        platform,
        arch,
        distribution,
        backend,
        version
      )
    }

    assignInNamespace("java_unpack", mock_unpack, ns = "rJavaEnv")
    withr::defer(
      assignInNamespace("java_unpack", original_java_unpack, ns = "rJavaEnv"),
      envir = env
    )
  }
}
