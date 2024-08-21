## Resubmission

This is a resubmission. In this version I have:

* Fixed removed the broken link in URI: vignettes/rJavaEnv.Rmd from: README.md

This is a resubmission. In this version I have:

* As per CRAN reviewer's request, added single quotes to all package, software and API names in the package title and package description.

* As per CRAN reviewer's request, revised the logic of the functions, examples and vignettes to not write to the user's home filespace by default. All examples use `tempdir()`. Also, like 'renv' ( https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/init.R#L69-L86 ), the package checks if user has previously consented to writing to the their home space on every run of a function that might result in writing something to the user's home filespace.

* Speficically, as per CRAN reviewer's instructions, I have changed the functions in `R/java_env.R`. `java_env_set()` now only changes the environemnt variables in current session by default. Other functions in this file would only change any files in the current project or any other non-temp directory only if instructed by the user.

* Created a global option `rJavaEnv.cache_path` to set the cache folder for downloaded Java installations. The default cache is in `tools::R_user_dir("rJavaEnv", which = "cache")`, just like in `renv` ( https://github.com/rstudio/renv/blob/d6bced36afa0ad56719ca78be6773e9b4bbb078f/R/bootstrap.R#L940-L950 ).

* With these safeguards, the pacakge will not download any files or write any data to either user space, current dir or even to the system cache in `tools::R_user_dir("rJavaEnv", which = "cache")`. However, keeping the default behaviour of the functions to act in the current directory is vital for the overall smooth experience that is similar to `renv`, which does not require the user to specify the target directory to act on every function run and, except for the first consent inquiry it does not ask the user where to keep the package cache. So the behavior of `rJavaEnv` mimics that of `renv` very closely to provide best user experience.

* Updated the vignettes. Switched vignettes to Quarto.

* Other minor code cleanups.

* I thank CRAN reviewers for the feedback on the initial submission, as it led to significant inmprovements in package design and stability.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.
