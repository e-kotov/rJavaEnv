
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rJavaEnv

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/rJavaEnv)](https://CRAN.R-project.org/package=rJavaEnv)
<!-- badges: end -->

The goal of rJavaEnv is to manage multiple Java JDK in R projects by
automating the process of downloading, installing and configuring Java
environments on a per-project basis. This package is inspired by the
[`renv`](https://rstudio.github.io/renv/) package, which is used to
manage R environments in R projects.

The idea is that you can request a specific Java Development Kit (JDK)
in your project, and `rJavaEnv` will download and install the requested
Java environment in a project-specific directory and set the PATH
variable for when you are using this project. Therefore, you can have
Amazon Corretto Java 21 for a project that uses
[`r5r`](https://github.com/ipeaGIT/r5r) package, and Adoptium Eclipse
Temurin Java 8 for a project that uses
[`opentripplanner`](https://github.com/ropensci/opentripplanner)
package.

Actually, you do not have to have any Java installed on your machine at
all. Each Java JDK ‘flavour’ will quietly live with all its executables
in the respective project directory without contaminating your system.

## Installation

You can install the development version of rJavaEnv like so:

``` r
devtools::install_github("e-kotov/rJavaEnv")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(rJavaEnv)
## basic example code
```
