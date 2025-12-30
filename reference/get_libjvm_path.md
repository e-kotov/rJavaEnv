# Find path to libjvm dynamic library

Locates the Java Virtual Machine (JVM) dynamic library within a given
JAVA_HOME. Searches for `libjvm.so` on Linux and `libjvm.dylib` on
macOS. Prefers the server JVM over the client JVM when multiple versions
are found.

## Usage

``` r
get_libjvm_path(java_home)
```

## Arguments

- java_home:

  Character. Path to Java Home directory.

## Value

Character path to libjvm library, or NULL if not found.
