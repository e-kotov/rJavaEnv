# rJava Path-Locking Documentation

Documentation template for rJava path-locking behavior.

## Usage

``` r
rjava_path_locking_note()
```

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
