% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/java_env.R
\name{java_check_version_rjava}
\alias{java_check_version_rjava}
\title{Check Java Version with a Specified JAVA_HOME Using a Separate R Session}
\usage{
java_check_version_rjava(java_home = NULL, quiet = FALSE)
}
\arguments{
\item{java_home}{Path to Java home directory. If NULL, the function uses the JAVA_HOME environment variable.}

\item{quiet}{A \code{logical} value indicating whether to suppress messages. Can be \code{TRUE} or \code{FALSE}.}
}
\value{
A \code{character} vector of length 1 containing the major Java version.
}
\description{
This function sets the JAVA_HOME environment variable, initializes the JVM using rJava, and prints the Java version that would be used if the user sets the given JAVA_HOME in the current R session. This check is performed in a separate R session to avoid having to reload the current R session. The reason for this is that once Java is initialized in an R session, it cannot be uninitialized unless the current R session is restarted.
}
\examples{
\dontrun{
java_check_version_rjava()
}

}
