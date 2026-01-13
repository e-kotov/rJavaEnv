# Check if version string is a SDKMAN identifier

Uses two-step detection:

1.  Primary: Check if ends with known vendor suffix

2.  Fallback: Regex pattern for unknown future vendors

## Usage

``` r
is_sdkman_identifier(version)
```

## Arguments

- version:

  Version string to check

## Value

Logical
