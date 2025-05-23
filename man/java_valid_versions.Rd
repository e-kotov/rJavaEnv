% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/java_valid_versions.R
\name{java_valid_versions}
\alias{java_valid_versions}
\title{Retrieve Valid Java Versions}
\usage{
java_valid_versions(
  distribution = "Corretto",
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  force = FALSE
)
}
\arguments{
\item{distribution}{The Java distribution to download. If not specified, defaults to "Amazon Corretto". Currently only \href{https://aws.amazon.com/corretto/}{"Amazon Corretto"} is supported.}

\item{platform}{The platform for which to download the Java distribution. Defaults to the current platform.}

\item{arch}{The architecture for which to download the Java distribution. Defaults to the current architecture.}

\item{force}{Logical. If TRUE, forces a fresh API call even if a cached value exists. Defaults to FALSE.}
}
\value{
A character vector of valid Java versions.
}
\description{
This function retrieves a list of valid Java versions by querying an appropriate API endpoint based on the chosen distribution.
The result is cached for 8 hours to avoid repeated API calls. If the API call fails (for example, due to a lack of internet connectivity),
the function falls back to a pre-defined list of Java versions.
}
\examples{
\dontrun{
  # Retrieve valid Java versions (cached if available) using Amazon Corretto endpoint
  versions <- java_valid_versions()

  # Force refresh the list of Java versions using the Oracle endpoint
  versions <- java_valid_versions(distribution = "Corretto", force = TRUE)
}

}
