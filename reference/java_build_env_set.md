# Set up the environment for building R packages with Java dependencies from source

This function configures the current R session with the necessary
environment variables to compile Java-dependent packages like 'rJava'
from source. **Note: this function is still experimental.**

## Usage

``` r
java_build_env_set(
  java_home = Sys.getenv("JAVA_HOME"),
  where = c("session", "project", "both"),
  project_path = NULL,
  quiet = FALSE
)
```

## Arguments

- java_home:

  The path to the desired `JAVA_HOME`. Defaults to the value of the
  `JAVA_HOME` environment variable.

- where:

  Where to set the build environment: "session", "project", or "both".
  Defaults to "session". When "both" or "project" is selected, the
  function updates the .Rprofile file in the project directory.

- project_path:

  The path to the project directory, required when `where` is "project"
  or "both". Defaults to the current working directory.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

Invisibly returns `NULL` after setting the environment variables.

## Examples

``` r
# \donttest{
# Download and install Java 17
java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
#> Detected platform: linux
#> Detected architecture: x64
#> You can change the platform and architecture by specifying the `platform` and
#> `arch` arguments.
#> Downloading Corretto Java 17...
#> Verifying sha256 checksum...
#> Checksum verified.
java_home_path <- java_install(
  java_distrib_path = java_17_distrib,
  project_path = tempdir(),
  autoset_java_env = FALSE # Manually set env
)
#> Java NA (amazon-corretto-17.0.17.10.1-linux-x64.tar.gz) for linux x64 installed
#> at /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17 and
#> symlinked to /tmp/RtmpxvyniH/rjavaenv/linux/x64/Corretto/native/NA

# Set up the build environment in the current session
java_build_env_set(java_home = java_home_path)
#> ✔ Build environment variables set for the current R session.
#> ℹ The environment is now set up to build Java-dependent packages from source.
#>   You can now run: `install.packages("rJava", type = "source")`
#> ! Please ensure your repository points to a source package repository (e.g.,
#>   https://cloud.r-project.org). Some repositories may serve pre-built binaries
#>   even when `type = "source"` is specified.
#> Warning: System dependencies required for building rJava from source on Linux.
#> ℹ On Debian/Ubuntu, you may need to install: libpcre2-dev, libdeflate-dev,
#>   libzstd-dev, liblzma-dev, libbz2-dev, zlib1g-dev, and libicu-dev.
#> ℹ Example installation command for Debian/Ubuntu:
#>   `sudo apt-get update && sudo apt-get install -y --no-install-recommends
#>   libpcre2-dev libdeflate-dev libzstd-dev liblzma-dev libbz2-dev zlib1g-dev
#>   libicu-dev && sudo rm -rf /var/lib/apt/lists/*`

# Now, install rJava from source
install.packages("rJava", type = "source", repos = "https://cloud.r-project.org")
#> Installing package into ‘/home/runner/work/_temp/Library’
#> (as ‘lib’ is unspecified)
# }
```
