test_that("full download, install, check, and clear cycle works for SDKMAN identifiers", {
  # --- Test Configuration ---
  testthat::skip_on_cran()

  # Skip if RUN_JAVA_DOWNLOAD_TESTS is not TRUE
  skip_if_not(
    Sys.getenv("RUN_JAVA_DOWNLOAD_TESTS") == "TRUE",
    "Skipping real download test. Set RUN_JAVA_DOWNLOAD_TESTS='TRUE' to run."
  )

  # Check verbosity settings
  rj_quiet <- Sys.getenv("RUN_JAVA_DOWNLOAD_TESTS_QUIET") == "TRUE"
  rj_dl_quiet <- Sys.getenv("RUN_JAVA_DOWNLOAD_TESTS_QUIET_DOWNLOAD") == "TRUE"

  # --- 1. Setup a Self-Cleaning Temporary Environment ---
  main_temp_dir <- tempfile(pattern = "rJavaEnv-sdkman-live-")
  dir.create(main_temp_dir, recursive = TRUE)
  on.exit(unlink(main_temp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  temp_cache_dir <- file.path(main_temp_dir, "cache")
  temp_project_dir <- file.path(main_temp_dir, "project")
  dir.create(temp_cache_dir, recursive = TRUE)
  dir.create(temp_project_dir, recursive = TRUE)

  withr::local_options(list(
    rJavaEnv.cache_path = temp_cache_dir,
    rJavaEnv.consent = TRUE
  ))

  # --- 2. List of SDKMAN identifiers to test ---
  # These are chosen for cross-platform availability and popularity
  sdkman_identifiers <- c(
    "21.0.9-tem", # Temurin 21
    "21.0.9-amzn", # Corretto 21
    "21.0.9-zulu", # Zulu 21
    "17.0.17-tem", # Temurin 17
    "11.0.29-tem" # Temurin 11
  )

  cli::cli_inform(
    "Starting live SDKMAN integration tests for: {sdkman_identifiers}"
  )

  # --- 3. Loop through each identifier and perform the full workflow ---
  for (identifier in sdkman_identifiers) {
    context_info <- paste("Testing SDKMAN identifier:", identifier)
    cli::cli_h2(context_info)

    # --- Step A: Download ---
    cli::cli_inform("-> Step 1: Downloading via SDKMAN: {identifier}...")

    # We use java_download with the identifier as the version
    # The backend will be automatically detected as "sdkman" if it matches an identifier pattern
    # or we can pass it explicitly.
    downloaded_file <- java_download(
      version = identifier,
      backend = "sdkman",
      quiet = rj_dl_quiet,
      force = FALSE
    )

    testthat::expect_true(file.exists(downloaded_file), info = context_info)
    cli::cli_alert_success("Successfully downloaded {identifier}")

    # --- Step B: Install ---
    cli::cli_inform("-> Step 2: Installing {identifier}...")
    java_home_path <- java_install(
      java_distrib_path = downloaded_file,
      project_path = temp_project_dir,
      autoset_java_env = TRUE,
      quiet = rj_quiet,
      force = FALSE
    )

    testthat::expect_true(dir.exists(java_home_path), info = context_info)
    cli::cli_alert_success(
      "Successfully installed {identifier} to {java_home_path}"
    )

    # --- Step C: Check and Verify ---
    cli::cli_inform("-> Step 3: Verifying with java_check_version_cmd()...")
    cmd_version_result <- java_check_version_cmd(
      java_home = java_home_path,
      quiet = rj_quiet
    )

    # Extract major version from identifier for comparison if simple check fails
    # or just match the result string contains parts of identifier
    # java_check_version_cmd usually returns the semantic version or major version
    # For SDKMAN identifiers like 21.0.9-tem, cmd_version_result might be "21.0.9"

    major_ver <- strsplit(identifier, "\\.")[[1]][1]
    testthat::expect_match(
      cmd_version_result,
      paste0("^", major_ver),
      info = context_info
    )

    cli::cli_alert_success(
      "Verified {identifier} version: {cmd_version_result}"
    )

    # --- Step D: Clean up within the loop ---
    cli::cli_inform("-> Step 4: Clearing caches with java_clear()...")

    java_clear(
      type = "distrib",
      target_dir = temp_cache_dir,
      check = FALSE,
      delete_all = TRUE
    )

    java_clear(
      type = "installed",
      target_dir = temp_cache_dir,
      check = FALSE,
      delete_all = TRUE
    )

    # Verify that the cleanup was successful
    distrib_dir <- file.path(temp_cache_dir, "distrib")
    installed_dir <- file.path(temp_cache_dir, "installed")

    testthat::expect_equal(
      length(list.files(distrib_dir)),
      0,
      info = context_info
    )
    testthat::expect_equal(
      length(list.files(installed_dir)),
      0,
      info = context_info
    )

    cli::cli_alert_success(
      "Successfully processed and cleared SDKMAN identifier: {identifier}"
    )
  }
})
