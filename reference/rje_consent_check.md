# Verify User Consent for rJavaEnv

Ensure that the user has granted permission for rJavaEnv to manage files
on their file system.

## Usage

``` r
rje_consent_check()
```

## Value

`TRUE` if consent is verified, otherwise an error is raised.

## Details

The function is based on the code of the `renv` package. Copyright 2023
Posit Software, PBC License:
https://github.com/rstudio/renv/blob/main/LICENSE
