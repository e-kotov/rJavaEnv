# Obtain User Consent for rJavaEnv

Get user consent for rJavaEnv to write and update files on the file
system. rJavaEnv needs permission to manage files in your project and
cache directories to function correctly.

## Usage

``` r
rje_consent(provided = FALSE)
```

## Arguments

- provided:

  Logical indicating if consent is already provided. To provide consent
  in non-interactive R sessions use
  `rJavaEnv::rje_consent(provided = TRUE)`. Default is `FALSE`.

## Value

`TRUE` if consent is given, otherwise an error is raised.

## Details

In line with [CRAN
policies](https://cran.r-project.org/web/packages/policies.html),
explicit user consent is required before making these changes. Please
call `rJavaEnv::consent()` to provide consent.

Alternatively, you can set the following R option (especially useful for
non-interactive R sessions):

    options(rJavaEnv.consent = TRUE)

The function is based on the code of the `renv` package. Copyright 2023
Posit Software, PBC License:
https://github.com/rstudio/renv/blob/main/LICENSE

## Examples

``` r
if (FALSE) { # \dontrun{

# to provide consent and prevent other functions from interrupting to get the consent
rje_consent(provided = TRUE)
} # }
```
