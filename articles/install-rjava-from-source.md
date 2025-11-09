# Install `rJava` from source

The basics of using `rJavaEnv` are covered in the [Quick Start
Guide](https://www.ekotov.pro/rJavaEnv/articles/rJavaEnv.qmd), which
demonstrates how to install Java in one line of code. This tutorial will
show you how to install `rJava` packag from source if you want to or
have to.

``` r
library(rJavaEnv)
```

Assume your project directory is currently in a temporary directory.
Feel free to skip that, if you are already working in a desired project
directory where you would like to install `Java`. In the example outputs
below you will see paths that point to a temporary directory, but in a
real project you would see your project directory instead.

``` r
project_dir <- tempdir()
setwd(project_dir)
```

## 1. Install Java

You can use detailed step-by-step process from the [step-by-step
vignette](https://www.ekotov.pro/rJavaEnv/articles/rJavaEnv-step-by-step.qmd)
to download, unpack, install and link `Java` JDK of your desired
version, but for simplicity, let’s use shortcut functions

Either quick install Java into current project directory:

``` r
java_quick_install(version = 21)
```

> **Note**
>
> You might also do `java_home <- java_quick_install(version = 21)`, as
> this will save the path to the installed Java home directory into
> `java_home` variable for later use, but the function to set the build
> environment actually uses the `JAVA_HOME` environment variable set by
> [`java_quick_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_quick_install.md)
> by default, so it’s not necessary.

Or you can simply do:

``` r
use_java(21)
```

This will essentially do the same as
[`java_quick_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_quick_install.md),
but only sets the `JAVA_HOME` and `PATH` environment variables in the
current R session, without modifying your `.Rprofile` file or
copying/linking the installation folder into your project directory.

## 2. Set the environment for building `rJava`

Now simply use:

``` r
java_build_env_set()
```

That is it, `java_build_env_set` will detect your platform and
architecture and set the correct environment variables. If you want
advanced control, you can use `java_home` to set custom `JAVA_HOME`
path, or use `where='project'` to set the environment variables in your
`.Rprofile` file in the current project directory. See
[`?java_build_env_set`](https://www.ekotov.pro/rJavaEnv/reference/java_build_env_set.md)
for details.

Once
[`java_build_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_build_env_set.md)
completes, it will print out OS-specific notes. In summary,

- **On Linux**, you may need to install several system dependencies. For
  Debian/Ubuntu, this can be done with:
  `bash sudo apt-get update && sudo apt-get install -y --no-install-recommends libpcre2-dev libdeflate-dev libzstd-dev liblzma-dev libbz2-dev zlib1g-dev libicu-dev && sudo rm -rf /var/lib/apt/lists/*`

- **On Windows**, `Rtools` is required. You can download it from
  [https://cran.r-project.org/bin/windows/Rtools/](https://cran.r-project.org/bin/windows/Rtools/).

- **On macOS**, you’ll need the Xcode Command Line Tools. Install them
  by running: `bash xcode-select --install`

## 3. Install `rJava` from source

Now you are ready to install `rJava` from source:

``` r
install.packages("rJava", type = "source")
```

If you are on a Linux distribution with pre-configured
[`Posit Package Manager` (PPM)](https://packagemanager.posit.co/)
repository that serves pre-compiled binaries even if `type="source"` (or
in a similar situation on `Windows` or `macOS`), you can use
`repos = "https://cloud.r-project.org"` to force installation from
source:

``` r
install.packages("rJava", type = "source", repos = "https://cloud.r-project.org")
```

And that is it. You have successfully installed `rJava` from source. If
you restart the R session, the build-related environment variables will
be reset. To use your newly installed `rJava` package just do:

``` r
library(rJavaEnv)
use_java(21) # or whatever version you installed
library(rJava)
```
