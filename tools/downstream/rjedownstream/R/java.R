# A startup probe must leave rJava unloaded, even when it is installed.
.onLoad <- function(libname, pkgname) {
  java_compatible_at_load <<- rJavaEnv::java_check_compatibility(8, action = "none")
}
java_compatible_at_load <- FALSE

setup_java <- function(version, ...) {
  if (!rJavaEnv::java_ensure(version, ...)) stop("Java setup failed.")
  invisible(TRUE)
}

command_version <- function(version) {
  rJavaEnv::local_java_env(version, install = FALSE)
  system2("java", "-version", stdout = TRUE, stderr = TRUE)
}

rjava_version <- function(version) {
  # Setup precedes the first use of rJava, including requireNamespace().
  setup_java(version, install = FALSE)
  if (!requireNamespace("rJava", quietly = TRUE)) stop("Install rJava first.")
  rJava::.jinit()
  rJavaEnv::java_check_compatibility(version, type = "exact", action = "stop")
  rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
}

isolated_version <- function(version) {
  rJavaEnv::with_rjava_env(version, install = FALSE, func = function() {
    rJava::.jinit()
    rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
  })
}
