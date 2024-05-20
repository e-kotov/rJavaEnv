# java-ver-via-rJava-init.R
args <- commandArgs(trailingOnly = TRUE)
java_home <- args[1]

# Set the JAVA_HOME environment variable
Sys.setenv(JAVA_HOME = java_home)

# Update PATH to include the Java bin directory
old_path <- Sys.getenv("PATH")
new_path <- file.path(java_home, "bin")
Sys.setenv(PATH = paste(new_path, old_path, sep = .Platform$path.sep))

# Load rJava and initialize the JVM
library(rJava)
.jinit()

# Check and print the Java version
java_version <- rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")

# Print the Java version
cat("Java version:", java_version, "\nAt path:", java_home, "\n")
