#' Detect current platform
#'
#' @return A list with two elements: os and arch
#'
detect_platform <- function() {
  sys_info <- Sys.info()

  os <- switch(sys_info["sysname"],
    "Windows" = "windows",
    "Linux" = "linux",
    "Darwin" = "mac",
    stop("Unsupported platform")
  )

  arch <- switch(sys_info["machine"],
    "x86_64" = "x64",
    "i386" = "x86",
    "i686" = "x86",
    "aarch64" = "arm64",
    "arm64" = "arm64",
    stop("Unsupported architecture")
  )

  return(list(os = os, arch = arch))
}

load_java_urls <- function() {
  json_file <- system.file("extdata", "java_urls.json", package = "rJavaEnv")
  if (json_file == "") {
    stop("Configuration file not found")
  }
  jsonlite::fromJSON(json_file, simplifyVector = FALSE)
}


# Function to test all URLs in the JSON file
test_all_urls <- function() {
  java_urls <- load_java_urls()
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
