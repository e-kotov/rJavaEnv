# Read the version of an already running rJava JVM

Does not load rJava or initialize its JVM. Loading rJava and starting
its JVM are distinct events; a loaded but uninitialized namespace
returns NULL.

## Usage

``` r
java_check_current_rjava_version()
```

## Value

Full Java version string, or NULL if not already running or unreadable.
