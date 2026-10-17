# rJava is already imported here, but this probe must not start the JVM.
.onLoad <- function(libname, pkgname) {
  java_compatible_at_load <<- rJavaEnv::java_check_compatibility(8, action = "none")
}
java_compatible_at_load <- FALSE

rjava_version <- function() {
  .jinit()
  rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
}
