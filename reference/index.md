# Package index

## Quick Install

Just quickly install `Java` in the current project

- [`java_quick_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_quick_install.md)
  : Download and install and set Java in current working/project
  directory

## Quick Set & Discovery

Quickly find available versions, check system for existing ones, and set
`Java` in the current project

- [`use_java()`](https://www.ekotov.pro/rJavaEnv/reference/use_java.md)
  :

  Install specified Java version and set the `JAVA_HOME` and `PATH`
  environment variables in current R session

- [`java_list_available()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)
  : List Available Java Versions

- [`java_find_system()`](https://www.ekotov.pro/rJavaEnv/reference/java_find_system.md)
  : Discover system-wide Java installations

- [`java_valid_versions()`](https://www.ekotov.pro/rJavaEnv/reference/java_valid_versions.md)
  : Retrieve Valid Java Versions

## Ensure Required Java Version

Ensure a specific Java version is available and set

- [`java_ensure()`](https://www.ekotov.pro/rJavaEnv/reference/java_ensure.md)
  : Ensure specific Java version is set
- [`java_resolve()`](https://www.ekotov.pro/rJavaEnv/reference/java_resolve.md)
  : Resolve path to specific Java version

## Scoped Java Environment

Temporarily set Java for the current scope (ideal for package
developers)

- [`local_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/local_java_env.md)
  : Set Java environment for the current scope
- [`with_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_java_env.md)
  : Execute code with a specific Java environment
- [`with_rjava_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_rjava_env.md)
  : Execute rJava code in a separate process with specific Java version

## Java Validation

Check `Java` version and compatibility with currently set environment

- [`java_check_version_cmd()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_cmd.md)
  : Check installed Java version using terminal commands
- [`java_check_version_rjava()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_rjava.md)
  : Check Java Version with a Specified JAVA_HOME Using a Separate R
  Session
- [`java_get_home()`](https://www.ekotov.pro/rJavaEnv/reference/java_get_home.md)
  : Get JAVA_HOME
- [`java_check_compatibility()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_compatibility.md)
  : Verify rJava Compatibility (Guard)

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

## Cache Management

Manage cached downloads, installations, and project-linked `Java`
versions

- [`java_list()`](https://www.ekotov.pro/rJavaEnv/reference/java_list.md)
  : List the contents of the Java versions installed or cached
- [`java_list_distrib()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_distrib.md)
  : List the contents of the Java distributions cache folder
- [`java_list_installed()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_installed.md)
  : List the contents of the Java installations cache folder
- [`java_list_project()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_project.md)
  : List the Java versions symlinked in the current project
- [`java_clear()`](https://www.ekotov.pro/rJavaEnv/reference/java_clear.md)
  : Manage Java installations and distributions caches
- [`java_clear_distrib()`](https://www.ekotov.pro/rJavaEnv/reference/java_clear_distrib.md)
  : Clear the Java distributions cache folder
- [`java_clear_installed()`](https://www.ekotov.pro/rJavaEnv/reference/java_clear_installed.md)
  : Clear the Java installations cache folder
- [`java_clear_project()`](https://www.ekotov.pro/rJavaEnv/reference/java_clear_project.md)
  : Clear the Java versions symlinked in the current project

## Other commands

- [`rje_consent()`](https://www.ekotov.pro/rJavaEnv/reference/rje_consent.md)
  : Obtain User Consent for rJavaEnv
