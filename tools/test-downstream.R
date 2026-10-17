# Run from the repository root: Rscript --vanilla tools/test-downstream.R
# Needs two real JDKs with different major versions, rJava and callr.
# Optionally specify RJE_JAVA_HOME_A and RJE_JAVA_HOME_B (otherwise discover them).
# Installs the checkout and both downstream fixtures into a temporary R library.
# No downloads, mocks, pkgload, or changes to the user's R library/cache.
stopifnot(requireNamespace("callr", quietly = TRUE))
root <- normalizePath(".", winslash = "/")
stopifnot(file.exists(file.path(root, "DESCRIPTION")))
sandbox <- tempfile("rjavaenv-downstream-")
dir.create(sandbox)
main <- function() {
  on.exit(unlink(sandbox, recursive = TRUE), add = TRUE)
  lib <- file.path(sandbox, "library")
  dir.create(lib)
  install <- function(path) {
    log <- file.path(sandbox, paste0(basename(path), "-install.log"))
    status <- system2(file.path(R.home("bin"), "R"), c(
      "CMD", "INSTALL", "--no-multiarch", "--no-test-load",
      paste0("--library=", shQuote(lib)), shQuote(path)
    ), stdout = log, stderr = log)
    if (status != 0) stop(paste(readLines(log), collapse = "\n"))
  }
  install(root)
  paths <- c(lib, .libPaths())
  homes <- Sys.getenv(c("RJE_JAVA_HOME_A", "RJE_JAVA_HOME_B"))
  if (!all(nzchar(homes))) {
    homes <- callr::r(function() {
      javas <- rJavaEnv::java_find_system()
      javas$java_home[!duplicated(javas$version)]
    }, libpath = paths, user_profile = FALSE, system_profile = FALSE)
    if (length(homes) < 2) stop("Two JDK majors required; set RJE_JAVA_HOME_A and RJE_JAVA_HOME_B.")
    homes <- homes[1:2]
  }
  homes <- normalizePath(homes, winslash = "/", mustWork = TRUE)
  install(file.path(root, "tools", "downstream", "rjedownstream"))
  install(file.path(root, "tools", "downstream", "rjeeager"))
  # Start every case with A on PATH; each child decides explicitly when to use B.
  initial_env <- c(JAVA_HOME = homes[1], PATH = paste(
    file.path(homes[1], "bin"), Sys.getenv("PATH"), sep = .Platform$path.sep
  ))
  # Make both supplied real installations discoverable even outside OS-standard
  # directories, as with actions/setup-java's JAVA_HOME_<major>_<arch> variables.
  majors <- callr::r(function(homes) {
    vapply(homes, rJavaEnv::java_check_version_cmd, character(1), quiet = TRUE)
  }, args = list(homes = homes), libpath = paths,
    user_profile = FALSE, system_profile = FALSE)
  stopifnot(length(unique(majors)) == 2)
  initial_env <- c(initial_env, setNames(homes, paste0("JAVA_HOME_", majors)))
  run <- function(name, func) {
    cat(name, "... ")
    callr::r(func, args = list(homes = homes), libpath = paths,
      env = initial_env, user_profile = FALSE, system_profile = FALSE)
    cat("OK\n")
  }
  run("Probes followed by switching and lazy downstream use", function(homes) {
    major <- function(home) rJavaEnv::java_check_version_cmd(home, quiet = TRUE)
    a <- major(homes[1]); b <- major(homes[2]); stopifnot(a != b)
    before <- Sys.getenv(c("JAVA_HOME", "PATH", "LD_LIBRARY_PATH", "DYLD_LIBRARY_PATH"), unset = NA)
    dlls <- getLoadedDLLs()
    stopifnot(!"rJava" %in% loadedNamespaces())
    stopifnot(!rJavaEnv::java_check_compatibility(b, action = "none"))
    stopifnot(!rJavaEnv::java_check_compatibility(b, action = "none"))
    rJavaEnv::java_find_system()
    stopifnot(major(homes[2]) == b)
    stopifnot(rJavaEnv::java_check_version_rjava(homes[2], quiet = TRUE) == b)
    stopifnot(!"rJava" %in% loadedNamespaces())
    jvm <- function(x) vapply(x, function(d) d[["path"]], character(1))
    stopifnot(identical(jvm(dlls), jvm(getLoadedDLLs())[names(dlls)]))
    stopifnot(!any(grepl("(libjvm|jvm[.]dll)", jvm(getLoadedDLLs()))))
    stopifnot(identical(before, Sys.getenv(names(before), unset = NA)))
    loadNamespace("rjedownstream")
    stopifnot(!"rJava" %in% loadedNamespaces())
    stopifnot(rjedownstream::setup_java(b, install = FALSE, quiet = TRUE))
    stopifnot(!"rJava" %in% loadedNamespaces())
    actual <- rjedownstream::rjava_version(b)
    stopifnot(sub("[.].*", "", actual) == b)
  })
  run("Scoped commands restore state on success and error", function(homes) {
    b <- rJavaEnv::java_check_version_cmd(homes[2], quiet = TRUE)
    before <- Sys.getenv(c("JAVA_HOME", "PATH"), unset = NA)
    output <- rjedownstream::command_version(b)
    stopifnot(any(grepl(paste0('version "', b), output, fixed = TRUE)))
    stopifnot(identical(before, Sys.getenv(names(before), unset = NA)))
    error <- tryCatch(rJavaEnv::with_java_env(b, install = FALSE, stop("intentional")), error = identity)
    stopifnot(inherits(error, "error"), identical(conditionMessage(error), "intentional"))
    stopifnot(identical(before, Sys.getenv(names(before), unset = NA)))
    Sys.unsetenv("JAVA_HOME")
    rjedownstream::command_version(b)
    stopifnot(is.na(Sys.getenv("JAVA_HOME", unset = NA)))
    Sys.setenv(JAVA_HOME = "")
    # R on Windows treats setting an empty value as unsetting the variable.
    # Preserve the observable starting state on each platform.
    empty_home <- Sys.getenv("JAVA_HOME", unset = NA)
    rjedownstream::command_version(b)
    stopifnot(identical(Sys.getenv("JAVA_HOME", unset = NA), empty_home))
    stopifnot(!"rJava" %in% loadedNamespaces())
  })
  run("Eager import probes do not initialize an unstarted JVM", function(homes) {
    a <- rJavaEnv::java_check_version_cmd(homes[1], quiet = TRUE)
    b <- rJavaEnv::java_check_version_cmd(homes[2], quiet = TRUE)
    # Exercise documented setup before importing an eager dependency. In
    # particular, Linux may need libjvm preloaded by java_env_set().
    rJavaEnv::java_env_set(java_home = homes[1], quiet = TRUE)
    loadNamespace("rjeeager")
    ns <- getNamespace("rJava")
    stopifnot(!get(".jniInitialized", ns))
    stopifnot(!rJavaEnv::java_check_compatibility(a, action = "none"))
    before <- Sys.getenv(c("JAVA_HOME", "PATH"), unset = NA)
    error <- tryCatch(rJavaEnv::java_ensure(b, install = FALSE, quiet = TRUE), error = identity)
    deferred <- get("java_rjava_can_select", asNamespace("rJavaEnv"))()
    if (deferred) {
      stopifnot(isTRUE(error), get(".jvmState", ns)()$state == "not-loaded")
    } else {
      stopifnot(inherits(error, "error"), grepl("Restart R", conditionMessage(error)))
      stopifnot(identical(before, Sys.getenv(names(before), unset = NA)))
    }
    stopifnot(!get(".jniInitialized", ns))
    # Command-only setup can still change the executable, without starting rJava.
    stopifnot(rJavaEnv::java_ensure(b, check_against = "cmd", install = FALSE, quiet = TRUE))
    stopifnot(!get(".jniInitialized", ns))
    stopifnot(rJavaEnv::java_check_version_cmd(quiet = TRUE) == b)
  })
  run("Running parent JVM stays fixed while isolated child uses another JDK", function(homes) {
    a <- rJavaEnv::java_check_version_cmd(homes[1], quiet = TRUE)
    b <- rJavaEnv::java_check_version_cmd(homes[2], quiet = TRUE)
    rJavaEnv::java_env_set(java_home = homes[1], quiet = TRUE)
    actual <- rjeeager::rjava_version()
    stopifnot(rJavaEnv::java_check_compatibility(a, type = "exact", action = "stop"))
    before <- Sys.getenv(c("JAVA_HOME", "PATH"), unset = NA)
    stopifnot(rJavaEnv::java_ensure(actual, install = FALSE, quiet = TRUE))
    error <- tryCatch(rJavaEnv::java_ensure(b, install = FALSE, quiet = TRUE), error = identity)
    stopifnot(inherits(error, "error"), grepl("restart", conditionMessage(error), ignore.case = TRUE))
    child <- rjedownstream::isolated_version(b)
    stopifnot(sub("[.].*", "", child) == b)
    stopifnot(identical(actual, rjeeager::rjava_version()))
    stopifnot(identical(before, Sys.getenv(names(before), unset = NA)))
  })
  run("Deferred rJava permits setup after eager downstream import", function(homes) {
    b <- rJavaEnv::java_check_version_cmd(homes[2], quiet = TRUE)
    loadNamespace("rjeeager")
    can_select <- get("java_rjava_can_select", asNamespace("rJavaEnv"))
    if (!can_select()) {
      # Released rJava must continue to reject selection after namespace load.
      error <- tryCatch(rJavaEnv::java_ensure(b, install = FALSE, quiet = TRUE), error = identity)
      stopifnot(inherits(error, "error"))
      return(invisible(NULL))
    }
    ns <- getNamespace("rJava")
    state <- get(".jvmState", ns)
    stopifnot(state()$state == "not-loaded", !state()$initialized)
    stopifnot(rJavaEnv::java_ensure(b, install = FALSE, quiet = TRUE))
    stopifnot(state()$state == "not-loaded", !state()$initialized)
    actual <- rjeeager::rjava_version()
    stopifnot(sub("[.].*", "", actual) == b, state()$initialized)
    stopifnot(!can_select())
  })
  run("Managed-only resolution never accepts active system Java", function(homes) {
    a <- rJavaEnv::java_check_version_cmd(homes[1], quiet = TRUE)
    cache <- tempfile("empty-java-cache-")
    on.exit(unlink(cache, recursive = TRUE), add = TRUE)
    dir.create(file.path(cache, "installed"), recursive = TRUE)
    error <- tryCatch(rJavaEnv::java_resolve(a, accept_system_java = FALSE,
      install = FALSE, cache_path = cache, quiet = TRUE), error = identity)
    stopifnot(inherits(error, "error"), grepl("not found", conditionMessage(error)))
    stopifnot(!"rJava" %in% loadedNamespaces())
  })
  cat("All downstream integration cases passed.\n")
}
main()
