# Get valid Java versions without network overhead

Returns a list of valid Java versions from the fastest available source.
This function never triggers a network call. It checks:

1.  Session cache (current options)

2.  Persistent file cache (24 hours)

3.  Shipped fallback list for the current platform

This is useful for offline workflows or when parsing filenames.

## Usage

``` r
java_valid_versions_fast()
```

## Value

A character vector of valid Java versions.
