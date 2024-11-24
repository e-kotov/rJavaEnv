if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
package_list <- c("tidyverse", "scales", "ggpubr", "directlabels", "lubridate", "gghighlight", "resmush")
pacman::p_load(char = package_list)
rm(package_list)

rJava_dlstats <- readr::read_csv2("vignettes/data-for-vignettes/rJava_dlstats.csv")
rJava_dependants_dlstats_cran <- readr::read_csv2("vignettes/data-for-vignettes/rJava_dependants_dlstats_cran.csv")
rJava_dependants_dlstats_bioc <- readr::read_csv2("vignettes/data-for-vignettes/rJava_dependants_dlstats_bioc.csv")
data_table_dlstats <- readr::read_csv2("vignettes/data-for-vignettes/data_table_dlstats.csv")
ggplot2_dlstats <- readr::read_csv2("vignettes/data-for-vignettes/ggplot2_dlstats.csv")

cutoff_date <- "2024-09-26"

rj_and_rj_dep_total_down <- rJava_dependants_dlstats_cran |>
  rbind(rJava_dlstats) |>
  rbind(data_table_dlstats) |>
  rbind(ggplot2_dlstats) |>
  mutate(is_rJava = if_else(package == "rJava", "rJava", "rJava dependent")) |>
  mutate(is_rJava = if_else(package == "ggplot2", "ggplot2", is_rJava)) |>
  mutate(is_rJava = if_else(package == "data.table", "data.table", is_rJava)) |>
  group_by(start, end, is_rJava) |>
  summarise(downloads = sum(downloads, na.rm = T), .groups = "keep") |>
  ungroup()


# Define the custom positioning method
# thanks to https://stackoverflow.com/a/19943864/2956729
# Define the custom positioning method
do.not.reduce <- list(
  cex = 1.5,
  "last.points",
  "calc.boxes",
  dl.trans(x = x + 0.3),  # Shift labels to the right
  qp.labels("y", "bottom", "top", make.tiebreaker("x", "y"))
)


# Overall popularity of rJava vs ggplot and data.table --------------------


# Overall popularity # rJavaPopularity
p_rJavaPopularity <- rj_and_rj_dep_total_down |>
  # filter(downloads < 1000000) |>
  ggplot(aes(x = start, y = downloads)) +
  geom_line(aes(col = is_rJava, linetype = is_rJava)) +
  # geom_line(aes(col = is_rJava)) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::label_number(), breaks = seq(0,3000000,500000)) +
  scale_color_manual(values = c("rJava" = "darkblue", "rJava dependent" = "darkgreen", "ggplot2" = "grey40", "data.table" = "grey40")) +
  scale_linetype_manual(values = c("rJava" = "solid", "rJava dependent" = "solid", "ggplot2" = "dashed", "data.table" = "dashed" )) +
  geom_dl(aes(label = is_rJava, color = is_rJava),
          method = do.not.reduce) +
  labs(title = "CRAN Downloads Over Time for rJava and rJava-dependent Packages",
       subtitle = "compared to popular ggplot2 and data.table for context",
       x = "Date",
       y = "Downloads",
       color = "Package") +
  theme_pubclean(base_size = 18) +
  theme(plot.margin = unit(c(1, 9, 1, 1), "lines"),
        legend.position = "none")


# Build the plot and get the gtable
rJavaPopularity_GTable <- ggplot_gtable(ggplot_build(p_rJavaPopularity))

# Modify the clipping settings
rJavaPopularity_GTable$layout$clip[rJavaPopularity_GTable$layout$name == "panel"] <- "off"

# Draw the plot
p_rJavaPopularity_filepath <- "vignettes/media/images/rJavaPopularity.svg"
dir.create(dirname(p_rJavaPopularity_filepath), recursive = TRUE)
svg(p_rJavaPopularity_filepath, width = 12, height = 6)
grid::grid.draw(rJavaPopularity_GTable)
dev.off()

# resmush::resmush_file(p_rJavaPopularity_filepath, overwrite = TRUE)

p_rJavaPopularity_filepath_pdf <- "vignettes/media/images/rJavaPopularity.pdf"
dir.create(dirname(p_rJavaPopularity_filepath_pdf), recursive = TRUE)
cairo_pdf(p_rJavaPopularity_filepath_pdf, width = 12, height = 6)
grid::grid.draw(rJavaPopularity_GTable)
dev.off()






# individual rJava-dependent packages -------------------------------------

p_rJavaDepIndivAll <- rJava_dependants_dlstats_cran |>
  ggplot(aes(x = end, y = downloads, group = package, color = package)) +
  geom_line(alpha = 0.5) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::label_number()) +
  gghighlight(max(downloads), max_highlight = 5L, label_key = package) +
  theme_pubclean(base_size = 18) +
  labs(title = "Downloads Over Time for Selected Packages",
       x = "Date",
       y = "Downloads",
       color = "Package")

# Draw the plot
p_rJavaDepIndivAll_filepath <- "vignettes/media/images/rJavaDepIndivAll.svg"
dir.create(dirname(p_rJavaDepIndivAll_filepath), recursive = TRUE)
svg(p_rJavaDepIndivAll_filepath, width = 12, height = 6)
grid::grid.draw(p_rJavaDepIndivAll)
dev.off()


# resmush::resmush_file(p_rJavaDepIndivAll_filepath, overwrite = TRUE)

# top 20 rJava-dependent packages without xlsx -----------------------------------------

p_rJavaDepIndivFiltered <- rJava_dependants_dlstats_cran |>
  filter(! package %in% c("xlsx", "xlsxjars") ) |>
  filter(! grepl("jars$", package)) |>
  filter(end >= "2023-09-26") |>
  group_by(package) |>
  summarise(downloads = sum(downloads, na.rm = T), .groups = "drop") |>
  arrange(desc(downloads)) |>
  head(20) |>
  mutate(package = factor(package, levels = rev(unique(package)))) |>
  ggplot(aes(x = downloads, y = package)) +
  geom_point() +
  geom_segment(aes(x = 0, xend = downloads, y = package, yend = package)) +
  scale_x_continuous(labels = scales::label_number()) +
  # geom_line(alpha = 0.5) +
  # scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  # scale_y_continuous(labels = scales::label_number()) +
  # gghighlight(max(downloads), max_highlight = 6L) +
  theme_pubclean(base_size = 18) +
  labs(title = "Top rJava-based Package Downloads",
       subtitle = "Over the Last Year (September 2023 - September 2024)",
       x = "Total dowloads",
       y = "")

# Draw the plot
p_rJavaDepIndivFiltered_filepath <- "vignettes/media/images/rJavaDepIndivFiltered.svg"
dir.create(dirname(p_rJavaDepIndivFiltered_filepath), recursive = TRUE)
svg(p_rJavaDepIndivFiltered_filepath, width = 12, height = 6)
grid::grid.draw(p_rJavaDepIndivFiltered)
dev.off()


# resmush::resmush_file(p_rJavaDepIndivFiltered_filepath, overwrite = TRUE)

# top 20 rJava-dependent packages with xlsx -----------------------------------------

p_rJavaDepIndivFilteredXslx <- rJava_dependants_dlstats_cran |>
  filter(! grepl("jars$", package)) |>
  filter(end >= "2023-09-26") |>
  group_by(package) |>
  summarise(downloads = sum(downloads, na.rm = T), .groups = "drop") |>
  arrange(desc(downloads)) |>
  head(20) |>
  mutate(package = factor(package, levels = rev(unique(package)))) |>
  ggplot(aes(x = downloads, y = package)) +
  geom_point() +
  geom_segment(aes(x = 0, xend = downloads, y = package, yend = package)) +
  scale_x_continuous(labels = scales::label_number()) +
  # geom_line(alpha = 0.5) +
  # scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  # scale_y_continuous(labels = scales::label_number()) +
  # gghighlight(max(downloads), max_highlight = 6L) +
  theme_pubclean(base_size = 18) +
  labs(title = "Top rJava-based Package Downloads",
       subtitle = "Over the Last Year (September 2023 - September 2024)",
       x = "Total dowloads",
       y = "")


# Draw the plot
p_rJavaDepIndivFilteredXslx_filepath <- "vignettes/media/images/rJavaDepIndivFilteredXslx.svg"
dir.create(dirname(p_rJavaDepIndivFilteredXslx_filepath), recursive = TRUE)
svg(p_rJavaDepIndivFilteredXslx_filepath, width = 12, height = 6)
grid::grid.draw(p_rJavaDepIndivFilteredXslx)
dev.off()


# resmush::resmush_file(p_rJavaDepIndivFiltered_filepath, overwrite = TRUE)
