# Java build metadata object

Constructor for java_build objects that contain all metadata needed for
download

## Usage

``` r
java_build(
  vendor,
  version,
  major = NULL,
  semver = NA_character_,
  platform,
  arch,
  download_url,
  filename,
  checksum = NULL,
  checksum_type = NULL,
  backend = "native"
)
```

## Arguments

- vendor:

  Java vendor name (e.g., "Corretto", "Temurin", "Zulu")

- major:

  Major Java version number

- semver:

  Full semantic version string (optional)

- platform:

  Platform OS (e.g., "linux", "macos", "windows")

- arch:

  Architecture (e.g., "x64", "aarch64")

- download_url:

  URL to download the Java distribution

- filename:

  Filename for the downloaded archive

- checksum:

  Expected checksum value for verification

- checksum_type:

  Type of checksum (e.g., "md5", "sha256", "sha512")

- backend:

  Backend used for resolution ("native" or "sdkman")

## Value

A java_build object (S3 list)
