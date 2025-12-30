# rJava Path-Locking Documentation

Documentation template for rJava path-locking behavior.

## Usage

``` r
rjava_path_locking_note()
```

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
