# rJavaEnv 0.2.2 (2024-09-13)

* Hot fix: improve robustness of setting Java environment in the current session with either `use_java()` or `java_quick_install()`. See bug fix below.

* Bug fix: Setting Java environment via `rJava::.jniInitialized()` rendered impossible changing Java version for `rJava`-dependent packages, because it somehow pre-initialised `rJava`
