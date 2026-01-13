# Read JSON from a URL

Helper function to read JSON from a URL using RcppSimdJson for fast
parsing

## Usage

``` r
read_json_url(url, max_simplify_lvl = "data_frame")
```

## Arguments

- url:

  URL to read JSON from

- max_simplify_lvl:

  Simplification level (default: "data_frame")

## Value

Parsed JSON object
