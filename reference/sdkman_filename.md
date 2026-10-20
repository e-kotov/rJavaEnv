# File name of a cached SDKMAN archive

Depends only on the request, not on the resolved build, so a cached
archive can be found without querying the SDKMAN API.

## Usage

``` r
sdkman_filename(version, distribution, platform, arch)
```

## Arguments

- version:

  Java version specification. Accepts:

  - **Major version** (e.g., `21`, `17`): Downloads the latest release
    for that major version.

  - **Specific version** (e.g., `"21.0.9"`, `"11.0.29"`): Requests that
    exact release. Only
    [`java_resolve()`](https://www.ekotov.pro/rJavaEnv/reference/java_resolve.md)
    and functions built on it check the installed runtime version.

  - **SDKMAN identifier** (e.g., `"25.0.1-amzn"`, `"24.0.2-open"`): Uses
    the SDKMAN backend automatically. When an identifier is detected,
    the `distribution` and `backend` arguments are **ignored** and
    derived from the identifier. Find available identifiers in the
    `identifier` column of
    [`java_list_available`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)`(backend = "sdkman")`.

- distribution:

  Java distribution name

- platform:

  Platform OS

- arch:

  Architecture

## Value

File name
