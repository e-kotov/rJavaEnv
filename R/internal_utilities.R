#' Detect platform and architecture
#'
#' @inheritParams global_quiet_param
#' @keywords internal
#' @return A list of length 2 with the detected platform and architecture.
#'
platform_detect <- function(quiet = TRUE) {
  sys_info <- tolower(Sys.info())

  os <- switch(
    sys_info["sysname"],
    "windows" = "windows",
    "linux" = "linux",
    "darwin" = "macos",
    stop(cli::cli_abort("Unsupported platform"))
  )

  arch <- switch(
    sys_info["machine"],
    "x86-64" = "x64",
    "x86_64" = "x64",
    "i386" = "x86",
    "i486" = "x86",
    "i586" = "x86",
    "i686" = "x86",
    "aarch64" = "aarch64",
    "arm64" = "aarch64",
    stop(cli::cli_abort("Unsupported architecture"))
  )

  if (isFALSE(quiet)) {
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
            response <- curl::curl_fetch_memory(
              url,
              handle = curl::new_handle(nobody = TRUE)
            )
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

      # On Linux, find and dynamically load libjvm.so
      if (Sys.info()["sysname"] == "Linux") {
        all_files <- list.files(
          path = java_home,
          pattern = "libjvm.so$",
          recursive = TRUE,
          full.names = TRUE
        )

        libjvm_path <- NULL
        if (length(all_files) > 0) {
          # Prefer the 'server' version if available
          server_files <- all_files[grepl("/server/libjvm.so$", all_files)]
          if (length(server_files) > 0) {
            libjvm_path <- server_files[1]
          } else {
            libjvm_path <- all_files[1]
          }
        }

        if (!is.null(libjvm_path) && file.exists(libjvm_path)) {
          tryCatch(
            dyn.load(libjvm_path),
            error = function(e) {
              # Use base message to avoid dependency issues in the isolated script
              message(sprintf(
                "Found libjvm.so at '%s' but failed to load it: %s",
                libjvm_path,
                e$message
              ))
            }
          )
        } else {
          message(sprintf(
            "Could not find libjvm.so within the provided JAVA_HOME: %s",
            java_home
          ))
        }
      }

      suppressWarnings(rJava::.jinit())
      suppressWarnings(
        java_version <- rJava::.jcall(
          "java.lang.System",
          "S",
          "getProperty",
          "java.version"
        )
      )

      message <- cli::format_message(
        "rJava and other rJava/Java-based packages will use Java version: {.val {java_version}}"
      )

      message
    },
    error = function(e) {
      cli::format_message("Error checking Java version: {e$message}")
    }
  )

  return(result)
}
