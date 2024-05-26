
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rJavaEnv

<!-- badges: start -->

<a href="https://lifecycle.r-lib.org/articles/stages.html#experimental"
target="_blank"><img
src="https://img.shields.io/badge/lifecycle-experimental-orange.svg"
alt="Lifecycle: experimental" /></a>
<a href="https://CRAN.R-project.org/package=rJavaEnv"
target="_blank"><img src="https://www.r-pkg.org/badges/version/rJavaEnv"
alt="CRAN status" /></a>

<!-- badges: end -->

The goal of `rJavaEnv` is to manage multiple Java JDK in R projects by
automating the process of downloading, installing and configuring Java
environments on a per-project basis. This package is inspired by the
<a href="https://rstudio.github.io/renv/"
target="_blank"><code>renv</code></a> package for managing R
environments in R projects.

The idea is that you can request a specific Java Development Kit (JDK)
in your project, and `rJavaEnv` will download and install the requested
Java environment in a project-specific directory and set the PATH
variable for when you are using this project. Therefore, you can have
Amazon Corretto Java 21 for a project that uses
<a href="https://github.com/ipeaGIT/r5r"
target="_blank"><code>r5r</code></a> package, and Adoptium Eclipse
Temurin Java 8 for a project that uses
<a href="https://github.com/ropensci/opentripplanner"
target="_blank"><code>opentripplanner</code></a> package.

Actually, you do not have to have any Java installed on your machine at
all. Each Java JDK ‘flavour’ will quietly live with all its executables
in the respective project directory without contaminating your system.

**WARNING** This package is in the early stages of development and is
not yet ready for production use. Function names, arguments, and
behaviour may change in future versions.

## Installation

You can install the development version of `rJavaEnv` like so:

``` r
devtools::install_github("e-kotov/rJavaEnv")
```

# Examples

## 1. Simple - install Java in current directory/project and set environment

This will download Java 21 distribution, install it in the current
project directory, and set the Java environment to Java 8, all in one
command, no hassle. Afer that, you can use Java-based R packages in your
project without worrying about Java versions.

``` r
library(rJavaEnv)
```

``` r
java_quick_install(version = 21)
#> Detected platform: macos
#> Detected architecture: arm64
#> You can change the platform and architecture by specifying the 'platform' and 'arch' arguments.
#> Downloading Java 21 (Corretto) for macos arm64 to /Users/ek/Library/Caches/org.R-project.R/R/rJavaEnv/amazon-corretto-21-aarch64-macos-jdk.tar.gz
#> Download completed.
#> Java 21 (amazon-corretto-21-aarch64-macos-jdk.tar.gz) for macos installed at .//bin/java/macos/aarch64/21
#> JAVA_HOME set to .//bin/java/macos/aarch64/21
```

## 2. Extended example - do things step by step

This will be useful if you want to manage multiple Java environments in
your project or if you want to understand the process better.

### Download Java

The distribution will be cached in the user-specific data directory. Let
us download Java 8 and 22 from default flavour (currently, Amazon
Corretto). The function’s output is the path to the downloaded Java
distribution file.

``` r
java_8_distrib_path <- rJavaEnv::download_java(version = 8)
#> Detected platform: macos
#> Detected architecture: arm64
#> You can change the platform and architecture by specifying the 'platform' and 'arch' arguments.
#> Downloading Java 8 (Corretto) for macos arm64 to /Users/ek/Library/Caches/org.R-project.R/R/rJavaEnv/amazon-corretto-8-aarch64-macos-jdk.tar.gz
#> Download completed.
```

``` r
java_22_distrib_path <- rJavaEnv::download_java(version = 22)
#> Detected platform: macos
#> Detected architecture: arm64
#> You can change the platform and architecture by specifying the 'platform' and 'arch' arguments.
#> Downloading Java 22 (Corretto) for macos arm64 to /Users/ek/Library/Caches/org.R-project.R/R/rJavaEnv/amazon-corretto-22-aarch64-macos-jdk.tar.gz
#> Download completed.
```

### Install Java

Install Java 8 and 22 from the downloaded file into current
project/working directory. The default install path is into
./bin/`platform`/`processor_architecture`/ folder in the current
working/project directory, but can be customised, see docs for
`rJavaEnv::install_java()`. The output of the function is the path to
the installed Java directory. Note that by default
`rJavaEnv::install_java()` sets the JAVA_HOME and PATH environment
variables to the installed Java directory, but you can turn this off
with the `autoset_java_path` argument.

``` r
java_8_install_path <- rJavaEnv::install_java(java_8_distrib_path)
#> Java 8 (amazon-corretto-8-aarch64-macos-jdk.tar.gz) for macos installed at .//bin/java/macos/aarch64/8
#> JAVA_HOME set to .//bin/java/macos/aarch64/8
```

``` r
java_22_install_path <- rJavaEnv::install_java(java_22_distrib_path)
#> Java 22 (amazon-corretto-22-aarch64-macos-jdk.tar.gz) for macos installed at .//bin/java/macos/aarch64/22
#> JAVA_HOME set to .//bin/java/macos/aarch64/22
```

### Check Java installation

This will run a separate R process, set JAVA_HOME to the given path, and
check the Java version that will be picked up if you were to use the
same JAVA_HOME in the current R session. This does not affect the
current R session. That is, you will be able to set the path to any Java
in the current session without restarting it before you initialise Java
using <a href="https://github.com/s-u/rJava"
target="_blank"><code>rJava</code></a> for the first time.

``` r
rJavaEnv::check_java_version_rjava(java_8_install_path)
#> If you set JAVA_HOME to path: .//bin/java/macos/aarch64/8  rJava and other Java-based packages will use Java version: 1.8.0_412
```

``` r
rJavaEnv::check_java_version_rjava(java_22_install_path)
#> If you set JAVA_HOME to path: .//bin/java/macos/aarch64/22  rJava and other Java-based packages will use Java version: 22.0.1
```

### Set Java Environment

We have installed two Java environments in our project directory. We
installed version 22 the last, so it is the default Java environment, as
`rJavaEnv::install_java()` sets the JAVA_HOME and PATH environment
variables to the installed Java directory by default. However, since we
have not yet initialised Java using `rJava::.jinit()` or by using some
other rJava-dependent package, the Java environment is not yet set in
the current R session irreversibly. So we can set the desired Java
environment manually. The function below sets the JAVA_HOME and PATH
environment variables to the desired Java environment.

``` r
rJavaEnv::set_java_env(java_8_install_path)
#> JAVA_HOME set to .//bin/java/macos/aarch64/8
```

### Check Current Java Version

Check using system commands. This will be relevant for packages like
<a href="https://github.com/ropensci/opentripplanner"
target="_blank"><code>opentripplanner</code></a> that don’t actually use
rJava, but manage a Java process using system commands.

``` r
java_path <- system("which java", intern = TRUE)
java_version <- system("java -version 2>&1", intern = TRUE)

cat("Java path:", java_path, "\n\n")
#> Java path: .//bin/java/macos/aarch64/8/bin/java
```

``` r
cat("Java version:\n", paste(java_version, collapse = "\n"), "\n")
#> Java version:
#>  openjdk version "1.8.0_412"
#> OpenJDK Runtime Environment Corretto-8.412.08.1 (build 1.8.0_412-b08)
#> OpenJDK 64-Bit Server VM Corretto-8.412.08.1 (build 25.412-b08, mixed mode)
```

Finally, check the Java version using
<a href="https://github.com/s-u/rJava"
target="_blank"><code>rJava</code></a>. This is relevant to the packages
like <a href="https://github.com/ipeaGIT/r5r"
target="_blank"><code>r5r</code></a> that depend on rJava.

``` r
rJava::.jinit(force.init = TRUE)
rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
#> [1] "1.8.0_412"
```

That’s it! You have successfully installed and set up Java environments
in your project directory. You can now use Java-based R packages in your
project without worrying about Java versions.

# Limitations

The limitation is that if you want to switch to another Java
environment, you will have to restart the current R session and set the
JAVA_HOME and PATH environment variables to the desired Java environment
from scratch using `rJavaEnv::set_java_env()`. This cannot be done
dynamically within the same R session due to the way Java is initialized
in R.

Therefore, if you need to use R packages that depend on different Java
versions within the same project, you will have to create separate R
scripts for each Java environment and run them in separate R sessions.
One effective way of doing this is to use the
<a href="https://github.com/r-lib/callr"
target="_blank"><code>callr</code></a> package to run R scripts in
separate R sessions. Another option is to use the
<a href="https://github.com/ropensci/targets"
target="_blank"><code>targets</code></a> package to manage the whole
project workflow, which, as a side effect, will lead to all R scripts
being run in separate R sessions.

# Helper functions

Check the cache created by the package to store downloaded Java
distributions.

``` r
rJavaEnv::list_java_distributions_cache()
#> Contents of the Java distributions cache folder:
#> [1] "amazon-corretto-21-aarch64-macos-jdk.tar.gz"
#> [2] "amazon-corretto-22-aarch64-macos-jdk.tar.gz"
#> [3] "amazon-corretto-8-aarch64-macos-jdk.tar.gz"
```

Remove the cache created by the package to store downloaded Java
distributions.

``` r
rJavaEnv::clear_java_distributions_cache(confirm = FALSE)
```

To remove the Java distributions already unpacked into the current
working/project folder, just delete the default or user defined folder:

``` r
unlink("./bin", recursive = TRUE)
```
