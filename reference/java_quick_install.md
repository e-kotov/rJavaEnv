# Download and install and set Java in current working/project directory

Download and install and set Java in current working/project directory

## Usage

``` r
java_quick_install(
  version = 21,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  project_path = NULL,
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
  temp_dir = FALSE
)
```

## Arguments

- version:

  Java version specification. Accepts:

  - **Major version** (e.g., `21`, `17`): Downloads the latest release
    for that major version.

  - **Specific version** (e.g., `"21.0.9"`, `"11.0.29"`): Downloads the
    exact version.

  - **SDKMAN identifier** (e.g., `"25.0.1-amzn"`, `"24.0.2-open"`): Uses
    the SDKMAN backend automatically. When an identifier is detected,
    the `distribution` and `backend` arguments are **ignored** and
    derived from the identifier. Find available identifiers in the
    `identifier` column of
    [`java_list_available`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)`(backend = "sdkman")`.

- distribution:

  The Java distribution to download. One of "Corretto", "Temurin", or
  "Zulu". Defaults to "Corretto". Ignored if `version` is a SDKMAN
  identifier.

- backend:

  Download backend to use. One of "native" (vendor APIs) or "sdkman".
  Defaults to "native". Can also be set globally via
  `options(rJavaEnv.backend = "sdkman")`.

- project_path:

  A `character` vector of length 1 containing the project directory
  where Java should be installed. If not specified or `NULL`, defaults
  to the current working directory.

- platform:

  The platform for which to download the Java distribution. Defaults to
  the current platform.

- arch:

  The architecture for which to download the Java distribution. Defaults
  to the current architecture.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- temp_dir:

  A logical. Whether the file should be saved in a temporary directory.
  Defaults to `FALSE`.

## Value

Invisibly returns the path to the Java home directory. If quiet is set
to `FALSE`, also prints a message indicating that Java was installed and
set in the current working/project directory.

## Examples

``` r
# \donttest{

# quick download, unpack, install and set in current working directory default Java version (21)
java_quick_install(17, temp_dir = TRUE)
#> Detected platform: linux
#> Detected architecture: x64
#> You can change the platform and architecture by specifying the `platform` and
#> `arch` arguments.
#> File already cached: amazon-corretto-17.0.18.9.1-linux-x64.tar.gz
#> Java distribution amazon-corretto-17.0.18.9.1-linux-x64.tar.gz already unpacked
#> at /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17
#> ℹ You have rJava loaded in the current session. rJava gets locked to the Java version that was active when it was first initialized.rJava is initialized when you: (1) call `library(rJava)`, (2) load a package that imports rJava, (3) use IDE autocomplete with `rJava::`, or (4) call any rJava function.This path-locking is a limitation of rJava itself. See: https://github.com/s-u/rJava/issues/25, https://github.com/s-u/rJava/issues/249, and https://github.com/s-u/rJava/issues/334Unless you restart the R session or run your code in a new R subprocess (using targets or callr), the new `JAVA_HOME` and `PATH` will not take effect.
#> ✔ Current R Session: JAVA_HOME and PATH set to /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17
#> ✔ Current R Project/Working Directory: JAVA_HOME and PATH set to '/home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17' in .Rprofile at '/tmp/RtmpoeQtFr/rJavaEnv_project'
#> ℹ On Linux, for rJava to work correctly, `libjvm.so` was dynamically loaded in
#>   the current session.
#>   To make this change permanent for installing rJava-dependent packages from
#>   source, you may need to reconfigure Java.
#>   See <https://solutions.posit.co/envs-pkgs/using-rjava/#reconfigure-r> for
#>   details.
#>   If you have admin rights, run the following in your terminal:
#>   `R CMD javareconf
#>   JAVA_HOME=/home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17`
#>   If you do not have admin rights, run:
#>   `R CMD javareconf
#>   JAVA_HOME=/home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17
#>   -e`
#> Java NA (amazon-corretto-17.0.18.9.1-linux-x64.tar.gz) for linux x64 installed
#> at /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17 and
#> symlinked to
#> /tmp/RtmpoeQtFr/rJavaEnv_project/rjavaenv/linux/x64/Corretto/native/NA
# }
```
