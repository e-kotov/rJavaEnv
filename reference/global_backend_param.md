# Global Backend Parameter

Documentation for the `backend` parameter, used for specifying the
download source.

## Usage

``` r
global_backend_param(backend)
```

## Arguments

- backend:

  Download backend to use. One of "native" (vendor APIs) or "sdkman".
  Defaults to "native". Can also be set globally via
  `options(rJavaEnv.backend = "sdkman")`.
