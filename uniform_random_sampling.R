################################################################################ 
# Uniform Random Sampling (URS)
################################################################################ 
# Running the URS-based optimization on BerkeleyDBC, 7z, and VP9
################################################################################ 

library(tidyverse)

VERSION <- "Uniform Random Sampling"

# SPLs considered in the experiments.
# The SPLs' data are read from the "data" directory
SPLs <- c("BerkeleyDBC", "7z", "VP9")

SAMPLE_SIZE <- 1000

EXPERIMENTAL_RUNS <- 100

NROWS <- EXPERIMENTAL_RUNS*length(SPLs)

near_optimals <- tibble(
  version = rep(VERSION, NROWS),
  spl = rep(NA, NROWS),
  achieved_best_perf = rep(NA, NROWS)
)

i <- 1
while (i <= NROWS) {
  for (spl in SPLs) {
    writeLines(str_c("Running experiment ", i, " of ", NROWS, "..."))  
    writeLines(str_c("Optimizing the performance of ", spl, "..."))
    
    data <- read.delim(str_c("./data/", spl, ".csv"), sep = ";")
    
    sample_indices <-
      sample(1:nrow(data), round(SAMPLE_SIZE), replace = FALSE)
    sample <- data[sample_indices, ]

    best_in_sample <- arrange(sample, PERFORMANCE)[1,]
    
    data <- data %>%
      mutate(RANK = min_rank(PERFORMANCE)) %>%
      mutate(NORMALIZED_RANK = (RANK -1) * 100 / (max(RANK) - 1)) 
    best_in_sample <- left_join(best_in_sample, data)
    near_optimals[i,]$spl <- spl 
    near_optimals[i,]$achieved_best_perf <- best_in_sample$NORMALIZED_RANK 

    i <- i+1
  }
}

write.table(near_optimals,
            "./results/uniform_random_sampling.csv",
            sep=";",
            row.names = FALSE)


