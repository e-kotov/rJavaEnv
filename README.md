
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rJavaEnv: Java Environments for R Projects <a href="http://www.ekotov.pro/rJavaEnv/"><img src="man/figures/logo.png" align="right" height="134" alt="rJavaEnv website" /></a>

<!-- badges: start -->

<a href="https://lifecycle.r-lib.org/articles/stages.html#experimental"
target="_blank"><img
src="https://img.shields.io/badge/lifecycle-experimental-orange.svg"
alt="Lifecycle: experimental" /></a>
<a href="https://CRAN.R-project.org/package=rJavaEnv"
target="_blank"><img src="https://www.r-pkg.org/badges/version/rJavaEnv"
alt="CRAN status" /></a>
[![R-CMD-check](https://github.com/e-kotov/rJavaEnv/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/e-kotov/rJavaEnv/actions/workflows/R-CMD-check.yaml)
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
not yet ready for production use.

<script type="application/ld+json">
      {
  "@context": "https://schema.org",
  "@graph": [
    {
      "type": "SoftwareSourceCode",
      "author": {
        "id": "https://orcid.org/0000-0001-6690-5345"
      },
      "codeRepository": "https://github.com/e-kotov/rJavaEnv",
      "copyrightHolder": {
        "id": "https://orcid.org/0000-0001-6690-5345",
        "type": "Person",
        "email": "kotov.egor@gmail.com",
        "familyName": "Kotov",
        "givenName": "Egor"
      },
      "description": "Install specific version of Java runtime environment at the R project level. The goal of rJavaEnv is to manage multiple Java JDKs in R projects by automatingthe process of downloading, installing, and configuring Java environments on a per-project basis. This package is inspired by the renv <https://rstudio.github.io/renv/> package for managing R environments in R projects. You can request a specific Java Development Kit (JDK) in your project, and rJavaEnv will download and install the requested Java environment in a project-specific directory and set the PATH and JAVA_HOME for when you are using this project. Therefore, you can have different Java versions for different projects without contaminating your system with different Java versions.",
      "license": "https://spdx.org/licenses/MIT",
      "name": "rJavaEnv: Java Environments for R Projects",
      "programmingLanguage": {
        "type": "ComputerLanguage",
        "name": "R",
        "url": "https://r-project.org"
      },
      "runtimePlatform": "R version 4.4.0 (2024-04-24)",
      "version": "0.0.0.9000"
    },
    {
      "type": "SoftwareSourceCode",
      "author": {
        "id": "https://orcid.org/0000-0001-6690-5345",
        "type": "Person",
        "email": "kotov.egor@gmail.com",
        "familyName": "Kotov",
        "givenName": "Egor"
      },
      "name": "rJavaEnv: Java Environments for R Projects"
    }
  ]
}
    </script>

## Install

You can install the development version of `rJavaEnv` from GitHub:

``` r
devtools::install_github("e-kotov/rJavaEnv")
```

## Simple Example

``` r
rJavaEnv::java_quick_install(version = 21)
```

This will:

- download Java 21 distribution compatible with the current operating
  system and processor architecture;

- create **rjavaenv/`platform`/`processor_architecture`/`java_version`**
  in current directory/project and unpack the downloaded Java
  distribution there;

- set the current session’s JAVA_HOME and PATH environment variables to
  point to the installed Java distribution;

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
2.  `java_download()`
    - Downloads a specified version and distribution of Java.
3.  `java_install()`
    - Installs a Java distribution file into current (or user-specified)
      project directory.
4.  `java_env_set()`
    - Sets the JAVA_HOME and PATH environment variables to a given path
      in current R session and/or in the .Rprofile file in the project
      directory.
5.  `java_env_set()`
    - Remove the JAVA_HOME and PATH environment variables from the
      .Rpofile file in the project directory (but not in the current R
      session, please restart the session so that R picks up the system
      Java).
6.  `java_check_version_cmd()`
    - Checks the installed Java version using terminal commands. Useful
      for checking Java version that would be picked up by packages like
      <a href="https://github.com/ropensci/opentripplanner"
      target="_blank"><code>opentripplanner</code></a>, that controls
      Java via command line.
7.  `java_version_check_rjava()`
    - Checks the Java version using `rJava` in a separate R session.
      Useful for checking Java version that would be picked up by
      packages like <a href="https://github.com/ipeaGIT/r5r"
      target="_blank"><code>r5r</code></a>, that initialize Java using
      `rJava`.
8.  `java_list_distrib_cache()`
    - Lists the contents of the Java distributions cache folder in user
      data directory.
9.  `java_clear_distrib_cache()`
    - Clears the Java distributions cache folder in user data directory.

For detailed usage, see the [Quick Start
Vignette](vignettes/quick_start.Rmd).

## Limitations

Currently, `rJavaEnv` only supports major Java versions such as 8, 11,
16, 17, 21, 22, etc. The download and install functions ignore the minor
version of the Java distribution and just downloads the latest stable
subversion of the specified major version. This is done to simplify the
process and avoid the need to update the package every time a new minor
version of Java is released. For most users this should be sufficient,
but this is substandard for full reproducibility.

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
calls using command line, you can swtich Java environments dynamically
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

- Adding support for more Java distributions and versions

- Possibly adding support for specifying Java version beyond the major
  version

- Possible allow downloading several Java distributions at once,
  e.g. different major versions of the same ‘flavour’ or different
  ‘flavours’ of the same major version

## Acknowledgements

I thank rOpenSci for the
<a href="https://devguide.ropensci.org/" target="_blank">Dev Guide</a>,
as well as Hadley Wickham and Jennifer Bryan for the
<a href="https://r-pkgs.org/" target="_blank">R Packages</a> book.

Package hex sticker logo is partially generated by DALL-E by OpenAI. The
logo also contains the original R logo.
