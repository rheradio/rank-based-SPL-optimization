library(tidyverse)

################################################################################
# Read data
################################################################################

files <- list.files("./results/") 
# Remove files with hyperparameter tuning information
files <- files[!str_detect(files, "tuned_pars")]
# Remove pdf files
files <- files[!str_detect(files, "[.]pdf")]

columns <- c("version","spl","achieved_best_perf") 
near_optimals <- data.frame(matrix(nrow = 0, ncol = length(columns))) 
colnames(near_optimals) <- columns

for (f in files) {
  d <- read.delim(str_c("./results/", f), sep = ";")
  near_optimals <- rbind(near_optimals, d)
}

spl_levels <- c(
  "BerkeleyDBC",
  "7z",
  "VP9"
)
near_optimals$spl <- factor(near_optimals$spl, spl_levels)

version_levels <- c(
  "Rank-based Approach",
  "Uniform Random Sampling"
)
near_optimals$version <- factor(near_optimals$version, 
                                rev(version_levels))

################################################################################

################################################################################
# Plot the results
################################################################################

ggplot(near_optimals, aes(x=version, y=achieved_best_perf)) +
  theme_bw() +
  geom_boxplot(outlier.shape = NA, size= 0.3) +
  facet_grid(spl~.) +
  labs(x ="Approach", 
       y = "Rank (0=best, 100=worst)")+
  coord_flip() +
  ggtitle("Best configuration") 

ggsave("./results/best_configuration.pdf", width=6, height=3.5)

################################################################################
# Print a summary
################################################################################

near_optimals_summary <- near_optimals %>%
  group_by(spl, version) %>%
  summarize(mean = mean(achieved_best_perf),
            sd = sd(achieved_best_perf),
            median = median(achieved_best_perf))
print(near_optimals_summary)

library(knitr)
kable(near_optimals_summary, "latex", booktabs = TRUE, digits = 2)
