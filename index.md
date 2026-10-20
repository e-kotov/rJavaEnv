# rJavaEnv: Java Environments for R Projects

Quickly install `Java Development Kit (JDK)` without administrative
privileges and set environment variables in current R session or project
to solve common issues with ‘Java’ environment management in ‘R’.
Recommended to users of
`Java`/[rJava](https://www.rforge.net/rJava/)-dependent `R` packages
such as [r5r](https://github.com/ipeaGIT/r5r),
[opentripplanner](https://docs.ropensci.org/opentripplanner),
[xlsx](https://github.com/colearendt/xlsx), `{openNLP}`, `{rWeka}`,
[RJDBC](http://www.rforge.net/RJDBC/),
[tabulapdf](https://docs.ropensci.org/tabulapdf/), and many more.
[rJavaEnv](https://github.com/e-kotov/rJavaEnv) prevents common problems
like `Java` not found, `Java` version conflicts, missing `Java`
installations, and the inability to install `Java` due to lack of
administrative privileges.
[rJavaEnv](https://github.com/e-kotov/rJavaEnv) automates the download,
installation, and setup of the `Java` on a per-project basis by setting
the relevant `JAVA_HOME` in the current `R` session or the current
working directory (via `.Rprofile`, with the user’s consent). Similar to
what [renv](https://rstudio.github.io/renv/) does for `R` packages,
[rJavaEnv](https://github.com/e-kotov/rJavaEnv) allows different `Java`
versions to be used across different projects, but can also be
configured to allow multiple versions within the same project (e.g. with
the help of [targets](https://docs.ropensci.org/targets/) package). For
users who need to install [rJava](https://www.rforge.net/rJava/) or
other `Java`-dependent packages from source,
[rJavaEnv](https://github.com/e-kotov/rJavaEnv) will display a message
with instructions on how to run `R CMD javareconf` to make the Java
configuration permanent, but also provides a function
[`java_build_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_build_env_set.md)
that sets the environment variables in the current R session temporarily
to allow installation of [rJava](https://www.rforge.net/rJava/) from
source without `R CMD javareconf`. On Linux, in addition to setting
environment variables, [rJavaEnv](https://github.com/e-kotov/rJavaEnv)
also dynamically loads `libjvm.so` to ensure
[rJava](https://www.rforge.net/rJava/) works correctly. See
[documentation](https://www.ekotov.pro/rJavaEnv/articles/rJavaEnv.html#note-linux)
for more details.

## Install

Install from CRAN:

``` r

install.packages('rJavaEnv')
```

Install the development version

Install the latest release development version from **R-multiverse**:

``` r

install.packages('rJavaEnv',
 repos = c('https://community.r-multiverse.org', 'https://cloud.r-project.org')
)
```

You can also install the development version of `rJavaEnv` directly from
GitHub:

``` r

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

remotes::install_github("e-kotov/rJavaEnv", force = TRUE)
```

## Simple Example

``` r

rJavaEnv::java_quick_install(version = 21)
```

This will:

- download `Java` 21 distribution compatible with the current operating
  system and processor architecture into a local cache folder;

- extract the downloaded `Java` distribution into another cache folder;

- create a symbolic link (for macOS and Linux) or junction (for Windows,
  if that fails, just copies the files)
  **rjavaenv/`platform`/`processor_architecture`/`distribution`/`backend`/`java_version`**
  in the current directory/project to point to the cached installation;

- set the current session’s `JAVA_HOME` and `PATH` environment variables
  to point to the installed (symlinked) `Java` distribution;

- add code to `.Rprofile` file in the current directory/project to set
  `JAVA_HOME` and `PATH` environment variables when the project is
  opened in RStudio.

As part of normal operation, `rJavaEnv` will update the `JAVA_HOME` and
`PATH` environment variables in the current R session, the local cache
in your R package library, and the `.Rprofile` file in the
project/current working directory. In line with [CRAN
policies](https://cran.r-project.org/web/packages/policies.html),
explicit user consent is required before making these changes.
Therefore, the first time you run any function from `rJavaEnv` that
makes such changes, you will be asked for consent. To explicitly consent
and/or to prevent interruptions in non-interactive mode, you can use the
[`rje_consent()`](https://www.ekotov.pro/rJavaEnv/reference/rje_consent.md)
function:

``` r

rje_consent(provided = TRUE)
```

You can also specify a distribution different from the default
“Corretto” (supported: “Corretto”, “Temurin” and “Zulu”), a specific
version, or the SDKMAN download backend:

``` r

rJavaEnv::java_quick_install(version = 17, distribution = "Temurin")
rJavaEnv::java_quick_install(version = "21.0.9", distribution = "Zulu")
rJavaEnv::java_quick_install(version = 21, backend = "sdkman")
```

The default `"native"` backend downloads from vendor APIs and verifies
SHA-256 checksums. The `"sdkman"` backend offers more builds but cannot
verify checksums. Use
[`java_list_available()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)
to see what can be installed.

## Ensuring a Java version in scripts and packages

[`java_ensure()`](https://www.ekotov.pro/rJavaEnv/reference/java_ensure.md)
uses an already active or installed Java when it satisfies the
requirement and downloads one only when needed:

``` r

rJavaEnv::java_ensure(version = 21, type = "min")
```

For rJava-dependent packages, call it before loading rJava or any
package that imports it. For packages that call Java on the command
line,
[`local_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/local_java_env.md)
and
[`with_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_java_env.md)
set Java for a single function or block and restore the environment
afterwards. See the [developer
vignette](https://www.ekotov.pro/rJavaEnv/articles/for-developers.html)
for integration patterns.

## Using `rJavaEnv` with `targets` and `callr`

Just insert this line at the top of any script that you run with
`targets` or `callr`:

``` r

rJavaEnv::use_java("21")
```

This acts exactly like
[`java_quick_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_quick_install.md),
but only sets the environment variables in the current session and does
not copy or link `Java` binaries into the project directory.

More details are in the vignette [Multiple `Java` environments in one
project with `targets` and
`callr`](https://www.ekotov.pro/rJavaEnv/articles/multiple-java-with-targets-callr.html).

## Cleanup

If you do not want to use `rJavaEnv` anymore, please clear the cache
folders before removing the package:

``` r

java_clear_project(delete_all = TRUE)
java_clear_installed(delete_all = TRUE)
java_clear_distrib(delete_all = TRUE)
```

Also, clear the `.Rprofile` file in the projects there you used the
package:

``` r

java_env_unset()
```

## Functions Overview

The package has several core functions:

1.  [`java_quick_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_quick_install.md)

    - Downloads, installs, and sets Java environment in the current
      working/project directory, all in one line of code.

2.  [`java_check_version_cmd()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_cmd.md)

    - Checks the installed Java version using terminal commands. For
      packages like
      [`opentripplanner`](https://github.com/ropensci/opentripplanner),
      that performs Java calls using command line.

3.  [`java_check_version_rjava()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_rjava.md)

    - Checks the installed `Java` version using `rJava` in a separate R
      session. For `rJava`-dependent packages such as
      [`r5r`](https://github.com/ipeaGIT/r5r).

4.  [`java_download()`](https://www.ekotov.pro/rJavaEnv/reference/java_download.md)

    - Downloads a specified version and distribution of `Java`.

5.  [`java_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_install.md)

    - Installs a `Java` distribution file into current (or
      user-specified) project directory.

6.  [`java_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_env_set.md)

    - Sets the `JAVA_HOME` and `PATH` environment variables to a given
      path in current R session and/or in the `.Rprofile` file in the
      project directory.

7.  [`java_env_unset()`](https://www.ekotov.pro/rJavaEnv/reference/java_env_unset.md)

    - Removes the `JAVA_HOME` and `PATH` environment variables from the
      `.Rprofile` file in the project directory (but not in the current
      R session, please restart the session so that R picks up the
      system Java).

8.  `java_list_*()`
    ([`java_list_project()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_project.md),
    [`java_list_installed()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_installed.md),
    [`java_list_distrib()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_distrib.md))

    - Lists all or some `Java` versions linked in the current project
      (or cached distributions or installations).

9.  `java_clear_*()`
    ([`java_clear_project()`](https://www.ekotov.pro/rJavaEnv/reference/java_clear_project.md),
    [`java_clear_installed()`](https://www.ekotov.pro/rJavaEnv/reference/java_clear_installed.md),
    [`java_clear_distrib()`](https://www.ekotov.pro/rJavaEnv/reference/java_clear_distrib.md))

    - Removes all or some `Java` versions linked in the current project
      (or cached distributions or installations).

10. [`java_valid_versions()`](https://www.ekotov.pro/rJavaEnv/reference/java_valid_versions.md)

    - Lists all valid major `Java` versions that can be downloaded and
      installed for either current automatically detected OS and CPU
      architecture or user-specified platform and architecture.

11. [`java_list_available()`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)

    - Lists all installable Java versions from supported backends
      (native vendor APIs or SDKMAN). Supports filtering by platform and
      architecture.

12. [`use_java()`](https://www.ekotov.pro/rJavaEnv/reference/use_java.md)

    - Same as
      [`java_quick_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_quick_install.md),
      but in a less intrusive way. Does not copy or link the `Java`
      installation folder from cache into the project directory and does
      not create or edit your `.Rprofile` file. Only sets requested java
      in the current R session.

13. [`java_build_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_build_env_set.md)
    (and
    [`java_build_env_unset()`](https://www.ekotov.pro/rJavaEnv/reference/java_build_env_unset.md))

    - Similar to
      [`java_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_env_set.md),
      but specifically designed for setting `Java` environment variables
      for building `rJava` from source.

14. [`java_ensure()`](https://www.ekotov.pro/rJavaEnv/reference/java_ensure.md)

    - Makes sure that a required `Java` version (exact or minimum) is
      active, using the current session, system installations, or the
      `rJavaEnv` cache before downloading anything.

15. [`java_resolve()`](https://www.ekotov.pro/rJavaEnv/reference/java_resolve.md)

    - Finds or installs a required `Java` version and returns its
      `JAVA_HOME` path without changing environment variables.

16. [`local_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/local_java_env.md),
    [`with_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_java_env.md)
    and
    [`with_rjava_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_rjava_env.md)

    - Use a `Java` version for the current scope or a block of code
      (command-line `Java`), or run an `rJava` function in a separate R
      process with a given `Java` version.

17. [`java_check_compatibility()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_compatibility.md)

    - Checks whether an already running `rJava` JVM meets a version
      requirement, without loading `rJava` or starting a JVM.

18. [`java_find_system()`](https://www.ekotov.pro/rJavaEnv/reference/java_find_system.md)
    and
    [`java_get_home()`](https://www.ekotov.pro/rJavaEnv/reference/java_get_home.md)

    - List `Java` installations found on the system, and return the
      current `JAVA_HOME`.

------------------------------------------------------------------------

See more details on all the functions in the
[Reference](https://www.ekotov.pro/rJavaEnv/reference/index.html).

For detailed usage, see the [Quick Start
Vignette](https://www.ekotov.pro/rJavaEnv/articles/rJavaEnv.html).

## Limitations

A major version such as `21` installs the latest release of that major
version. For reproducibility, request a specific version such as
`"21.0.9"`.
[`java_resolve()`](https://www.ekotov.pro/rJavaEnv/reference/java_resolve.md)
and the functions built on it
([`java_ensure()`](https://www.ekotov.pro/rJavaEnv/reference/java_ensure.md),
[`local_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/local_java_env.md),
[`with_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_java_env.md)
and
[`with_rjava_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_rjava_env.md))
then check the full runtime version of active, system, cached and newly
installed `Java`, and do not use a release that does not match. If no
matching release can be installed,
[`java_ensure()`](https://www.ekotov.pro/rJavaEnv/reference/java_ensure.md)
returns `FALSE` and the others report an error. The convenience helpers
[`java_quick_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_quick_install.md)
and
[`use_java()`](https://www.ekotov.pro/rJavaEnv/reference/use_java.md),
like
[`java_download()`](https://www.ekotov.pro/rJavaEnv/reference/java_download.md)
and
[`java_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_install.md),
request the release from the vendor backend but do not check the
installed runtime, and the native Zulu backend may return another
release of the same major version. SDKMAN catalogues can lag behind
vendor releases.

The main limitation is that if you want to switch to another `Java`
environment for `rJava`, you will most likely have to restart the
current R session and set the `JAVA_HOME` and `PATH` environment
variables to the desired `Java` environment using
[`rJavaEnv::java_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_env_set.md).
This cannot be done dynamically within the same R session due to the way
Java is initialized in R, particularly with the `rJava`-dependent
packages such as [`r5r`](https://github.com/ipeaGIT/r5r). With the
released `rJava`, loading the `rJava` namespace (for example, by loading
a package that imports it) can lock the JVM library path even before the
JVM starts, so configure `Java` before that point.
[`java_ensure()`](https://www.ekotov.pro/rJavaEnv/reference/java_ensure.md)
refuses to change `Java` once it can no longer take effect for `rJava`.
With packages like
[`opentripplanner`](https://github.com/ropensci/opentripplanner), that
performs `Java` calls using command line, you can switch `Java`
environments dynamically within the same R session as much as you want.

Therefore, if you need to use R packages that depend on different `Java`
versions within the same project, you will have to create separate R
scripts for each `Java` environment and run them in separate R sessions.
One effective way of doing this is to use the
[`callr`](https://github.com/r-lib/callr) package to run R scripts in
separate R sessions. Another option is to use the
[`targets`](https://github.com/ropensci/targets) package to manage the
whole project workflow, which, as a side effect, will lead to all R
scripts being run in separate R sessions. To use `rJavaEnv` with
`targets`, you will need to download and install several Java
environments using
[`rJavaEnv::java_download()`](https://www.ekotov.pro/rJavaEnv/reference/java_download.md)
and
[`rJavaEnv::java_install()`](https://www.ekotov.pro/rJavaEnv/reference/java_install.md)
and set the relevant path with
[`rJavaEnv::java_env_set()`](https://www.ekotov.pro/rJavaEnv/reference/java_env_set.md)
at the beginning of each function that requires a certain `Java`
version.

`rJavaEnv` also has experimental, optional support for `rJava` builds
with deferred JVM loading, which are not part of released `rJava`. When
such a build reports that no JVM has been loaded yet,
[`java_ensure()`](https://www.ekotov.pro/rJavaEnv/reference/java_ensure.md)
can still select `Java` after the `rJava` namespace has loaded. Nothing
in `rJavaEnv` requires these builds; see the [developer
vignette](https://www.ekotov.pro/rJavaEnv/articles/for-developers.html)
for details.

## Recommended by

`rJavaEnv` is recommended by several R packages and educational
resources to help users easily set up their Java environment:

### R Packages

- **[{r5r}](https://github.com/ipeaGIT/r5r)**: Recommended in their
  [README](https://github.com/ipeaGIT/r5r#readme) as the easiest way to
  install JDK.

- **[{rTASSEL}](https://github.com/maize-genetics/rTASSEL)**:
  Recommended in their [installation
  instructions](https://github.com/maize-genetics/rTASSEL#readme) to
  automate R-to-Java setup.

- **[{causalDisco}](https://github.com/disco-coders/causalDisco)**:
  Recommended in their
  [README](https://github.com/disco-coders/causalDisco#readme) and
  vignettes for simpler Java configuration.

- **[{photon}](https://github.com/JsLth/photon)**: Recommends `rJavaEnv`
  dynamically in startup and warning messages when Java is missing or
  has the wrong version.

- **[{r5rgui}](https://github.com/chico2405/r5rgui-UFBA)**: Recommended
  in their setup instructions.

### Courses and Books

- **[Intro to Transport Accessibility
  Book](https://github.com/ipeaGIT/intro_access_book)** (ipeaGIT)

- **[EIT Urban Mobility
  Courses](https://github.com/rosamfelix/EITbraga)** (EITbraga,
  PGmob360)

- **[Web Scraping Course (University of
  Innsbruck)](https://github.com/etiennebacher/innsbruck_teaching_may_2025)**

- **[NICAR Transit Workshop
  (2025)](https://github.com/invisibae/nicar_2025_transit)**

- **[Tracking Access Change
  Book](https://github.com/urbanjuhyeon/tracking-access-change)**

## Future work

The future work includes:

- Add support for more `Java` distributions

- Take care of
  [`R CMD javareconf`](https://solutions.posit.co/envs-pkgs/using-rjava/#reconfigure-r)

- Possibly allow downloading several `Java` distributions in one
  function call, e.g. different major versions of the same ‘flavour’ or
  different ‘flavours’ of the same major version

- Possibly add automation to get the `Java` that is required by specific
  `Java`-dependent R packages

I am open to suggestions and contributions, welcome to
[issues](https://github.com/e-kotov/rJavaEnv/issues) and [pull
requests](https://github.com/e-kotov/rJavaEnv/pulls).

## Acknowledgements

I thank rOpenSci for the [Dev Guide](https://devguide.ropensci.org/), as
well as Hadley Wickham and Jennifer Bryan for the [R
Packages](https://r-pkgs.org/) book.

Package hex sticker logo is partially generated by DALL-E by OpenAI. The
logo also contains the original R logo.

## Citation

To cite package ‘rJavaEnv’ in publications use:

Kotov E, Chan C (2024). *rJavaEnv: Java Environments for R Projects*.
<doi:10.32614/CRAN.package.rJavaEnv>
<https://doi.org/10.32614/CRAN.package.rJavaEnv>.
<https://github.com/e-kotov/rJavaEnv>.

BibTeX:

``` R
@Manual{rjavaenv,
  title = {rJavaEnv: Java Environments for R Projects},
  author = {Egor Kotov and Chung-hong Chan},
  year = {2024},
  url = {https://github.com/e-kotov/rJavaEnv},
  doi = {10.32614/CRAN.package.rJavaEnv},
}
```
