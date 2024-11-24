if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
package_list <- c("devtools", "dlstats", "tidyverse")
pacman::p_load(char = package_list)
rm(package_list)


dlstats::set_cran_start_year(2014)

rJava_dependants <- devtools::revdep("rJava", dependencies = c("Imports", "Depends"), bioconductor = TRUE)

rJava_dlstats <- dlstats::cran_stats("rJava", use_cache = FALSE)
rJava_dependants_dlstats_cran <- dlstats::cran_stats(rJava_dependants, use_cache = FALSE)
rJava_dependants_dlstats_bioc <- dlstats::bioc_stats(rJava_dependants, use_cache = FALSE, type = "Software")
data_table_dlstats <- dlstats::cran_stats("data.table", use_cache = FALSE)
ggplot2_dlstats <- dlstats::cran_stats("ggplot2", use_cache = FALSE)



write_csv2(rJava_dlstats, "vignettes/data-for-vignettes/rJava_dlstats.csv")
write_csv2(rJava_dependants_dlstats_cran, "vignettes/data-for-vignettes/rJava_dependants_dlstats_cran.csv")
write_csv2(rJava_dependants_dlstats_bioc, "vignettes/data-for-vignettes/rJava_dependants_dlstats_bioc.csv")
write_csv2(data_table_dlstats, "vignettes/data-for-vignettes/data_table_dlstats.csv")
write_csv2(ggplot2_dlstats, "vignettes/data-for-vignettes/ggplot2_dlstats.csv")
