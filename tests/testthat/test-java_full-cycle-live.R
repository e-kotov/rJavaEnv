test_that("full download, install, check, and clear cycle works for all versions", {
  # --- Test Configuration ---
  testthat::skip_on_cran()
  # Sys.setenv("RUN_JAVA_DOWNLOAD_TESTS" = "TRUE")
  # Sys.setenv("RUN_JAVA_DOWNLOAD_TESTS_QUIET" = "FALSE")
  # Sys.setenv("RUN_JAVA_DOWNLOAD_TESTS_QUIET" = "TRUE")
  # Sys.setenv("RUN_JAVA_DOWNLOAD_TESTS_QUIET_DOWNLOAD" = "FALSE")
  # Sys.setenv("RUN_JAVA_DOWNLOAD_TESTS_QUIET_DOWNLOAD" = "TRUE")
  skip_if_not(
    Sys.getenv("RUN_JAVA_DOWNLOAD_TESTS") == "TRUE",
    "Skipping real download test. Set RUN_JAVA_DOWNLOAD_TESTS='TRUE' to run."
  )
  if (Sys.getenv("RUN_JAVA_DOWNLOAD_TESTS_QUIET") == "TRUE") {
    rj_quiet <- TRUE
  } else {
    rj_quiet <- FALSE
  }
  if (Sys.getenv("RUN_JAVA_DOWNLOAD_TESTS_QUIET_DOWNLOAD") == "TRUE") {
    rj_dl_quiet <- TRUE
  } else {
    rj_dl_quiet <- FALSE
  }

  # --- 1. Setup a Self-Cleaning Temporary Environment ---
  main_temp_dir <- tempfile(pattern = "rJavaEnv-full-test-")
  dir.create(main_temp_dir, recursive = TRUE)

  # The on.exit() call is the final safety net, ensuring everything is deleted
  # at the end, even if the test or the in-loop java_clear() fails.
  on.exit(unlink(main_temp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  temp_cache_dir <- file.path(main_temp_dir, "cache")
  temp_project_dir <- file.path(main_temp_dir, "project")
  dir.create(temp_cache_dir, recursive = TRUE)
  dir.create(temp_project_dir, recursive = TRUE)

  withr::local_options(list(
    rJavaEnv.cache_path = temp_cache_dir,
    rJavaEnv.consent = TRUE
  ))

  # --- 2. Get the list of Java versions to test ---
  java_versions <- tryCatch(
    {
      java_valid_versions(force = TRUE)
    },
    error = function(e) {
      getOption("rJavaEnv.fallback_valid_versions_current_platform")
    }
  )
  cli::cli_inform(
    "Found {length(java_versions)} Java versions to test: {java_versions}"
  )

  # --- 3. Loop through each version and perform the full workflow ---
  for (java_version in java_versions) {
    context_info <- paste("Testing Java version:", java_version)
    cli::cli_h2(context_info)

    # --- Step A: Download ---
    cli::cli_inform("-> Step 1: Downloading Java {java_version}...")
    downloaded_file <- java_download(
      version = java_version,
      quiet = rj_dl_quiet,
      force = FALSE,
    )
    testthat::expect_true(file.exists(downloaded_file), info = context_info)

    # --- Step B: Install ---
    cli::cli_inform("-> Step 2: Installing Java {java_version}...")
    java_home_path <- java_install(
      java_distrib_path = downloaded_file,
      project_path = temp_project_dir,
      autoset_java_env = TRUE,
      quiet = rj_quiet,
      force = FALSE
    )
    testthat::expect_true(dir.exists(java_home_path), info = context_info)

    # --- Step C: Check and Verify ---
    cli::cli_inform("-> Step 3: Verifying with java_check_version_cmd()...")
    cmd_version_result <- java_check_version_cmd(
      java_home = java_home_path,
      quiet = rj_quiet
    )
    testthat::expect_equal(
      cmd_version_result,
      java_version,
      info = context_info
    )
    if (cmd_version_result == java_version) {
      cli::cli_inform(
        "Successfully verified Java {java_version} with command line."
      )
    } else {
      cli::cli_alert_danger(
        "Command line verification failed for Java {java_version}."
      )
    }

    cli::cli_inform("-> Step 4: Verifying with java_check_version_rjava()...")
    rjava_version_result <- java_check_version_rjava(
      java_home = java_home_path,
      quiet = rj_quiet
    )

    # Handle the case where rJava is not installed (returns FALSE)
    if (isFALSE(rjava_version_result)) {
      cli::cli_alert_warning(
        "Skipping rJava verification: rJava package not installed or check failed."
      )
    } else {
      testthat::expect_equal(
        rjava_version_result,
        java_version,
        info = context_info
      )
      if (rjava_version_result == java_version) {
        cli::cli_inform("Successfully verified Java {java_version} with rJava.")
      } else {
        cli::cli_alert_danger(
          "rJava verification failed for Java {java_version}."
        )
      }
    }

    # --- Step D: Clean up within the loop to test java_clear() ---
    cli::cli_inform("-> Step 5: Clearing caches with java_clear()...")

    # Clear the downloaded distribution files
    java_clear(
      type = "distrib",
      target_dir = temp_cache_dir,
      check = FALSE, # Must be FALSE for non-interactive use
      delete_all = TRUE # Must be TRUE for non-interactive use
    )

    # Clear the unpacked installation files
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
      "Successfully processed and cleared Java version: {java_version}"
    )
  }
})
