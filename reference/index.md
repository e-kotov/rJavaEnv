# Package index

## Quick Install

Just quickly install `Java` in the current project

- [`java_quick_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_quick_install.md)
  : Download and install and set Java in current working/project
  directory

## Quick Set

Just quickly set `Java` in the current project (for use with
`targets`/`callr`)

- [`use_java()`](https://www.ekotov.pro/rJavaEnv/reference/use_java.md)
  :

  Install specified Java version and set the `JAVA_HOME` and `PATH`
  environment variables in current R session

## Check `Java` version

Check `Java` version with currently set environment

- [`java_check_version_cmd()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_cmd.md)
  : Check installed Java version using terminal commands
- [`java_check_version_rjava()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_rjava.md)
  : Check Java Version with a Specified JAVA_HOME Using a Separate R
  Session
- [`java_get_home()`](https://www.ekotov.pro/rJavaEnv/reference/java_get_home.md)
  : Get JAVA_HOME

## Fine-grained Control

Control every step of `Java` download, unpacking and installation

- [`java_download()`](https://www.ekotov.pro/rJavaEnv/reference/java_download.md)
  : Download a Java distribution

- [`java_unpack()`](https://www.ekotov.pro/rJavaEnv/reference/java_unpack.md)
  : Unpack a Java distribution file into cache directory

- [`java_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_install.md)
  : Install Java from a distribution file

- [`java_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_env_set.md)
  :

  Set the `JAVA_HOME` and `PATH` environment variables to a given path

- [`java_env_unset()`](https://www.ekotov.pro/rJavaEnv/reference/java_env_unset.md)
  : Unset the JAVA_HOME and PATH environment variables in the project
  .Rprofile

- [`java_build_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_build_env_set.md)
  : Set up the environment for building R packages with Java
  dependencies from source

- [`java_build_env_unset()`](https://www.ekotov.pro/rJavaEnv/reference/java_build_env_unset.md)
  : Unset the Java build environment variables in the project .Rprofile

## Manage files

Manage downloads, installs, and project-linked `Java` versions

- [`java_list()`](https://www.ekotov.pro/rJavaEnv/reference/java_list.md)
  : List the contents of the Java versions installed or cached
- [`java_clear()`](https://www.ekotov.pro/rJavaEnv/reference/java_clear.md)
  : Manage Java installations and distributions caches

## Other commands

- [`java_valid_versions()`](https://www.ekotov.pro/rJavaEnv/reference/java_valid_versions.md)
  : Retrieve Valid Java Versions
- [`rje_consent()`](https://www.ekotov.pro/rJavaEnv/reference/rje_consent.md)
  : Obtain User Consent for rJavaEnv
