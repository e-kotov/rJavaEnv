
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rJavaEnv: Java Environments for R Projects <a href="http://www.ekotov.pro/rJavaEnv/"><img src="man/figures/logo.png" align="right" height="134" alt="rJavaEnv website" /></a>

<!-- badges: start -->

[![Project Status: WIP – Initial development is in progress, but there
has not yet been a stable, usable release suitable for the
public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
<a href="https://lifecycle.r-lib.org/articles/stages.html#experimental"
target="_blank"><img
src="https://img.shields.io/badge/lifecycle-experimental-orange.svg"
alt="Lifecycle: experimental" /></a>
<a href="https://CRAN.R-project.org/package=rJavaEnv"
target="_blank"><img src="https://www.r-pkg.org/badges/version/rJavaEnv"
alt="CRAN status" /></a>
[![R-CMD-check](https://github.com/e-kotov/rJavaEnv/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/e-kotov/rJavaEnv/actions/workflows/R-CMD-check.yaml)
[![pkgcheck](https://github.com/e-kotov/rJavaEnv/workflows/pkgcheck/badge.svg)](https://github.com/e-kotov/rJavaEnv/actions?query=workflow%3Apkgcheck)
[![codecov](https://codecov.io/github/e-kotov/rJavaEnv/graph/badge.svg?token=2UKGZVNO5V)](https://codecov.io/github/e-kotov/rJavaEnv)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.11403009.svg)](https://dx.doi.org/10.5281/zenodo.11403009)

<!-- badges: end -->

The goal of `rJavaEnv` is to manage multiple Java JDKs in R projects by
automating the process of downloading, installing, and configuring Java
environments on a per-project basis. This package is inspired by the
<a href="https://rstudio.github.io/renv/"
target="_blank"><code>renv</code></a> package for managing R
environments in R projects.

You can request a specific Java Development Kit (JDK) in your project,
and `rJavaEnv` will download and install the requested Java environment
in a project-specific directory and set the PATH and JAVA_HOME for when
you are using this project. Therefore, you can have different Java
versions for different projects without contaminating your system with
different Java versions.

**WARNING** This package is in the early stages of development and is
not yet ready for production use. Please test it thoroughly before using
it in your projects.

## Install

You can install the development version of `rJavaEnv` from GitHub:

``` r
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

remotes::install_github("e-kotov/rJavaEnv")
```

## Simple Example

``` r
rJavaEnv::java_quick_install(version = 21)
```

This will:

- download Java 21 distribution compatible with the current operating
  system and processor architecture into a local cache folder;

- extract the downloaded Java distribution into another cache folder;

- create a symbolic link (for macOS and Linux) or junction (for Windows,
  if that fails, just copies the files)
  **rjavaenv/`platform`/`processor_architecture`/`java_version`** in the
  current directory/project to point to the cached installation;

- set the current session’s JAVA_HOME and PATH environment variables to
  point to the installed (symlinked) Java distribution;

- add code to .Rprofile file in the current directory/project to set
  JAVA_HOME and PATH environment variables when the project is opened in
  RStudio.

After that, you can even remove `rJavaEnv` completely, as the Java
environment will be set up in the project directory with the base R code
that does not rely on `rJavaEnv`.

## Functions Overview

The package has several core functions:

1.  `java_quick_install()`
    - Downloads, installs, and sets Java environment in the current
      working/project directory, all in one line of code.
2.  `java_check_version_cmd()`
    - Checks the installed Java version using terminal commands. For
      packages like
      <a href="https://github.com/ropensci/opentripplanner"
      target="_blank"><code>opentripplanner</code></a>, that performs
      Java calls using command line.
3.  `java_version_check_rjava()`
    - Checks the installed Java version using `rJava` in a separate R
      session. For `rJava`-dependent packages such as
      <a href="https://github.com/ipeaGIT/r5r"
      target="_blank"><code>r5r</code></a>.
4.  `java_download()`
    - Downloads a specified version and distribution of Java.
5.  `java_install()`
    - Installs a Java distribution file into current (or user-specified)
      project directory.
6.  `java_env_set()`
    - Sets the JAVA_HOME and PATH environment variables to a given path
      in current R session and/or in the .Rprofile file in the project
      directory.
7.  `java_env_unset()`
    - Remove the JAVA_HOME and PATH environment variables from the
      .Rpofile file in the project directory (but not in the current R
      session, please restart the session so that R picks up the system
      Java).
8.  `java_list()`
    - Lists all or some Java versions linked in the current project (or
      cached distributions or installations).
9.  `java_clear()`
    - Removes all or some Java versions linked in the current project
      (or cached distributions or installations).

See more details on all the functions in the
<a href="https://e-kotov.github.io/rJavaEnv/reference/index.html"
target="_blank">Reference</a>.

For detailed usage, see the [Quick Start
Vignette](https://www.ekotov.pro/rJavaEnv/articles/rJavaEnv.html) (work
in progress).

## Limitations

Currently, `rJavaEnv` only supports major Java versions such as 8, 11,
17, 21, 22. The download and install functions ignore the minor version
of the Java distribution and just downloads the latest stable subversion
of the specified major version. This is done to simplify the process and
avoid the need to update the package every time a new minor version of
Java is released. For most users this should be sufficient, but this is
substandard for full reproducibility.

The main limitation is that if you want to switch to another Java
environment, you will most likely have to restart the current R session
and set the JAVA_HOME and PATH environment variables to the desired Java
environment using `rJavaEnv::java_env_set()`. This cannot be done
dynamically within the same R session due to the way Java is initialized
in R, particularly with the `rJava`-dependent packages such as
<a href="https://github.com/ipeaGIT/r5r"
target="_blank"><code>r5r</code></a>. With packages like
<a href="https://github.com/ropensci/opentripplanner"
target="_blank"><code>opentripplanner</code></a>, that performs Java
calls using command line, you can switch Java environments dynamically
within the same R session as much as you want.

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
being run in separate R sessions. To use `rJavaEnv` with `targets`, you
will need to download and install several Java environments using
`rJavaEnv::java_download()` and `rJavaEnv::java_install()` and set the
relevant path with `rJavaEnv::java_env_set()` at the beginning of each
function that requires a certain Java version.

## Future work

The future work includes:

- Add support for more Java distributions and versions

- Take care of <a
  href="https://solutions.posit.co/envs-pkgs/using-rjava/#reconfigure-r"
  target="_blank"><code>R CMD javareconf</code></a>

- Possibly add support for specifying Java version beyond the major
  version

- Possibly allow downloading several Java distributions in one function
  call, e.g. different major versions of the same ‘flavour’ or different
  ‘flavours’ of the same major version

- Possibly add automation to get the Java that is required by specific
  Java-dependent R packages

I am open to suggestions and contributions, welcome to
<a href="https://github.com/e-kotov/rJavaEnv/issues"
target="_blank">issues</a> and
<a href="https://github.com/e-kotov/rJavaEnv/pulls" target="_blank">pull
requests</a>.

## Acknowledgements

I thank rOpenSci for the
<a href="https://devguide.ropensci.org/" target="_blank">Dev Guide</a>,
as well as Hadley Wickham and Jennifer Bryan for the
<a href="https://r-pkgs.org/" target="_blank">R Packages</a> book.

Package hex sticker logo is partially generated by DALL-E by OpenAI. The
logo also contains the original R logo.

## Citation

To cite package ‘rJavaEnv’ in publications use:

Kotov E (2024). *rJavaEnv: Java Environments for R Projects*.
<doi:10.5281/zenodo.11403010> <https://doi.org/10.5281/zenodo.11403010>,
<https://github.com/e-kotov/rJavaEnv>.

BibTeX:

    @Manual{rjavaenv,
      title = {rJavaEnv: Java Environments for R Projects},
      author = {Egor Kotov},
      year = {2024},
      url = {https://github.com/e-kotov/rJavaEnv},
      doi = {10.5281/zenodo.11403010},
    }
