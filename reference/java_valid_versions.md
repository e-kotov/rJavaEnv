# Retrieve Valid Java Versions

This function retrieves a list of valid Java versions by querying an
appropriate API endpoint based on the chosen distribution. The result is
cached across sessions via file cache (24 hours) and within a session in
memory (8 hours) to avoid repeated API calls. If the API call fails (for
example, due to a lack of internet connectivity), the function falls
back to a pre-defined list of Java versions.

## Usage

``` r
java_valid_versions(
  distribution = "Corretto",
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  force = FALSE
)
```

## Arguments

- distribution:

  The Java distribution to download. If not specified, defaults to
  "Amazon Corretto". Currently only ["Amazon
  Corretto"](https://aws.amazon.com/corretto/) is supported.

- platform:

  The platform for which to download the Java distribution. Defaults to
  the current platform.

- arch:

  The architecture for which to download the Java distribution. Defaults
  to the current architecture.

- force:

  Logical. If TRUE, forces a fresh API call even if a cached value
  exists. Defaults to FALSE.

## Value

A character vector of valid Java versions.

## Examples

``` r
if (FALSE) { # \dontrun{
  # Retrieve valid Java versions (cached if available) using Amazon Corretto endpoint
  versions <- java_valid_versions()

  # Force refresh the list of Java versions using the Oracle endpoint
  versions <- java_valid_versions(distribution = "Corretto", force = TRUE)
} # }
```
