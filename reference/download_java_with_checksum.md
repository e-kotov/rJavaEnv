# Download and verify checksum

Internal function to download a Java distribution and verify its
checksum

## Usage

``` r
download_java_with_checksum(build, dest, quiet, force)
```

## Arguments

- build:

  A java_build object containing download metadata

- dest:

  Destination file path

- quiet:

  Logical, suppress messages

- force:

  Logical, overwrite existing files

## Value

Path to downloaded file
