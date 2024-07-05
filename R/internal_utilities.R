#' Detect platform and architecture
#'
#' @keywords internal
#' @param verbose Whether to print detailed messages. Defaults to FALSE.
#' @return A list of length 2 with the detected platform and architecture.
#'
platform_detect <- function(verbose = FALSE) {
  sys_info <- tolower(Sys.info())

  os <- switch(sys_info["sysname"],
    "windows" = "windows",
    "linux" = "linux",
    "darwin" = "macos",
    stop(cli::cli_abort("Unsupported platform"))
  )

  arch <- switch(sys_info["machine"],
    "x86-64" = "x64",
    "x86_64" = "x64",
    "i386" = "x86",
    "i686" = "x86",
    "aarch64" = "arm64",
    "arm64" = "arm64",
    stop(cli::cli_abort("Unsupported architecture"))
  )

  if (verbose) {
    cli::cli_inform("Detected platform: {os}")
    cli::cli_inform("Detected architecture: {arch}")
  }

  return(list(os = os, arch = arch))
}


#' Load Java URLs from JSON file
#'
#' @keywords internal
#'
#' @return A list with the Java URLs structured as in the JSON file by distribution, platform, and architecture.
#'
java_urls_load <- function() {
  json_file <- system.file("extdata", "java_urls.json", package = "rJavaEnv")
  if (json_file == "") {
    cli::cli_abort("Configuration file not found")
  }
  jsonlite::fromJSON(json_file, simplifyVector = FALSE)
}

#' Test all Java URLs
#'
#' @keywords internal
#'
#' @return A list with the results of testing all Java URLs.
#'
urls_test_all <- function() {
  java_urls <- java_urls_load()
  results <- list()

  for (distribution in names(java_urls)) {
    for (platform in names(java_urls[[distribution]])) {
      for (arch in names(java_urls[[distribution]][[platform]])) {
        url_template <- java_urls[[distribution]][[platform]][[arch]]

        # Replace {version} with a placeholder version to test URL
        url <- gsub("\\{version\\}", "11", url_template)

        try(
          {
            response <- curl::curl_fetch_memory(url, handle = curl::new_handle(nobody = TRUE))
            status <- response$status_code
          },
          silent = TRUE
        )

        if (!exists("status")) {
          status <- NA
        }

        results[[paste(distribution, platform, arch, sep = "-")]] <- list(
          url = url,
          status = status
        )

        # Clear status variable for next iteration
        rm(status)
      }
    }
  }

  return(results)
}


# Unexported function to initialize Java using rJava and check Java version
# This is intended to be called from the exported function java_check_version_rjava
# Updated java_version_check_rscript function with verbosity control
#' Check Java version using rJava
#'
#' @keywords internal
#'
#' @param java_home
#'
#' @return A message with the Java version or an error message.
#'
java_version_check_rscript <- function(java_home) {
  result <- tryCatch(
    {
      Sys.setenv(JAVA_HOME = java_home)

      old_path <- Sys.getenv("PATH")
      new_path <- file.path(java_home, "bin")
      Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep))

      suppressWarnings(rJava::.jinit())
      suppressWarnings(java_version <- rJava::.jcall("java.lang.System", "S", "getProperty", "java.version"))

      message <- cli::format_message("rJava and other rJava/Java-based packages will use Java version: {.val {java_version}}")

      message
    },
    error = function(e) {
      cli::format_message("Error checking Java version: {e$message}")
    }
  )

  return(result)
}
