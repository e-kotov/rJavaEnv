# rJavaEnv 0.4.0

## Breaking and behaviour changes

- Installed Java environments and project links now use the layout
  `<platform>/<arch>/<distribution>/<backend>/<version>`, so different vendors
  and backends of the same version can coexist. Environments in the 0.3.0 layout
  (`<platform>/<arch>/<version>`) are still listed, and existing project
  `.Rprofile` settings keep pointing to them.
- Downloaded archive names now include their backend, preventing native and
  SDKMAN downloads from reusing each other's files. Older archives are left in
  place and are not reused (#107).
- Setup now protects rJava's JVM selection. With the released rJava, a loaded
  but uninitialized rJava namespace is treated as unverified: `java_ensure()`
  errors before changing environment variables, because the namespace may
  already have locked its JVM library path. Restart R before setup in that case
  (see rJava issues [#334](https://github.com/s-u/rJava/issues/334) and
  [#25](https://github.com/s-u/rJava/issues/25)).
- Compatibility probes no longer load rJava or start its JVM in the calling
  process: `java_check_version_rjava()` runs in a separate R process, and
  command-version checks execute the selected JDK without preloading libjvm and
  restore temporary environment variables on every exit.
- Dependencies: `jsonlite` was replaced by `RcppSimdJson`, and `digest`,
  `memoise`, `rlang`, `withr` and `yaml` were added to Imports. `callr` is a new
  suggested package, needed by `with_rjava_env()`.

## New features

### Ensure and resolve Java

- New `java_ensure()` checks the active session, then system installations,
  then `rJavaEnv`'s cache, and downloads only when nothing suitable is found. It
  does nothing when a valid Java is already active. `check_against = "rJava"`
  (default) refuses to select Java that rJava could no longer use;
  `check_against = "cmd"` configures command-line Java only (#92).
- New `java_resolve()` finds or installs a Java and returns its `JAVA_HOME`
  without changing environment variables.
- New scoped helpers: `local_java_env()` and `with_java_env()` set `JAVA_HOME`
  and `PATH` for command-line Java and restore them on exit; `with_rjava_env()`
  runs a function in a fresh R process with the requested Java for rJava (#92).
- New `java_check_compatibility()` reports whether an already running rJava JVM
  meets a version requirement, without loading rJava or calling `.jinit()`.
- New `java_find_system()` lists Java installations from `JAVA_HOME`, `PATH`,
  versioned `JAVA_HOME_<major>` variables (including CI architecture suffixes)
  and platform-specific locations.
- New `java_get_home()`, a shortcut for `Sys.getenv("JAVA_HOME")` (#85).
- `java_quick_install()` now invisibly returns the path to `JAVA_HOME`.

### Version requirements

- `version` accepts a major version (`21`), a specific numeric version
  (`"21.0.9"`, `"11.0.29"`, or legacy spellings such as `"1.8.0_452"`), or an
  SDKMAN identifier (`"25.0.1-amzn"`), which selects the SDKMAN backend.
- `type = "exact"` or `type = "min"` selects exact or minimum matching in
  `java_ensure()`, `java_resolve()`, `local_java_env()` and `with_java_env()`.
- Specific (patch-level) requirements are strict in `java_resolve()` and the
  functions built on it (`java_ensure()`, `local_java_env()`, `with_java_env()`
  and `with_rjava_env()`): system, active and cached candidates are compared by
  their full runtime version, candidates are ordered numerically, and a fresh
  download is verified after unpacking. If a vendor API returned a different
  release than requested, `java_ensure()` returns `FALSE` and the others
  error. `java_quick_install()`, `use_java()`, `java_download()` and
  `java_install()` do not check the installed runtime, and the native Zulu
  backend may return another release of the requested major version.
- `accept_system_java = FALSE` ignores system and active JDKs and uses only
  managed installations, filtered by distribution, backend, platform and
  architecture.
- `java_valid_versions()` falls back to a dynamic range of major versions when
  vendor APIs are unreachable, so new Java releases do not require a package
  update.

### Distributions and download backends

- Eclipse Temurin and Azul Zulu are supported in addition to Amazon Corretto.
- New `backend` argument (`"native"` or `"sdkman"`), also settable with
  `options(rJavaEnv.backend = ...)`. The native backend uses vendor APIs and
  verifies SHA-256 checksums. The SDKMAN backend covers more builds but cannot
  verify checksums and warns about it (#98).
- New `java_list_available()` lists installable versions from the native
  backend, SDKMAN, or both, for the current or a given platform and
  architecture.
- `java_unpack()` and `java_install()` gain `distribution`, `backend` and
  `force` arguments (#86).
- The cache management functions `java_list_project()`, `java_list_installed()`,
  `java_list_distrib()`, `java_clear_project()`, `java_clear_installed()` and
  `java_clear_distrib()` are now exported.

### Linux and building rJava from source

- On Linux, `libjvm.so` is located and loaded with `dyn.load()` when Java is
  set, so rJava and dependent packages load with the selected Java. Command-only
  setup (`check_against = "cmd"`) does not preload it.
- New `java_build_env_set()` and `java_build_env_unset()` set, in the session
  or the project `.Rprofile`, the variables needed to install rJava from source
  on macOS, Linux and Windows without `R CMD javareconf`. System requirements
  still apply; see the new vignette "Install 'rJava' from source".

### rJava: released behaviour and experimental deferred loading

- With released rJava, configure Java before loading the rJava namespace. Once
  rJava has loaded, restart R before selecting another JVM, or use
  `with_rjava_env()` for a separate process. All documented patterns rely only
  on released rJava.
- Experimental, optional: rJava builds with deferred JVM loading (explored in
  rJava's `feature/dynamic` branch) expose a JVM state API. When that state
  confirms that no JVM library is loaded, no JVM is initialized, and no native
  host has already mapped a JVM, `java_ensure()` permits setup after the
  namespace has loaded and skips the Linux libjvm preload. If the state is
  missing, unknown or reports a loaded JVM, the released-rJava behaviour
  applies. rJavaEnv does not require these builds.

## Performance

- Version checks and system scans can be memoised within the session with
  `.use_cache = TRUE` in `java_check_version_cmd()`, `java_check_version_rjava()`,
  `java_find_system()`, `java_ensure()`, `java_resolve()` and
  `local_java_env()`. Caching is opt-in; the default `.use_cache = FALSE`
  always performs a fresh check. Version-check caches are keyed by the
  effective `JAVA_HOME`.

## Bug fixes and minor improvements

- More robust Java home and version detection: symlinks are resolved, ANSI
  output is cleaned, versions without a minor component are parsed, and
  `Rscript` is located more reliably (#82, #95).
- macOS no longer picks up the `/usr/bin/java` stubs as a Java installation
  (#96).
- `java_check_version_rjava()` works on Linux after installing Java (#100, #101).
- Live Java checks are isolated in subprocesses, and Temurin version discovery
  uses release assets (#103).
- Zulu requests for a specific version no longer combine the version filter
  with `latest=true` in the API query.
- SDKMAN support adapts to upstream API schema changes and fixes path
  resolution (#104). Broker resolution handles rejected catalogue identifiers,
  reads redirect URLs without downloading the archive into memory, and retries
  transient API failures (#105).
- SDKMAN download broker URL updated to `https://broker.sdkman.io/download/java`
  to fix 404 errors on new releases (#112).
- Plain SDKMAN major- and patch-version requests exclude JavaFX, CRaC,
  early-access and snapshot builds unless requested explicitly. Fresh SDKMAN
  downloads report the resolved identifier and respect `quiet = TRUE`; cached
  archives are reused without resolving an identifier (#107). SDKMAN catalogues
  can lag vendor releases; use `backend = "native"` when an entry is stale or
  unavailable (#106).
- Download progress in `java_download()` respects `quiet`.
- `java_check_version_cmd()` and `java_check_version_rjava()` document that they
  return `FALSE` when Java cannot be found or checked.
- `{rlang}` is declared as a dependency, so functions work right after
  installation.

## Documentation and testing

- New developer vignette on integrating `rJavaEnv` into packages: passive
  probes, explicit setup, eager and lazy rJava dependencies, and subprocess
  isolation.
- Minimal downstream consumer packages exercise these contracts in fresh R
  processes on Linux, macOS and Windows in continuous integration.
- Live download tests, SDKMAN contract tests and a daily SDKMAN API canary run
  on a schedule.

# rJavaEnv 0.3.0

## New features

- `Java` version (currently still only for `Amazon Corretto`) is now determined dynamically using the official GitHub `json` with releases, so when new `Java` version becomes available, you will not be depenent on `rJavaEnv` to be updated. As a fallback, versions up to 24 are hardcoded.

- Added `force` argument to `java_download()`. When set to `TRUE`, allows to overwrite the distribution file if it already exist in the cache. This save the trouble of deleting the cached file with `java_clear()` before re-downloading.

- Added a new function `java_valid_versions()` allows to retrieve a list of all available `Java` versions for the current automatically detected OS and CPU architecture, or user-specified platform and architecture.

## Improvements

- Better command line `Java` detection (thanks to Jonas Lieth)

- Test coverage is now 7.2%

# rJavaEnv 0.2.2 (2024-09-13)

* Hot fix: improve robustness of setting `Java` environment in the current session with either `use_java()` or `java_quick_install()`. See bug fix below.

* Bug fix: Setting Java environment via `rJava::.jniInitialized()` rendered impossible changing Java version for `rJava`-dependent packages, because it somehow pre-initialised `rJava`

# rJavaEnv 0.2.1 (2024-09-03)

* Documentation and description clean-up

# rJavaEnv 0.2.0 (2024-08-28)

* Breaking change: `java_check_version_cmd()` and `java_check_version_rjava()` now return detected `Java` version instead of `TRUE`/`FALSE`

* New function `use_java()` to download, install and set `Java` from cache for the current sesssion, without touching the current project/working directory. This is intended for use with `targets` and `callr`.

* New vignette on using the package with `targets' and 'callr`

* Updated documentation with clearer instructions on cache folder cleanup before removing the package

* Depends on `R` > 4.0 to be able to write to the package cache directory without extra user warning. Cache cleanup and management functions are provided, as well as the documentation in both README and vignettes.

# rJavaEnv 0.1.2

* Fixed broken links in README.md

# rJavaEnv 0.1.1

* Improved documentation

* Better handling of cache directory

* Bug fixes and changes to address CRAN reviewer's comments to the first submission

# rJavaEnv 0.1.0

* Initial release
