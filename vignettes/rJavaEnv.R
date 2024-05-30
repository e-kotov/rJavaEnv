## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "man/figures/README-",
  out.width = "100%"
)

## ----eval=FALSE---------------------------------------------------------------
#  devtools::install_github("e-kotov/rJavaEnv")

## ----eval=FALSE---------------------------------------------------------------
#  library(rJavaEnv)
#  java_quick_install(21)

## ----eval=FALSE---------------------------------------------------------------
#  java_distr_path_21 <- java_download(version = 21)

## ----eval=FALSE---------------------------------------------------------------
#  java_home_path_21 <- java_install(java_distr_path_21)

## ----eval=FALSE---------------------------------------------------------------
#  java_env_set(java_home_path_21)

## ----eval=FALSE---------------------------------------------------------------
#  java_check_version_cmd()

## ----eval=FALSE---------------------------------------------------------------
#  java_version_check_rjava("/path/to/installed/java")

