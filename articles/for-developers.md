# Using `rJavaEnv` in R Packages

If you are developing an R package that involves `Java` (either via
[rJava](http://www.rforge.net/rJava/) or through command-line `Java`
tools), you often face the “Java Hell” problem: your users might not
have Java installed, or they might have the wrong version, or
[rJava](http://www.rforge.net/rJava/) cannot find the `JAVA_HOME`.

`rJavaEnv` solves this by providing a unified, reliable way to help your
users ensure a specific Java version is present and configured
correctly.

## The Critical Decision: Does Your Package Use rJava?

Before using `rJavaEnv`, you must categorize your package into one of
two scenarios. This distinction is critical because
[rJava](http://www.rforge.net/rJava/) introduces a “locking” constraint
that fundamentally changes how you must manage Java.

**Scenario A: Command-Line Java Only** (No
[rJava](http://www.rforge.net/rJava/) dependency) Your package calls
Java executables via [`system()`](https://rdrr.io/r/base/system.html),
[`system2()`](https://rdrr.io/r/base/system2.html), or `processx`. You
do **not** have `Imports: rJava` in your DESCRIPTION.

**Scenario B: rJava Dependency** (Most Common) Your package has
`Imports: rJava` or `Depends: rJava`, or executes code that uses
[rJava](http://www.rforge.net/rJava/) functions.

------------------------------------------------------------------------

## Scenario A: Packages Using Command-Line Java (No rJava)

In this scenario, you have flexibility. The Java version is **not**
locked by the R session. You can use different Java versions for
different tasks or change them dynamically.

However, modifying the global `JAVA_HOME` and `PATH` environment
variables might accidentally affect other parts of the user’s workflow.
To avoid this, you should use a **scoped** approach.

#### Recommended Pattern: `local_java_env()`

The `rJavaEnv` package provides a scoped helper that handles everything
for you in one line. It ensures Java is installed, sets the environment
for your function, and automatically cleans up afterwards.

> \[!WARNING\] **Do not use
> [`local_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/local_java_env.md)
> or
> [`with_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_java_env.md)
> if your package depends on rJava.** rJava locks the JVM at
> initialization and cannot switch versions within a session. For rJava
> packages, see Scenario B below.

``` r
#' Run my Java tool (using system2)
#' @export
run_my_tool <- function(input_file) {
  rJavaEnv::local_java_env(version = 21)
  system2("java", c("-jar", "tool.jar", input_file))
} # Environment restored automatically here

#' Run my Java tool (using processx)
#' @export
run_my_tool_px <- function(input_file) {
  rJavaEnv::local_java_env(version = 21)
  processx::run("java", c("-jar", "tool.jar", input_file))
}
```

This ensures that: 1. Your code runs with the correct Java version. 2.
The user’s `JAVA_HOME` is restored immediately after your function
exits. 3. You don’t need to write manual
[`on.exit()`](https://rdrr.io/r/base/on.exit.html) cleanup code.

#### Using `with_java_env()`

If you prefer block-scoped execution:

``` r
# With system2
rJavaEnv::with_java_env(version = 21, {
  system2("java", "-version")
})

# With processx
rJavaEnv::with_java_env(version = 21, {
  processx::run("java", c("-jar", "tool.jar", "--help"))
})
```

#### Performance: Using `.use_cache`

If your function calls Java multiple times (e.g., inside a loop), enable
caching to avoid the 30-200ms overhead of version checks on each call:

``` r
process_files <- function(files) {
  for (f in files) {
    rJavaEnv::local_java_env(version = 21, .use_cache = TRUE)
    processx::run("java", c("-jar", "processor.jar", f))
  }
}
```

#### Controlling Whether to Use System Java

By default, `accept_system_java = TRUE`. `rJavaEnv` will first check if
a suitable Java version exists on the system. If found, it uses it
without downloading anything. This is efficient and recommended.

If you strictly require an isolated, reproducible environment (ignoring
the user’s system Java), set `accept_system_java = FALSE` and
`install = TRUE`.

------------------------------------------------------------------------

## Scenario B: Packages Importing rJava

If your package calls `rJava` (or imports a package that does), you face
a strict constraint:

> **The rJava Lock**: Once [rJava](http://www.rforge.net/rJava/) is
> initialized (loaded), the Java version is **locked** for the entire R
> session. It cannot be changed without restarting R.

**Implications:** - You **cannot** set Java in your package’s `.onLoad`
or inside your functions. By the time your package loads,
[rJava](http://www.rforge.net/rJava/) is likely already initializing, or
will initialize the moment you call it. - You **must** instruct users to
set up Java **before** loading your package.

#### Pattern 1: The Guard (Recommended)

Since you cannot fix the environment automatically after `rJava` loads,
the best practice is to **detect issues immediately** and instruct the
user.

Add a check to your `.onLoad` function using `java_check_compatibility`.

``` r
# In R/zzz.R
.onLoad <- function(libname, pkgname) {
  # Check if the active Java version is at least 21
  # If not, warn the user and explain how to fix it via rJavaEnv
  rJavaEnv::java_check_compatibility(version = 21, type = "min", action = "warn")
}
```

**What the user sees:** If the user is running Java 8, they immediately
see:

``` text
Warning: Java version mismatch.
Current loaded Java: 8
Required Java: >= 21
! Because rJava is already initialized, you must restart R to switch versions.
  To fix this, restart R and run:
  rJavaEnv::use_java(21)
  BEFORE loading this package.
```

#### Pattern 2: Process Isolation (Advanced)

If you want to guarantee a specific Java environment without relying on
the user’s setup, you can run your `rJava` code in a subprocess. This
bypasses the lock in the main session.

**Requirements:** 1. Add `callr` to `Suggests`. 2. Your function must
not rely on objects existing in the main session (stateless execution).

``` r
#' Run a heavy calculation in a Java 21 subprocess
#' @export
run_heavy_calc <- function(input_data) {
  rJavaEnv::with_rjava_env(
    version = 21,
    func = function(df) {
      rJava::.jinit()
      # Process df using rJava...
      nrow(df)  # Return actual result
    },
    args = list(df = input_data)
  )
}
```

#### Choosing Between `use_java` and `java_ensure`

| Function                        | Behavior                                     | Best For              |
|---------------------------------|----------------------------------------------|-----------------------|
| `use_java(21)`                  | Sets exactly Java 21, downloads if missing   | Interactive scripts   |
| `java_ensure(21, type = "min")` | Accepts any Java \>= 21, checks system first | Package setup helpers |

Use `java_ensure` in package code because it’s more lenient and
efficient.

#### Strategy: “Inform and Guide”

Your goal is to make the setup process as easy as possible for your
users.

##### 1. Add rJavaEnv to Imports

Add `rJavaEnv` to your `DESCRIPTION`:

``` dcf
Imports:
    rJava,
    rJavaEnv
```

##### 2. Document the Requirement

In your README or vignette, provide clear instructions.

> **Java Requirement** This package requires Java 21+. If you see
> errors, run:
>
> ``` r
> library(rJavaEnv)
> java_ensure(version = 21, type = "min")
> # RESTART R session
> library(your_package)
> ```

##### 3. Optional: Provide a Setup Helper

To make it even easier, you can export a setup function that users can
call *if* they run into issues. This function can leverage
`java_ensure(install = TRUE)` to interactively guide them.

``` r
#' Install and Configure Java
#' @export
setup_java <- function() {
  # Interactive check and install
  rJavaEnv::java_ensure(version = 21, type = "min", install = TRUE)
  
  message("Java setup complete. Please RESTART your R session for changes to take effect.")
}
```

------------------------------------------------------------------------

## Performance & Caching

Regardless of the scenario, `rJavaEnv` performs checks to ensure Java is
ready. To avoid performance penalties (approx. 30-200ms per check),
`rJavaEnv` supports session-level caching.

#### When to use `.use_cache = TRUE`

- **Inside functions called repeatedly**: If you have a function calling
  `java_ensure` inside a loop, enable caching.
- **In `.onLoad` checks**: To keep package startup fast.

``` r
# Fast check using cache
rJavaEnv::java_check_version_cmd(quiet = TRUE, .use_cache = TRUE)
```

The first call takes time (to verify the system state), but subsequent
calls in the same session return in \<1ms.

## Debugging

If Java setup isn’t working as expected, use `quiet = FALSE` to see what
`rJavaEnv` is checking:

``` r
# See all resolution steps
rJavaEnv::java_ensure(version = 21, quiet = FALSE)

# Check what Java is currently active
rJavaEnv::java_check_version_cmd(quiet = FALSE)

# See all system Java installations
rJavaEnv::java_find_system(quiet = FALSE)
```

------------------------------------------------------------------------

## CI/CD (GitHub Actions)

Ensure Java is available in your CI workflows.

**Option A: Standard generic action (Recommended)**

``` yaml
- uses: actions/setup-java@v4
  with:
    distribution: 'corretto'
    java-version: '21'
```

**Option B: Using rJavaEnv**

``` yaml
- name: Install Java via rJavaEnv
  run: |
    install.packages("rJavaEnv")
    rJavaEnv::java_ensure(version = 21, type = "min")
  shell: Rscript {0}
```
