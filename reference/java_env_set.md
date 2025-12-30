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

**Important for **rJava** Users**: This function sets environment
variables (JAVA_HOME, PATH) that affect both command-line Java tools and
**rJava** initialization. However, due to **rJava**'s path-locking
behavior when [`.jinit`](https://rdrr.io/pkg/rJava/man/jinit.html) is
called (see <https://github.com/s-u/rJava/issues/25>,
<https://github.com/s-u/rJava/issues/249>, and
<https://github.com/s-u/rJava/issues/334>), this function must be called
**BEFORE** [`.jinit`](https://rdrr.io/pkg/rJava/man/jinit.html) is
invoked. Once [`.jinit`](https://rdrr.io/pkg/rJava/man/jinit.html)
initializes, the Java version is locked for that R session and cannot be
changed without restarting R.

[`.jinit`](https://rdrr.io/pkg/rJava/man/jinit.html) is invoked (and
Java locked) when you:

- Explicitly call [`library(rJava)`](http://www.rforge.net/rJava/)

- Load any package that imports **rJava** (which auto-loads it as a
  dependency)

- Even just use IDE autocomplete with `rJava::` (this triggers
  initialization!)

- Call any **rJava**-dependent function

Once any of these happen, the Java version used by **rJava** for that
session is locked in. For command-line Java tools that don't use
**rJava**, this function can be called at any time to switch Java
versions for subsequent system calls.

## Examples

``` r
if (FALSE) { # \dontrun{
# download, install Java 17
java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
java_home <- java_install(
  java_distrib_path = java_17_distrib,
  project_path = tempdir(),
  autoset_java_env = FALSE
)

# now manually set the JAVA_HOME and PATH environment variables in current session
java_env_set(
  where = "session",
  java_home = java_home
)

# or set JAVA_HOME and PATH in the spefific projects' .Rprofile
java_env_set(
  where = "project",
  java_home = java_home,
  project_path = tempdir()
)

} # }
```
