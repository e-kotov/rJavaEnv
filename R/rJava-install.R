#' Re-install rJava with properly set enviroment variables
#' @param java_home
#' @export
java_reinstall_rJava <- function(
  java_home
) {
  # java_reinstall_rJava(rJavaEnv::java_install(rJavaEnv::java_download("21", quiet = TRUE),quiet = TRUE))
  # java_home <- rJavaEnv::java_install(rJavaEnv::java_download("21"))
  if ("rJava" %in% rownames(installed.packages())) {
    pkg_path <- find.package("rJava", quiet = TRUE)
    remove.packages("rJava", lib = dirname(pkg_path))
    print("Successfully removed rJava")
  }

  env_vars <- c(
    JAVA_HOME = java_home,
    JAVA_CPPFLAGS = paste0(
      "-I",
      java_home,
      "/include -I",
      java_home,
      "/include/linux"
    ),
    JAVA_LIBS = paste0("-L", java_home, "/lib/server -ljvm"),
    LD_LIBRARY_PATH = paste0(java_home, "/lib/server")
  )

  env_list <- as.list(env_vars)
  do.call(Sys.setenv, env_list)

  install.packages("rJava")
  if (requireNamespace("rJava", quietly = TRUE)) {
    print("Successfully re-installed rJava")
  }
}
