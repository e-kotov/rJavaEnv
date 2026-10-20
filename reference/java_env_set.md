# Set the `JAVA_HOME` and `PATH` environment variables to a given path

Sets the JAVA_HOME and PATH environment variables for command-line Java
tools and rJava initialization. See details for important information
about rJava timing.

## Usage

``` r
java_env_set(
  where = c("session", "both", "project"),
  java_home,
  project_path = NULL,
  quiet = FALSE
)
```

## Arguments

- where:

  Where to set the `JAVA_HOME`: "session", "project", or "both".
  Defaults to "session" and only updates the paths in the current R
  session. When "both" or "project" is selected, the function updates
  the .Rprofile file in the project directory to set the JAVA_HOME and
  PATH environment variables at the start of the R session.

- java_home:

  The path to the desired `JAVA_HOME`.

- project_path:

  A `character` vector of length 1 containing the project directory
  where Java should be installed. If not specified or `NULL`, defaults
  to the current working directory.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

Nothing. Sets the JAVA_HOME and PATH environment variables.

## Additional Details

To use a different Java version with rJava-dependent packages, you must:

1.  Set JAVA_HOME using this function BEFORE loading rJava or any
    package that imports it

2.  Restart your R session if you already loaded rJava with the wrong
    Java version

## rJava Path-Locking

**Important for *rJava* Users**: This function sets environment
variables (JAVA_HOME, PATH) that affect both command-line Java tools and
*rJava* initialization. Configure Java **before loading rJava**,
including before
[`requireNamespace("rJava")`](https://www.rforge.net/rJava/) or loading
packages that import it. Loading the namespace can resolve and lock the
JVM library path even before `.jinit()` starts the JVM. See
<https://github.com/s-u/rJava/issues/334> and
<https://github.com/s-u/rJava/issues/25>.

Once rJava has loaded, restart R before selecting another JVM, or use
[`with_rjava_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_rjava_env.md)
to run with a different JVM in a fresh R process.
[`java_check_compatibility()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_compatibility.md)
does not load rJava or initialize a JVM.
[`java_check_version_rjava()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_rjava.md)
performs its probe in a separate R process.

For command-line Java tools that don't use *rJava*, this function can be
called at any time to switch Java versions for subsequent system calls.

## Examples

``` r
# \donttest{
# download, install Java 17
java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
#> Detected platform: linux
#> Detected architecture: x64
#> You can change the platform and architecture by specifying the `platform` and
#> `arch` arguments.
#> File already cached: native-amazon-corretto-17.0.20.12.1-linux-x64.tar.gz
java_home <- java_install(
  java_distrib_path = java_17_distrib,
  project_path = tempdir(),
  autoset_java_env = FALSE
)
#> Java distribution native-amazon-corretto-17.0.20.12.1-linux-x64.tar.gz already
#> unpacked at
#> /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17
#> Java 17 (native-amazon-corretto-17.0.20.12.1-linux-x64.tar.gz) for linux x64
#> installed at
#> /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17 and
#> symlinked to /tmp/RtmplslJt6/rjavaenv/linux/x64/Corretto/native/17

# now manually set the JAVA_HOME and PATH environment variables in current session
java_env_set(
  where = "session",
  java_home = java_home
)
#> ℹ You have rJava loaded in the current session.Loading rJava can lock the JVM library path even before .jinit() starts the JVM.Set Java before loading rJava. To change its JVM, restart R or use `with_rjava_env()`.See https://github.com/s-u/rJava/issues/334
#> ✔ Current R Session: JAVA_HOME and PATH set to /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17
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

# or set JAVA_HOME and PATH in the spefific projects' .Rprofile
java_env_set(
  where = "project",
  java_home = java_home,
  project_path = tempdir()
)
#> ✔ Current R Project/Working Directory: JAVA_HOME and PATH set to '/home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17' in .Rprofile at '/tmp/RtmplslJt6'
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

# }
```
